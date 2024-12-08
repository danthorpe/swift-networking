// swift-tools-version: 6.0
@preconcurrency import PackageDescription

var package = Package(
  name: "swift-networking",
  swiftLanguageModes: [
    .v5,
    .version("6"),
  ]
)

// MARK: 💫 Package Customization

package.platforms = [
  .macOS(.v13),
  .iOS(.v16),
  .tvOS(.v16),
  .watchOS(.v9),
]

// MARK: - 🧸 Module Names

let Helpers = "Helpers"
let NetworkClient = "NetworkClient"
let Networking = "Networking"
let OAuth = "OAuth"
let TestSupport = "TestSupport"

// MARK: - 🔑 Builders

let 📦 = Module.builder(
  withDefaults: Module(
    name: "Basic Module",
    defaultWith: [
      .dependencies,
      .dependenciesMacros,
      .concurrencyExtras,
    ],
    unitTestsWith: [
      .dependenciesTestSupport
    ],
    swiftSettings: .concurrency
  )
)

// MARK: - 🎯 Targets

Helpers
  <+ 📦 {
    $0.createUnitTests = false
  }

NetworkClient
  <+ 📦 {
    $0.createProduct = .library(nil)
    $0.createUnitTests = false
    $0.dependsOn = [
      Networking
    ]
  }

NetworkClient.live
  <+ 📦 {
    $0.createProduct = .library(nil)
    $0.createUnitTests = false
    $0.dependsOn = [
      NetworkClient
    ]
  }

Networking
  <+ 📦 {
    $0.createProduct = .library(nil)
    $0.dependsOn = [
      Helpers
    ]
    $0.with = [
      .algorithms,
      .asyncAlgorithms,
      .httpTypes,
      .httpTypesFoundation,
      .protected,
      .shortID,
      .tagged,
    ]
    $0.unitTestsDependsOn = [
      TestSupport
    ]
    $0.unitTestsWith = [
      .assertionExtras,
      .concurrencyExtras,
    ]
  }

OAuth
  <+ 📦 {
    $0.createProduct = .library(nil)
    $0.dependsOn = [
      Helpers,
      Networking,
    ]
    $0.unitTestsDependsOn = [
      TestSupport
    ]
    $0.unitTestsWith = [
      .assertionExtras,
      .concurrencyExtras,
      .numerics,
    ]
  }

TestSupport
  <+ 📦 {
    $0.createUnitTests = false
    $0.createProduct = .library(nil)
    $0.dependsOn = [
      Networking,
      Helpers,
    ]
  }

/// ------------------------------------------------------------
/// 👜 Define 3rd party dependencies. Associate these dependencies
/// with modules using `$0.with = [ ]` property
/// ------------------------------------------------------------

// MARK: - 👜 3rd Party Dependencies

package.dependencies = [
  .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
  .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.2"),
  .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0"),
  .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
  .package(url: "https://github.com/apple/swift-http-types", from: "1.0.0"),
  .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
  .package(url: "https://github.com/danthorpe/swift-utilities", from: "0.5.0"),
  .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
  .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.0"),
  .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
]

extension Target.Dependency {
  static let algorithms: Target.Dependency = .product(
    name: "Algorithms", package: "swift-algorithms"
  )
  static let assertionExtras: Target.Dependency = .product(
    name: "AssertionExtras", package: "swift-utilities"
  )
  static let asyncAlgorithms: Target.Dependency = .product(
    name: "AsyncAlgorithms", package: "swift-async-algorithms"
  )
  static let concurrencyExtras: Target.Dependency = .product(
    name: "ConcurrencyExtras", package: "swift-concurrency-extras"
  )
  static let dependencies: Target.Dependency = .product(
    name: "Dependencies", package: "swift-dependencies"
  )
  static let dependenciesMacros: Target.Dependency = .product(
    name: "DependenciesMacros", package: "swift-dependencies"
  )
  static let dependenciesTestSupport: Target.Dependency = .product(
    name: "DependenciesTestSupport", package: "swift-dependencies"
  )
  static let deque: Target.Dependency = .product(
    name: "DequeModule", package: "swift-collections"
  )
  static let orderedCollections: Target.Dependency = .product(
    name: "OrderedCollections", package: "swift-collections"
  )
  static let httpTypes: Target.Dependency = .product(
    name: "HTTPTypes", package: "swift-http-types"
  )
  static let httpTypesFoundation: Target.Dependency = .product(
    name: "HTTPTypesFoundation", package: "swift-http-types"
  )
  static let numerics: Target.Dependency = .product(
    name: "Numerics", package: "swift-numerics"
  )
  static let protected: Target.Dependency = .product(
    name: "Protected", package: "swift-utilities"
  )
  static let shortID: Target.Dependency = .product(
    name: "ShortID", package: "swift-utilities"
  )
  static let tagged: Target.Dependency = .product(
    name: "Tagged", package: "swift-tagged"
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
    .enableUpcomingFeature("InferSendableFromCaptures")
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
  @MainActor static func <+ (lhs: String, rhs: Module) {
    var module = rhs
    module.name = lhs
    package.add(module: module)
  }
}

infix operator <+
extension String {

  /// Adds the string as a module to the package, allowing for inline customization
  @MainActor static func <> (lhs: String, rhs: Module.Builder) {
    var module = Module(name: lhs)
    rhs(&module)
    package.add(module: module)
  }
}
