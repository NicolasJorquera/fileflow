package io.github.nicolasjorquera.platform_files

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class StreamCopyTest {
    @Test
    fun `copies every byte in chunks`() {
        val data = ByteArray(1_000_003) { (it % 251).toByte() }
        val out = ByteArrayOutputStream()
        assertEquals(data.size.toLong(), copyStream(ByteArrayInputStream(data), out, bufferSize = 4096))
        assertContentEquals(data, out.toByteArray())
    }

    @Test
    fun `stops between chunks once cancelled`() {
        var chunks = 0
        val endless = object : InputStream() {
            override fun read(): Int = 0
            override fun read(b: ByteArray, off: Int, len: Int): Int = len.also { chunks++ }
        }
        assertFailsWith<CopyCancelled> { copyStream(endless, ByteArrayOutputStream(), { chunks >= 3 }, 16) }
        assertEquals(3, chunks)
    }

    @Test
    fun `classifies failures for the app`() {
        assertEquals(ErrorCodes.CANCELLED, classifyIo(CopyCancelled()))
        assertEquals(ErrorCodes.ACCESS_LOST, classifyIo(SecurityException("Permission Denial")))
        assertEquals(ErrorCodes.ACCESS_LOST, classifyIo(FileNotFoundException("gone")))
        assertEquals(ErrorCodes.NO_SPACE, classifyIo(IOException("write failed: ENOSPC (No space left on device)")))
        assertEquals(ErrorCodes.NO_SPACE, classifyIo(IOException("wrapper", IOException("No space left on device"))))
        assertEquals(ErrorCodes.IO, classifyIo(IOException("broken pipe")))
    }
}
