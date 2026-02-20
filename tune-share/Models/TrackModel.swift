//
//  TrackModel.swift
//  tune-share
//
//  Created by Gale Williams on 2/20/26.
//

import Foundation

enum MusicService: String, Codable, CaseIterable, Hashable {
	case spotify
	case appleMusic
	case youtube
}

struct ServiceTrackRef: Codable, Hashable {
	var service: MusicService
	var serviceID: String
	var url: URL?
}

struct CanonicalTrack: Codable, Hashable, Identifiable {
	var canonicalID: UUID
	var id: UUID { canonicalID }
	var isrc: String?
	var title: String
	var artists: [String]
	var album: String?
	var durationMs: Int?
	var explicit: Bool?
	var releaseDate: Date?
	var trackNumber: Int?
	var discNumber: Int?
	var sourceService: MusicService
	var sourceServiceID: String
	var sourceURL: URL?
	var fingerprint: TrackFingerprint {
		TrackFingerprint(
			isrc: isrc?.uppercased(),
			titleNormalized: TrackTextNormalizer.normalize(title),
			artistsNormalized: artists.map(TrackTextNormalizer.normalize),
			albumNormalized: album.map(TrackTextNormalizer.normalize),
			durationMs: durationMs,
			versionTags: TrackTextNormalizer.extractVersionTags(from: title)
		)
	}
}

typealias TrackModel = CanonicalTrack
