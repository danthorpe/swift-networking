import AssertionExtras
import Dependencies
import Foundation
import HTTPTypes
import os.log
import TestSupport
import XCTest

@testable import Networking

final class ServerTests: XCTestCase {
  
  func test__set_authority_on_all_requests() async throws {
    let reporter = TestReporter()
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      var headerFields = HTTPFields()
      headerFields[.contentType] = "application/json"
      headerFields[.cookie] = "cookie"
      
      let network = TerminalNetworkingComponent()
        .mocked(HTTPRequestData(authority: "example.com"), stub: .ok())
        .reported(by: reporter)
        .server(authority: "example.com")
        .logged(using: Logger())
      
      try await network.data(HTTPRequestData())
      
      let sentRequests = await reporter.requests
      XCTAssertEqual(sentRequests.map(\.authority), ["example.com"])
    }
  }
  
  func test__set_path_prefix_on_all_requests() async throws {
    let reporter = TestReporter()
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      var headerFields = HTTPFields()
      headerFields[.contentType] = "application/json"
      headerFields[.cookie] = "cookie"
      
      let network = TerminalNetworkingComponent()
        .mocked(HTTPRequestData(authority: "example.com", path: "v1/hello"), stub: .ok())
        .reported(by: reporter)
        .server(prefixPath: "v1")
        .server(authority: "example.com")
        .logged(using: Logger())
      
      try await network.data(HTTPRequestData(path: "hello"))
      
      let sentRequests = await reporter.requests
      XCTAssertEqual(sentRequests.map(\.authority), ["example.com"])
      XCTAssertEqual(sentRequests.map(\.path), ["v1/hello"])
    }
  }
  
  func test__set_path_prefix_on_all_requests__with_empty_path() async throws {
    let reporter = TestReporter()
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      var headerFields = HTTPFields()
      headerFields[.contentType] = "application/json"
      headerFields[.cookie] = "cookie"
      
      let network = TerminalNetworkingComponent()
        .mocked(HTTPRequestData(authority: "example.com", path: "v1"), stub: .ok())
        .reported(by: reporter)
        .server(prefixPath: "v1")
        .server(authority: "example.com")
        .logged(using: Logger())
      
      try await network.data(HTTPRequestData())
      
      let sentRequests = await reporter.requests
      XCTAssertEqual(sentRequests.map(\.authority), ["example.com"])
      XCTAssertEqual(sentRequests.map(\.path), ["v1"])
    }
  }
  
  func test__set_default_headers() async throws {
    let reporter = TestReporter()
    try await withDependencies {
      $0.shortID = .incrementing
      $0.continuousClock = TestClock()
    } operation: {
      var headerFields = HTTPFields()
      headerFields[.contentType] = "application/json"
      
      let network = TerminalNetworkingComponent()
        .mocked(HTTPRequestData(authority: "example.com", headerFields: headerFields), stub: .ok())
        .reported(by: reporter)
        .server(headerField: .contentType, value: "application/json")
        .server(authority: "example.com")
        .logged(using: Logger())
      
      try await network.data(HTTPRequestData())
      
      let sentRequests = await reporter.requests
      XCTAssertEqual(sentRequests.map(\.authority), ["example.com"])
      XCTAssertEqual(sentRequests.map(\.headerFields).compactMap { $0[.contentType] }, ["application/json"])
    }
  }
}
