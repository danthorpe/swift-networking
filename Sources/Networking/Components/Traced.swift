import Dependencies
import DependenciesMacros
import Foundation
import HTTPTypes
import Helpers

extension NetworkingComponent {

  /// Generates a HTTP Trace Parent header for each request.
  ///
  /// - See-Also: [Trace-Context](https://www.w3.org/TR/trace-context/)
  public func traced() -> some NetworkingComponent {
    modified(Traced())
  }
}

private struct Traced: NetworkingModifier {
  @Dependency(\.traceParentGenerator) var generate
  func resolve(upstream: some NetworkingComponent, request: HTTPRequestData) -> HTTPRequestData {
    guard nil == request.traceParent else {
      return request
    }
    var copy = request
    copy.traceParent = generate()
    return copy
  }
}

extension HTTPField.Name {
  public static let traceparent = HTTPField.Name("traceparent")!
}

extension HTTPRequestData {
  package fileprivate(set) var traceParent: TraceParent? {
    get { self[option: TraceParent.self] }
    set {
      self[option: TraceParent.self] = newValue
      self.headerFields[.traceparent] = newValue?.description
    }
  }

  public var traceId: String? {
    traceParent?.traceId
  }

  public var parentId: String? {
    traceParent?.parentId
  }
}

public struct TraceParent: Sendable, HTTPRequestDataOption {
  public static var defaultOption: Self?

  // Current version of the spec only supports 01 flag
  // Future versions of the spec will require support for bit-field mask
  public let traceId: String
  public let parentId: String

  public var description: String {
    "00-\(traceId)-\(parentId)-01"
  }

  public init(traceId: String, parentId: String) {
    self.traceId = traceId
    self.parentId = parentId
  }
}

// MARK: - Generator

@DependencyClient
public struct TraceParentGenerator: Sendable {
  public var generate: @Sendable () -> TraceParent = {
    TraceParent(traceId: "dummy-trace-id", parentId: "dummy-parent-id")
  }

  package func callAsFunction() -> TraceParent {
    generate()
  }
}

extension TraceParentGenerator: DependencyKey {
  public static let liveValue = {
    let traceId = UniqueIdentifier.Generator(.secureBytes(length: 16, format: .hex))
    let parentId = UniqueIdentifier.Generator(.secureBytes(length: 8, format: .hex))
    return TraceParentGenerator {
      TraceParent(
        traceId: traceId(),
        parentId: parentId()
      )
    }
  }()
}

extension DependencyValues {
  public var traceParentGenerator: TraceParentGenerator {
    get { self[TraceParentGenerator.self] }
    set { self[TraceParentGenerator.self] = newValue }
  }
}

extension TraceParentGenerator {
  public static let incrementing = {
    let traceId = UniqueIdentifier.Generator.incrementing(.secureBytes(length: 16, format: .hex))
    let parentId = UniqueIdentifier.Generator.incrementing(.secureBytes(length: 8, format: .hex))
    return TraceParentGenerator {
      TraceParent(
        traceId: traceId(),
        parentId: parentId()
      )
    }
  }()
}
