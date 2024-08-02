import AssertionExtras
import Dependencies
import Foundation
import Helpers
import Networking
import TestSupport
import XCTest
import XCTestDynamicOverlay

@testable import OAuth

open class OAuthTestCase: NetworkingTestCase {

  var stub: StubOAuthSystem!

  open override func setUp() {
    super.setUp()
    stub = StubOAuthSystem(
      authorizationEndpoint: "https://accounts.example.com/authorize",
      tokenEndpoint: "https://accounts.example.com/api/token",
      clientId: "some-client-id",
      redirectURI: "some-redirect-uri://callback",
      scope: "some-scope"
    )
  }

  open override func tearDown() {
    stub = nil
    super.tearDown()
  }

  open override func invokeTest() {
    withTestDependencies {
      super.invokeTest()
    }
  }
}
