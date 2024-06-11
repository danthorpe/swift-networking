private enum ExpectedContentLength: HTTPRequestDataOption {
  static let defaultOption: Int64? = nil
}

extension HTTPRequestData {
  public var expectedContentLength: Int64? {
    get { self[option: ExpectedContentLength.self] }
    set { self[option: ExpectedContentLength.self] = newValue }
  }
}
