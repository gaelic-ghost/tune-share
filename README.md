# tune-share

macOS menu bar app for turning a currently playing song into shareable links across streaming services.

## Current Status

- Spotify settings and OAuth connection flow are implemented.
- Spotify "now playing" fetch is implemented.
- Canonical track models + matching/scoring logic are implemented.
- Matcher unit tests are in place.
- Apple Music and YouTube adapters are still placeholders.

## Run The App

1. Open `/Users/galew/Workspace/projects/tune-share/tune-share.xcodeproj` in Xcode.
2. Run the `tune-share` scheme on macOS.
3. Open app Settings to configure Spotify credentials.

## Spotify Setup

1. Create a Spotify app in the [Spotify Developer Dashboard](https://developer.spotify.com/dashboard).
2. Add this redirect URI exactly: `tuneshare://spotify-callback`
3. In app Settings, enter your Spotify Client ID and Redirect URI.
4. Click `Save & Connect` (or `Connect Spotify`) and complete browser auth.
5. Use `Test Now Playing` to verify token/auth + playback lookup.

## Tests

Run tests from terminal:

```bash
xcodebuild test -project tune-share.xcodeproj -scheme tune-share -destination 'platform=macOS' -derivedDataPath /tmp/tune-share-derived CODE_SIGNING_ALLOWED=NO
```

Current automated coverage is focused on matching/normalization behavior (`/Users/galew/Workspace/projects/tune-share/tune-shareTests/tune_shareTests.swift`).

## Next Steps

- Add automated tests for `SpotifyController` and `SpotifySettingsViewModel`.
- Implement Apple Music adapter.
- Implement YouTube adapter.
- Connect matching output to menu-bar link generation.
