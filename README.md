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
            oneSignalAppID: "your-onesignal-app-id",
            amplitudeAPIKey: "your-amplitude-api-key"
        ) {
            ContentRouter(
                contentType: .classic,
                contentSourceURL: "https://example.com/content",
                progressColor: .blue,
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
- 🎨 **Customizable Progress Color** - Set color for loading indicators and refresh control
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

## 🎨 Progress Color

The `progressColor` parameter sets the color for:
- Progress bar during web content loading
- Pull-to-refresh control in web view

```swift
ContentRouter(
    contentType: .classic,
    contentSourceURL: "https://example.com",
    progressColor: .blue,        // Required - sets loading indicators color
    loaderContent: { /* */ },
    content: { /* */ }
)
```

Common colors: `.blue`, `.red`, `.green`, `.orange`, `.purple`, `.white`, `.black`

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
```

