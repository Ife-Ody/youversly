import { describe, expect, it } from "bun:test"
import {
  DEFAULT_VERSE_FONT_SIZE,
  MAX_VERSE_FONT_SIZE,
  MIN_VERSE_FONT_SIZE,
  POSTER_TEMPLATES,
  fitTextToBox,
  getCenteredTextBlockStartY,
  layoutTextAtFontSize,
  normalizeVerseFontSize,
  verseFontSizeFromScale,
  wrapTextLines,
} from "./poster-renderer"

function makeMeasureContext(widthPerCharacter = 9) {
  return {
    font: "",
    measureText(value: string) {
      return { width: value.length * widthPerCharacter } as TextMetrics
    },
  }
}

describe("poster text layout", () => {
  it("wraps text within the requested width", () => {
    const context = makeMeasureContext(10)
    const lines = wrapTextLines(
      context,
      "In the beginning God created the heaven and the earth",
      150
    )

    expect(lines.length).toBeGreaterThan(1)
    expect(lines.every((line) => context.measureText(line).width <= 150)).toBe(
      true
    )
  })

  it("keeps short text near the maximum font size", () => {
    const context = makeMeasureContext(8)
    const fit = fitTextToBox(context, "Jesus wept.", {
      maxWidth: 500,
      maxHeight: 240,
      maxFontSize: 72,
      minFontSize: 32,
      fontFamily: "Georgia",
      fontWeight: "400",
    })

    expect(fit.fontSize).toBe(72)
    expect(fit.lines).toHaveLength(1)
  })

  it("reduces type size for longer passages", () => {
    const context = makeMeasureContext(9)
    const fit = fitTextToBox(
      context,
      "As the hart panteth after the water brooks, so panteth my soul after thee, O God. My soul thirsteth for God, for the living God.",
      {
        maxWidth: 420,
        maxHeight: 170,
        maxFontSize: 70,
        minFontSize: 28,
        fontFamily: "Georgia",
        fontWeight: "400",
      }
    )

    expect(fit.fontSize).toBeLessThan(70)
    expect(fit.lines.length * fit.lineHeight).toBeLessThanOrEqual(170)
  })

  it("uses the requested manual font size without fitting it down", () => {
    const context = makeMeasureContext(9)
    const fit = layoutTextAtFontSize(
      context,
      "As the hart panteth after the water brooks, so panteth my soul after thee, O God. My soul thirsteth for God, for the living God.",
      {
        maxWidth: 420,
        fontSize: 140,
        fontFamily: "Georgia",
        fontWeight: "400",
      }
    )

    expect(fit.fontSize).toBe(140)
    expect(fit.lines.length * fit.lineHeight).toBeGreaterThan(170)
  })

  it("keeps user font-size overrides within the supported px range", () => {
    expect(normalizeVerseFontSize(12)).toBe(MIN_VERSE_FONT_SIZE)
    expect(normalizeVerseFontSize(425.4)).toBe(425)
    expect(normalizeVerseFontSize(640)).toBe(MAX_VERSE_FONT_SIZE)
    expect(normalizeVerseFontSize(Number.NaN)).toBe(DEFAULT_VERSE_FONT_SIZE)
  })

  it("migrates legacy scale values to pixel font sizes", () => {
    expect(verseFontSizeFromScale(100)).toBe(DEFAULT_VERSE_FONT_SIZE)
    expect(verseFontSizeFromScale(500)).toBe(390)
  })

  it("centers fitted verse text inside its text box", () => {
    expect(
      getCenteredTextBlockStartY({
        boxY: 100,
        boxHeight: 300,
        lineCount: 2,
        lineHeight: 48,
        fontSize: 40,
      })
    ).toBe(242)
  })

  it("keeps the centered start inside the box when text fills the space", () => {
    expect(
      getCenteredTextBlockStartY({
        boxY: 100,
        boxHeight: 96,
        lineCount: 2,
        lineHeight: 48,
        fontSize: 40,
      })
    ).toBe(140)
  })

  it("keeps template choices compact while offering layered backgrounds", () => {
    const mistTemplate = POSTER_TEMPLATES.find(
      (template) => template.id === "mist"
    )

    expect(POSTER_TEMPLATES).toHaveLength(5)
    expect(
      mistTemplate?.background.some((layer) => layer.type === "radial")
    ).toBe(true)
    expect(
      mistTemplate?.background.some((layer) => layer.type === "linear")
    ).toBe(true)
  })
})
