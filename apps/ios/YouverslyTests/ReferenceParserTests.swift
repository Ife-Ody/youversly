import Testing

@testable import Youversly

struct ReferenceParserTests {
  @Test func parsesASingleVerse() {
    #expect(
      ReferenceParser.parse("John 1:1")
        == ParsedReference(book: "John", startChapter: 1, endChapter: 1, startVerse: 1, endVerse: 1))
  }

  @Test func parsesAContiguousVerseRange() {
    #expect(
      ReferenceParser.parse("Psalm 42:1-2")
        == ParsedReference(
          book: "Psalms", startChapter: 42, endChapter: 42, startVerse: 1, endVerse: 2))
  }

  @Test(arguments: [
    ("Exo33:15", "Exodus", 33, 15),
    ("1Cor. 6:18", "1 Corinthians", 6, 18),
    ("I Samuel 17:45", "1 Samuel", 17, 45),
    ("song of songs 2:1", "Song of Solomon", 2, 1),
  ])
  func parsesCompactAndAbbreviatedBookNames(
    input: String, book: String, chapter: Int, verse: Int
  ) throws {
    let parsed = try #require(ReferenceParser.parse(input))
    #expect(parsed.book == book)
    #expect(parsed.startChapter == chapter)
    #expect(parsed.startVerse == verse)
  }

  @Test func parsesWholeChaptersAndChapterRanges() {
    #expect(
      ReferenceParser.parse("Psalm 23")
        == ParsedReference(book: "Psalms", startChapter: 23, endChapter: 23))
    #expect(
      ReferenceParser.parse("Genesis 1-2")
        == ParsedReference(book: "Genesis", startChapter: 1, endChapter: 2))
    #expect(
      ReferenceParser.parse("John 3:16-4:2")
        == ParsedReference(
          book: "John", startChapter: 3, endChapter: 4, startVerse: 16, endVerse: 2))
  }

  @Test func returnsNilForInvalidReferences() {
    #expect(ReferenceParser.parse("not a reference") == nil)
    #expect(ReferenceParser.parse("") == nil)
  }

  @Test func formatsCommaSeparatedReferencesCompactly() throws {
    let parsed = try #require(ReferenceParser.parse("John 3:16, 18-19"))
    #expect(parsed.selectedVerses == [16, 18, 19])
    #expect(ReferenceParser.format(parsed) == "John 3:16, 18-19")
  }
}
