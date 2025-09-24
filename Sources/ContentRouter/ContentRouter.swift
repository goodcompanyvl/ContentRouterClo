import SwiftUI

public struct ContentRouter<LoaderContent: View, Content: View>: View {
    @StateObject private var coordinator: ContentCoordinator
    @Environment(\.scenePhase) private var scenePhase
    let loaderContent: () -> LoaderContent
    let content: () -> Content
    let progressColor: Color
    
    public init(
        contentType: ContentType,
        contentSourceURL: String,
        progressColor: Color = .white,
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
    }
}
