package io.github.nicolasjorquera.platform_files

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.nio.ByteBuffer

/**
 * JPEG and PNG encoding with the platform codec (spike S7: ~4x faster than Dart).
 * Pixels arrive as RGBA, already box-reduced by the PDF engine; this scales the
 * remaining fraction and compresses. The source bitmap is reused between calls
 * of the same size (scanned pages usually share one) to cut allocations.
 */
class JpegEncoder {
    private var reusable: Bitmap? = null

    @Synchronized
    private fun take(width: Int, height: Int): Bitmap {
        val cached = reusable
        if (cached != null && !cached.isRecycled && cached.width == width && cached.height == height) {
            reusable = null
            return cached
        }
        return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    }

    @Synchronized
    private fun give(bitmap: Bitmap) {
        reusable?.recycle()
        reusable = bitmap
    }

    fun encode(rgba: ByteArray, width: Int, height: Int, targetWidth: Int, targetHeight: Int, quality: Int): ByteArray {
        val out = ByteArrayOutputStream(targetWidth * targetHeight / 4)
        write(rgba, width, height, targetWidth, targetHeight, Bitmap.CompressFormat.JPEG, quality, out)
        return out.toByteArray()
    }

    /**
     * Encodes straight into [dest] (written to a temporary sibling, then
     * renamed) and returns its size: big pages never travel back over the channel.
     * PNG ignores [quality].
     */
    fun encodeToFile(rgba: ByteArray, width: Int, height: Int, png: Boolean, quality: Int, dest: File): Long {
        val part = File(dest.path + ".part")
        try {
            FileOutputStream(part).use { out ->
                val format = if (png) Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG
                write(rgba, width, height, width, height, format, quality, out)
                out.fd.sync()
            }
            if (!part.renameTo(dest)) throw java.io.IOException("rename failed")
            return dest.length()
        } finally {
            part.delete()
        }
    }

    private fun write(
        rgba: ByteArray,
        width: Int,
        height: Int,
        targetWidth: Int,
        targetHeight: Int,
        format: Bitmap.CompressFormat,
        quality: Int,
        out: OutputStream,
    ) {
        require(rgba.size == width * height * 4) { "pixel buffer does not match ${width}x$height" }
        val src = take(width, height)
        src.copyPixelsFromBuffer(ByteBuffer.wrap(rgba))
        val scaled = if (targetWidth != width || targetHeight != height) {
            Bitmap.createScaledBitmap(src, targetWidth, targetHeight, true)
        } else {
            src
        }
        if (!scaled.compress(format, quality, out)) throw java.io.IOException("compress failed")
        if (scaled !== src) scaled.recycle()
        give(src)
    }
}
