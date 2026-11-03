package io.github.nicolasjorquera.platform_files

import android.system.ErrnoException
import android.system.OsConstants
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream

/** Thrown by [copyStream] when [isCancelled] turns true; callers delete the partial output. */
class CopyCancelled : IOException("copy cancelled")

/**
 * Copies [input] to [output] in fixed-size chunks so a 300 MB document never
 * sits in memory, checking [isCancelled] between chunks. Returns bytes copied.
 */
fun copyStream(
    input: InputStream,
    output: OutputStream,
    isCancelled: () -> Boolean = { false },
    bufferSize: Int = 256 * 1024,
): Long {
    val buffer = ByteArray(bufferSize)
    var total = 0L
    while (true) {
        if (isCancelled()) throw CopyCancelled()
        val read = input.read(buffer)
        if (read < 0) break
        output.write(buffer, 0, read)
        total += read
    }
    output.flush()
    return total
}

/** Error codes shared with Dart (PlatformFilesException.code). */
object ErrorCodes {
    const val ACCESS_LOST = "access_lost"
    const val NO_SPACE = "no_space"
    const val IO = "io"
    const val CANCELLED = "cancelled"
    const val BUSY = "busy"
    const val NO_APP = "no_app"
    const val BAD_ARGS = "bad_args"
    const val ENCODE_FAILED = "encode_failed"
}

/** Maps a failure while reading a picked URI or writing a file to an error code. */
fun classifyIo(error: Throwable): String {
    var e: Throwable? = error
    while (e != null) {
        when {
            e is CopyCancelled -> return ErrorCodes.CANCELLED
            e is SecurityException || e is FileNotFoundException && e.message.orEmpty().contains("Permission", ignoreCase = true) ->
                return ErrorCodes.ACCESS_LOST
            e is ErrnoException && e.errno == OsConstants.ENOSPC -> return ErrorCodes.NO_SPACE
            e.message.orEmpty().contains("ENOSPC") || e.message.orEmpty().contains("No space left", ignoreCase = true) ->
                return ErrorCodes.NO_SPACE
        }
        e = e.cause
    }
    return if (error is FileNotFoundException) ErrorCodes.ACCESS_LOST else ErrorCodes.IO
}
