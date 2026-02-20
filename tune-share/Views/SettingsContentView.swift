//
//  SettingsContentView.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

struct SettingsContentView: View {
	@ObservedObject var spotifyModel: SpotifySettingsViewModel

	var body: some View {
		Form {
			Section("Spotify") {
				TextField("Client ID", text: $spotifyModel.clientID)
					.textFieldStyle(.roundedBorder)
				TextField("Redirect URI", text: $spotifyModel.redirectURI)
					.textFieldStyle(.roundedBorder)

				HStack {
					Button("Save") {
						spotifyModel.saveConfiguration()
					}
					Button("Connect Spotify") {
						spotifyModel.connectSpotify()
					}
					.buttonStyle(.borderedProminent)
					Button("Test Now Playing") {
						spotifyModel.fetchNowPlaying()
					}
					Button("Sign Out") {
						spotifyModel.signOut()
					}
				}
				.disabled(spotifyModel.isBusy)

				if let statusMessage = spotifyModel.statusMessage {
					Text(statusMessage)
						.font(.footnote)
						foregroundStyle(.secondary)
				}

				if let summary = spotifyModel.nowPlayingSummary {
					Text(summary)
				}
			}
		}
		.padding()
		.frame(minWidth: 560)
		.onOpenURL { spotifyModel.handleCallback(url: $0) }
	}

}

#Preview {
	SettingsContentView(spotifyModel: SpotifySettingsViewModel())
}
