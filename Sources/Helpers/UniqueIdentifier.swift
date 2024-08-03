import ConcurrencyExtras
import Foundation

package enum UniqueIdentifier: Hashable {
  package enum Format: Hashable {
    case base64, hex
  }
  case secureBytes(length: UInt = 10, format: Format)
}

extension UniqueIdentifier {

  func generate() -> String {
    switch self {
    case let .secureBytes(length, _):
      var data = Data()
      repeat {
        data = .secureRandomData(length: length) ?? Data()
      } while data.isEmpty
      return format(data: data)
    }
  }

  func format(data: Data) -> String {
    switch self {
    case .secureBytes(_, .base64):
      return data.base64EncodedString(options: [])
    case .secureBytes(_, .hex):
      return data.map { String(format: "%02hhx", $0) }.joined()
    }
  }
}

// MARK: - Generator

extension UniqueIdentifier {
  package struct Generator: Sendable {
    private let generate: @Sendable () -> String

    package init(_ id: UniqueIdentifier) {
      self.init { id.generate() }
    }

    package init(generate: @escaping @Sendable () -> String) {
      self.generate = generate
    }

    @discardableResult
    package func callAsFunction() -> String {
      generate()
    }
  }
}

extension UniqueIdentifier.Generator {
  package static func constant(_ id: UniqueIdentifier) -> Self {
    let generation = id.generate()
    return Self { generation }
  }

  package static func incrementing(_ id: UniqueIdentifier) -> Self {
    let sequence = LockIsolated<Int>(0)
    return Self {
      let number = sequence.withValue {
        $0 += 1
        return $0
      }
      let data = withUnsafeBytes(of: number.bigEndian) { Data($0) }
      return id.format(data: data)
    }
  }
}
