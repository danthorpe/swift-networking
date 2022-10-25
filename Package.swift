// swift-tools-version: 5.7
import PackageDescription

var package = Package(name: "danthorpe-networking")

// MARK: - Platforms

package.platforms = [
    .macOS(.v12),
    .iOS(.v14),
    .tvOS(.v14),
    .watchOS(.v7)
]

package.dependencies = [
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.7.0"),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", branch: "main"),
    .package(url: "https://github.com/danthorpe/danthorpe-utilities", from: "0.2.0"),
    .package(url: "https://github.com/danthorpe/danthorpe-plugins", from: "0.2.0"),
]

// MARK: - Names

let Networking = "Networking"

extension String {
    var tests: String { "\(self)Tests" }
}

// MARK: - Products

package.products = [
    .library(name: Networking, targets: [Networking])
]

// MARK: Targets

extension Target {
    static let networking: Target = .target(
        name: Networking,
        dependencies: [
            .cache, .shortID, .tagged, .URLRouting
        ],
        plugins: [
            .swiftLint
        ]
    )
    static let networkingTests: Target = .testTarget(
        name: Networking.tests,
        dependencies: [
            .networking
        ]
    )
}

package.targets = [
    .networking,
    .networkingTests
]

// MARK: - Dependencies

extension Target.Dependency {
    static let networking: Target.Dependency = .target(
        name: Networking
    )
    static let cache: Target.Dependency = .product(
        name: "Cache", package: "danthorpe-utilities"
    )
    static let shortID: Target.Dependency = .product(
        name: "ShortID", package: "danthorpe-utilities"
    )
    static let tagged: Target.Dependency = .product(
        name: "Tagged", package: "swift-tagged"
    )
    static let URLRouting: Target.Dependency = .product(
        name: "URLRouting", package: "swift-url-routing"
    )
}

// MARK: - Plugins

extension Target.PluginUsage {
    static let swiftLint: Target.PluginUsage = .plugin(
        name: "SwiftLint", package: "danthorpe-plugins"
    )
}
