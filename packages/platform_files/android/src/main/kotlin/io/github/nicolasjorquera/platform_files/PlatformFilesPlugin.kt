package io.github.nicolasjorquera.platform_files

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/** FileProvider of this plugin, limited to files/results/ (see res/xml/platform_files_paths.xml). */
class PlatformFilesProvider : FileProvider()

/**
 * File plumbing for FileFlow: system pickers (SAF, Photo Picker), streamed
 * copies in and out of the app, sharing through a FileProvider, receiving
 * "Share" intents and JPEG encoding with the platform codec.
 *
 * No storage permission is needed for any of it (PRD RN-12).
 */
class PlatformFilesPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.NewIntentListener,
    EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var incomingChannel: EventChannel
    private var activity: Activity? = null
    private var binding: ActivityPluginBinding? = null

    private val io = Executors.newFixedThreadPool(2)
    private val encoderPool = Executors.newFixedThreadPool(2)
    private val main = Handler(Looper.getMainLooper())
    private val encoder = JpegEncoder()
    private val cancelledCopies = ConcurrentHashMap.newKeySet<String>()

    private var pending: Pending? = null
    private var incomingSink: EventChannel.EventSink? = null
    private var undelivered: List<Map<String, Any?>>? = null

    private sealed class Pending(val result: MethodChannel.Result) {
        class Documents(result: MethodChannel.Result) : Pending(result)
        class Images(result: MethodChannel.Result, val max: Int) : Pending(result)
        class SaveAs(result: MethodChannel.Result, val src: String) : Pending(result)
        class SaveAll(result: MethodChannel.Result, val sources: List<String>, val names: List<String>, val mime: String) :
            Pending(result)
        class Scan(result: MethodChannel.Result, val destPath: String) : Pending(result)
    }

    private val scanner by lazy { DocumentScanner(context) }

    // region Flutter lifecycle

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        context = b.applicationContext
        channel = MethodChannel(b.binaryMessenger, CHANNEL).also { it.setMethodCallHandler(this) }
        incomingChannel = EventChannel(b.binaryMessenger, "$CHANNEL/incoming").also { it.setStreamHandler(this) }
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        incomingChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(b: ActivityPluginBinding) {
        binding = b
        activity = b.activity
        b.addActivityResultListener(this)
        b.addOnNewIntentListener(this)
        handleIntent(b.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = onAttachedToActivity(b)

    override fun onDetachedFromActivity() {
        binding?.removeActivityResultListener(this)
        binding?.removeOnNewIntentListener(this)
        binding = null
        activity = null
    }

    // endregion

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "pickDocuments" -> pickDocuments(call.argument("mimeTypes")!!, call.argument("multiple") ?: false, result)
                "pickImages" -> pickImages(call.argument("max") ?: 100, result)
                "copyToFile" -> copyToFile(call.argument("uri")!!, call.argument("destPath")!!, call.argument("copyId")!!, result)
                "cancelCopy" -> {
                    cancelledCopies.add(call.argument<String>("copyId")!!)
                    result.success(null)
                }
                "saveAs" -> saveAs(call.argument("srcPath")!!, call.argument("name")!!, call.argument("mime")!!, result)
                "saveAllToFolder" -> saveAllToFolder(call.argument("srcPaths")!!, call.argument("names")!!, call.argument("mime")!!, result)
                "share" -> share(call.argument("paths")!!, call.argument("mime")!!, result)
                "openWith" -> openWith(call.argument("path")!!, call.argument("mime")!!, result)
                "freeBytes" -> result.success(StatFs(call.argument<String>("path")!!).availableBytes)
                "encodeJpeg" -> encodeJpeg(call, result)
                "encodeToFile" -> encodeToFile(call, result)
                "prepareImage" -> prepareImage(call, result)
                "deviceMemory" -> result.success(scanner.totalMemory())
                "scannerStatus" -> scanner.status { result.success(it) }
                "prepareScanner" -> {
                    scanner.prepare()
                    result.success(null)
                }
                "scanDocument" -> scanDocument(call.argument("maxPages")!!, call.argument("destPath")!!, result)
                else -> result.notImplemented()
            }
        } catch (e: NullPointerException) {
            result.error(ErrorCodes.BAD_ARGS, "missing argument for ${call.method}", null)
        }
    }

    // region Pickers

    private fun startForResult(intent: Intent, request: Pending, code: Int) {
        val a = activity ?: return request.result.error(ErrorCodes.IO, "no activity", null)
        if (pending != null) return request.result.error(ErrorCodes.BUSY, "another picker is open", null)
        pending = request
        try {
            a.startActivityForResult(intent, code)
        } catch (e: ActivityNotFoundException) {
            pending = null
            request.result.error(ErrorCodes.NO_APP, "no app handles ${intent.action}", null)
        }
    }

    private fun pickDocuments(mimeTypes: List<String>, multiple: Boolean, result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mimeTypes.size == 1) mimeTypes.first() else "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
        }
        startForResult(intent, Pending.Documents(result), REQUEST_DOCUMENTS)
    }

    /** Photo Picker (backported by Google Play services below Android 13). */
    private fun pickImages(max: Int, result: MethodChannel.Result) {
        val request = PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
        val intent = if (max > 1) {
            ActivityResultContracts.PickMultipleVisualMedia(max).createIntent(context, request)
        } else {
            ActivityResultContracts.PickVisualMedia().createIntent(context, request)
        }
        startForResult(intent, Pending.Images(result, max), REQUEST_IMAGES)
    }

    private fun saveAs(srcPath: String, name: String, mime: String, result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mime
            putExtra(Intent.EXTRA_TITLE, name)
        }
        startForResult(intent, Pending.SaveAs(result, srcPath), REQUEST_SAVE_AS)
    }

    private fun saveAllToFolder(srcPaths: List<String>, names: List<String>, mime: String, result: MethodChannel.Result) {
        startForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), Pending.SaveAll(result, srcPaths, names, mime), REQUEST_SAVE_ALL)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode !in REQUEST_DOCUMENTS..REQUEST_SCAN) return false
        val request = pending ?: return true
        pending = null
        val ok = resultCode == Activity.RESULT_OK && data != null
        when (request) {
            is Pending.Documents -> request.result.success(if (ok) urisOf(data!!).map(::describe) else emptyList<Any>())
            is Pending.Images -> {
                val uris = if (!ok) emptyList() else if (request.max > 1) {
                    ActivityResultContracts.PickMultipleVisualMedia(request.max).parseResult(resultCode, data)
                } else {
                    listOfNotNull(ActivityResultContracts.PickVisualMedia().parseResult(resultCode, data))
                }
                request.result.success(uris.map(::describe))
            }
            is Pending.SaveAs -> {
                val target = data?.data
                if (!ok || target == null) request.result.success(null) else writeTo(target, request.src, request.result)
            }
            is Pending.SaveAll -> {
                val tree = data?.data
                if (!ok || tree == null) request.result.success(null) else writeAll(tree, request)
            }
            is Pending.Scan -> {
                val scanned = scanner.parse(resultCode, data)
                if (scanned == null) request.result.success(null) else copyScan(scanned, request)
            }
        }
        return true
    }

    private fun urisOf(data: Intent): List<Uri> {
        val clip = data.clipData
        if (clip != null) return (0 until clip.itemCount).map { clip.getItemAt(it).uri }
        return listOfNotNull(data.data)
    }

    private fun describe(uri: Uri): Map<String, Any?> {
        var name: String? = null
        var size: Long? = null
        try {
            context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    name = c.getString(0)
                    if (!c.isNull(1)) size = c.getLong(1)
                }
            }
        } catch (_: Exception) {
            // Some providers refuse queries; the name falls back below.
        }
        return mapOf(
            "uri" to uri.toString(),
            "name" to (name ?: uri.lastPathSegment ?: "documento"),
            "size" to size,
            "mime" to context.contentResolver.getType(uri),
        )
    }

    // endregion

    // region Streamed copies

    private fun copyToFile(uri: String, destPath: String, copyId: String, result: MethodChannel.Result) {
        io.execute {
            val dest = File(destPath)
            try {
                val bytes = context.contentResolver.openInputStream(Uri.parse(uri)).use { input ->
                    requireNotNull(input) { "provider returned no stream" }
                    FileOutputStream(dest).use { out -> copyStream(input, out, { copyId in cancelledCopies }) }
                }
                main.post { result.success(bytes) }
            } catch (e: Throwable) {
                dest.delete()
                main.post { result.error(classifyIo(e), e.javaClass.simpleName, null) }
            } finally {
                cancelledCopies.remove(copyId)
            }
        }
    }

    private fun writeTo(target: Uri, srcPath: String, result: MethodChannel.Result) {
        io.execute {
            try {
                context.contentResolver.openOutputStream(target, "wt").use { out ->
                    requireNotNull(out) { "provider returned no stream" }
                    FileInputStream(srcPath).use { input -> copyStream(input, out) }
                }
                main.post { result.success(target.toString()) }
            } catch (e: Throwable) {
                runCatching { DocumentsContract.deleteDocument(context.contentResolver, target) }
                main.post { result.error(classifyIo(e), e.javaClass.simpleName, null) }
            }
        }
    }

    private fun writeAll(tree: Uri, request: Pending.SaveAll) {
        io.execute {
            val resolver: ContentResolver = context.contentResolver
            val parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
            var written = 0
            try {
                request.sources.forEachIndexed { i, src ->
                    val doc = DocumentsContract.createDocument(resolver, parent, request.mime, request.names[i])
                        ?: throw java.io.IOException("could not create document")
                    resolver.openOutputStream(doc, "wt").use { out ->
                        FileInputStream(src).use { input -> copyStream(input, out!!) }
                    }
                    written++
                }
                main.post { request.result.success(written) }
            } catch (e: Throwable) {
                main.post { request.result.error(classifyIo(e), "${e.javaClass.simpleName} after $written files", null) }
            }
        }
    }

    // endregion

    // region Share / open with

    private fun contentUri(path: String): Uri =
        FileProvider.getUriForFile(context, "${context.packageName}.platform_files.fileprovider", File(path))

    private fun share(paths: List<String>, mime: String, result: MethodChannel.Result) {
        val a = activity ?: return result.error(ErrorCodes.IO, "no activity", null)
        val uris = ArrayList(paths.map(::contentUri))
        val send = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).putExtra(Intent.EXTRA_STREAM, uris.first())
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
        }
        send.type = mime
        send.clipData = ClipData.newUri(context.contentResolver, "files", uris.first()).apply {
            uris.drop(1).forEach { addItem(ClipData.Item(it)) }
        }
        send.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        a.startActivity(Intent.createChooser(send, null).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
        result.success(null)
    }

    private fun openWith(path: String, mime: String, result: MethodChannel.Result) {
        val a = activity ?: return result.error(ErrorCodes.IO, "no activity", null)
        val view = Intent(Intent.ACTION_VIEW).setDataAndType(contentUri(path), mime).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            a.startActivity(view)
            result.success(null)
        } catch (e: ActivityNotFoundException) {
            result.error(ErrorCodes.NO_APP, "no app opens $mime", null)
        }
    }

    // endregion

    // region Incoming "Share" intents

    override fun onNewIntent(intent: Intent): Boolean = handleIntent(intent)

    private fun handleIntent(intent: Intent?): Boolean {
        if (intent == null || intent.getBooleanExtra(HANDLED, false)) return false
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamListExtra(intent)
            else -> return false
        }
        intent.putExtra(HANDLED, true) // a recreated activity must not re-deliver it
        if (uris.isEmpty()) return true
        val docs = uris.map(::describe)
        val sink = incomingSink
        if (sink != null) sink.success(docs) else undelivered = docs
        return true
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= 33) intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun streamListExtra(intent: Intent): List<Uri> =
        (if (Build.VERSION.SDK_INT >= 33) intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        else intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)) ?: emptyList()

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        incomingSink = events
        undelivered?.let { events.success(it) }
        undelivered = null
    }

    override fun onCancel(arguments: Any?) {
        incomingSink = null
    }

    // endregion

    private fun encodeJpeg(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")!!
        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        val targetWidth = call.argument<Int>("targetWidth")!!
        val targetHeight = call.argument<Int>("targetHeight")!!
        val quality = call.argument<Int>("quality")!!
        encoderPool.execute {
            try {
                val jpeg = encoder.encode(bytes, width, height, targetWidth, targetHeight, quality)
                main.post { result.success(jpeg) }
            } catch (e: Throwable) {
                main.post { result.error(ErrorCodes.ENCODE_FAILED, e.javaClass.simpleName, null) }
            }
        }
    }

    private fun encodeToFile(call: MethodCall, result: MethodChannel.Result) {
        val bytes = call.argument<ByteArray>("bytes")!!
        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        val png = call.argument<String>("format")!! == "png"
        val quality = call.argument<Int>("quality")!!
        val dest = File(call.argument<String>("destPath")!!)
        encoderPool.execute {
            try {
                val size = encoder.encodeToFile(bytes, width, height, png, quality, dest)
                main.post { result.success(size) }
            } catch (e: java.io.IOException) {
                main.post { result.error(classifyIo(e), e.javaClass.simpleName, null) }
            } catch (e: Throwable) {
                main.post { result.error(ErrorCodes.ENCODE_FAILED, e.javaClass.simpleName, null) }
            }
        }
    }

    // region Photos and scanner

    private fun prepareImage(call: MethodCall, result: MethodChannel.Result) {
        val src = File(call.argument<String>("srcPath")!!)
        val dest = File(call.argument<String>("destPath")!!)
        val maxWidth = call.argument<Int>("maxWidth")!!
        val maxHeight = call.argument<Int>("maxHeight")!!
        val quality = call.argument<Int>("quality")!!
        val turns = call.argument<Int>("quarterTurns") ?: 0
        // One photo at a time per lane: a decoded 12 MP photo is ~48 MB.
        encoderPool.execute {
            try {
                val size = ImagePreparer.prepare(src, dest, maxWidth, maxHeight, quality, turns)
                main.post { result.success(listOf(size[0], size[1])) }
            } catch (e: ImageUnreadable) {
                main.post { result.error(ErrorCodes.IMAGE_UNREADABLE, "unreadable", null) }
            } catch (e: OutOfMemoryError) {
                main.post { result.error(ErrorCodes.IMAGE_UNREADABLE, "out of memory", null) }
            } catch (e: java.io.IOException) {
                main.post { result.error(classifyIo(e), e.javaClass.simpleName, null) }
            }
        }
    }

    private fun scanDocument(maxPages: Int, destPath: String, result: MethodChannel.Result) {
        val a = activity ?: return result.error(ErrorCodes.IO, "no activity", null)
        if (pending != null) return result.error(ErrorCodes.BUSY, "another picker is open", null)
        val request = Pending.Scan(result, destPath)
        pending = request
        scanner.start(a, maxPages, REQUEST_SCAN) { code ->
            if (pending === request) pending = null
            result.error(code, code, null)
        }
    }

    /** Copies the scanner's PDF out of Google Play services' cache into the result slot. */
    private fun copyScan(scanned: Pair<Uri, Int>, request: Pending.Scan) {
        io.execute {
            val dest = File(request.destPath)
            try {
                context.contentResolver.openInputStream(scanned.first).use { input ->
                    FileOutputStream(dest).use { out -> copyStream(input!!, out) }
                }
                main.post { request.result.success(scanned.second) }
            } catch (e: Exception) {
                dest.delete()
                main.post { request.result.error(classifyIo(e), e.javaClass.simpleName, null) }
            }
        }
    }

    // endregion

    companion object {
        const val CHANNEL = "io.github.nicolasjorquera.platform_files"
        private const val HANDLED = "io.github.nicolasjorquera.platform_files.HANDLED"
        private const val REQUEST_DOCUMENTS = 0x4F10
        private const val REQUEST_IMAGES = 0x4F11
        private const val REQUEST_SAVE_AS = 0x4F12
        private const val REQUEST_SAVE_ALL = 0x4F13
        private const val REQUEST_SCAN = 0x4F14
    }
}
