// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Networking", targets: ["Networking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0"),
        .package(url: "https://github.com/danthorpe/swift-url-routing", branch: "danthorpe/per-request-options"),
        .package(url: "https://github.com/danthorpe/swift-utilities", branch: "main"),
    ],
    targets: [
        .target(name: "Networking", dependencies: [
            .product(name: "Cache", package: "swift-utilities"),
            .product(name: "ShortID", package: "swift-utilities"),
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "URLRouting", package: "swift-url-routing")
        ]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
      ]
)
