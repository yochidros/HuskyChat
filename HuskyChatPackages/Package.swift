// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HuskyChatPackages",
    platforms: [.iOS(.v16), .macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SettingFeature",
            targets: ["SettingFeature"]
        ),
        .library(
            name: "Prelude",
            targets: ["Prelude"]
        ),
        .library(
            name: "RecoveryChatFeature",
            targets: ["RecoveryChatFeature"]
        ),
        .library(
            name: "Message",
            targets: ["Message"]
        ),
        .library(
            name: "LocalStorage",
            targets: ["LocalStorage"]
        ),
        .library(
            name: "SpeechFeature",
            targets: ["SpeechFeature"]
        ),
        .library(
            name: "ChatGPTAPIClient",
            targets: ["ChatGPTAPIClient"]
        ),
        .library(
            name: "AudioRecoderTools",
            targets: ["AudioRecoderTools"]
        ),
        .library(
            name: "FeatureBuilder",
            targets: ["FeatureBuilder"]
        ),
        .library(
            name: "RecoveryChatFeatureBuilder",
            targets: ["RecoveryChatFeatureBuilder"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Prelude",
            dependencies: [],
            path: "Sources/Prelude"
        ),
        .target(
            name: "SettingFeature",
            dependencies: ["Prelude", "LocalStorage"],
            path: "Sources/SettingFeature"
        ),
        .target(
            name: "RecoveryChatFeature",
            dependencies: ["Prelude", "Message", "LocalStorage"],
            path: "Sources/RecoveryChatFeature"
        ),
        .target(
            name: "Message",
            dependencies: ["Prelude"],
            path: "Sources/Message"
        ),
        .target(
            name: "LocalStorage",
            dependencies: ["Prelude"],
            path: "Sources/LocalStorage"
        ),
        .target(
            name: "SpeechFeature",
            dependencies: ["Prelude", "Message", "LocalStorage", "ChatGPTAPIClient", "AudioRecoderTools", "FeatureBuilder", "RecoveryChatFeatureBuilder"],
            path: "Sources/SpeechFeature"
        ),
        .target(
            name: "ChatGPTAPIClient",
            path: "Sources/ChatGPTAPIClient"
        ),
        .target(
            name: "AudioRecoderTools",
            path: "Sources/AudioRecoderTools"
        ),
        .target(
            name: "FeatureBuilder",
            path: "Sources/FeatureBuilder"
        ),
        .target(
            name: "RecoveryChatFeatureBuilder",
            dependencies: ["FeatureBuilder"],
            path: "Sources/RecoveryChatFeatureBuilder"
        ),
    ]
)
