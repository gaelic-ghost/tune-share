//
//  tune_shareApp.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import SwiftUI

@main
struct tune_shareApp: App {
	@AppStorage("isOnboarded") private var isOnboarded: Bool = false
    var body: some Scene {
		/// Menu Bar Scene
		MenuBarExtra("Menu Item Label") {
			// TODO: Impl view
			MenuBarView()
		}
		/// macOS Settings Scene
		Settings {
			// TODO: Pass in AppStorage settings
			// TODO: Impl both these views
			switch isOnboarded {
				case true: SettingsView()
				case false: SetupView()
			}
		}
    }
}
