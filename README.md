# ContentRouter

A powerful SwiftUI framework for intelligent content routing with built-in analytics support.

## ✨ Features

- 🎯 **Smart Content Routing** - Automatically routes between native and web content
- 📊 **Built-in Analytics** - OneSignal and Amplitude integration without AppDelegate
- 🔄 **Multiple Content Types** - Classic, Privacy, Dropbox modes
- 📱 **SwiftUI Native** - Clean integration with modern SwiftUI apps
- 🚀 **Zero Configuration** - Works out of the box

## 📦 Installation

### Swift Package Manager

Add ContentRouter to your project:

```swift
dependencies: [
    .package(url: "https://github.com/goodcompanyvl/ContentRouterClo.git", from: "1.1.0")
]
```

## 🚀 Quick Start

### Basic Usage

```swift
import SwiftUI
import ContentRouter

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var dataStore = DataStore()
    
    var body: some View {
        ContentRouter(
            contentType: .classic,
            contentSourceURL: "https://example.com/content",
            loaderContent: {
                SplashScreen()
            },
            content: {
                MainAppView(dataStore: dataStore)
            }
        )
    }
}
```

### With Analytics (Recommended)

```swift
ContentRouter(
    contentType: .classic,
    contentSourceURL: "https://example.com/content",
    loaderContent: {
        SplashScreen()
    },
    content: {
        MainAppView(dataStore: dataStore)
    }
)
.oneSignal("your-onesignal-app-id")
.amplitude("your-amplitude-api-key")
```

### Privacy Mode

```swift
ContentRouter(
    contentType: .privacy(appleId: "123456789"),
    contentSourceURL: "https://example.com/content",
    loaderContent: {
        SplashScreen()
    },
    content: {
        MainAppView()
    }
)
.oneSignal("your-onesignal-app-id")
.amplitude("your-amplitude-api-key")
```

## 🎨 Advanced Examples

### Custom Loading Screen

```swift
ContentRouter(
    contentType: .classic,
    contentSourceURL: "https://example.com/content",
    progressColor: .blue,
    loaderContent: {
        VStack(spacing: 20) {
            Image("app-logo")
                .resizable()
                .frame(width: 100, height: 100)
            
            Text("Loading amazing content...")
                .font(.headline)
                .foregroundColor(.gray)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    },
    content: {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
)
.oneSignal("your-onesignal-app-id")
.amplitude("your-amplitude-api-key")
```

### Onboarding Flow

```swift
struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        ContentRouter(
            contentType: .classic,
            contentSourceURL: "https://example.com/content",
            loaderContent: {
                LaunchScreen()
            },
            content: {
                if appState.isFirstLaunch {
                    OnboardingFlow(appState: appState)
                        .transition(.slide)
                } else {
                    MainTabView()
                        .transition(.slide)
                }
            }
        )
        .oneSignal("your-onesignal-app-id")
        .amplitude("your-amplitude-api-key")
        .animation(.easeInOut(duration: 0.5), value: appState.isFirstLaunch)
    }
}
```

## 📋 Content Types

### `.classic`
Standard mode with analytics and smart routing
```swift
contentType: .classic
```

### `.privacy(appleId: String)`
Privacy-aware mode that checks for Apple ID in content
```swift
contentType: .privacy(appleId: "123456789")
```

### `.dropbox`
Special mode for Dropbox-hosted content
```swift
contentType: .dropbox
```

### `.withoutLibAndTest`
Testing mode without analytics
```swift
contentType: .withoutLibAndTest
```

## 🔧 Analytics Configuration

### OneSignal Only
```swift
.oneSignal("your-app-id")
```

### Amplitude Only
```swift
.amplitude("your-api-key")
```

### Both Services
```swift
.oneSignal("your-onesignal-app-id")
.amplitude("your-amplitude-api-key")
```

### No Analytics
Simply don't add any analytics modifiers - the framework will work without them.

## 📊 Automatic Event Tracking

ContentRouter automatically tracks these events:
- `app_launch` - When app starts
- `onboarding_launch` - When showing native content
- `main_page_launch` - When main view appears
- `wv_launch` - When web view opens
- `page_in_wview` - Web view navigation

## 🛠️ Key Features

### ✅ No AppDelegate Required
Analytics initialization happens automatically through built-in `UIApplicationDelegateAdaptor`.

### ✅ Smart Content Detection
Automatically determines whether to show native content or web view based on:
- Network connectivity
- Content availability
- Device type (iPad handling)
- Previous user behavior

### ✅ Persistent Configuration
User preferences and content URLs are automatically cached for faster subsequent launches.

### ✅ Error Handling
Graceful fallback to native content when web content is unavailable.

## 🔄 Migration from v1.0.x

If you were using manual AppDelegate setup:

**Before:**
```swift
// Remove this from AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    AnalyticsManager.shared
        .enable(launchOptions: launchOptions)
        .oneSignal("app-id")
        .amplitude("api-key")
        .start()
    return true
}
```

**After:**
```swift
// Just use modifiers
ContentRouter(...)
    .oneSignal("app-id")
    .amplitude("api-key")
```

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+

## 📄 License

ContentRouter is available under the MIT license.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
