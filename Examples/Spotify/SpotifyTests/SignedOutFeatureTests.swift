import AsyncAlgorithms
import ComposableArchitecture
import Networking
import OAuth
import XCTest

@testable import SpotifyApp

final class SignedOutFeatureTests: XCTestCase {

  @MainActor func test__given_no_error_signing_in__then_state_is_success() async throws {
    let store = TestStore(initialState: .pending) {
      SignedOutFeature()
    } withDependencies: {
      $0.spotify.signIn = { @Sendable context in
        XCTAssertNil(context)
      }
    }
    await store.send(.view(.signInButtonTapped))
    await store.receive(\.signInResponse, .success(true)) {
      $0 = .success
    }
  }

  @MainActor func test__given_error_signing_in__then_state_is_failed() async throws {
    enum DummyError: Error, Equatable { case signInFailed }
    let store = TestStore(initialState: .pending) {
      SignedOutFeature()
    } withDependencies: {
      $0.spotify.signIn = { @Sendable context in
        XCTAssertNil(context)
        throw DummyError.signInFailed
      }
    }
    await store.send(.view(.signInButtonTapped))
    await store.receive(\.signInResponse, .failure(DummyError.signInFailed)) {
      $0 = .failed
    }
  }
}
