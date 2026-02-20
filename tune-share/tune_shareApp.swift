//
//  tune_shareApp.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

@main
struct tune_shareApp: App {
	
	// TODO: Consider CA and Shazam as another way to match currently playing tracks
	
	let defaults = UserDefaults()
	
    var body: some Scene {
		
		/// Menu Bar Scene
		MenuBarExtra("Menu Item Label") {
			// TODO: Impl view
			MenuBarContentView()
		}
		
		/// macOS Settings Scene
		Settings {
			// TODO: Pass in AppStorage settings
			SettingsSwitchView()
		}
    }
}
