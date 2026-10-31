import Foundation
import Testing

@testable import Youversly

struct PassageResolverTests {
  @Test func resolvesASingleVerseFromKJV() async throws {
    let bible = try await BibleLoader.load(.kjv)
    let passage = try PassageResolver.resolve(reference: "John 1:1", in: bible, version: .kjv)

    #expect(passage.displayReference == "John 1:1")
    #expect(passage.verses.count == 1)
    #expect(passage.verses.first?.text.contains("In the beginning") == true)
  }

  @Test func resolvesAVerseRange() async throws {
    let bible = try await BibleLoader.load(.asv)
    let passage = try PassageResolver.resolve(reference: "Psalm 42:1-2", in: bible, version: .asv)

    #expect(passage.displayReference == "Psalms 42:1-2")
    #expect(passage.verses.map(\.verse) == [1, 2])
  }

  @Test func removesPsalmSuperscriptionsAndPilcrows() async throws {
    let bible = try await BibleLoader.load(.kjv)
    let passage = try PassageResolver.resolve(reference: "Psalm 42:1-2", in: bible, version: .kjv)

    #expect(passage.verses.first?.text.hasPrefix("As the hart panteth") == true)
    #expect(passage.verses.allSatisfy { !$0.text.contains("¶") })
  }

  @Test func throwsForMissingPassages() async throws {
    let bible = try await BibleLoader.load(.kjv)
    let error = #expect(throws: PassageResolutionError.self) {
      try PassageResolver.resolve(reference: "John 99:1", in: bible, version: .kjv)
    }
    #expect(error?.message.contains("was not found") == true)
  }

  @Test func allThreeVersionsAreBundled() async throws {
    for version in BibleVersionKey.allCases {
      let bible = try await BibleLoader.load(version)
      #expect(bible.verses.count > 30_000, "\(version) looks incomplete")
    }
  }
}
