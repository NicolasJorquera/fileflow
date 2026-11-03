import Flutter
import UIKit

/// iOS arrives with FileFlow 2.0 (gate E). Until then every call reports
/// "not implemented" so the Dart side can fail cleanly.
public class PlatformFilesPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "io.github.nicolasjorquera.platform_files", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(PlatformFilesPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
