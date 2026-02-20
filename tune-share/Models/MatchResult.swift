//
//  MatchResult.swift
//  tune-share
//
//  Created by Codex on 2/20/26.
//

import Foundation

enum MatchState: String, Codable, Hashable {
	case matched
	case ambiguous
	case notFound
}

enum MatchReason: String, Codable, Hashable {
	case isrcExact
	case titleSimilarity
	case artistSimilarity
	case albumSimilarity
	case durationClose
	case explicitParity
	case versionParity
}

struct MatchScoreBreakdown: Codable, Hashable {
	var title: Double
	var artist: Double
	var album: Double
	var duration: Double
	var explicit: Double
	var version: Double
	var total: Double
}

struct MatchCandidate: Codable, Hashable {
	var track: CanonicalTrack
	var score: Double
	var reasons: [MatchReason]
	var breakdown: MatchScoreBreakdown
}

struct MatchResult: Codable, Hashable {
	var sourceTrack: CanonicalTrack
	var state: MatchState
	var bestMatch: MatchCandidate?
	var alternatives: [MatchCandidate]
}
