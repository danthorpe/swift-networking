import Dependencies
import Foundation
import Networking
import TestSupport
import Testing

@testable import OAuth

@Suite
struct RedactedBodyFieldsTests: TestableNetwork {

  // A minimal valid token JSON so `post` decodes into Credentials without error.
  private let tokenJSON = Data(
    #"{"access_token":"a","expires_in":3600,"refresh_token":"r","token_type":"Bearer"}"#.utf8)

  @Test func spotifyRefreshRequestCarriesRedactedFields() async throws {
    let reporter = TestReporter()
    try await withTestDependencies { _ in
    } operation: {
      let network = TerminalNetworkingComponent()
        .mocked { [tokenJSON] _ in .ok(data: tokenJSON) }
        .reported(by: reporter)
      let spotify = OAuth.AvailableSystems.Spotify.spotify(
        clientId: "id", callback: "app://cb", scope: nil)
      let creds = OAuth.AvailableSystems.Spotify.Credentials(
        accessToken: "a", expiresIn: 1, refreshToken: "old", scope: nil, tokenType: "Bearer")

      _ = try await spotify.refreshCredentials(creds, using: network)

      let sent = await reporter.requests
      #expect(sent.first?.redactedBodyFields == OAuth.redactedBodyFields)
    }
  }

  @Test func googleRefreshRequestCarriesRedactedFields() async throws {
    let reporter = TestReporter()
    try await withTestDependencies { _ in
    } operation: {
      let network = TerminalNetworkingComponent()
        .mocked { [tokenJSON] _ in .ok(data: tokenJSON) }
        .reported(by: reporter)
      let google = OAuth.AvailableSystems.Google(
        clientId: "id", redirectURI: "com.example:/cb", scope: nil)
      let creds = OAuth.AvailableSystems.Google.Credentials(
        accessToken: "a", expiresIn: 1, refreshToken: "old", scope: nil, tokenType: "Bearer")

      _ = try await google.refreshCredentials(creds, using: network)

      let sent = await reporter.requests
      #expect(sent.first?.redactedBodyFields == OAuth.redactedBodyFields)
    }
  }
}
