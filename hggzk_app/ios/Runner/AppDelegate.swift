import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      let bundleId = Bundle.main.bundleIdentifier ?? "(nil)"
      if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         let options = FirebaseOptions(contentsOfFile: filePath) {
        if let runtimeBundleId = Bundle.main.bundleIdentifier {
          options.bundleID = runtimeBundleId
        }
        FirebaseApp.configure(options: options)
        NSLog("Firebase configured. bundleId=\(bundleId) plistPath=\(filePath)")
      } else {
        NSLog("Firebase NOT configured: GoogleService-Info.plist not found in app bundle. bundleId=\(bundleId)")
      }
    } else {
      NSLog("Firebase already configured; skipping configure()")
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
