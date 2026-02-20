# tune-share

Get a variety of links to share a track with your friends.

## Product goal

Given a currently playing track (or a pasted link), return high-confidence links for the same recording across:

- Spotify
- Apple Music
- YouTube

## MVP milestones

1. Lock data model and matching contract
- Define canonical track identity and service-specific IDs.
- Define normalized text fields and confidence scoring.
- Add fixtures for tricky cases: remaster, live, explicit/clean, featured artists.

2. Implement source adapters
- `SpotifyController`: currently playing + search + track lookup.
- `AMController`: currently playing + catalog search + lookup.
- `YTController`: search + candidate fetch + normalization.

3. Matching engine (accuracy-first)
- Phase A: deterministic exact match by ISRC when available.
- Phase B: weighted fallback score from title/artist/duration/album/explicit/version tags.
- Return top match + confidence + reason codes.

4. Link generation and menu-bar UI flow
- Capture current track.
- Show per-service match state (`matched`, `ambiguous`, `not_found`).
- Copy/share all resolved links.

5. Reliability and regression safety
- Unit tests for normalization and scoring.
- Snapshot fixtures from real API responses.
- Error handling for rate limits/auth failures/empty now playing.

## Why data modeling should be step 1

Yes, this should be step 1. If your canonical model is stable early, adapters and matching logic stay simple and testable.

Recommended core entities:

- `CanonicalTrack`: unified representation used by scoring.
- `ServiceTrackRef`: IDs/URLs per service.
- `TrackFingerprint`: identity hints (`isrc`, duration, normalized title/artist).
- `MatchResult`: candidate + score + explanation.

Suggested `CanonicalTrack` fields:

- `canonicalID` (internal UUID)
- `isrc` (optional, strongest cross-service key)
- `title`
- `titleNormalized`
- `artists` / `artistsNormalized`
- `album` / `albumNormalized`
- `durationMs`
- `explicit` (optional)
- `releaseDate` (optional)
- `trackNumber` / `discNumber` (optional)
- `sourceService`
- `sourceServiceID`
- `sourceURL`

## Matching strategy (industry-practical)

1. ISRC-first exact lookup
- If source has ISRC, query target service by ISRC when API supports it.
- If one exact result is returned, mark as high confidence.

2. Metadata fallback scoring
- Build a candidate set from service search.
- Normalize text (case-fold, punctuation removal, feat./ft. normalization, version tag extraction).
- Score with weighted features:
  - ISRC exact: +1.00
  - Duration delta <= 2s: +0.25
  - Primary artist token match: +0.20
  - Title token similarity: +0.30
  - Album similarity: +0.10
  - Explicit parity/version tag parity: +0.05

3. Ambiguity handling
- If top two scores are very close, return `ambiguous` with both candidates.
- Keep explanation fields so the UI can show why a match was chosen.

## API metadata reality (as of February 20, 2026)

- Spotify Web API track objects include `duration_ms` and `external_ids.isrc` (plus EAN/UPC fields shown in docs).
- Apple Music provides ISRC in song metadata, and Apple Music API has ISRC-based catalog fetch endpoints.
- YouTube Data API is search/video metadata based (`q`, title, description, `contentDetails.duration`) and does not expose a standard ISRC field for videos.

Practical implication: Spotify <-> Apple can often be matched deterministically via ISRC; YouTube usually requires best-candidate scoring from metadata.

## Implementation notes

- Keep service adapters thin and map all responses into `CanonicalTrack`.
- Put normalization/scoring in a pure Swift module with fixtures.
- Store raw source payloads in debug builds for easy mismatch analysis.

## References

- Spotify Web API `Get Track`: https://developer.spotify.com/documentation/web-api/reference/get-track
- Spotify Web API `Get Currently Playing Track`: https://developer.spotify.com/documentation/web-api/reference/get-the-users-currently-playing-track
- Apple Music API `Get Multiple Catalog Songs by ISRC`: https://developer.apple.com/documentation/applemusicapi/get-multiple-catalog-songs-by-isrc
- Apple Music Feed `Song` object (`isrc`, `durationInMillis`): https://developer.apple.com/documentation/applemusicfeed/song
- YouTube Data API `search.list`: https://developers.google.com/youtube/v3/docs/search/list
- YouTube Data API `videos` resource: https://developers.google.com/youtube/v3/docs/videos
- MusicBrainz API (identifier lookups incl. ISRC): https://musicbrainz.org/doc/MusicBrainz_API
- AcoustID Web Service (fingerprint lookup): https://acoustid.org/webservice
