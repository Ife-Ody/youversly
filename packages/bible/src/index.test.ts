import { describe, expect, it } from "bun:test"
import { formatPassageReference, parseBibleReference, resolvePassage } from "."

describe("parseBibleReference", () => {
  it("parses a single verse", () => {
    expect(parseBibleReference("John 1:1")).toEqual({
      book: "John",
      startChapter: 1,
      endChapter: 1,
      startVerse: 1,
      endVerse: 1,
    })
  })

  it("parses a contiguous verse range", () => {
    expect(parseBibleReference("Psalm 42:1-2")).toEqual({
      book: "Psalms",
      startChapter: 42,
      endChapter: 42,
      startVerse: 1,
      endVerse: 2,
    })
  })

  it("parses compact and abbreviated book names", () => {
    expect(parseBibleReference("Exo33:15")).toMatchObject({
      book: "Exodus",
      startChapter: 33,
      startVerse: 15,
    })
    expect(parseBibleReference("1Cor. 6:18")).toMatchObject({
      book: "1 Corinthians",
      startChapter: 6,
      startVerse: 18,
    })
  })

  it("returns null for invalid references", () => {
    expect(parseBibleReference("not a reference")).toBeNull()
  })
})

describe("resolvePassage", () => {
  it("resolves a single verse from KJV", () => {
    const passage = resolvePassage({ reference: "John 1:1", version: "kjv" })

    expect(passage.displayReference).toBe("John 1:1")
    expect(passage.verses).toHaveLength(1)
    expect(passage.verses[0]?.text).toContain("In the beginning")
  })

  it("resolves a verse range", () => {
    const passage = resolvePassage({
      reference: "Psalm 42:1-2",
      version: "asv",
    })

    expect(passage.displayReference).toBe("Psalms 42:1-2")
    expect(passage.verses.map((verse) => verse.verse)).toEqual([1, 2])
  })

  it("removes Psalm superscriptions from share text", () => {
    const passage = resolvePassage({
      reference: "Psalm 42:1-2",
      version: "kjv",
    })

    expect(passage.verses[0]?.text).toStartWith("As the hart panteth")
  })

  it("formats comma-separated references compactly", () => {
    const parsed = parseBibleReference("John 3:16, 18-19")

    expect(parsed && formatPassageReference(parsed)).toBe("John 3:16, 18-19")
  })

  it("throws for missing passages", () => {
    expect(() => resolvePassage({ reference: "John 99:1" })).toThrow(
      "was not found"
    )
  })
})
