import SwiftUI
import UIKit

extension Notification.Name {
    static let analyticsInitialized = Notification.Name("analyticsInitialized")
}

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
        
        // Уведомляем ContentRouter что аналитика инициализирована
        NotificationCenter.default.post(name: .analyticsInitialized, object: nil)
    }
}

public struct ContentRouter<LoaderContent: View, Content: View>: View {
    @StateObject private var coordinator: ContentCoordinator
    @Environment(\.scenePhase) private var scenePhase
    let loaderContent: () -> LoaderContent
    let content: () -> Content
    let progressColor: Color
    let contentType: ContentType
    let originalContentSourceURL: String
    let releaseDate: DateComponents
    
    public init(
        contentType: ContentType,
        contentSourceURL: String,
        releaseDate: DateComponents,
        progressColor: Color,
        loaderContent: @escaping () -> LoaderContent,
        content: @escaping () -> Content
    ) {
        self.contentType = contentType
        self.originalContentSourceURL = contentSourceURL
        self.releaseDate = releaseDate
        
        print("[APP:System] 🔍 Input URL: \(contentSourceURL)")
        
        // Создаем координатор с исходным URL, он обновится после инициализации аналитики
        self._coordinator = StateObject(
            wrappedValue: ContentCoordinator(
                contentSourceURL: contentSourceURL, // Временно исходный URL
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
        .onReceive(NotificationCenter.default.publisher(for: .analyticsInitialized)) { _ in
            updateURLWithAnalytics()
        }
    }
    
    private func updateURLWithAnalytics() {
        let finalURL: String
        
        switch contentType {
        case .classic:
            finalURL = AnalyticsManager.shared.appendUserIDToURL(originalContentSourceURL)
            print("[APP:System] 🚀 Classic mode with analytics - URL updated")
        case .withoutLibAndTest:
            finalURL = originalContentSourceURL
            print("[APP:System] 🚀 Classic mode without analytics")
        case .dropbox:
            finalURL = originalContentSourceURL
            print("[APP:System] 📦 Dropbox mode")
        case .privacy(let appleId):
            finalURL = AnalyticsManager.shared.appendUserIDToURL(originalContentSourceURL)
            print("[APP:System] 🔒 Privacy mode with analytics (AppleID: \(appleId)) - URL updated")
        }
        
        // Обновляем URL в координаторе
        coordinator.updateContentSourceURL(finalURL)
    }
}

