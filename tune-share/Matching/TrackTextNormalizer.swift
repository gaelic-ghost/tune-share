//
//  TrackTextNormalizer.swift
//  tune-share
//
//  Created by Codex on 2/20/26.
//

import Foundation

enum TrackTextNormalizer {
	private static let punctuationRegex = try! NSRegularExpression(pattern: "[^\\p{L}\\p{N}\\s]")
	private static let whitespaceRegex = try! NSRegularExpression(pattern: "\\s+")

	private static let featureSynonyms = [
		"feat.": "feat",
		"feat": "feat",
		"ft.": "feat",
		"ft": "feat",
		"featuring": "feat"
	]

	private static let versionKeywords: Set<String> = [
		"live",
		"remaster",
		"remastered",
		"acoustic",
		"instrumental",
		"karaoke",
		"mono",
		"stereo",
		"explicit",
		"clean",
		"edit",
		"radio"
	]

	static func normalize(_ text: String) -> String {
		let folded = text
			.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
			.lowercased()

		let synonymNormalized = featureSynonyms.reduce(folded) { partial, next in
			partial.replacingOccurrences(of: next.key, with: next.value)
		}

		let range = NSRange(synonymNormalized.startIndex..., in: synonymNormalized)
		let punctuationStripped = punctuationRegex.stringByReplacingMatches(
			in: synonymNormalized,
			options: [],
			range: range,
			withTemplate: " "
		)
		let wsRange = NSRange(punctuationStripped.startIndex..., in: punctuationStripped)
		let compactWhitespace = whitespaceRegex.stringByReplacingMatches(
			in: punctuationStripped,
			options: [],
			range: wsRange,
			withTemplate: " "
		)
		return compactWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	static func tokenize(_ text: String) -> Set<String> {
		let normalized = normalize(text)
		guard !normalized.isEmpty else { return [] }
		return Set(normalized.split(separator: " ").map(String.init))
	}

	static func extractVersionTags(from title: String) -> Set<String> {
		let tokens = tokenize(title)
		return tokens.intersection(versionKeywords)
	}

	static func tokenSetSimilarity(lhs: String, rhs: String) -> Double {
		let lhsTokens = tokenize(lhs)
		let rhsTokens = tokenize(rhs)
		guard !lhsTokens.isEmpty || !rhsTokens.isEmpty else { return 0 }
		let intersectionCount = lhsTokens.intersection(rhsTokens).count
		let unionCount = lhsTokens.union(rhsTokens).count
		guard unionCount > 0 else { return 0 }
		return Double(intersectionCount) / Double(unionCount)
	}
}
