//
//  SetupContentView.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

struct SetupContentView: View {
	@ObservedObject var spotifyModel: SpotifySettingsViewModel

	var body: some View {
		Form {
			Section("Welcome") {
				Text("Add your Spotify app credentials to get started.")
				Text("Use redirect URI: tuneshare://spotify-callback")
					.font(.footnote)
					foregroundStyle(.secondary)
			}

			Section("Spotify Setup") {
				TextField("Client ID", text: $spotifyModel.clientID)
					.textFieldStyle(.roundedBorder)
				TextField("Redirect URI", text: $spotifyModel.redirectURI)
					.textFieldStyle(.roundedBorder)

				HStack {
					Button("Save") {
						spotifyModel.saveConfiguration()
					}
					Button("Save & Connect") {
						spotifyModel.connectSpotify()
					}
					.buttonStyle(.borderedProminent)
				}
				.disabled(spotifyModel.isBusy)

				if let statusMessage = spotifyModel.statusMessage {
					Text(statusMessage)
						.font(.footnote)
						foregroundStyle(.secondary)
				}
			}
		}
		.padding()
		.frame(minWidth: 560)
		.onOpenURL { spotifyModel.handleCallback(url: $0) }
	}
}

#Preview {
	SetupContentView(spotifyModel: SpotifySettingsViewModel())
}
