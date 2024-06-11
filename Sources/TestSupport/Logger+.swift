import os.log

extension Logger {
  package static let test = Self(
    subsystem: "works.dan.danthorpe-networking", category: "Tests"
  )
}
