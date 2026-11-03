package io.github.nicolasjorquera.platform_files

import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

/**
 * JPEG encoding with the platform codec (spike S7: ~4x faster than Dart).
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
        require(rgba.size == width * height * 4) { "pixel buffer does not match ${width}x$height" }
        val src = take(width, height)
        src.copyPixelsFromBuffer(ByteBuffer.wrap(rgba))
        val scaled = if (targetWidth != width || targetHeight != height) {
            Bitmap.createScaledBitmap(src, targetWidth, targetHeight, true)
        } else {
            src
        }
        val out = ByteArrayOutputStream(targetWidth * targetHeight / 4)
        scaled.compress(Bitmap.CompressFormat.JPEG, quality, out)
        if (scaled !== src) scaled.recycle()
        give(src)
        return out.toByteArray()
    }
}
