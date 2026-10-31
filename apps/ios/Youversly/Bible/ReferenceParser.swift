import Foundation

/// Port of the reference parsing in `packages/bible/src/index.ts`.
nonisolated enum ReferenceParser {
  static func parse(_ reference: String) -> ParsedReference? {
    let normalized = normalizeReferenceInput(reference)
    guard
      let groups = normalized.firstMatch(
        of: #"^((?:[123]\s*)?[a-z]+(?:\s+(?:of|and|the|[a-z]+))*)\s+(.+)$"#,
        caseInsensitive: true
      ),
      let bookGroup = groups[1], let passageGroup = groups[2]
    else {
      return nil
    }

    let book = normalizeBookName(bookGroup)
    let passage = passageGroup.trimmed

    if passage.contains(",") {
      return parseCommaSeparatedPassage(book: book, passage: passage)
    }
    if passage.containsRangeSeparator {
      return parseRangedPassage(book: book, passage: passage)
    }
    if passage.contains(":") {
      let parts = passage.components(separatedBy: ":")
      guard
        let chapter = parsePositiveInteger(parts[0]),
        let verse = parsePositiveInteger(parts.count > 1 ? parts[1] : nil)
      else {
        return nil
      }
      return ParsedReference(
        book: book, startChapter: chapter, endChapter: chapter,
        startVerse: verse, endVerse: verse)
    }

    guard let chapter = parsePositiveInteger(passage) else { return nil }
    return ParsedReference(book: book, startChapter: chapter, endChapter: chapter)
  }

  static func format(_ reference: ParsedReference) -> String {
    let chapter =
      reference.startChapter == reference.endChapter
      ? "\(reference.startChapter)"
      : "\(reference.startChapter)-\(reference.endChapter)"

    guard let startVerse = reference.startVerse, let endVerse = reference.endVerse else {
      return "\(reference.book) \(chapter)"
    }
    if reference.startChapter != reference.endChapter {
      return
        "\(reference.book) \(reference.startChapter):\(startVerse)-\(reference.endChapter):\(endVerse)"
    }
    if let selected = reference.selectedVerses, !selected.isEmpty {
      return "\(reference.book) \(reference.startChapter):\(formatVerseGroups(selected))"
    }
    if startVerse == endVerse {
      return "\(reference.book) \(reference.startChapter):\(startVerse)"
    }
    return "\(reference.book) \(reference.startChapter):\(startVerse)-\(endVerse)"
  }

  static func normalizeBookName(_ bookName: String) -> String {
    let key = normalizeBookLookupKey(bookName)
    return bookAliases[key] ?? key.titleCased
  }

  // MARK: - Passage shapes

  private static func parseCommaSeparatedPassage(book: String, passage: String) -> ParsedReference? {
    let parts = passage.components(separatedBy: ",").map(\.trimmed)
    guard let first = parts.first, first.contains(":") else { return nil }

    let firstParts = first.components(separatedBy: ":")
    guard
      let chapter = parsePositiveInteger(firstParts[0]),
      firstParts.count > 1, !firstParts[1].isEmpty
    else {
      return nil
    }

    var selectedVerses = expandVersePart(firstParts[1])
    for part in parts.dropFirst() {
      let versePart = part.contains(":") ? (part.components(separatedBy: ":")[safe: 1] ?? "") : part
      selectedVerses.append(contentsOf: expandVersePart(versePart))
    }

    guard let minVerse = selectedVerses.min(), let maxVerse = selectedVerses.max() else {
      return nil
    }
    return ParsedReference(
      book: book, startChapter: chapter, endChapter: chapter,
      startVerse: minVerse, endVerse: maxVerse, selectedVerses: selectedVerses)
  }

  private static func parseRangedPassage(book: String, passage: String) -> ParsedReference? {
    let pieces = passage.splitOnRangeSeparator.map(\.trimmed)
    guard pieces.count >= 2, let start = pieces[safe: 0], let end = pieces[safe: 1],
      !start.isEmpty, !end.isEmpty
    else {
      return nil
    }

    if start.contains(":") {
      let startParts = start.components(separatedBy: ":")
      guard
        let startChapter = parsePositiveInteger(startParts[0]),
        let startVerse = parsePositiveInteger(startParts[safe: 1])
      else {
        return nil
      }

      if end.contains(":") {
        let endParts = end.components(separatedBy: ":")
        guard
          let endChapter = parsePositiveInteger(endParts[0]),
          let endVerse = parsePositiveInteger(endParts[safe: 1])
        else {
          return nil
        }
        return ParsedReference(
          book: book, startChapter: startChapter, endChapter: endChapter,
          startVerse: startVerse, endVerse: endVerse)
      }

      guard let endVerse = parsePositiveInteger(end) else { return nil }
      return ParsedReference(
        book: book, startChapter: startChapter, endChapter: startChapter,
        startVerse: startVerse, endVerse: endVerse)
    }

    guard
      let startChapter = parsePositiveInteger(start),
      let endChapter = parsePositiveInteger(end)
    else {
      return nil
    }
    return ParsedReference(book: book, startChapter: startChapter, endChapter: endChapter)
  }

  private static func expandVersePart(_ value: String) -> [Int] {
    let normalized = value.trimmed
    if normalized.containsRangeSeparator {
      let pieces = normalized.splitOnRangeSeparator
      guard
        let start = parsePositiveInteger(pieces[safe: 0]),
        let end = parsePositiveInteger(pieces[safe: 1]),
        end >= start
      else {
        return []
      }
      return Array(start...end)
    }
    return parsePositiveInteger(normalized).map { [$0] } ?? []
  }

  // MARK: - Normalization

  private static func normalizeReferenceInput(_ reference: String) -> String {
    reference
      .precomposedStringWithCompatibilityMapping
      .trimmed
      .replacing(regex: #"\s+"#, with: " ")
      .replacing(regex: #"([A-Za-z])\.\s*(\d)"#, with: "$1 $2")
      .replacing(
        regex: #"^((?:\d+\s*)?[A-Za-z]+(?:\s+(?:of|and|the|[A-Za-z]+))*)(\d)"#,
        with: "$1 $2", caseInsensitive: true)
      .replacing(regex: #"(\d)\s*;\s*(\d)"#, with: "$1:$2")
  }

  static func normalizeBookLookupKey(_ book: String) -> String {
    book
      .precomposedStringWithCompatibilityMapping
      .trimmed
      .replacing(regex: #"^(first|1st|i)\b\.?"#, with: "1", caseInsensitive: true)
      .replacing(regex: #"^(second|2nd|ii)\b\.?"#, with: "2", caseInsensitive: true)
      .replacing(regex: #"^(third|3rd|iii)\b\.?"#, with: "3", caseInsensitive: true)
      .replacing(regex: #"[.]"#, with: " ")
      .replacing(regex: #"^([123])([a-z])"#, with: "$1 $2", caseInsensitive: true)
      .replacing(regex: #"\s+"#, with: " ")
      .lowercased()
  }

  private static func parsePositiveInteger(_ value: String?) -> Int? {
    guard let value, let parsed = Int(value.trimmed), parsed > 0 else { return nil }
    return parsed
  }

  private static func formatVerseGroups(_ verses: [Int]) -> String {
    let unique = Array(Set(verses)).sorted()
    guard var start = unique.first else { return "" }
    var previous = start
    var groups: [String] = []

    func flush() {
      groups.append(start == previous ? "\(start)" : "\(start)-\(previous)")
    }

    for verse in unique.dropFirst() {
      if verse == previous + 1 {
        previous = verse
        continue
      }
      flush()
      start = verse
      previous = verse
    }
    flush()
    return groups.joined(separator: ", ")
  }

  // MARK: - Book aliases

  static let bookAliases: [String: String] = {
    var map: [String: String] = [:]
    func add(_ canonical: String, _ aliases: [String]) {
      for alias in [canonical] + aliases {
        map[normalizeBookLookupKey(alias)] = canonical
      }
    }

    add("Genesis", ["gen", "ge", "gn"])
    add("Exodus", ["exo", "exod", "ex"])
    add("Leviticus", ["lev", "levit", "lv"])
    add("Numbers", ["num", "numb", "nu", "nm", "nmb"])
    add("Deuteronomy", ["deut", "deu", "dt"])
    add("Joshua", ["josh", "jos", "jsh"])
    add("Judges", ["judg", "jdg", "jdgs", "jug"])
    add("Ruth", ["rth", "rut", "ru"])
    add("1 Samuel", ["1 sam", "1sam", "1 sa", "1sa", "first samuel"])
    add("2 Samuel", ["2 sam", "2sam", "2 sa", "2sa", "second samuel"])
    add("1 Kings", ["1 kings", "1kings", "1 kgs", "1kgs", "1 ki", "1ki"])
    add("2 Kings", ["2 kings", "2kings", "2 kgs", "2kgs", "2 ki", "2ki"])
    add("1 Chronicles", ["1 chronicles", "1chronicles", "1 chr", "1chr", "1 chro", "1chro"])
    add("2 Chronicles", ["2 chronicles", "2chronicles", "2 chr", "2chr", "2 chro", "2chro"])
    add("Ezra", ["ezr"])
    add("Nehemiah", ["neh", "nehem"])
    add("Esther", ["esth", "est"])
    add("Job", ["jb"])
    add("Psalms", ["ps", "psa", "psalm", "psalms", "psm", "pss"])
    add("Proverbs", ["prov", "pro", "prv", "pr"])
    add("Ecclesiastes", ["eccl", "ecc", "eccles"])
    add("Song of Solomon", ["song", "songs", "song of songs", "sos", "canticles"])
    add("Isaiah", ["isa", "isai"])
    add("Jeremiah", ["jer", "jr", "jerem"])
    add("Lamentations", ["lam", "lamentation"])
    add("Ezekiel", ["ezek", "ezk", "eze"])
    add("Daniel", ["dan", "dn"])
    add("Hosea", ["hos"])
    add("Joel", ["joe", "jl"])
    add("Amos", ["amo"])
    add("Obadiah", ["obad", "ob"])
    add("Jonah", ["jon", "jnh"])
    add("Micah", ["mic"])
    add("Nahum", ["nah"])
    add("Habakkuk", ["hab", "hb"])
    add("Zephaniah", ["zeph", "zep"])
    add("Haggai", ["hag"])
    add("Zechariah", ["zech", "zec"])
    add("Malachi", ["mal"])
    add("Matthew", ["matt", "mat", "mt"])
    add("Mark", ["mrk", "mar", "mk"])
    add("Luke", ["luk", "lk"])
    add("John", ["jhn", "joh", "jn"])
    add("Acts", ["act", "ac"])
    add("Romans", ["rom", "rm"])
    add("1 Corinthians", ["1 cor", "1cor", "1 co", "1co", "1corinthians"])
    add("2 Corinthians", ["2 cor", "2cor", "2 co", "2co", "2corinthians"])
    add("Galatians", ["gal", "galat"])
    add("Ephesians", ["eph", "ephes"])
    add("Philippians", ["phil", "php", "phl"])
    add("Colossians", ["col", "colos"])
    add("1 Thessalonians", ["1 thess", "1thess", "1 thes", "1thes", "1 th"])
    add("2 Thessalonians", ["2 thess", "2thess", "2 thes", "2thes", "2 th"])
    add("1 Timothy", ["1 tim", "1tim", "1 ti", "1ti"])
    add("2 Timothy", ["2 tim", "2tim", "2 ti", "2ti"])
    add("Titus", ["tit", "tts"])
    add("Philemon", ["phm", "philem"])
    add("Hebrews", ["heb", "hebr"])
    add("James", ["jam", "jas", "jms"])
    add("1 Peter", ["1 pet", "1pet", "1 pe", "1pe", "1 pt", "1pt"])
    add("2 Peter", ["2 pet", "2pet", "2 pe", "2pe", "2 pt", "2pt"])
    add("1 John", ["1 john", "1john", "1 jn", "1jn", "1 jhn", "1jhn"])
    add("2 John", ["2 john", "2john", "2 jn", "2jn", "2 jhn", "2jhn"])
    add("3 John", ["3 john", "3john", "3 jn", "3jn", "3 jhn", "3jhn"])
    add("Jude", ["jud", "jd"])
    add("Revelation", ["rev", "revelations", "rv"])

    return map
  }()
}

// MARK: - String helpers

nonisolated extension String {
  var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

  var titleCased: String {
    split(separator: " ")
      .map { $0.prefix(1).uppercased() + $0.dropFirst() }
      .joined(separator: " ")
  }

  /// Matches the JS `/[-–—]/` range separator.
  var containsRangeSeparator: Bool {
    contains { $0 == "-" || $0 == "–" || $0 == "—" }
  }

  var splitOnRangeSeparator: [String] {
    split(omittingEmptySubsequences: false) { $0 == "-" || $0 == "–" || $0 == "—" }
      .map(String.init)
  }

  func replacing(regex pattern: String, with template: String, caseInsensitive: Bool = false)
    -> String
  {
    guard
      let expression = try? NSRegularExpression(
        pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : [])
    else {
      return self
    }
    let range = NSRange(startIndex..., in: self)
    return expression.stringByReplacingMatches(
      in: self, range: range, withTemplate: template)
  }

  /// Returns the capture groups (index 0 is the whole match) of the first match, or nil.
  func firstMatch(of pattern: String, caseInsensitive: Bool = false) -> [String?]? {
    guard
      let expression = try? NSRegularExpression(
        pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : []),
      let match = expression.firstMatch(in: self, range: NSRange(startIndex..., in: self))
    else {
      return nil
    }
    return (0..<match.numberOfRanges).map { index in
      Range(match.range(at: index), in: self).map { String(self[$0]) }
    }
  }
}

nonisolated extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
