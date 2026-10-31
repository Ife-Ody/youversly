import CoreGraphics
import SwiftUI

/// A CSS colour literal (`#rrggbb` or `rgba(r, g, b, a)`), kept as text so the
/// templates read identically to `apps/web/lib/poster-renderer.ts`.
nonisolated struct PosterColor: Hashable, Sendable {
  var red: CGFloat
  var green: CGFloat
  var blue: CGFloat
  var alpha: CGFloat

  init(_ css: String) {
    let value = css.trimmed.lowercased()
    if value.hasPrefix("#"), value.count == 7, let hex = UInt32(value.dropFirst(), radix: 16) {
      red = CGFloat((hex >> 16) & 0xff) / 255
      green = CGFloat((hex >> 8) & 0xff) / 255
      blue = CGFloat(hex & 0xff) / 255
      alpha = 1
      return
    }
    if value.hasPrefix("rgba(") || value.hasPrefix("rgb(") {
      let inner = value.drop { $0 != "(" }.dropFirst().prefix { $0 != ")" }
      let parts = inner.split(separator: ",").compactMap { Double($0.trimmed) }
      if parts.count >= 3 {
        red = CGFloat(parts[0]) / 255
        green = CGFloat(parts[1]) / 255
        blue = CGFloat(parts[2]) / 255
        alpha = parts.count > 3 ? CGFloat(parts[3]) : 1
        return
      }
    }
    assertionFailure("Unsupported colour literal: \(css)")
    (red, green, blue, alpha) = (0, 0, 0, 1)
  }

  var cgColor: CGColor {
    CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
  }

  var color: Color {
    Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
  }
}

nonisolated extension Substring {
  var trimmed: String { String(self).trimmed }
}
