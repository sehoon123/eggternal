import UIKit
import Flutter
import GoogleMaps
import flutter_local_notifications
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate, FlutterStreamHandler {

  private var eventSink: FlutterEventSink?

  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.delegate = self
    manager.requestWhenInUseAuthorization()
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = false
    return manager
  }()

  private let networkEventchanner = "com.dts.eggciting/location"
  private let CHANNEL_SHARED_PREFS = "sharedPrefsPlatform"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // TODO: Add your Google Maps API key
    GMSServices.provideAPIKey("AIzaSyDOPAW5EG9wHdGM_dY4xz7jz--36HaXVks")

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let locationChannel = FlutterMethodChannel(name: "locationPlatform", binaryMessenger: controller.binaryMessenger)

    FlutterEventChannel(name: networkEventchanner, binaryMessenger: controller.binaryMessenger).setStreamHandler(self)


    locationChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if ("getLocation" == call.method) {
        self.locationManager.startUpdatingLocation()
        result("Location service started")
      } else if ("stopLocation" == call.method) {
        self.locationManager.stopUpdatingLocation()
        result("Location service stopped")
      } else {
        result(FlutterMethodNotImplemented)
        return
      }
    })


    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    guard let eventSink = eventSink else {
        return
      }
    
    if let loc = locations.last?.coordinate {
      eventSink("\(loc.latitude), \(String(describing: loc.longitude))")
    }
}

func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
  if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
    locationManager.startUpdatingLocation()
  } else {
    locationManager.stopUpdatingLocation()
  }
}

func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
  eventSink = events
  return nil
}

func onCancel(withArguments arguments: Any?) -> FlutterError? {
  eventSink = nil
  return nil
}
}
