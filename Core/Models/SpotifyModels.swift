import Foundation
import CryptoKit

struct NowPlaying: Equatable {
    var title: String
    var artist: String
    var artwork: URL?
    var link: URL?
    var isPlaying: Bool
}

struct SpotifyPlayback: Decodable {
    let is_playing: Bool
    let item: Item?
    struct Item: Decodable {
        let name: String
        let type: String?
        let artists: [Artist]?
        let album: Album?
        let external_urls: [String: String]?
    }
    struct Artist: Decodable { let name: String }
    struct Album: Decodable { let images: [Artwork] }
    struct Artwork: Decodable { let url: URL }
    var nowPlaying: NowPlaying? {
        guard let item, item.type == nil || item.type == "track" else { return nil }
        let art = item.album?.images.first?.url
        let link = item.external_urls?["spotify"].flatMap(URL.init(string:))
        return NowPlaying(title: item.name, artist: item.artists?.map(\.name).joined(separator: ", ") ?? "Spotify",
                          artwork: art?.scheme == "https" ? art : nil,
                          link: link?.scheme == "https" && link?.host == "open.spotify.com" ? link : nil,
                          isPlaying: is_playing)
    }
}

enum SpotifyOAuth {
    // Bring your own Spotify app: set SPOTIFY_CLIENT_ID (see README). It reaches the app through
    // the SpotifyClientID Info.plist key. No client secret is used by this native PKCE client.
    static var clientID: String {
        (Bundle.main.object(forInfoDictionaryKey: "SpotifyClientID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    /// False until a real client ID is configured; an unexpanded build variable counts as missing.
    static var isConfigured: Bool { !clientID.isEmpty && !clientID.hasPrefix("$(") }
    static let redirect = "zerodock://spotify/callback"
    enum Failure: Error { case invalidCallback }
    static func challenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    static func authorizationURL(state: String, challenge: String) -> URL {
        var url = URLComponents(string: "https://accounts.spotify.com/authorize")!
        url.queryItems = [
            URLQueryItem(name: "client_id", value: clientID), URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirect), URLQueryItem(name: "scope", value: "user-read-currently-playing"),
            URLQueryItem(name: "state", value: state), URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge)
        ]
        return url.url!
    }
    static func code(from callback: URL, expectedState: String) throws -> String {
        guard callback.scheme == "zerodock", callback.host == "spotify", callback.path == "/callback",
              let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems,
              items.filter({ $0.name == "state" }).count == 1,
              items.first(where: { $0.name == "state" })?.value == expectedState,
              !items.contains(where: { $0.name == "error" }),
              items.filter({ $0.name == "code" }).count == 1,
              let code = items.first(where: { $0.name == "code" })?.value, !code.isEmpty
        else { throw Failure.invalidCallback }
        return code
    }
    static func form(_ values: [String: String]) -> Data {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return Data(values.sorted(by: { $0.key < $1.key }).map { key, value in
            "\(key.addingPercentEncoding(withAllowedCharacters: allowed)!)=\(value.addingPercentEncoding(withAllowedCharacters: allowed)!)"
        }.joined(separator: "&").utf8)
    }
}
