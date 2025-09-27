import SwiftUI
import UIKit

public struct ContentRouter<LoaderContent: View, Content: View>: View {
    @StateObject private var coordinator: ContentCoordinator
    @Environment(\.scenePhase) private var scenePhase
    let loaderContent: () -> LoaderContent
    let content: () -> Content
    let progressColor: Color
    private var oneSignalAppID: String?
    private var amplitudeAPIKey: String?
    
    public init(
        contentType: ContentType,
        contentSourceURL: String,
        progressColor: Color = .white,
        loaderContent: @escaping () -> LoaderContent,
        content: @escaping () -> Content
    ) {
        self.oneSignalAppID = nil
        self.amplitudeAPIKey = nil
        print("[APP:System] 🔍 Input URL: \(contentSourceURL)")        
        let finalURL: String
        
        switch contentType {
        case .classic:
            finalURL = AnalyticsManager.shared.appendUserIDToURL(contentSourceURL)
            print("[APP:System] 🚀 Classic mode with analytics")
        case .withoutLibAndTest:
            finalURL = contentSourceURL
            print("[APP:System] 🚀 Classic mode without analytics")
        case .dropbox:
            finalURL = contentSourceURL
            print("[APP:System] 📦 Dropbox mode")
        case .privacy(let appleId):
            finalURL = AnalyticsManager.shared.appendUserIDToURL(contentSourceURL)
            print("[APP:System] 🔒 Privacy mode with analytics (AppleID: \(appleId))")
        }
                
        self._coordinator = StateObject(
            wrappedValue: ContentCoordinator(
                contentSourceURL: finalURL,
                contentType: contentType
            )
        )
        self.loaderContent = loaderContent
        self.content = content
        self.progressColor = progressColor
    }
    
    private init(
        contentType: ContentType,
        contentSourceURL: String,
        progressColor: Color = .white,
        loaderContent: @escaping () -> LoaderContent,
        content: @escaping () -> Content,
        oneSignalAppID: String?,
        amplitudeAPIKey: String?
    ) {
        self.oneSignalAppID = oneSignalAppID
        self.amplitudeAPIKey = amplitudeAPIKey
        print("[APP:System] 🔍 Input URL: \(contentSourceURL)")        
        let finalURL: String
        
        switch contentType {
        case .classic:
            finalURL = AnalyticsManager.shared.appendUserIDToURL(contentSourceURL)
            print("[APP:System] 🚀 Classic mode with analytics")
        case .withoutLibAndTest:
            finalURL = contentSourceURL
            print("[APP:System] 🚀 Classic mode without analytics")
        case .dropbox:
            finalURL = contentSourceURL
            print("[APP:System] 📦 Dropbox mode")
        case .privacy(let appleId):
            finalURL = AnalyticsManager.shared.appendUserIDToURL(contentSourceURL)
            print("[APP:System] 🔒 Privacy mode with analytics (AppleID: \(appleId))")
        }
                
        self._coordinator = StateObject(
            wrappedValue: ContentCoordinator(
                contentSourceURL: finalURL,
                contentType: contentType
            )
        )
        self.loaderContent = loaderContent
        self.content = content
        self.progressColor = progressColor
    }
    
    public var body: some View {
        ZStack {
            switch coordinator.displayMode {
            case .loading:
                loaderContent()
                    .transition(.opacity)
                
            case .basic:
                content()
                    .transition(.opacity)
                    .onAppear {
                        AnalyticsManager.shared.trackEvent(.mainPageLaunch)
                        print("[APP:System] 📱 Open basic")
                    }
                
            case .enhanced(let contentURL):
                ContentInterface(contentURL: contentURL, contentCoordinator: coordinator, progressColor: progressColor)
                    .transition(.opacity)
                    .onAppear {
                        AnalyticsManager.shared.trackEvent(.wVLaunch)
                        print("[APP:System] ✅ Open W: \(contentURL)")
                    }
            }
        }
        .animation(.easeInOut, value: coordinator.displayMode)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                AnalyticsManager.shared.refreshPushSubscription()
            }
        }
        .onAppear {
            initializeAnalyticsIfNeeded()
        }
    }
    
    private func initializeAnalyticsIfNeeded() {
        if oneSignalAppID != nil || amplitudeAPIKey != nil {
            let launchOptions = getLaunchOptions()
            AnalyticsManager.shared
                .enable(launchOptions: launchOptions)
                .oneSignal(oneSignalAppID)
                .amplitude(amplitudeAPIKey)
                .start()
        }
    }
    
    private func getLaunchOptions() -> [UIApplication.LaunchOptionsKey: Any]? {
        return nil
    }
}

public extension ContentRouter {
    func oneSignal(_ appID: String?) -> ContentRouter {
        return ContentRouter(
            contentType: coordinator.contentType,
            contentSourceURL: coordinator.contentSourceURL,
            progressColor: progressColor,
            loaderContent: loaderContent,
            content: content,
            oneSignalAppID: appID,
            amplitudeAPIKey: amplitudeAPIKey
        )
    }
    
    func amplitude(_ apiKey: String?) -> ContentRouter {
        return ContentRouter(
            contentType: coordinator.contentType,
            contentSourceURL: coordinator.contentSourceURL,
            progressColor: progressColor,
            loaderContent: loaderContent,
            content: content,
            oneSignalAppID: oneSignalAppID,
            amplitudeAPIKey: apiKey
        )
    }
}
