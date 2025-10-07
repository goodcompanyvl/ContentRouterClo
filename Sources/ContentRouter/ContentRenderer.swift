import Foundation
import UIKit
import SwiftUI
import WebKit
import SafariServices

internal struct ContentRenderer: UIViewRepresentable {
    let contentSourceURL: String
    let enableGestureControl: Bool
    let enablePullToRefresh: Bool
    let contentType: ContentType
    let progressColor: Color
    @Binding var contentRenderer: WKWebView?
    @Binding var isBuffering: Bool
    @Binding var bufferingProgress: Double
    @Binding var webKitCanGoBack: Bool
    let contentCoordinator: ContentCoordinator?
    
    internal init(
        contentSourceURL: String,
        contentRenderer: Binding<WKWebView?>,
        isBuffering: Binding<Bool>,
        bufferingProgress: Binding<Double>,
        webKitCanGoBack: Binding<Bool>,
        enableGestureControl: Bool = false,
        enablePullToRefresh: Bool = false,
        contentType: ContentType = .dropbox,
        contentCoordinator: ContentCoordinator? = nil,
        progressColor: Color
    ) {
        self.contentSourceURL = contentSourceURL
        self._contentRenderer = contentRenderer
        self._isBuffering = isBuffering
        self._bufferingProgress = bufferingProgress
        self._webKitCanGoBack = webKitCanGoBack
        self.enableGestureControl = enableGestureControl
        self.enablePullToRefresh = enablePullToRefresh
        self.contentType = contentType
        self.contentCoordinator = contentCoordinator
        self.progressColor = progressColor
    }
    
    internal func makeUIView(context: Context) -> WKWebView {
        let engineConfig = WKWebViewConfiguration()
        let enginePrefs = WKWebpagePreferences()
        enginePrefs.allowsContentJavaScript = true
        enginePrefs.preferredContentMode = .mobile
        engineConfig.defaultWebpagePreferences = enginePrefs
        engineConfig.allowsInlineMediaPlayback = true
        engineConfig.mediaTypesRequiringUserActionForPlayback = []
        engineConfig.allowsAirPlayForMediaPlayback = true
        engineConfig.allowsPictureInPictureMediaPlayback = true
        engineConfig.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let contentView = WKWebView(frame: .zero, configuration: engineConfig)
        contentView.navigationDelegate = context.coordinator
        contentView.uiDelegate = context.coordinator
        contentView.allowsBackForwardNavigationGestures = enableGestureControl
        contentView.scrollView.isScrollEnabled = true
        contentView.scrollView.backgroundColor = .clear
        contentView.allowsLinkPreview = true
        contentView.customUserAgent = AppConfig.securityEngineBrowserAgent
        context.coordinator.monitorBuffering(contentView: contentView)
        
        if enablePullToRefresh {
            context.coordinator.setupPullToRefresh(contentView: contentView)
        }
        
        let contentIdentifier = AppConfig.contentSourceKey
        if let savedURL = UserDefaults.standard.string(forKey: contentIdentifier) {
            print("[APP:W] 💾 Saved URL: \(savedURL)")
        }
        
        return contentView
    }
    
    internal func updateUIView(_ uiView: WKWebView, context: Context) {
        DispatchQueue.main.async {
            self.contentRenderer = uiView
        }
        
        if uiView.allowsBackForwardNavigationGestures != enableGestureControl {
            uiView.allowsBackForwardNavigationGestures = enableGestureControl
        }
        
        context.coordinator.updatePullToRefresh(contentView: uiView, enabled: enablePullToRefresh)
        
        if uiView.url == nil {
            if contentSourceURL == "about:blank" {
                uiView.loadHTMLString("", baseURL: nil)
                return
            }
            if let contentURL = URL(string: contentSourceURL) {
                var contentRequest = URLRequest(
                    url: contentURL,
                    cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                    timeoutInterval: AppConfig.networkTimeoutInterval
                )
                contentRequest.setValue(
                    AppConfig.securityEngineBrowserAgent,
                    forHTTPHeaderField: "User-Agent"
                )
                uiView.load(contentRequest)
            }
        }
    }
    
    internal func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    internal class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: ContentRenderer
        
        private var bufferingMonitor: NSKeyValueObservation?
        private var canGoBackMonitor: NSKeyValueObservation?
        private var bufferingTimer: Timer?
        private var refreshControl: UIRefreshControl?
        private var hasCompletedInitialLoad = false
        private var urlProtectionTimer: Timer?
        private var popupWebView: WKWebView?
        private var popupContainerView: UIView?
        var didTriggerBasicSwitch = false

        init(_ parent: ContentRenderer) {
            self.parent = parent
        }
        
        private func isURLOverwriteBlocked() -> Bool {
            let protectionKey = "\(AppConfig.contentSourceKey)_protected"
            return UserDefaults.standard.bool(forKey: protectionKey)
        }
        
        private func blockURLOverwrite() {
            let protectionKey = "\(AppConfig.contentSourceKey)_protected"
            UserDefaults.standard.set(true, forKey: protectionKey)
            UserDefaults.standard.synchronize()
        }
        
        func monitorBuffering(contentView: WKWebView) {
            bufferingMonitor = contentView.observe(\.estimatedProgress, options: [.new]) { [weak self] engine, _ in
                DispatchQueue.main.async {
                    let progress = engine.estimatedProgress
                    self?.parent.bufferingProgress = progress
                }
            }
            
            canGoBackMonitor = contentView.observe(\.canGoBack, options: [.new]) { [weak self] engine, _ in
                DispatchQueue.main.async {
                    let webKitCanGoBack = engine.canGoBack
                    self?.parent.webKitCanGoBack = webKitCanGoBack
                }
            }
        }
        
        func setupPullToRefresh(contentView: WKWebView) {
            if refreshControl == nil {
                let control = UIRefreshControl()
                control.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
                control.tintColor = UIColor(self.parent.progressColor)
                contentView.scrollView.refreshControl = control
                refreshControl = control
            }
        }
        
        func updatePullToRefresh(contentView: WKWebView, enabled: Bool) {
            if enabled && refreshControl == nil {
                setupPullToRefresh(contentView: contentView)
            } else if !enabled && refreshControl != nil {
                contentView.scrollView.refreshControl = nil
                refreshControl = nil
            }
        }
        
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            if let webView = sender.superview?.superview as? WKWebView {
                parent.isBuffering = true
                webView.reload()
            } else {
                sender.endRefreshing()
            }
        }
        
        func resetInitialLoadFlag() {
            hasCompletedInitialLoad = false
        }
        
        deinit {
            bufferingMonitor?.invalidate()
            canGoBackMonitor?.invalidate()
            
            if let popup = popupWebView {
                popup.removeFromSuperview()
                popupWebView = nil
            }
            
            if let container = popupContainerView {
                container.removeFromSuperview()
                popupContainerView = nil
            }
        }
        
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Проверяем это popup окно
            let isPopup = (webView == popupWebView)
            
            if didTriggerBasicSwitch && !isPopup {
                decisionHandler(.cancel)
                return
            }
            
            if let url = navigationAction.request.url {
                let scheme = url.scheme?.lowercased()
                let urlString = url.absoluteString.lowercased()

                if let scheme = scheme,
                   scheme != "http", scheme != "https", scheme != "about" {
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url, options: [:]) { success in
                            if !success {
                                self.showAppNotInstalledAlert(for: scheme)
                            }
                        }
                    }
                    
                    decisionHandler(.cancel)
                    return
                }
            }

            decisionHandler(.allow)
        }
        
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            let urlString = navigationResponse.response.url?.absoluteString ?? "N/A"
            print("[APP:W] 📡 Response: \(urlString)")
            if let httpResponse = navigationResponse.response as? HTTPURLResponse {
                let status = httpResponse.statusCode
                print("[APP:W] 📡 Code: \(status)")
                if parent.contentType == .dropbox && status == 404 {
                    // Проверяем, был ли уже показан enhanced режим ранее
                    let hasShownEnhanced = UserDefaults.standard.string(forKey: AppConfig.contentSourceKey) != nil
                    if hasShownEnhanced {
                        print("[APP:W] ⚠️ HTTP \(status) but enhanced was shown before, continuing")
                        decisionHandler(.allow)
                        return
                    }
                    
                    if didTriggerBasicSwitch {
                        decisionHandler(.cancel)
                        return
                    }
                    didTriggerBasicSwitch = true
                    print("[APP:W] ❌ HTTP \(status) in dropbox mode (first launch), switching to basic")
                    cancelBufferingTimer()
                    parent.isBuffering = false
                    DispatchQueue.main.async { [weak webView] in
                        webView?.stopLoading()
                        webView?.loadHTMLString("", baseURL: nil)
                        self.parent.contentCoordinator?.handle404Error()
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            let urlString = webView.url?.absoluteString ?? "N/A"
            print("[APP:W] 🔄 Loading: \(urlString)")
            if didTriggerBasicSwitch {
                webView.stopLoading()
                return
            }
            
            if urlString.contains("about:blank") {
                print("[APP:W] ⚠️ about:blank detected")
            }
                        
            parent.isBuffering = true
            cancelBufferingTimer()
            bufferingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
                 print("[APP:W] ⏰ Loading timeout")
                 self?.parent.isBuffering = false
                 DispatchQueue.main.async {
                     self?.refreshControl?.endRefreshing()
                 }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let urlString = webView.url?.absoluteString ?? "N/A"
            print("[APP:W] 🎉 Finish: \(urlString)")
            parent.isBuffering = false
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl?.endRefreshing()
            }
            cancelBufferingTimer()
            
            // Сохраняем URL только при успешной загрузке в dropbox режиме
            if parent.contentType == .dropbox {
                let dropboxKey = "\(AppConfig.contentSourceKey)_dropbox"
                let hasShownEnhanced = UserDefaults.standard.string(forKey: dropboxKey) != nil
                if !hasShownEnhanced && !urlString.isEmpty && urlString != "N/A" {
                    UserDefaults.standard.set(urlString, forKey: dropboxKey)
                    print("[APP:W] 💾 Dropbox URL saved after successful load: \(urlString)")
                }
            }
            
            AnalyticsManager.shared.trackWebViewNavigation(url: urlString)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            let urlString = webView.url?.absoluteString ?? "N/A"
            print("[APP:W] ❌ Navigation failed for \(urlString): \(error.localizedDescription)")
            processBufferingError(error)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
             let urlString = webView.url?.absoluteString ?? "attempted content buffering"
            print("[APP:W] ❌ Provisional navigation failed for \(urlString): \(error.localizedDescription)")
            processBufferingError(error)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            let urlString = navigationAction.request.url?.absoluteString ?? "N/A"
            
            // Если это App Store ссылка - открываем в системном браузере
            if urlString.lowercased().contains("apps.apple.com") || urlString.lowercased().contains("itunes.apple.com") {
                if let url = navigationAction.request.url {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url, options: [:]) { success in
                        }
                    }
                }
                return nil
            }
            
            let isNewWindowRequest = navigationAction.targetFrame == nil
            let isPaymentPopup = isNewWindowRequest
            
            // Если это запрос из popup окна (например, OAuth) - загружаем в том же popup
            let isPopup = (webView == popupWebView)
            if isPopup {
                print("[APP:W] 🔄 Popup redirect: \(urlString)")
                if let url = navigationAction.request.url {
                    webView.load(navigationAction.request)
                }
                return nil
            }
            
            if isPaymentPopup {
                if let existingPopup = popupWebView {
                    existingPopup.removeFromSuperview()
                    popupWebView = nil
                }
                if let existingContainer = popupContainerView {
                    existingContainer.removeFromSuperview()
                    popupContainerView = nil
                }
                
                configuration.allowsInlineMediaPlayback = true
                configuration.mediaTypesRequiringUserActionForPlayback = []
                configuration.allowsAirPlayForMediaPlayback = true
                configuration.allowsPictureInPictureMediaPlayback = true
                configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
                configuration.preferences.javaScriptEnabled = true
                
                popupWebView = WKWebView(frame: webView.bounds, configuration: configuration)
                guard let popup = popupWebView else {
                    return nil
                }
                
                popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                popup.navigationDelegate = self
                popup.uiDelegate = self
                popup.customUserAgent = webView.customUserAgent
                popup.scrollView.backgroundColor = .black
                popup.backgroundColor = .black
                popup.isOpaque = true
                popup.allowsLinkPreview = true
                
                let containerView = UIView(frame: webView.bounds)
                containerView.backgroundColor = .black
                containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                
                containerView.addSubview(popup)
                
                let closeButton = createCloseButton()
                containerView.addSubview(closeButton)
                
                NSLayoutConstraint.activate([
                    closeButton.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 10),
                    closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
                    closeButton.widthAnchor.constraint(equalToConstant: 30),
                    closeButton.heightAnchor.constraint(equalToConstant: 30)
                ])
                
                if let superView = webView.superview {
                    superView.addSubview(containerView)
                    popupContainerView = containerView
                }
                
                if let url = navigationAction.request.url {
                    popup.load(navigationAction.request)
                }
                
                return popup
            }
            
            if let targetContentURL = navigationAction.request.url {
                var request = URLRequest(url: targetContentURL)
                
                if let headers = navigationAction.request.allHTTPHeaderFields {
                    for (key, value) in headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                }
                
                request.setValue(webView.customUserAgent, forHTTPHeaderField: "User-Agent")
                request.httpMethod = navigationAction.request.httpMethod
                
                if let body = navigationAction.request.httpBody {
                    request.httpBody = body
                }
                
                print("[APP:W] ➡️ Load: \(targetContentURL.absoluteString)")
                webView.load(request)
            }
            return nil
        }
        
        private func processBufferingError(_ error: Error) {
            parent.isBuffering = false
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl?.endRefreshing()
            }
            cancelBufferingTimer()
        }
        
        private func cancelBufferingTimer() {
            if bufferingTimer != nil {
                bufferingTimer?.invalidate()
                bufferingTimer = nil
            }
        }
        
        private func startURLProtectionTimer() {
            urlProtectionTimer?.invalidate()
            urlProtectionTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                self?.blockURLOverwrite()
                self?.urlProtectionTimer = nil
            }
        }
        
        private func haveSameBaseDomain(urlString1: String?, urlString2: String?) -> Bool {
            guard let urlString1 = urlString1, let urlString2 = urlString2,
                  let url1 = URL(string: urlString1), let url2 = URL(string: urlString2),
                  let host1 = url1.host, let host2 = url2.host else {
                return false
            }
            
            let components1 = host1.components(separatedBy: ".")
            let components2 = host2.components(separatedBy: ".")
            
            let baseDomain1 = components1.count >= 2 ? components1.suffix(2).joined(separator: ".") : host1
            let baseDomain2 = components2.count >= 2 ? components2.suffix(2).joined(separator: ".") : host2
            
            return baseDomain1 == baseDomain2
        }
        
        private func createCloseButton() -> UIButton {
            let closeButton = UIButton(type: .system)
            closeButton.setTitle("✕", for: .normal)
            closeButton.setTitleColor(.white, for: .normal)
            closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            closeButton.layer.cornerRadius = 15
            closeButton.layer.borderWidth = 2
            closeButton.layer.borderColor = UIColor.white.cgColor
            closeButton.layer.shadowColor = UIColor.black.cgColor
            closeButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            closeButton.layer.shadowOpacity = 0.5
            closeButton.layer.shadowRadius = 4
            closeButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
            
            closeButton.layer.zPosition = 1000
            
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            closeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
            closeButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
            
            return closeButton
        }
        
        @objc private func closePopup() {
            if let popup = popupWebView {
                popup.removeFromSuperview()
                popupWebView = nil
            }
            if let container = popupContainerView {
                container.removeFromSuperview()
                popupContainerView = nil
            }
        }
        
        func webViewDidClose(_ webView: WKWebView) {
            if webView == popupWebView {
                webView.removeFromSuperview()
                popupWebView = nil
                if let container = popupContainerView {
                    container.removeFromSuperview()
                    popupContainerView = nil
                }
            }
        }
        
        private func showAppNotInstalledAlert(for scheme: String?) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            
            let appName = getAppName(for: scheme)
            let alert = UIAlertController(
                title: "App Not Installed",
                message: "\(appName) is not installed on this device. Please install it from the App Store to continue.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            rootViewController.present(alert, animated: true)
        }
        
        private func getAppName(for scheme: String?) -> String {
            guard let scheme = scheme else { return "Required app" }
            
            switch scheme.lowercased() {
            case "metamask": return "MetaMask"
            case "trust": return "Trust Wallet"
            case "rainbow": return "Rainbow"
            case "coinbase": return "Coinbase Wallet"
            case "exodus": return "Exodus"
            case "safe": return "Safe"
            case "zerion": return "Zerion"
            case "argent": return "Argent"
            case "1inch": return "1inch Wallet"
            case "imtokenv2": return "imToken"
            case "tokenpocket": return "TokenPocket"
            default: return "Wallet app"
            }
        }
    }
} 

