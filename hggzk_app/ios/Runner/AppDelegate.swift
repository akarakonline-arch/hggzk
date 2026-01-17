import Flutter
import UIKit
import FirebaseCore
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configure Firebase
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
      print("✅ Firebase configured")
    }

    GMSServices.provideAPIKey("AIzaSyD9O2NbSnvuV3L8Fknz1SqQehBxWLKkZKE")

    GeneratedPluginRegistrant.register(with: self)
    print("✅ Plugins registered")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}