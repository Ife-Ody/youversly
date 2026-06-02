import { describe, expect, it } from "bun:test"
import { fitTextToBox, wrapTextLines } from "./poster-renderer"

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
})
