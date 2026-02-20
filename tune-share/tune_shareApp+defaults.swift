//
//  tune_shareApp+defaults.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import Foundation

extension tune_shareApp {
	enum DefaultsKey {
		static let spotifyClientID = "spotifyClientID"
		static let spotifyRedirectURI = "spotifyRedirectURI"
	}

	enum OnboardingState {
		case needsConfiguration
		case configured
	}

	static func onboardingState(defaults: UserDefaults = .standard) -> OnboardingState {
		hasSpotifyConfiguration(defaults: defaults) ? .configured : .needsConfiguration
	}

	static func hasSpotifyConfiguration(defaults: UserDefaults = .standard) -> Bool {
		let clientID = defaults.string(forKey: DefaultsKey.spotifyClientID)?
			.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		let redirectURI = defaults.string(forKey: DefaultsKey.spotifyRedirectURI)?
			.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		return !clientID.isEmpty && !redirectURI.isEmpty
	}

	static func resetSpotifyConfiguration(defaults: UserDefaults = .standard) {
		defaults.removeObject(forKey: DefaultsKey.spotifyClientID)
		defaults.removeObject(forKey: DefaultsKey.spotifyRedirectURI)
	}
}
