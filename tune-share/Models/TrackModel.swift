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

	init(
		canonicalID: UUID = UUID(),
		isrc: String? = nil,
		title: String,
		artists: [String],
		album: String? = nil,
		durationMs: Int? = nil,
		explicit: Bool? = nil,
		releaseDate: Date? = nil,
		trackNumber: Int? = nil,
		discNumber: Int? = nil,
		sourceService: MusicService,
		sourceServiceID: String,
		sourceURL: URL? = nil
	) {
		self.canonicalID = canonicalID
		self.isrc = isrc
		self.title = title
		self.artists = artists
		self.album = album
		self.durationMs = durationMs
		self.explicit = explicit
		self.releaseDate = releaseDate
		self.trackNumber = trackNumber
		self.discNumber = discNumber
		self.sourceService = sourceService
		self.sourceServiceID = sourceServiceID
		self.sourceURL = sourceURL
	}

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
