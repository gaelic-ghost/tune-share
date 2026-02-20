//
//  SpotifyController+Models.swift
//  tune-share
//
//  Created by Codex on 2/20/26.
//

import Foundation
import Security
import CryptoKit

struct SpotifyConfiguration {
	let clientID: String
	let redirectURI: URL
	let scopes: [String]

	init?(defaults: UserDefaults) {
		guard
			let clientID = defaults.string(forKey: "spotifyClientID") ?? Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_CLIENT_ID") as? String,
			let redirectString = defaults.string(forKey: "spotifyRedirectURI") ?? Bundle.main.object(forInfoDictionaryKey: "SPOTIFY_REDIRECT_URI") as? String,
			let redirectURI = URL(string: redirectString)
		else {
			return nil
		}
		self.clientID = clientID
		self.redirectURI = redirectURI
		self.scopes = [
			"user-read-currently-playing",
			"user-read-playback-state"
		]
	}
}

struct SpotifyAuthContext {
	let state: String
	let codeVerifier: String
}

struct SpotifyCallback {
	let code: String
	let state: String

	init(url: URL) throws {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
			throw SpotifyError.invalidCallback
		}
		let items = components.queryItems ?? []
		if let error = items.first(where: { $0.name == "error" })?.value {
			throw SpotifyError.authorizationDenied(error)
		}
		guard
			let code = items.first(where: { $0.name == "code" })?.value,
			let state = items.first(where: { $0.name == "state" })?.value
		else {
			throw SpotifyError.invalidCallback
		}
		self.code = code
		self.state = state
	}
}

enum PKCE {
	private static let verifierCharacters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

	static func generateCodeVerifier(length: Int = 64) -> String {
		var bytes = [UInt8](repeating: 0, count: length)
		_ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

		return String(bytes.map { byte in
			verifierCharacters[Int(byte) % verifierCharacters.count]
		})
	}

	static func generateCodeChallenge(from verifier: String) -> String {
		let digest = SHA256.hash(data: Data(verifier.utf8))
		return Data(digest)
			.base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
}

struct SpotifyToken: Codable {
	var accessToken: String
	var refreshToken: String?
	var tokenType: String
	var scope: String
	var expiresAt: Date

	var isValid: Bool {
		Date().addingTimeInterval(60) < expiresAt
	}
}

struct SpotifyTokenResponse: Codable {
	var accessToken: String
	var tokenType: String
	var scope: String
	var expiresIn: Int
	var refreshToken: String?

	enum CodingKeys: String, CodingKey {
		case accessToken = "access_token"
		case tokenType = "token_type"
		case scope
		case expiresIn = "expires_in"
		case refreshToken = "refresh_token"
	}
}

protocol SpotifyTokenStore {
	func save(_ token: SpotifyToken) throws
	func load() throws -> SpotifyToken
	func clear() throws
}

final class KeychainSpotifyTokenStore: SpotifyTokenStore {
	private let service = "com.galewilliams.tune-share.spotify"
	private let account = "oauth-token"

	func save(_ token: SpotifyToken) throws {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .iso8601
		let payload = try encoder.encode(token)

		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account
		]

		let attributes: [String: Any] = [
			kSecValueData as String: payload
		]

		let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
		if updateStatus == errSecSuccess {
			return
		}

		var createQuery = query
		createQuery[kSecValueData as String] = payload

		let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
		guard createStatus == errSecSuccess else {
			throw SpotifyError.keychainWriteFailed(createStatus)
		}
	}

	func load() throws -> SpotifyToken {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account,
			kSecReturnData as String: true,
			kSecMatchLimit as String: kSecMatchLimitOne
		]

		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)

		guard status != errSecItemNotFound else {
			throw SpotifyError.missingStoredToken
		}
		guard status == errSecSuccess, let data = result as? Data else {
			throw SpotifyError.keychainReadFailed(status)
		}

		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .iso8601
		return try decoder.decode(SpotifyToken.self, from: data)
	}

	func clear() throws {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrService as String: service,
			kSecAttrAccount as String: account
		]
		let status = SecItemDelete(query as CFDictionary)
		guard status == errSecSuccess || status == errSecItemNotFound else {
			throw SpotifyError.keychainDeleteFailed(status)
		}
	}
}

struct CurrentlyPlayingResponse: Codable {
	var item: SpotifyTrack?
}

struct SpotifyTrack: Codable {
	var id: String?
	var name: String
	var explicit: Bool?
	var durationMS: Int?
	var artists: [SpotifyArtist]
	var album: SpotifyAlbum
	var externalIDs: SpotifyExternalIDs?
	var externalURLs: SpotifyExternalURLs

	enum CodingKeys: String, CodingKey {
		case id
		case name
		case explicit
		case durationMS = "duration_ms"
		case artists
		case album
		case externalIDs = "external_ids"
		case externalURLs = "external_urls"
	}
}

struct SpotifyArtist: Codable {
	var name: String
}

struct SpotifyAlbum: Codable {
	var name: String
}

struct SpotifyExternalIDs: Codable {
	var isrc: String?
}

struct SpotifyExternalURLs: Codable {
	var spotify: URL?
}

enum SpotifyError: Error, LocalizedError {
	case missingConfiguration
	case authorizationURLBuildFailed
	case missingAuthContext
	case invalidCallback
	case invalidState
	case tokenExchangeFailed
	case tokenRefreshFailed
	case missingStoredToken
	case missingRefreshToken
	case invalidResponse
	case unexpectedStatusCode(Int)
	case authorizationDenied(String)
	case keychainReadFailed(OSStatus)
	case keychainWriteFailed(OSStatus)
	case keychainDeleteFailed(OSStatus)

	var errorDescription: String? {
		switch self {
		case .missingConfiguration:
			return "Missing Spotify configuration. Set spotifyClientID and spotifyRedirectURI."
		case .authorizationURLBuildFailed:
			return "Failed to build Spotify authorization URL."
		case .missingAuthContext:
			return "Missing in-flight Spotify authorization context."
		case .invalidCallback:
			return "Invalid Spotify callback URL."
		case .invalidState:
			return "Spotify authorization state mismatch."
		case .tokenExchangeFailed:
			return "Spotify token exchange failed."
		case .tokenRefreshFailed:
			return "Spotify token refresh failed."
		case .missingStoredToken:
			return "No Spotify token is stored."
		case .missingRefreshToken:
			return "Spotify refresh token is missing."
		case .invalidResponse:
			return "Spotify returned an invalid response."
		case .unexpectedStatusCode(let code):
			return "Spotify returned an unexpected status code: \(code)."
		case .authorizationDenied(let reason):
			return "Spotify authorization denied: \(reason)."
		case .keychainReadFailed(let status):
			return "Failed to read Spotify token from Keychain (\(status))."
		case .keychainWriteFailed(let status):
			return "Failed to write Spotify token to Keychain (\(status))."
		case .keychainDeleteFailed(let status):
			return "Failed to delete Spotify token from Keychain (\(status))."
		}
	}
}
