# ContentRouter

A powerful SwiftUI framework for intelligent content routing with built-in analytics support.

## 📦 Installation

```swift
dependencies: [
    .package(url: "https://github.com/goodcompanyvl/ContentRouterClo.git", from: "2.3.1")
]
```

## 📝 Changelog

### v2.3.1
- Fixed push subscription race condition - added delay before login to prevent old deltas

### v2.3.0
- Fixed push subscription race condition - removed duplicate refresh calls on initialization

### v2.2.0
- Fixed OneSignal push subscription reliability - login immediately after initialization

### v2.1.1
- Fixed push notifications in basic mode - login to OneSignal before showing permission dialog

### v2.1.0
- Fixed OneSignal external ID - now sets user ID even when notifications are denied

### v2.0.1
- Optimized UIViewRepresentable lifecycle - moved all initialization logic to makeUIView

### v2.0.0
- Fixed keyboard viewport jump - disabled automatic content inset adjustments
- Changed media autoplay behavior - now requires user interaction

### v1.9.0
- Fixed OneSignal push subscription for basic mode - now properly subscribes after user grants permission

## 🚀 Usage

```swift
		ContentRouterScene(
			oneSignalAppID: "",
			amplitudeAPIKey: "",
			root: {
				ContentRouter(
					contentType: .classic,
					contentSourceURL: "",
					releaseDate: DateComponents(year: 2025, month: 9, day: 30),
					progressColor: Theme.primary,
					loaderContent: {
						SplashView()
					},
					content: {

					}
				)
			}
		)
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

