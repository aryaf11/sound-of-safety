import Flutter
import UIKit

/// تضمين Flutter الكلاسيكي — متوافق مع إصدارات Flutter الأقدم على الماك (بدون Implicit Engine APIs).
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
