package io.github.nicolasjorquera.platform_files

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import kotlin.math.max
import kotlin.math.min

/** A photo the platform cannot decode (corrupt or unsupported format, E-IMG-01). */
class ImageUnreadable : IOException("image unreadable")

/**
 * Turns a photo (JPG, PNG, WebP, HEIC where the device decodes it) into an
 * upright JPEG no larger than the requested box, for «Fotos a PDF» pages and
 * their thumbnails. Decodes with inSampleSize so a 50 MP photo never sits in
 * memory at full size (PRD H2), then applies the EXIF orientation plus the
 * user's quarter turns.
 */
object ImagePreparer {
    /** Returns the written JPEG's width and height. */
    fun prepare(src: File, dest: File, maxWidth: Int, maxHeight: Int, quality: Int, quarterTurns: Int): IntArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(src.path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw ImageUnreadable()

        val exifTurns = exifQuarterTurns(src)
        val turns = ((exifTurns + quarterTurns) % 4 + 4) % 4
        // The box applies to the upright image: swap it when the image turns sideways.
        val (boxW, boxH) = if (turns % 2 == 1) maxHeight to maxWidth else maxWidth to maxHeight
        val scale = min(1.0, min(boxW.toDouble() / bounds.outWidth, boxH.toDouble() / bounds.outHeight))

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= bounds.outWidth * scale && bounds.outHeight / (sample * 2) >= bounds.outHeight * scale) {
            sample *= 2
        }
        val decoded = BitmapFactory.decodeFile(src.path, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: throw ImageUnreadable()

        val targetW = max(1, (bounds.outWidth * scale).toInt())
        val targetH = max(1, (bounds.outHeight * scale).toInt())
        val matrix = Matrix().apply {
            postScale(targetW.toFloat() / decoded.width, targetH.toFloat() / decoded.height)
            postRotate(90f * turns)
        }
        val upright = Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
        if (upright !== decoded) decoded.recycle()

        val part = File(dest.path + ".part")
        try {
            FileOutputStream(part).use { out ->
                // JPEG has no alpha: paint transparent PNG areas white, like paper.
                val opaque = if (upright.hasAlpha()) onWhite(upright) else upright
                if (!opaque.compress(Bitmap.CompressFormat.JPEG, quality, out)) throw IOException("compress failed")
                if (opaque !== upright) opaque.recycle()
            }
            if (!part.renameTo(dest)) throw IOException("rename failed")
            return intArrayOf(upright.width, upright.height)
        } finally {
            part.delete()
            upright.recycle()
        }
    }

    private fun onWhite(bitmap: Bitmap): Bitmap {
        val out = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)
        android.graphics.Canvas(out).apply {
            drawColor(android.graphics.Color.WHITE)
            drawBitmap(bitmap, 0f, 0f, null)
        }
        return out
    }

    private fun exifQuarterTurns(src: File): Int = try {
        when (ExifInterface(src.path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
            ExifInterface.ORIENTATION_ROTATE_90, ExifInterface.ORIENTATION_TRANSPOSE -> 1
            ExifInterface.ORIENTATION_ROTATE_180, ExifInterface.ORIENTATION_FLIP_VERTICAL -> 2
            ExifInterface.ORIENTATION_ROTATE_270, ExifInterface.ORIENTATION_TRANSVERSE -> 3
            else -> 0
        }
    } catch (_: Exception) {
        0 // PNG, WebP without EXIF or unreadable metadata: keep as is.
    }
}
