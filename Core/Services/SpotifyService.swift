import Foundation
import Observation
import AuthenticationServices
import Security
#if os(iOS)
import UIKit
#else
import AppKit
#endif

private struct SpotifyCredentials: Codable {
    var access: String
    var refresh: String
    var expires: Date
}

/// Only ZeroDock's own credentials are stored here, under its own Keychain service.
private enum SpotifyVault {
    static let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                      kSecAttrService as String: "dev.zerodock.spotify",
                                      kSecAttrAccount as String: SpotifyOAuth.clientID]
    static func load() -> Data? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &item) == errSecSuccess else { return nil }
        return item as? Data
    }
    static func save(_ data: Data) throws {
        let updates = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
        if status == errSecItemNotFound {
            var request = query
            request[kSecValueData as String] = data
            request[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(request as CFDictionary, nil) == errSecSuccess else { throw SpotifyError.storage }
        } else if status != errSecSuccess { throw SpotifyError.storage }
    }
    static func clear() { SecItemDelete(query as CFDictionary) }
}

private enum SpotifyError: Error { case storage, random, token, authorization, request, forbidden }

@MainActor @Observable
final class SpotifyService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private(set) var nowPlaying: NowPlaying?
    private(set) var connected = false
    private(set) var connecting = false
    private(set) var message = "Connect Spotify to see your current track and original album artwork."
    private var credentials: SpotifyCredentials?
    private var authSession: ASWebAuthenticationSession?
    private var nextRefresh = Date.distantPast
    private var refreshing = false
    private var restored = false
    private var generation = UUID()

    func restore() {
        guard !restored else { return }
        restored = true
        if let data = SpotifyVault.load(), let value = try? JSONDecoder().decode(SpotifyCredentials.self, from: data) {
            credentials = value
            connected = true
            message = "Connected. Checking playback…"
        }
    }

    func connect() async {
        guard !connecting else { return }
        guard SpotifyOAuth.isConfigured else {
            message = "Add your Spotify client ID to connect. See the README."
            return
        }
        connecting = true
        let attempt = generation
        defer { connecting = false; authSession = nil }
        do {
            let verifier = try randomString()
            let state = try randomString()
            let url = SpotifyOAuth.authorizationURL(state: state, challenge: SpotifyOAuth.challenge(for: verifier))
            let callback: URL = try await withCheckedThrowingContinuation { continuation in
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "zerodock") { callback, error in
                    if let callback { continuation.resume(returning: callback) }
                    else { continuation.resume(throwing: error ?? SpotifyError.authorization) }
                }
                session.presentationContextProvider = self
                session.prefersEphemeralWebBrowserSession = false
                authSession = session
                if !session.start() { continuation.resume(throwing: SpotifyError.authorization) }
            }
            guard generation == attempt else { return }
            let code = try SpotifyOAuth.code(from: callback, expectedState: state)
            try await updateToken(["grant_type": "authorization_code", "code": code,
                                   "redirect_uri": SpotifyOAuth.redirect, "code_verifier": verifier,
                                   "client_id": SpotifyOAuth.clientID], generation: attempt)
            guard generation == attempt else { return }
            connected = true
            nextRefresh = .distantPast
            await refresh()
        } catch {
            guard generation == attempt else { return }
            message = "Spotify sign-in did not complete. Confirm the ZeroDock callback is registered, then try again."
        }
    }

    func disconnect() {
        generation = UUID()
        authSession?.cancel()
        credentials = nil
        connected = false
        nowPlaying = nil
        SpotifyVault.clear()
        message = "Disconnected from ZeroDock. Your other Spotify connections are unchanged."
    }

    func refresh() async {
        guard connected, !refreshing, Date.now >= nextRefresh else { return }
        refreshing = true
        let attempt = generation
        defer { refreshing = false }
        nextRefresh = .now.addingTimeInterval(20)
        do {
            guard let token = credentials else { throw SpotifyError.authorization }
            if token.expires.timeIntervalSinceNow < 60 {
                try await updateToken(["grant_type": "refresh_token", "refresh_token": token.refresh, "client_id": SpotifyOAuth.clientID], generation: attempt)
            }
            guard generation == attempt else { return }
            guard let access = credentials?.access else { throw SpotifyError.authorization }
            var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
            request.timeoutInterval = 15
            request.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard generation == attempt, connected, let response = response as? HTTPURLResponse else { return }
            switch response.statusCode {
            case 200:
                nowPlaying = try JSONDecoder().decode(SpotifyPlayback.self, from: data).nowPlaying
                message = nowPlaying == nil ? "Nothing is playing. Start music in Spotify on any of your devices." : "Connected to Spotify"
            case 204:
                nowPlaying = nil
                message = "Nothing is playing. Start music in Spotify on any of your devices."
            case 401:
                credentials?.expires = .distantPast
                nowPlaying = nil
                message = "Refreshing Spotify access…"
            case 403:
                nowPlaying = nil
                message = "Spotify access is unavailable. Check the app’s user allowlist and developer-account eligibility."
            case 429:
                nowPlaying = nil
                let seconds = Double(response.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
                nextRefresh = .now.addingTimeInterval(max(20, min(3600, seconds)))
                message = "Spotify has limited requests. ZeroDock will wait before retrying."
            default: throw SpotifyError.request
            }
        } catch {
            guard generation == attempt else { return }
            nowPlaying = nil
            message = "Spotify is temporarily unavailable. Reconnect if this persists."
        }
    }

    private func updateToken(_ fields: [String: String], generation attempt: UUID) async throws {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = SpotifyOAuth.form(fields)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard generation == attempt else { throw CancellationError() }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw SpotifyError.token }
        struct Token: Decodable { let access_token: String; let refresh_token: String?; let expires_in: Double }
        let token = try JSONDecoder().decode(Token.self, from: data)
        guard let refresh = token.refresh_token ?? credentials?.refresh, !token.access_token.isEmpty else { throw SpotifyError.token }
        let value = SpotifyCredentials(access: token.access_token, refresh: refresh, expires: .now.addingTimeInterval(token.expires_in))
        try SpotifyVault.save(JSONEncoder().encode(value))
        credentials = value
    }

    private func randomString() throws -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw SpotifyError.random }
        return Data(bytes).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        #else
        return NSApplication.shared.keyWindow ?? ASPresentationAnchor()
        #endif
    }
}
