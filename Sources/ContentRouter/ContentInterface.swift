import SwiftUI
import WebKit
import AVFoundation
import UIKit

internal struct ContentInterface: View {
    let progressColor: Color
    let contentURL: String
    let contentCoordinator: ContentCoordinator?
    
    @State private var contentRenderer: WKWebView?
    @State private var isBuffering = true
    @State private var bufferingProgress: Double = 0
    @State private var webKitCanGoBack = false
    
    internal init(contentURL: String, contentCoordinator: ContentCoordinator? = nil, progressColor: Color) {
        self.contentURL = contentURL
        self.contentCoordinator = contentCoordinator
        self.progressColor = progressColor
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if isBuffering {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(progressColor)
                        .frame(
                            width: geometry.size.width * CGFloat(bufferingProgress),
                            height: 2
                        )
                        .animation(.linear, value: bufferingProgress)
                }
                .frame(height: 2)
                .background(Color.black)
            }
            
            ContentRenderer(
                contentSourceURL: contentURL,
                contentRenderer: $contentRenderer,
                isBuffering: $isBuffering,
                bufferingProgress: $bufferingProgress,
                webKitCanGoBack: $webKitCanGoBack,
                enableGestureControl: true,
                enablePullToRefresh: true,
                contentType: contentCoordinator?.contentType ?? .dropbox,
                contentCoordinator: contentCoordinator,
                progressColor: progressColor
            )
        }
        .preferredColorScheme(.dark)
    }
} 
