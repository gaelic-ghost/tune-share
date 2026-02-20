//
//  LinkModel.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import Foundation

struct LinkModel: Codable, Hashable {
	var service: MusicService
	var title: String
	var url: URL
}
