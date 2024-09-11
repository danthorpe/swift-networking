// swift-tools-version: 5.10
import PackageDescription

var package = Package(name: "SpotifyExample")

// MARK: 💫 Package Customization

package.platforms = [
  .macOS(.v13),
  .iOS(.v16),
  .tvOS(.v16),
  .watchOS(.v9),
]

// MARK: - 🧸 Module Names

let SignedIn = "SignedIn"
let SignedOut = "SignedOut"
let SpotifyClient = "SpotifyClient"
let SpotifyExample = "SpotifyExample"

// MARK: - 🔑 Builders

let 📦 = Module.builder(
  withDefaults: .init(
    name: "Basic Module",
    defaultWith: [
      .dependencies,
      .dependenciesMacros,
    ],
    swiftSettings: .concurrency
  )
)

// MARK: - 🎯 Targets

SignedIn
  <+ 📦 {
    $0.with = [
      .composableArchitecture,
      .composableLoadable,
    ]
    $0.dependsOn = [
      SpotifyClient
    ]
  }

SignedOut
  <+ 📦 {
    $0.with = [
      .composableArchitecture
    ]
    $0.dependsOn = [
      SpotifyClient
    ]
  }

SpotifyExample
  <+ 📦 {
    $0.createProduct = .library()
    $0.with = [
      .composableArchitecture,
      .composableLoadable,
      .networking,
      // Ideally, this would be added directly to the application, but
      // it's not possible to add a package which is a direct
      // ascendant of an Xcode Project.
      .networkClientLive,
      .oauth,
    ]
    $0.dependsOn = [
      SignedIn,
      SignedOut,
      SpotifyClient,
    ]
  }

SpotifyClient
  <+ 📦 {
    $0.with = [
      .networking,
      .networkClient,
      .oauth,
    ]
  }

/// ------------------------------------------------------------
/// 👜 Define 3rd party dependencies. Associate these dependencies
/// with modules using `$0.with = [ ]` property
/// ------------------------------------------------------------

// MARK: - 👜 3rd Party Dependencies

package.dependencies = [
  .package(name: "swift-networking", path: "../../.."),
  .package(url: "https://github.com/danthorpe/swift-composable-loadable", branch: "main"),
  .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.14.0"),
  .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
]

extension Target.Dependency {
  static let composableArchitecture: Target.Dependency = .product(
    name: "ComposableArchitecture", package: "swift-composable-architecture"
  )
  static let composableLoadable: Target.Dependency = .product(
    name: "ComposableLoadable", package: "swift-composable-loadable"
  )
  static let dependencies: Target.Dependency = .product(
    name: "Dependencies", package: "swift-dependencies"
  )
  static let dependenciesMacros: Target.Dependency = .product(
    name: "DependenciesMacros", package: "swift-dependencies"
  )
  static let networking: Target.Dependency = .product(
    name: "Networking", package: "swift-networking"
  )
  static let networkClient: Target.Dependency = .product(
    name: "NetworkClient", package: "swift-networking"
  )
  static let networkClientLive: Target.Dependency = .product(
    name: "NetworkClientLive", package: "swift-networking"
  )
  static let oauth: Target.Dependency = .product(
    name: "OAuth", package: "swift-networking"
  )
}

/// ------------------------------------------------------------
/// ✂️ Copy everything below this into other Package.swift files
/// to re-create the same DSL capabilities.
/// ------------------------------------------------------------

// MARK: - 🚦 Swift Settings

extension [SwiftSetting] {
  #if swift(>=6)
  static let concurrency: Self = [
    // Already enabled
  ]
  #else
  static let concurrency: Self = [
    .enableExperimentalFeature("GlobalConcurrency"),
    .enableExperimentalFeature("TargetedConcurrency"),
    .enableExperimentalFeature("InferSendableFromCaptures"),
  ]
  #endif
}

// MARK: - 🪄 Package Helpers

extension String {
  var feature: String { self + "Feature " }
  var dependency: Target.Dependency {
    Target.Dependency.target(name: self)
  }
  var snapshotTests: String { "\(self)SnapshotTests" }
  var tests: String { "\(self)Tests" }
  var live: String { "\(self)Live" }
}

struct Module {
  enum ProductType {
    case library(Product.Library.LibraryType? = nil)
  }

  typealias Builder = (inout Self) -> Void

  static func builder(withDefaults defaults: Module) -> (Builder?) -> Module {
    { block in
      var module = Self(
        name: "TO BE REPLACED",
        defaultWith: defaults.defaultWith,
        swiftSettings: defaults.swiftSettings,
        plugins: defaults.plugins
      )
      block?(&module)
      return module.merged(with: defaults)
    }
  }

  var name: String
  var group: String?
  var dependsOn: [String]
  let defaultWith: [Target.Dependency]
  var with: [Target.Dependency]

  var createProduct: ProductType?
  var createTarget: Bool
  var createUnitTests: Bool
  var unitTestsDependsOn: [String]
  var unitTestsWith: [Target.Dependency]
  var createSnapshotTests: Bool
  var snapshotTestsDependsOn: [String]

  var resources: [Resource]?
  var swiftSettings: [SwiftSetting]
  var plugins: [Target.PluginUsage]

  var dependencies: [Target.Dependency] {
    defaultWith + with + dependsOn.map { $0.dependency }
  }

  var productTargets: [String] {
    createTarget ? [name] : dependsOn
  }

  init(
    name: String,
    group: String? = nil,
    dependsOn: [String] = [],
    defaultWith: [Target.Dependency] = [],
    with: [Target.Dependency] = [],
    createProduct: ProductType? = nil,
    createTarget: Bool = true,
    createUnitTests: Bool = true,
    unitTestsDependsOn: [String] = [],
    unitTestsWith: [Target.Dependency] = [],
    createSnapshotTests: Bool = false,
    snapshotTestsDependsOn: [String] = [],
    resources: [Resource]? = nil,
    swiftSettings: [SwiftSetting] = [],
    plugins: [Target.PluginUsage] = []
  ) {
    self.name = name
    self.group = group
    self.dependsOn = dependsOn
    self.defaultWith = defaultWith
    self.with = with
    self.createProduct = createProduct
    self.createTarget = createTarget
    self.createUnitTests = createUnitTests
    self.unitTestsDependsOn = unitTestsDependsOn
    self.unitTestsWith = unitTestsWith
    self.createSnapshotTests = createSnapshotTests
    self.snapshotTestsDependsOn = snapshotTestsDependsOn
    self.resources = resources
    self.swiftSettings = swiftSettings
    self.plugins = plugins
  }

  private func merged(with other: Self) -> Self {
    var copy = self
    copy.dependsOn = Set(dependsOn).union(other.dependsOn).sorted()
    copy.unitTestsDependsOn = Set(unitTestsDependsOn).union(other.unitTestsDependsOn).sorted()
    copy.snapshotTestsDependsOn = Set(snapshotTestsDependsOn).union(other.snapshotTestsDependsOn).sorted()
    return copy
  }

  func group(by group: String) -> Self {
    var copy = self
    if let existingGroup = self.group {
      copy.group = "\(group)/\(existingGroup)"
    } else {
      copy.group = group
    }
    return copy
  }
}

extension Package {
  func add(module: Module) {
    // Check should create a product
    if case let .library(type) = module.createProduct {
      products.append(
        .library(
          name: module.name,
          type: type,
          targets: module.productTargets
        )
      )
    }
    // Check should create a target
    if module.createTarget {
      let path = module.group.map { "\($0)/Sources/\(module.name)" }
      targets.append(
        .target(
          name: module.name,
          dependencies: module.dependencies,
          path: path,
          resources: module.resources,
          swiftSettings: module.swiftSettings,
          plugins: module.plugins
        )
      )
    }
    // Check should add unit tests
    if module.createUnitTests {
      let path = module.group.map { "\($0)/Tests/\(module.name.tests)" }
      targets.append(
        .testTarget(
          name: module.name.tests,
          dependencies: [module.name.dependency]
            + module.unitTestsDependsOn.map { $0.dependency }
            + module.unitTestsWith
            + [],
          path: path,
          plugins: module.plugins
        )
      )
    }
    // Check should add snapshot tests
    if module.createSnapshotTests {
      let path = module.group.map { "\($0)/Tests/\(module.name.snapshotTests)" }
      targets.append(
        .testTarget(
          name: module.name.snapshotTests,
          dependencies: [module.name.dependency]
            + module.snapshotTestsDependsOn.map { $0.dependency }
            + [],
          path: path,
          plugins: module.plugins
        )
      )
    }
  }
}

protocol ModuleGroupConvertible {
  func makeGroup() -> [Module]
}

extension Module: ModuleGroupConvertible {
  func makeGroup() -> [Module] { [self] }
}

struct ModuleGroup {
  var name: String
  var modules: [Module]
  init(_ name: String, @ModuleBuilder builder: () -> [Module]) {
    self.name = name
    self.modules = builder()
  }
}

extension ModuleGroup: ModuleGroupConvertible {
  func makeGroup() -> [Module] {
    modules.map { $0.group(by: name) }
  }
}

@resultBuilder
struct ModuleBuilder {
  static func buildBlock() -> [Module] { [] }
  static func buildBlock(_ modules: ModuleGroupConvertible...) -> [Module] {
    modules.flatMap { $0.makeGroup() }
  }
}

infix operator <>
extension String {

  /// Adds the string as a module to the package, using the provided module
  static func <+ (lhs: String, rhs: Module) {
    var module = rhs
    module.name = lhs
    package.add(module: module)
  }
}

infix operator <+
extension String {

  /// Adds the string as a module to the package, allowing for inline customization
  static func <> (lhs: String, rhs: Module.Builder) {
    var module = Module(name: lhs)
    rhs(&module)
    package.add(module: module)
  }
}
