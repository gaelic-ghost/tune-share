//
//  TrackMatcher.swift
//  tune-share
//
//  Created by Codex on 2/20/26.
//

import Foundation

struct MatchConfig: Codable, Hashable {
	var titleWeight: Double
	var artistWeight: Double
	var albumWeight: Double
	var durationWeight: Double
	var explicitWeight: Double
	var versionWeight: Double
	var matchThreshold: Double
	var ambiguityDelta: Double

	static let `default` = MatchConfig(
		titleWeight: 0.30,
		artistWeight: 0.20,
		albumWeight: 0.10,
		durationWeight: 0.25,
		explicitWeight: 0.05,
		versionWeight: 0.05,
		matchThreshold: 0.60,
		ambiguityDelta: 0.03
	)
}

enum TrackMatcher {
	static func match(
		source: CanonicalTrack,
		candidates: [CanonicalTrack],
		config: MatchConfig = .default
	) -> MatchResult {
		let scored = candidates
			.map { scoreCandidate(source: source, candidate: $0, config: config) }
			.sorted(by: { $0.score > $1.score })

		guard let best = scored.first else {
			return MatchResult(sourceTrack: source, state: .notFound, bestMatch: nil, alternatives: [])
		}

		let secondBestScore = scored.dropFirst().first?.score
		let isAmbiguous = secondBestScore.map { abs(best.score - $0) <= config.ambiguityDelta } ?? false

		if best.score < config.matchThreshold {
			return MatchResult(sourceTrack: source, state: .notFound, bestMatch: nil, alternatives: scored)
		}

		if isAmbiguous {
			return MatchResult(sourceTrack: source, state: .ambiguous, bestMatch: best, alternatives: scored)
		}

		return MatchResult(sourceTrack: source, state: .matched, bestMatch: best, alternatives: scored)
	}

	private static func scoreCandidate(
		source: CanonicalTrack,
		candidate: CanonicalTrack,
		config: MatchConfig
	) -> MatchCandidate {
		let sourceFingerprint = source.fingerprint
		let candidateFingerprint = candidate.fingerprint

		if let sourceISRC = sourceFingerprint.isrc,
		   let candidateISRC = candidateFingerprint.isrc,
		   sourceISRC == candidateISRC {
			let breakdown = MatchScoreBreakdown(
				title: 0,
				artist: 0,
				album: 0,
				duration: 0,
				explicit: 0,
				version: 0,
				total: 1.0
			)
			return MatchCandidate(
				track: candidate,
				score: 1.0,
				reasons: [.isrcExact],
				breakdown: breakdown
			)
		}

		let titleSimilarity = TrackTextNormalizer.tokenSetSimilarity(lhs: source.title, rhs: candidate.title)
		let artistSimilarity = artistsSimilarity(
			sourceArtists: source.artists,
			candidateArtists: candidate.artists
		)
		let albumSimilarity = optionalStringSimilarity(lhs: source.album, rhs: candidate.album)
		let durationSimilarity = durationSimilarity(sourceMs: source.durationMs, candidateMs: candidate.durationMs)
		let explicitParity = boolParity(lhs: source.explicit, rhs: candidate.explicit)
		let versionParity = versionTagParity(
			sourceTags: sourceFingerprint.versionTags,
			candidateTags: candidateFingerprint.versionTags
		)

		let weightedTitle = titleSimilarity * config.titleWeight
		let weightedArtist = artistSimilarity * config.artistWeight
		let weightedAlbum = albumSimilarity * config.albumWeight
		let weightedDuration = durationSimilarity * config.durationWeight
		let weightedExplicit = explicitParity * config.explicitWeight
		let weightedVersion = versionParity * config.versionWeight
		let total = max(
			0,
			min(
				1,
				weightedTitle + weightedArtist + weightedAlbum + weightedDuration + weightedExplicit + weightedVersion
			)
		)

		var reasons: [MatchReason] = []
		if titleSimilarity >= 0.60 { reasons.append(.titleSimilarity) }
		if artistSimilarity >= 0.60 { reasons.append(.artistSimilarity) }
		if albumSimilarity >= 0.60 { reasons.append(.albumSimilarity) }
		if durationSimilarity >= 0.75 { reasons.append(.durationClose) }
		if explicitParity == 1 { reasons.append(.explicitParity) }
		if versionParity == 1 { reasons.append(.versionParity) }

		return MatchCandidate(
			track: candidate,
			score: total,
			reasons: reasons,
			breakdown: MatchScoreBreakdown(
				title: weightedTitle,
				artist: weightedArtist,
				album: weightedAlbum,
				duration: weightedDuration,
				explicit: weightedExplicit,
				version: weightedVersion,
				total: total
			)
		)
	}

	private static func artistsSimilarity(sourceArtists: [String], candidateArtists: [String]) -> Double {
		guard !sourceArtists.isEmpty, !candidateArtists.isEmpty else { return 0 }
		let lhs = sourceArtists.joined(separator: " ")
		let rhs = candidateArtists.joined(separator: " ")
		return TrackTextNormalizer.tokenSetSimilarity(lhs: lhs, rhs: rhs)
	}

	private static func optionalStringSimilarity(lhs: String?, rhs: String?) -> Double {
		guard let lhs, let rhs else { return 0 }
		return TrackTextNormalizer.tokenSetSimilarity(lhs: lhs, rhs: rhs)
	}

	private static func durationSimilarity(sourceMs: Int?, candidateMs: Int?) -> Double {
		guard let sourceMs, let candidateMs else { return 0 }
		let delta = abs(sourceMs - candidateMs)
		if delta <= 2_000 { return 1.0 }
		if delta <= 10_000 { return 0.5 }
		return 0
	}

	private static func boolParity(lhs: Bool?, rhs: Bool?) -> Double {
		guard let lhs, let rhs else { return 0 }
		return lhs == rhs ? 1.0 : 0
	}

	private static func versionTagParity(sourceTags: Set<String>, candidateTags: Set<String>) -> Double {
		if sourceTags.isEmpty && candidateTags.isEmpty { return 1.0 }
		guard !sourceTags.isEmpty || !candidateTags.isEmpty else { return 0 }
		let intersectionCount = sourceTags.intersection(candidateTags).count
		let unionCount = sourceTags.union(candidateTags).count
		guard unionCount > 0 else { return 0 }
		return Double(intersectionCount) / Double(unionCount)
	}
}
