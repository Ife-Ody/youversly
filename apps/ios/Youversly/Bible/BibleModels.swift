import Foundation

/// Mirrors `packages/bible/src/types.ts`.
nonisolated enum BibleVersionKey: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
  case kjv
  case asv
  case net

  var id: Self { self }
  var label: String { rawValue.uppercased() }
}

nonisolated struct BibleVerse: Codable, Hashable, Sendable {
  var bookName: String
  var chapter: Int
  var verse: Int
  var text: String

  enum CodingKeys: String, CodingKey {
    case bookName = "book_name"
    case chapter
    case verse
    case text
  }
}

nonisolated struct BibleVersion: Decodable, Sendable {
  struct Metadata: Decodable, Sendable {
    var name: String
    var shortname: String
  }

  var metadata: Metadata
  var verses: [BibleVerse]
}

nonisolated struct ParsedReference: Hashable, Sendable {
  var book: String
  var startChapter: Int
  var endChapter: Int
  var startVerse: Int?
  var endVerse: Int?
  var selectedVerses: [Int]?
}

nonisolated struct ResolvedPassage: Hashable, Sendable {
  var version: BibleVersionKey
  var versionName: String
  var reference: ParsedReference
  var displayReference: String
  var verses: [BibleVerse]
}

nonisolated struct PassageResolutionError: Error, LocalizedError, Hashable, Sendable {
  var message: String
  var errorDescription: String? { message }
}
