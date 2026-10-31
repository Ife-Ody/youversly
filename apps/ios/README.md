# Youversly for iOS

Native SwiftUI port of the web verse-poster studio in `apps/web`.

- `Youversly/Bible` — reference parser and passage resolver, ported from `packages/bible`.
  The three Bible JSON files are referenced in place from `packages/bible/src/en`, so
  both apps share one copy.
- `Youversly/Poster` — Core Graphics port of `apps/web/lib/poster-renderer.ts`
  (templates, text fitting, drawing).
- `Youversly/Editor` — the editor screen and its `@Observable` model. Settings persist
  in `UserDefaults` under the same key the web app uses in `localStorage`.

## Building

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen)
and is not committed.

```bash
brew install xcodegen
cd apps/ios && xcodegen generate && open Youversly.xcodeproj
```

Run the unit tests from Xcode, or:

```bash
xcodebuild test -project Youversly.xcodeproj -scheme Youversly -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max'
```

## Fonts

The web app renders with Merriweather and Dancing Script (Google Fonts). iOS does not
ship them, so `PosterFont` uses the system fallbacks the web declares: Georgia for verse
text, Snell Roundhand for the reference, Times New Roman for the title and signature.
To match the web pixel for pixel, add the OFL font files to the app target, list them under
`UIAppFonts`, and change the names in `PosterFont`.
