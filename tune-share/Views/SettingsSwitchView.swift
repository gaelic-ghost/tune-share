//
//  SettingsSwitchView.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

// TODO: Impl settings view and k/vs

struct SettingsSwitchView: View {
	@AppStorage("isOnboarded") private var isOnboarded: Bool = false
	@ObservedObject var spotifyModel: SpotifySettingsViewModel
	
	var body: some View {
		// TODO: Impl both these views
		switch isOnboarded {
			case true: SettingsContentView(spotifyModel: spotifyModel)
			case false: SetupContentView()
		}
	}
}
