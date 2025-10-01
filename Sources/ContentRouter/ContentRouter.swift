import SwiftUI
import UIKit

public struct ContentRouterScene<R: View>: Scene {
    private let root: R
    private let oneSignalAppID: String?
    private let amplitudeAPIKey: String?

    public init(
        oneSignalAppID: String? = nil,
        amplitudeAPIKey: String? = nil,
        @ViewBuilder root: () -> R
    ) {
        self.oneSignalAppID = oneSignalAppID
        self.amplitudeAPIKey = amplitudeAPIKey
        self.root = root()
    }

    public var body: some Scene {
        WindowGroup { 
            ContentRouterSceneView(
                root: root,
                oneSignalAppID: oneSignalAppID,
                amplitudeAPIKey: amplitudeAPIKey
            )
        }
    }
    
}

private struct ContentRouterSceneView<R: View>: View {
    @Environment(\.scenePhase) private var scenePhase
    let root: R
    let oneSignalAppID: String?
    let amplitudeAPIKey: String?
    @State private var hasInitialized = false
    
    var body: some View {
        root
            .onAppear {
                if !hasInitialized {
                    initializeAnalytics()
                    hasInitialized = true
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    AnalyticsManager.shared.refreshPushSubscription()
                }
            }
    }
    
    private func initializeAnalytics() {
        print("[APP:ContentRouterScene] 🚀 Initializing analytics...")
        AnalyticsManager.shared
            .enable(launchOptions: nil)
            .oneSignal(oneSignalAppID)
            .amplitude(amplitudeAPIKey)
            .start()
    }
}

public struct ContentRouter<LoaderContent: View, Content: View>: View {
    @StateObject private var coordinator: ContentCoordinator
    @Environment(\.scenePhase) private var scenePhase
    let loaderContent: () -> LoaderContent
    let content: () -> Content
    let progressColor: Color
    
    public init(
        contentType: ContentType,
        contentSourceURL: String,
        releaseDate: DateComponents,
        progressColor: Color,
        loaderContent: @escaping () -> LoaderContent,
        content: @escaping () -> Content
    ) {
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
                contentType: contentType,
                releaseDate: releaseDate
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
    }
}

