import CoreGraphics
import Foundation
import Testing

@testable import Youversly

/// Fixed-width measurement, like the web tests' fake canvas context.
private func monospaced(_ widthPerCharacter: CGFloat) -> TextLayout.Measure {
  { text, _ in CGFloat(text.count) * widthPerCharacter }
}

struct TextLayoutTests {
  @Test func wrapsTextWithinTheRequestedWidth() {
    let measure = monospaced(10)
    let lines = TextLayout.wrapTextLines(
      "In the beginning God created the heaven and the earth", maxWidth: 150
    ) { measure($0, 0) }

    #expect(lines.count > 1)
    #expect(lines.allSatisfy { measure($0, 0) <= 150 })
  }

  @Test func keepsShortTextNearTheMaximumFontSize() {
    let fit = TextLayout.fitTextToBox(
      "Jesus wept.", maxWidth: 500, maxHeight: 240, maxFontSize: 72, minFontSize: 32,
      measure: monospaced(8))

    #expect(fit.fontSize == 72)
    #expect(fit.lines.count == 1)
  }

  @Test func reducesTypeSizeForLongerPassages() {
    let fit = TextLayout.fitTextToBox(
      "As the hart panteth after the water brooks, so panteth my soul after thee, O God. My soul thirsteth for God, for the living God.",
      maxWidth: 420, maxHeight: 170, maxFontSize: 70, minFontSize: 28,
      measure: monospaced(9))

    #expect(fit.fontSize < 70)
    #expect(CGFloat(fit.lines.count * fit.lineHeight) <= 170)
  }

  @Test func usesTheRequestedManualFontSizeWithoutFittingItDown() {
    let fit = TextLayout.layoutText(
      "As the hart panteth after the water brooks, so panteth my soul after thee, O God.",
      fontSize: 140, maxWidth: 420, measure: monospaced(9))

    #expect(fit.fontSize == 140)
    #expect(fit.lineHeight == 179)
    #expect(fit.lines.count > 1)
  }

  @Test(arguments: [
    (nil, 78), (10.0, 24), (900.0, 500), (77.6, 78), (Double.nan, 78),
  ])
  func normalizesVerseFontSizes(input: Double?, expected: Int) {
    #expect(TextLayout.normalizeVerseFontSize(input) == expected)
  }

  @Test func convertsLegacyScaleToFontSize() {
    #expect(TextLayout.verseFontSize(fromScale: 100) == 78)
    #expect(TextLayout.verseFontSize(fromScale: 50) == 39)
    #expect(TextLayout.verseFontSize(fromScale: nil) == 78)
  }

  @Test func centersTheTextBlockInsideItsBox() {
    let startY = TextLayout.centeredTextBlockStartY(
      boxY: 100, boxHeight: 400, lineCount: 2, lineHeight: 100, fontSize: 80)
    #expect(startY == 280)
    #expect(
      TextLayout.centeredTextBlockStartY(
        boxY: 100, boxHeight: 400, lineCount: 0, lineHeight: 100, fontSize: 80) == 300)
  }
}

struct EditorFormattingTests {
  @Test(arguments: [
    (1, "1st"), (2, "2nd"), (3, "3rd"), (4, "4th"), (11, "11th"), (12, "12th"), (13, "13th"),
    (21, "21st"), (22, "22nd"), (23, "23rd"), (31, "31st"),
  ])
  func posterDateOrdinals(day: Int, prefix: String) throws {
    var components = DateComponents(year: 2026, month: 10, day: day)
    components.hour = 12
    let date = try #require(Calendar(identifier: .gregorian).date(from: components))
    #expect(EditorModel.posterDate(date) == "\(prefix) October 2026")
  }

  @Test func slugifiesReferences() {
    #expect(EditorModel.slugify("Psalms 42:1-2") == "psalms-42-1-2")
    #expect(EditorModel.slugify("John 3:16, 18-19") == "john-3-16-18-19")
  }
}
