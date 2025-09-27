# ContentRouter

A powerful SwiftUI framework for intelligent content routing with built-in analytics support.

## 📦 Installation

```swift
dependencies: [
    .package(url: "https://github.com/goodcompanyvl/ContentRouterClo.git", from: "1.2.0")
]
```

## 🚀 Usage

```swift
import SwiftUI
import ContentRouter

@main
struct MyApp: App {
    @StateObject private var dataStore = DataStore()

    var body: some Scene {
        ContentRouterScene(
            oneSignalAppID: "5c36bf56-7b2f-452f-bcf8-b2b39e98242e",
            amplitudeAPIKey: "cd65a778a84a2da4063bae931e04f8bf"
        ) {
            ContentRouter(
                contentType: .classic,
                contentSourceURL: "https://goodcompanyapps.com/TPsszR5Z",
                loaderContent: {
                    SplashView()
                },
                content: {
                    ContentView()
                }
            )
        }
    }
}
```

## ✨ Features

- 🎯 **Smart Content Routing** - Automatically routes between native and web content
- 📊 **Built-in Analytics** - OneSignal and Amplitude integration without AppDelegate
- 🔄 **Multiple Content Types** - Classic, Privacy, Dropbox modes
- 📱 **SwiftUI Native** - Clean integration with modern SwiftUI apps
- 🚀 **Zero Configuration** - Works out of the box

## 📋 Content Types

```swift
.classic                              // Standard mode with analytics
.privacy(appleId: "123456789")       // Privacy-aware mode
.dropbox                             // Dropbox-hosted content
.withoutLibAndTest                   // Testing mode without analytics
```

## 🔧 Analytics Options

```swift
// Both services
ContentRouterScene(
    oneSignalAppID: "your-onesignal-app-id",
    amplitudeAPIKey: "your-amplitude-api-key"
) { /* content */ }

// OneSignal only
ContentRouterScene(oneSignalAppID: "your-app-id") { /* content */ }

// Amplitude only
ContentRouterScene(amplitudeAPIKey: "your-api-key") { /* content */ }

// No analytics
ContentRouterScene() { /* content */ }
```

## 📊 Automatic Events

- `app_launch` - When app starts
- `onboarding_launch` - When showing native content
- `main_page_launch` - When main view appears
- `wv_launch` - When web view opens
- `page_in_wview` - Web view navigation

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+