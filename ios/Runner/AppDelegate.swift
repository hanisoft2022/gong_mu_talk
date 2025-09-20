import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    window?.backgroundColor = UIColor(red: 0.09411765, green: 0.10980392, blue: 0.15294118, alpha: 1.0)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
