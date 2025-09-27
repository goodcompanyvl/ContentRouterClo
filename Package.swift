// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContentRouter",
	platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ContentRouter",
            targets: ["ContentRouter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/amplitude/Amplitude-Swift.git", from: "1.15.0"),
        .package(url: "https://github.com/OneSignal/OneSignal-iOS-SDK.git", from: "5.2.14")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ContentRouter",
            dependencies: [
                .product(name: "AmplitudeSwift", package: "amplitude-swift"),
                .product(name: "OneSignalFramework", package: "onesignal-ios-sdk"),
                .product(name: "OneSignalInAppMessages", package: "onesignal-ios-sdk")
            ]),
        

    ],
	swiftLanguageVersions: [.v5]
)
