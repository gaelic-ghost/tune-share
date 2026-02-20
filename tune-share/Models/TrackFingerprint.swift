//
//  TrackFingerprint.swift
//  tune-share
//
//  Created by Codex on 2/20/26.
//

import Foundation

struct TrackFingerprint: Codable, Hashable {
	var isrc: String?
	var titleNormalized: String
	var artistsNormalized: [String]
	var albumNormalized: String?
	var durationMs: Int?
	var versionTags: Set<String>
}
