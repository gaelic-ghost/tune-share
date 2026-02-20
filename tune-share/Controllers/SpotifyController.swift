//
//  SpotifyController.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import Foundation

final class SpotifyController {
	private let session: URLSession
	private let tokenStore: SpotifyTokenStore
	private let defaults: UserDefaults
	private var authContext: SpotifyAuthContext?

	init(
		session: URLSession = .shared,
		defaults: UserDefaults = .standard
	) {
		self.session = session
		self.tokenStore = KeychainSpotifyTokenStore()
		self.defaults = defaults
	}

	func beginAuthorization() throws -> URL {
		let config = try resolveConfiguration()
		let verifier = PKCE.generateCodeVerifier()
		let challenge = PKCE.generateCodeChallenge(from: verifier)
		let state = UUID().uuidString.lowercased()
		authContext = SpotifyAuthContext(state: state, codeVerifier: verifier)

		var components = URLComponents(string: "https://accounts.spotify.com/authorize")
		components?.queryItems = [
			URLQueryItem(name: "client_id", value: config.clientID),
			URLQueryItem(name: "response_type", value: "code"),
			URLQueryItem(name: "redirect_uri", value: config.redirectURI.absoluteString),
			URLQueryItem(name: "code_challenge_method", value: "S256"),
			URLQueryItem(name: "code_challenge", value: challenge),
			URLQueryItem(name: "state", value: state),
			URLQueryItem(name: "scope", value: config.scopes.joined(separator: " "))
		]

		guard let url = components?.url else {
			throw SpotifyError.authorizationURLBuildFailed
		}
		return url
	}

	func handleAuthorizationCallback(_ url: URL) async throws {
		guard let context = authContext else {
			throw SpotifyError.missingAuthContext
		}

		let callback = try SpotifyCallback(url: url)
		guard callback.state == context.state else {
			throw SpotifyError.invalidState
		}

		let config = try resolveConfiguration()
		let token = try await exchangeCodeForToken(
			callback.code,
			codeVerifier: context.codeVerifier,
			config: config
		)
		try tokenStore.save(token)
		authContext = nil
	}

	func fetchCurrentlyPlayingTrack() async throws -> CanonicalTrack? {
		let accessToken = try await validAccessToken()
		var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
		request.httpMethod = "GET"
		request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

		let (data, response) = try await session.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw SpotifyError.invalidResponse
		}

		if httpResponse.statusCode == 204 {
			return nil
		}

		guard (200...299).contains(httpResponse.statusCode) else {
			throw SpotifyError.unexpectedStatusCode(httpResponse.statusCode)
		}

		let payload = try JSONDecoder().decode(CurrentlyPlayingResponse.self, from: data)
		guard let track = payload.item else {
			return nil
		}
		let sourceID = track.id ?? track.externalURLs.spotify?.absoluteString ?? UUID().uuidString

		return CanonicalTrack(
			canonicalID: UUID(),
			isrc: track.externalIDs?.isrc,
			title: track.name,
			artists: track.artists.map(\.name),
			album: track.album.name,
			durationMs: track.durationMS,
			explicit: track.explicit,
			releaseDate: nil,
			trackNumber: nil,
			discNumber: nil,
			sourceService: .spotify,
			sourceServiceID: sourceID,
			sourceURL: track.externalURLs.spotify
		)
	}

	func signOut() throws {
		try tokenStore.clear()
		authContext = nil
	}

	private func validAccessToken() async throws -> String {
		var token = try tokenStore.load()

		if token.isValid {
			return token.accessToken
		}

		guard let refreshToken = token.refreshToken else {
			throw SpotifyError.missingRefreshToken
		}

		let config = try resolveConfiguration()
		token = try await refreshAccessToken(
			refreshToken: refreshToken,
			config: config,
			previous: token
		)
		try tokenStore.save(token)
		return token.accessToken
	}

	private func resolveConfiguration() throws -> SpotifyConfiguration {
		if let configuration = SpotifyConfiguration(defaults: defaults) {
			return configuration
		}
		throw SpotifyError.missingConfiguration
	}

	private func exchangeCodeForToken(
		_ code: String,
		codeVerifier: String,
		config: SpotifyConfiguration
	) async throws -> SpotifyToken {
		var components = URLComponents(string: "https://accounts.spotify.com/api/token")
		components?.queryItems = [
			URLQueryItem(name: "grant_type", value: "authorization_code"),
			URLQueryItem(name: "code", value: code),
			URLQueryItem(name: "redirect_uri", value: config.redirectURI.absoluteString),
			URLQueryItem(name: "client_id", value: config.clientID),
			URLQueryItem(name: "code_verifier", value: codeVerifier)
		]

		guard let query = components?.percentEncodedQuery else {
			throw SpotifyError.tokenExchangeFailed
		}

		var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.httpBody = Data(query.utf8)

		let (data, response) = try await session.data(for: request)
		return try parseTokenResponse(data: data, response: response)
	}

	private func refreshAccessToken(
		refreshToken: String,
		config: SpotifyConfiguration,
		previous: SpotifyToken
	) async throws -> SpotifyToken {
		var components = URLComponents(string: "https://accounts.spotify.com/api/token")
		components?.queryItems = [
			URLQueryItem(name: "grant_type", value: "refresh_token"),
			URLQueryItem(name: "refresh_token", value: refreshToken),
			URLQueryItem(name: "client_id", value: config.clientID)
		]

		guard let query = components?.percentEncodedQuery else {
			throw SpotifyError.tokenRefreshFailed
		}

		var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
		request.httpMethod = "POST"
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.httpBody = Data(query.utf8)

		let (data, response) = try await session.data(for: request)
		var refreshed = try parseTokenResponse(data: data, response: response)
		if refreshed.refreshToken == nil {
			refreshed.refreshToken = previous.refreshToken
		}
		return refreshed
	}

	private func parseTokenResponse(data: Data, response: URLResponse) throws -> SpotifyToken {
		guard let httpResponse = response as? HTTPURLResponse else {
			throw SpotifyError.invalidResponse
		}
		guard (200...299).contains(httpResponse.statusCode) else {
			throw SpotifyError.unexpectedStatusCode(httpResponse.statusCode)
		}

		let decoded = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
		return SpotifyToken(
			accessToken: decoded.accessToken,
			refreshToken: decoded.refreshToken,
			tokenType: decoded.tokenType,
			scope: decoded.scope,
			expiresAt: Date().addingTimeInterval(TimeInterval(decoded.expiresIn))
		)
	}
}
