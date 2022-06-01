// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .macOS("12.0"),
        .iOS("15.0"),
        .tvOS("15.0"),
        .watchOS("8.0")
    ],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0"),
//        .package(url: "https://github.com/danthorpe/swift-url-routing", branch: "danthorpe/per-request-options"),
        .package(path: "/Users/daniel/Work/Personal/swift-url-routing"),
//        .package(url: "https://github.com/danthorpe/swift-utilities", from: "0.1.0"),
        .package(path: "/Users/daniel/Work/Personal/swift-utilities"),
    ],
    targets: [
        .target(name: "Networking", dependencies: [
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "Utilities", package: "swift-utilities"),
            .product(name: "URLRouting", package: "swift-url-routing")
        ]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
      ]
)
