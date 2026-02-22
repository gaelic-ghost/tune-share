//
//  SettingsSwitchView.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

// TODO: Impl settings view and k/vs

struct SettingsSwitchView: View {
	@ObservedObject var spotifyModel: SpotifySettingsViewModel
	
	var body: some View {
		if spotifyModel.hasConfiguration {
			SettingsContentView(spotifyModel: spotifyModel)
		} else {
			SetupContentView(spotifyModel: spotifyModel)
		}
	}
}
