// swift-tools-version: 5.6

import PackageDescription

var externals: [Target.Dependency] = [
//    .product(name: "Tagged", package: "swift-tagged"),
    .product(name: "Utilities", package: "swift-utilities"),
]

var standard: [Target.Dependency] = externals + []

let package = Package(
    name: "Networking",
    platforms: [
        .macOS("12.0"),
        .iOS("15.0"),
        .tvOS("15.0"),
        .watchOS("8.0")
    ],
    products: [
        .library(name: "Networking", targets: ["HTTP"]),
    ],
    dependencies: [
        .package(url: "ssh://github.com/danthorpe/swift-utilities", branch: "main"),
    ],
    targets: [
        .target(name: "HTTP", dependencies: standard + []),
        .testTarget(name: "HTTPTests", dependencies: ["HTTP"]),
    ]
)
