package io.github.nicolasjorquera.platform_files

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.mlkit.vision.documentscanner.GmsDocumentScanner
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult

/**
 * Google's ML Kit document scanner, used directly so the app can tell the two
 * failures of the PRD apart: E-SCAN-01 (the scanner module is not on the
 * phone yet and there is no connection to fetch it) and E-SCAN-02 (no Google
 * Play services or under 1.7 GB of RAM). No camera permission: the scanner
 * runs in Google Play services' own UI.
 */
class DocumentScanner(private val context: Context) {
    private fun scanner(maxPages: Int): GmsDocumentScanner = GmsDocumentScanning.getClient(
        GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(true)
            .setPageLimit(maxPages)
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build(),
    )

    /** ML Kit's documented minimum for the scanner. */
    private val minimumRam = 1_700L * 1024 * 1024

    fun totalMemory(): Long {
        val info = ActivityManager.MemoryInfo()
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(info)
        return info.totalMem
    }

    fun isSupported(): Boolean =
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS &&
            totalMemory() >= minimumRam

    /**
     * "ready", "needsDownload", "offline" (module missing and no connection:
     * Google Play services would only show its own «Can't reach the Internet»
     * screen, so the app explains it instead, E-SCAN-01) or "unsupported".
     */
    fun status(done: (String) -> Unit) {
        if (!isSupported()) return done(STATUS_UNSUPPORTED)
        val missing = { done(if (hasInternet()) STATUS_NEEDS_DOWNLOAD else STATUS_OFFLINE) }
        ModuleInstall.getClient(context).areModulesAvailable(scanner(1))
            .addOnSuccessListener { if (it.areModulesAvailable()) done(STATUS_READY) else missing() }
            .addOnFailureListener { missing() }
    }

    private fun hasInternet(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    /** Asks Google Play services to fetch the module when it can (PRD: first start with a connection). */
    fun prepare() {
        if (isSupported()) ModuleInstall.getClient(context).deferredInstall(scanner(1))
    }

    /** Opens the scanner; [onError] gets an error code when it cannot start. */
    fun start(activity: Activity, maxPages: Int, requestCode: Int, onError: (String) -> Unit) {
        if (!isSupported()) return onError(ERROR_UNSUPPORTED)
        scanner(maxPages).getStartScanIntent(activity)
            .addOnSuccessListener { sender ->
                try {
                    activity.startIntentSenderForResult(sender, requestCode, null, 0, 0, 0)
                } catch (_: Exception) {
                    onError(ErrorCodes.IO)
                }
            }
            // Offline without the module is the usual cause (spike S4).
            .addOnFailureListener { onError(ERROR_MODULE_MISSING) }
    }

    /** The scanned PDF's content URI and page count, or null when the user cancelled. */
    fun parse(resultCode: Int, data: Intent?): Pair<android.net.Uri, Int>? {
        if (resultCode != Activity.RESULT_OK) return null
        val pdf = GmsDocumentScanningResult.fromActivityResultIntent(data)?.pdf ?: return null
        return pdf.uri to pdf.pageCount
    }

    companion object {
        const val STATUS_READY = "ready"
        const val STATUS_NEEDS_DOWNLOAD = "needsDownload"
        const val STATUS_UNSUPPORTED = "unsupported"
        const val STATUS_OFFLINE = "offline"
        const val ERROR_MODULE_MISSING = "scanner_module_missing"
        const val ERROR_UNSUPPORTED = "scanner_unsupported"
    }
}
