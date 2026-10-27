import Foundation
#if !CORE_TEST_RUNNER
import XCTest
#endif
#if canImport(ZeroDock)
@testable import ZeroDock
#endif

final class SpotifyTests: XCTestCase {
    func testPKCEChallengeMatchesRFC7636Vector() {
        XCTAssertEqual(SpotifyOAuth.challenge(for: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"), "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
    }
    func testAuthorizationRequestsOnlyReadOnlyPlaybackScope() {
        let url = SpotifyOAuth.authorizationURL(state: "unique-state", challenge: "challenge")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems ?? []
        let fields = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(fields["scope"], "user-read-currently-playing")
        XCTAssertEqual(fields["code_challenge_method"], "S256")
        XCTAssertEqual(fields["state"], "unique-state")
        XCTAssertEqual(fields["redirect_uri"], "zerodock://spotify/callback")
        XCTAssertNil(fields["client_secret"])
    }
    func testCallbackRejectsWrongStateHostPathAndDeniedConsent() {
        for input in ["zerodock://spotify/callback?code=abc&state=wrong", "zerodock://wrong/callback?code=abc&state=ok", "https://spotify/callback?code=abc&state=ok", "zerodock://spotify/other?code=abc&state=ok", "zerodock://spotify/callback?error=access_denied&state=ok"] {
            do {
                _ = try SpotifyOAuth.code(from: URL(string: input)!, expectedState: "ok")
                XCTAssertTrue(false)
            } catch { /* Rejection is the contract. */ }
        }
    }
    func testValidCallbackReturnsCode() throws {
        XCTAssertEqual(try SpotifyOAuth.code(from: URL(string: "zerodock://spotify/callback?code=abc123&state=ok")!, expectedState: "ok"), "abc123")
    }
    func testTokenFormEscapesReservedCharacters() {
        XCTAssertEqual(String(data: SpotifyOAuth.form(["code_verifier": "a+b&c=d"]), encoding: .utf8), "code_verifier=a%2Bb%26c%3Dd")
    }
    func testPlaybackDecodesOriginalArtworkAndSpotifyLink() throws {
        let data = Data(#"{"is_playing":true,"currently_playing_type":"track","item":{"name":"Test track","type":"track","artists":[{"name":"Artist one"},{"name":"Artist two"}],"album":{"images":[{"url":"https://i.scdn.co/image/original"}]},"external_urls":{"spotify":"https://open.spotify.com/track/example"}}}"#.utf8)
        let value = try JSONDecoder().decode(SpotifyPlayback.self, from: data).nowPlaying
        XCTAssertEqual(value?.title, "Test track")
        XCTAssertEqual(value?.artist, "Artist one, Artist two")
        XCTAssertEqual(value?.artwork?.absoluteString, "https://i.scdn.co/image/original")
        XCTAssertEqual(value?.link?.host, "open.spotify.com")
        XCTAssertEqual(value?.isPlaying, true)
    }
    func testAbsentOrAdvertisementPlaybackDoesNotInventTrack() throws {
        for payload in [#"{"is_playing":false,"item":null}"#, #"{"is_playing":true,"currently_playing_type":"ad","item":null}"#] {
            XCTAssertNil(try JSONDecoder().decode(SpotifyPlayback.self, from: Data(payload.utf8)).nowPlaying)
        }
    }
}
