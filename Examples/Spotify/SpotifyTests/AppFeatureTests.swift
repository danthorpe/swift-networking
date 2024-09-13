import AsyncAlgorithms
import ComposableArchitecture
import Networking
import OAuth
import XCTest

@testable import SpotifyApp

final class AppFeatureTests: XCTestCase {

  var credentialsDidChangeChannel: AsyncThrowingChannel<Spotify.Credentials, Error>! = .init()

  override func tearDown() {
    credentialsDidChangeChannel = nil
    super.tearDown()
  }

  override func invokeTest() {
    withDependencies { [weak self] in
      guard let this = self else { return }
      $0.spotify = Spotify.Client()
        .override(\.credentialsDidChange) {
          this.credentialsDidChangeChannel.eraseToThrowingStream()
        }
    } operation: {
      super.invokeTest()
    }
  }

  @MainActor func test__given_no_existing_credentials__then_state_is_signed_out() async throws {
    let store = TestStore(initialState: .pending) {
      AppFeature()
    }
    let lifecycle = await store.send(.view(.onTask)) {
      $0 = .signedOut(.pending)
    }
    await lifecycle.cancel()
  }

  @MainActor func test__given_no_existing_credential__when_sign_in_successful__then_credentials_are_received()
    async throws
  {
    let store = TestStore(initialState: .pending) {
      AppFeature()
    }
    let lifecycle = await store.send(.view(.onTask)) {
      $0 = .signedOut(.pending)
    }
    // Configure successful sign in
    store.dependencies.spotify.signIn = { @Sendable context in
      XCTAssertNil(context)
      await self.credentialsDidChangeChannel.send(.mock)
    }
    await store.send(.signedOut(.view(.signInButtonTapped)))
    await store.receive(\.signedOut.signInResponse, .success(true)) {
      $0 = .signedOut(.success)
    }
    await store.receive(\.credentialsDidChange, .mock)
    await store.receive(\.signedInSuccess) {
      $0 = .signedIn(SignedInFeature.State())
    }
    await lifecycle.cancel()
  }

  @MainActor func test__given_already_have_credentials__then_state_is_signed_in() async throws {
    @Shared(.fileStorage(.credentials)) var sharedCredentials: OAuth.AvailableSystems.Spotify.Credentials? = .mock
    let store = TestStore(initialState: .pending) {
      AppFeature()
    }
    let expect = expectation(description: "Set Existing Credentials is called")
    store.dependencies.spotify.setExistingCredentials = { @Sendable credentials in
      XCTAssertEqual(credentials, .mock)
      expect.fulfill()
    }
    let lifecycle = await store.send(.view(.onTask))
    await store.receive(\.signedInSuccess) {
      $0 = .signedIn(SignedInFeature.State())
    }
    await fulfillment(of: [expect])
    await lifecycle.cancel()
  }

  @MainActor func test__given_already_signed_in__then_sign_out() async throws {
    let store = TestStore(initialState: .signedIn(SignedInFeature.State())) {
      AppFeature()
    }
    // Configure successful sign out
    let expect = expectation(description: "Sign Out is called")
    store.dependencies.spotify.signOut = { @Sendable in
      expect.fulfill()
    }
    await store.send(.view(.signOutButtonTapped))
    await store.receive(\.signedOutSuccess) {
      $0 = .signedOut(.pending)
    }
    await fulfillment(of: [expect])
  }
}
