# Brand

`logo.svg` is the source of truth for the Youversly mark: a solid black open book
with a thin spine on `#ffa500`. Only those two colours are used.

Generated from it:

- `apps/ios/Youversly/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024)
- `apps/web/app/favicon.ico` (32 + 16)

The web icon routes (`apps/web/app/icon.tsx`, `apple-icon.tsx`, `opengraph-image.tsx`)
and the iOS `BookMark` shape embed the same path data.
