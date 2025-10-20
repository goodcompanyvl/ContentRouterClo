# ContentRouter

A powerful SwiftUI framework for intelligent content routing with built-in analytics support.

## 📦 Installation

```swift
dependencies: [
    .package(url: "https://github.com/goodcompanyvl/ContentRouterClo.git", from: "1.9.0")
]
```

## 📝 Changelog

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

