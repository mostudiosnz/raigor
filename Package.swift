// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Raigor",
    platforms: [
        .iOS(.v15),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Raigor",
            targets: [
                "Raigor",
            ]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/firebase/firebase-ios-sdk", exact: Version(12, 3, 0)),
        .package(url: "https://github.com/mixpanel/mixpanel-swift.git", exact: Version(5, 1, 3)),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Raigor",
            dependencies: [
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "Mixpanel", package: "mixpanel-swift"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("ApproachableConcurrency"),
                .define("DEBUG", .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "RaigorTests",
            dependencies: [
                "Raigor",
            ]
        ),
    ]
)
