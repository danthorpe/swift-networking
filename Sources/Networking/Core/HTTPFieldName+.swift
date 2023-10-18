import HTTPTypes
import os.log

extension HTTPField.Name {
  static let requiresPrivateLogging: Set<Self> = Self.requireHashPrivateLogging
  static let requireHashPrivateLogging: Set<Self> = [.authorization]
  public var requiresPrivateLogging: Bool {
    Self.requiresPrivateLogging.contains(self)
  }
  public var requireHashPrivateLogging: Bool {
    Self.requireHashPrivateLogging.contains(self)
  }
}
