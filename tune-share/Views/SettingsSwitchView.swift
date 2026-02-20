//
//  SettingsSwitchView.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

// TODO: Impl settings view and k/vs

struct SettingsSwitchView: View {
	@AppStorage(tune_shareApp.DefaultsKey.spotifyClientID) private var spotifyClientID: String = ""
	@AppStorage(tune_shareApp.DefaultsKey.spotifyRedirectURI) private var spotifyRedirectURI: String = ""
	@ObservedObject var spotifyModel: SpotifySettingsViewModel
	
	var body: some View {
		let _ = (spotifyClientID, spotifyRedirectURI)
		switch tune_shareApp.onboardingState() {
			case .configured:
				SettingsContentView(spotifyModel: spotifyModel)
			case .needsConfiguration:
				SetupContentView(spotifyModel: spotifyModel)
		}
	}
}
