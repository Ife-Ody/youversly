import Foundation
import Observation

/// Decodes a bundled Bible off the main thread. Pure, so it can run anywhere.
nonisolated enum BibleLoader {
  @concurrent
  static func load(_ key: BibleVersionKey, bundle: Bundle = .main) async throws -> BibleVersion {
    guard let url = bundle.url(forResource: key.rawValue, withExtension: "json") else {
      throw PassageResolutionError(message: "Bible version \"\(key.rawValue)\" is not available.")
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(BibleVersion.self, from: data)
  }
}

/// Port of `resolvePassage` and its helpers in `packages/bible/src/index.ts`.
nonisolated enum PassageResolver {
  static func resolve(
    reference: String, in bible: BibleVersion, version: BibleVersionKey
  ) throws(PassageResolutionError) -> ResolvedPassage {
    guard let parsed = ReferenceParser.parse(reference) else {
      throw PassageResolutionError(
        message: "Enter a Bible reference like John 3:16 or Psalm 42:1-2.")
    }

    let verses = collectVerses(bible.verses, reference: parsed).map(cleanVerse)
    guard !verses.isEmpty else {
      throw PassageResolutionError(
        message: "\(ReferenceParser.format(parsed)) was not found in \(version.label).")
    }

    let shortname = bible.metadata.shortname
    return ResolvedPassage(
      version: version,
      versionName: shortname.isEmpty ? version.label : shortname,
      reference: parsed,
      displayReference: ReferenceParser.format(parsed),
      verses: verses)
  }

  static func collectVerses(_ allVerses: [BibleVerse], reference: ParsedReference) -> [BibleVerse] {
    let selected = Set(reference.selectedVerses ?? [])

    return allVerses.filter { verse in
      guard verse.bookName == reference.book else { return false }
      guard verse.chapter >= reference.startChapter, verse.chapter <= reference.endChapter else {
        return false
      }
      if !selected.isEmpty {
        return verse.chapter == reference.startChapter && selected.contains(verse.verse)
      }
      guard let startVerse = reference.startVerse, let endVerse = reference.endVerse else {
        return true
      }
      if reference.startChapter == reference.endChapter {
        return verse.verse >= startVerse && verse.verse <= endVerse
      }
      if verse.chapter == reference.startChapter {
        return verse.verse >= startVerse
      }
      if verse.chapter == reference.endChapter {
        return verse.verse <= endVerse
      }
      return true
    }
  }

  static func cleanVerse(_ verse: BibleVerse) -> BibleVerse {
    var cleaned = verse
    cleaned.text = cleanVerseText(verse)
    return cleaned
  }

  static func cleanVerseText(_ verse: BibleVerse) -> String {
    let text = verse.text.replacing(regex: #"^¶\s*"#, with: "").trimmed
    guard verse.bookName == "Psalms", verse.verse == 1 else { return text }
    return text.replacing(
      regex:
        #"^(?:To the chief Musician|A Psalm|Maschil|Michtam|A Song|Song|A Prayer|Prayer|Praise|Of David|For the sons)[^.]*\.\s+"#,
      with: "", caseInsensitive: true)
  }
}

/// Main-actor cache of decoded Bibles, one per version.
@Observable
final class BibleLibrary {
  private var loaded: [BibleVersionKey: BibleVersion] = [:]

  func version(_ key: BibleVersionKey) async throws -> BibleVersion {
    if let cached = loaded[key] { return cached }
    let bible = try await BibleLoader.load(key)
    // Another task may have finished first while we were suspended; either copy is identical.
    loaded[key] = bible
    return bible
  }

  func resolve(reference: String, version: BibleVersionKey) async throws -> ResolvedPassage {
    let bible = try await self.version(version)
    return try PassageResolver.resolve(reference: reference, in: bible, version: version)
  }
}
