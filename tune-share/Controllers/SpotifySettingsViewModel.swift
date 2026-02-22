//
//  SpotifySettingsViewModel.swift
//  tune-share
//
//  Created by Codex on 2/20/26.
//

import Foundation
import AppKit
import Combine

@MainActor
final class SpotifySettingsViewModel: ObservableObject {
	@Published var clientID: String
	@Published var redirectURI: String
	@Published var statusMessage: String?
	@Published var nowPlayingSummary: String?
	@Published var isBusy = false

	private let controller: SpotifyController
	private let defaults: UserDefaults

	init(
		controller: SpotifyController = SpotifyController(),
		defaults: UserDefaults = .standard
	) {
		self.controller = controller
		self.defaults = defaults
		self.clientID = defaults.string(forKey: "spotifyClientID") ?? ""
		self.redirectURI = defaults.string(forKey: "spotifyRedirectURI") ?? ""
	}

	var hasConfiguration: Bool {
		!clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
		!redirectURI.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}

	func saveConfiguration() {
		defaults.set(clientID.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "spotifyClientID")
		defaults.set(redirectURI.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "spotifyRedirectURI")
		statusMessage = "Saved Spotify configuration."
	}

	func connectSpotify() {
		saveConfiguration()

		do {
			let authorizationURL = try controller.beginAuthorization()
			NSWorkspace.shared.open(authorizationURL)
			statusMessage = "Opened Spotify authorization in your browser."
		} catch {
			statusMessage = error.localizedDescription
		}
	}

	func handleCallback(url: URL) {
		isBusy = true

		Task {
			defer { isBusy = false }
			do {
				try await controller.handleAuthorizationCallback(url)
				statusMessage = "Spotify connected successfully."
			} catch {
				statusMessage = error.localizedDescription
			}
		}
	}

	func fetchNowPlaying() {
		isBusy = true
		nowPlayingSummary = nil

		Task {
			defer { isBusy = false }
			do {
				let track = try await controller.fetchCurrentlyPlayingTrack()
				if let track {
					let artists = track.artists.joined(separator: ", ")
					nowPlayingSummary = "\(track.title) - \(artists)"
					statusMessage = "Fetched Spotify now playing."
				} else {
					nowPlayingSummary = "Nothing currently playing."
					statusMessage = "No active playback found."
				}
			} catch {
				statusMessage = error.localizedDescription
			}
		}
	}

	func signOut() {
		do {
			try controller.signOut()
			statusMessage = "Cleared Spotify token from Keychain."
			nowPlayingSummary = nil
		} catch {
			statusMessage = error.localizedDescription
		}
	}
}
