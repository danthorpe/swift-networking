import os.log

extension Logger {
  public static let test: Self = .init(
    subsystem: "works.dan.danthorpe-networking", category: "Tests")
}
