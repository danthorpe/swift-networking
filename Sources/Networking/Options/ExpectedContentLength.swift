private enum ExpectedContentLength: HTTPRequestDataOption {
  static var defaultOption: Int64?
}

extension HTTPRequestData {
  public var expectedContentLength: Int64? {
    get { self[option: ExpectedContentLength.self] }
    set { self[option: ExpectedContentLength.self] = newValue }
  }
}
