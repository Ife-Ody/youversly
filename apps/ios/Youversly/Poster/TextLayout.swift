import CoreGraphics
import Foundation

/// Pure text-fitting logic, ported from `apps/web/lib/poster-renderer.ts`.
/// Measurement is injected so the layout can be tested without a graphics context.
nonisolated enum TextLayout {
  static let defaultVerseFontSize = 78
  static let minVerseFontSize = 24
  static let maxVerseFontSize = 500

  /// Width of `text` when set at `fontSize`.
  typealias Measure = (_ text: String, _ fontSize: Int) -> CGFloat

  struct Fit: Hashable, Sendable {
    var fontSize: Int
    var lineHeight: Int
    var lines: [String]
  }

  static func normalizeVerseFontSize(_ value: Double?) -> Int {
    guard let value, value.isFinite else { return defaultVerseFontSize }
    return min(maxVerseFontSize, max(minVerseFontSize, Int(value.rounded())))
  }

  static func verseFontSize(fromScale value: Double?) -> Int {
    guard let value, value.isFinite else { return defaultVerseFontSize }
    return normalizeVerseFontSize(Double(defaultVerseFontSize) * value / 100)
  }

  static func fitTextToBox(
    _ text: String,
    maxWidth: CGFloat,
    maxHeight: CGFloat,
    maxFontSize: Int,
    minFontSize: Int,
    measure: Measure
  ) -> Fit {
    let quoted = "“\(text)”"
    var fontSize = maxFontSize
    while fontSize >= minFontSize {
      let lineHeight = Int((Double(fontSize) * 1.28).rounded())
      let lines = wrapTextLines(quoted, maxWidth: maxWidth) { measure($0, fontSize) }
      if CGFloat(lines.count * lineHeight) <= maxHeight {
        return Fit(fontSize: fontSize, lineHeight: lineHeight, lines: lines)
      }
      fontSize -= 2
    }

    return Fit(
      fontSize: minFontSize,
      lineHeight: Int((Double(minFontSize) * 1.25).rounded()),
      lines: wrapTextLines(quoted, maxWidth: maxWidth) { measure($0, minFontSize) })
  }

  static func layoutText(
    _ text: String, fontSize: Int, maxWidth: CGFloat, measure: Measure
  ) -> Fit {
    Fit(
      fontSize: fontSize,
      lineHeight: Int((Double(fontSize) * 1.28).rounded()),
      lines: wrapTextLines("“\(text)”", maxWidth: maxWidth) { measure($0, fontSize) })
  }

  static func centeredTextBlockStartY(
    boxY: CGFloat, boxHeight: CGFloat, lineCount: Int, lineHeight: Int, fontSize: Int
  ) -> CGFloat {
    guard lineCount > 0 else { return boxY + boxHeight / 2 }
    let blockHeight = CGFloat(lineCount * lineHeight)
    return boxY + max(0, (boxHeight - blockHeight) / 2) + CGFloat(fontSize)
  }

  static func wrapTextLines(
    _ text: String, maxWidth: CGFloat, measure: (_ text: String) -> CGFloat
  ) -> [String] {
    let words = text.replacing(regex: #"\s+"#, with: " ").trimmed.split(separator: " ")
      .map(String.init)
    var lines: [String] = []
    var currentLine = ""

    for word in words {
      let candidate = currentLine.isEmpty ? word : "\(currentLine) \(word)"
      if measure(candidate) <= maxWidth || currentLine.isEmpty {
        currentLine = candidate
        continue
      }
      lines.append(currentLine)
      currentLine = word
    }

    if !currentLine.isEmpty {
      lines.append(currentLine)
    }
    return lines
  }
}
