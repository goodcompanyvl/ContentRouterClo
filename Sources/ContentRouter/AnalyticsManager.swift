import Foundation
import UIKit
#if canImport(AmplitudeSwift)
import AmplitudeSwift
#endif

#if canImport(OneSignalFramework)
import OneSignalFramework
#endif

public final class AnalyticsManager {
	@MainActor public static let shared = AnalyticsManager()
    
    private let userIDKey = "user_unique_identifier"
    private var userID: String = ""
    private var appLaunchCount: Int {
        get { UserDefaults.standard.integer(forKey: "app_launch_count") }
        set { UserDefaults.standard.set(newValue, forKey: "app_launch_count") }
    }
    
    private var lastTrackedURL: String = ""
    private var lastTrackedTime: Date = Date.distantPast
    private let navigationDebounceInterval: TimeInterval = 1.0
    
    private var isEnabled = false
    private var isInitialized = false
    
    #if canImport(OneSignalFramework)
    private var oneSignalInitialized = false
    #endif
    
    #if canImport(AmplitudeSwift)
    private var amplitude: Any?
    #endif
    
    private init() { }
    
    private func initializeIfNeeded() {
        guard !isInitialized else { return }
        
        if let storedUserID = UserDefaults.standard.string(forKey: userIDKey) {
            userID = storedUserID
            print("[APP:AnalyticsManager] Using existing userID: \(userID)")
        } else {
            userID = generateUserID()
            UserDefaults.standard.set(userID, forKey: userIDKey)
            print("[APP:AnalyticsManager] Generated new userID: \(userID)")
        }
        
        isInitialized = true
    }
    
    private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    public func enable(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> AnalyticsManager {
        print("[APP:AnalyticsManager] 🚀 Enabling AnalyticsManager...")
        initializeIfNeeded()
        isEnabled = true
        self.launchOptions = launchOptions
        
        let oldCount = appLaunchCount
        appLaunchCount += 1
        print("[APP:AnalyticsManager] App launch count: \(oldCount) → \(appLaunchCount)")
        
        return self
    }
    
    @discardableResult
    public func oneSignal(_ appID: String?) -> AnalyticsManager {
        guard let appID = appID, !appID.isEmpty else {
            print("[APP:AnalyticsManager] OneSignal appID not provided - skipping")
            return self
        }
        
        #if canImport(OneSignalFramework)
        print("[APP:AnalyticsManager] Initializing OneSignal with appID: \(appID)")
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize(appID, withLaunchOptions: launchOptions)
        oneSignalInitialized = true
        print("[APP:AnalyticsManager] ✅ OneSignal successfully loaded")
        
        if appLaunchCount == 1 || appLaunchCount == 3 || appLaunchCount == 6 {
            print("[APP:AnalyticsManager] Requesting push notification permissions (launch #\(self.appLaunchCount))")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                OneSignal.Notifications.requestPermission({ accepted in
                    print("[APP:AnalyticsManager] User accepted notifications: \(accepted)")
                    if accepted {
                        self.refreshPushSubscription()
                    }
                }, fallbackToSettings: true)
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshPushSubscription()
            }
        }
        #else
        print("[APP:AnalyticsManager] ❌ OneSignal framework not available - skipping initialization")
        #endif
        
        return self
    }
    
    @discardableResult
    public func amplitude(_ apiKey: String?) -> AnalyticsManager {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            print("[APP:AnalyticsManager] Amplitude apiKey not provided - skipping")
            return self
        }
        
        #if canImport(AmplitudeSwift)
        print("[APP:AnalyticsManager] Initializing Amplitude with apiKey: \(apiKey)")
        let amplitudeConfig = Configuration(apiKey: apiKey)
        amplitude = Amplitude(configuration: amplitudeConfig)
        if let amp = amplitude as? Amplitude {
            amp.setUserId(userId: userID)
        }
        print("[APP:AnalyticsManager] ✅ Amplitude successfully loaded")
        #else
        print("[APP:AnalyticsManager] ❌ Amplitude framework not available - skipping initialization")
        #endif
        
        return self
    }
    
    public func start() {
        trackEvent(.appLaunch)
    }
    
    public func appendUserIDToURL(_ url: String) -> String {
        guard isEnabled else { return url }
        
        initializeIfNeeded()
        
        guard var urlComponents = URLComponents(string: url) else {
            print("[APP:AnalyticsManager] Failed to parse URL: \(url)")
            return url
        }
        
        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "push_id", value: userID))
        urlComponents.queryItems = queryItems
        
        let resultURL = urlComponents.url?.absoluteString ?? url
        print("[APP:AnalyticsManager] URL modified: \(url) → \(resultURL)")
        return resultURL
    }
    
    public func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        initializeIfNeeded()
        
        var eventParameters = parameters ?? [:]
        eventParameters["user_id"] = userID
        
        var sentTo: [String] = []
        
        #if canImport(AmplitudeSwift)
        if let amp = amplitude as? Amplitude {
            let eventOptions = EventOptions()
            amp.track(
                eventType: event.rawValue,
                eventProperties: eventParameters,
                options: eventOptions
            )
            sentTo.append("Amplitude")
        }
        #endif
        
        // Логируем только если есть активные сервисы
        if !sentTo.isEmpty {
            let parametersString = parameters?.map { "\($0.key): \($0.value)" }.joined(separator: ", ") ?? "none"
            let servicesString = sentTo.joined(separator: ", ")
            print("[APP:AnalyticsManager] Tracking event: \(event.rawValue) → [\(servicesString)], parameters: [\(parametersString)]")
        }
    }
    
    public func trackWebViewNavigation(url: String?) {
        guard isEnabled, let url = url else { return }
        
        initializeIfNeeded()
        
        let normalizedURL = normalizeURL(url)
        let now = Date()
        
        if normalizedURL == lastTrackedURL && now.timeIntervalSince(lastTrackedTime) < navigationDebounceInterval {
            print("[APP:AnalyticsManager] Skipping duplicate navigation event for: \(url)")
            return
        }
        
        lastTrackedURL = normalizedURL
        lastTrackedTime = now
        
        trackEvent(.pageInWV, parameters: ["link": url])
    }
    
    private func normalizeURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString }
        
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.path = url.path
        
        var path = components.path
        if path.hasSuffix("/") && path.count > 1 {
            path.removeLast()
            components.path = path
        }
        
        return components.url?.absoluteString ?? urlString
    }
    
    private func generateUserID() -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let length = Int.random(in: 10...20)
        
        return String((0..<length).map { _ in
            allowedChars.randomElement()!
        })
    }
    
    public var userIDValue: String { 
        initializeIfNeeded()
        return userID 
    }
    
    public func refreshPushSubscription() {
        guard isEnabled else { return }
        
        initializeIfNeeded()
        
        #if canImport(OneSignalFramework)
        guard oneSignalInitialized else {
            print("[APP:AnalyticsManager] OneSignal not initialized - skipping push subscription refresh")
            return
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            
            if isAuthorized {
                print("[APP:AnalyticsManager] Notifications enabled, logging into OneSignal with userID: \(self.userID)")
                OneSignal.login(self.userID)
            } else {
                print("[APP:AnalyticsManager] Notifications not authorized")
            }
        }
        #else
        print("[APP:AnalyticsManager] ❌ OneSignal not available - skipping push subscription refresh")
        #endif
    }
}

public enum AnalyticsEvent: String {
    case appLaunch = "app_launch"
    case onboardingLaunch = "Onboarding_launch"
    case mainPageLaunch = "MainPage_launch"
    case wVLaunch = "WV_launch"
    case pageInWV = "page_in_wview"
    case payment = "payment_page_opened"
}

// @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
//    ) -> Bool {
//        AnalyticsManager.shared
//            .enable(launchOptions: launchOptions)
//            .oneSignal("2616aa05-9b27-42dc-ab67-5cbf88ac3c1f")
//            .amplitude("cd65a778a84a2da4063bae931e04f8bf")
//            .start()
//        return true
//    }
//    
//    func applicationDidBecomeActive(_ application: UIApplication) {
//        AnalyticsManager.shared.refreshPushSubscription()
//    }
//}
