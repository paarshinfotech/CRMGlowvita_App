import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let path = Bundle.main.path(forResource: "flutter_assets/.env", ofType: nil) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                if line.starts(with: "GOOGLE_MAPS_API_KEY=") {
                    let key = line.replacingOccurrences(of: "GOOGLE_MAPS_API_KEY=", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    GMSServices.provideAPIKey(key)
                }
            }
        } catch {
            print("Error reading .env file: \(error)")
        }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

}
