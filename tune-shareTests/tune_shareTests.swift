//
//  tune_shareTests.swift
//  tune-shareTests
//
//  Created by Gale Williams on 2/20/26.
//

import Foundation
import Testing
@testable import tune_share

struct TrackMatcherTests {
	@Test func prefersISRCExactMatch() {
		let source = makeTrack(
			title: "Around the World",
			artists: ["Daft Punk"],
			album: "Homework",
			durationMs: 427_000,
			isrc: "GBDUW0000059",
			sourceService: .spotify,
			sourceServiceID: "src-1"
		)

		let exact = makeTrack(
			title: "Around the World",
			artists: ["Daft Punk"],
			album: "Homework",
			durationMs: 427_000,
			isrc: "GBDUW0000059",
			sourceService: .appleMusic,
			sourceServiceID: "am-1"
		)
		let wrong = makeTrack(
			title: "Around the World (Live)",
			artists: ["Daft Punk"],
			album: "Live Set",
			durationMs: 436_000,
			isrc: "USUM71703861",
			sourceService: .appleMusic,
			sourceServiceID: "am-2"
		)

		let result = TrackMatcher.match(source: source, candidates: [wrong, exact])

		#expect(result.state == .matched)
		#expect(result.bestMatch?.track.sourceServiceID == "am-1")
		#expect(result.bestMatch?.score == 1.0)
		#expect(result.bestMatch?.reasons.contains(.isrcExact) == true)
	}

	@Test func rewardsSmallDurationDeltaOverLargeDelta() {
		let source = makeTrack(
			title: "N95",
			artists: ["Kendrick Lamar"],
			album: "Mr. Morale & the Big Steppers",
			durationMs: 195_000,
			sourceService: .spotify,
			sourceServiceID: "src-2"
		)
		let closeDuration = makeTrack(
			title: "N95",
			artists: ["Kendrick Lamar"],
			album: "Mr Morale and the Big Steppers",
			durationMs: 196_200,
			sourceService: .appleMusic,
			sourceServiceID: "am-close"
		)
		let farDuration = makeTrack(
			title: "N95",
			artists: ["Kendrick Lamar"],
			album: "Mr Morale and the Big Steppers",
			durationMs: 208_000,
			sourceService: .appleMusic,
			sourceServiceID: "am-far"
		)

		let result = TrackMatcher.match(source: source, candidates: [farDuration, closeDuration])

		#expect(result.state == .matched)
		#expect(result.bestMatch?.track.sourceServiceID == "am-close")
		#expect(result.bestMatch?.reasons.contains(.durationClose) == true)
	}

	@Test func normalizesFeatAndPunctuationAndVersionTokens() {
		let normalized = TrackTextNormalizer.normalize("Blinding Lights (feat. ROSALÍA)!!!")
		let tags = TrackTextNormalizer.extractVersionTags(from: "Blinding Lights - Live Remastered")
		let similarity = TrackTextNormalizer.tokenSetSimilarity(
			lhs: "Blinding Lights ft ROSALIA",
			rhs: "Blinding Lights (feat. Rosalía)"
		)

		#expect(normalized == "blinding lights feat rosalia")
		#expect(tags.contains("live"))
		#expect(tags.contains("remastered"))
		#expect(similarity == 1.0)
	}

	@Test func marksCloseScoresAsAmbiguousWhenWithinDelta() {
		let source = makeTrack(
			title: "Halo",
			artists: ["Beyonce"],
			album: "I Am... Sasha Fierce",
			durationMs: 261_000,
			sourceService: .spotify,
			sourceServiceID: "src-3"
		)
		let candidateA = makeTrack(
			title: "Halo",
			artists: ["Beyonce"],
			album: "I Am Sasha Fierce",
			durationMs: 261_500,
			sourceService: .appleMusic,
			sourceServiceID: "am-a"
		)
		let candidateB = makeTrack(
			title: "Halo",
			artists: ["Beyonce"],
			album: "I Am Sasha Fierce",
			durationMs: 262_500,
			sourceService: .appleMusic,
			sourceServiceID: "am-b"
		)

		let result = TrackMatcher.match(source: source, candidates: [candidateA, candidateB])

		#expect(result.state == .ambiguous)
		#expect(result.bestMatch != nil)
		#expect(result.alternatives.count == 2)
	}

	private func makeTrack(
		title: String,
		artists: [String],
		album: String? = nil,
		durationMs: Int? = nil,
		isrc: String? = nil,
		sourceService: MusicService,
		sourceServiceID: String
	) -> CanonicalTrack {
		CanonicalTrack(
			canonicalID: UUID(),
			isrc: isrc,
			title: title,
			artists: artists,
			album: album,
			durationMs: durationMs,
			explicit: nil,
			releaseDate: nil,
			trackNumber: nil,
			discNumber: nil,
			sourceService: sourceService,
			sourceServiceID: sourceServiceID,
			sourceURL: nil
		)
	}
}
