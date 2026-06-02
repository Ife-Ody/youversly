import { versions } from "./en"
import type {
  BibleVerse,
  ParsedReference,
  ResolvedPassage,
  ResolvePassageInput,
} from "./types"

export type {
  BibleVerse,
  BibleVersion,
  BibleVersionKey,
  ParsedReference,
  ResolvedPassage,
  ResolvePassageInput,
} from "./types"

export { bibleVersionOptions, versions } from "./en"

const BOOK_ALIASES: Record<string, string> = createBookAliasMap()

export class PassageResolutionError extends Error {
  constructor(message: string) {
    super(message)
    this.name = "PassageResolutionError"
  }
}

export function parseBibleReference(reference: string): ParsedReference | null {
  const normalized = normalizeReferenceInput(reference)
  const match = normalized.match(
    /^((?:[123]\s*)?[a-z]+(?:\s+(?:of|and|the|[a-z]+))*)\s+(.+)$/i
  )

  if (!match?.[1] || !match[2]) {
    return null
  }

  const book = normalizeBookName(match[1])
  const passage = match[2].trim()

  if (passage.includes(",")) {
    return parseCommaSeparatedPassage(book, passage)
  }

  if (/[-–—]/.test(passage)) {
    return parseRangedPassage(book, passage)
  }

  if (passage.includes(":")) {
    const [chapterValue, verseValue] = passage.split(":")
    const chapter = parsePositiveInteger(chapterValue)
    const verse = parsePositiveInteger(verseValue)

    if (!chapter || !verse) {
      return null
    }

    return {
      book,
      startChapter: chapter,
      endChapter: chapter,
      startVerse: verse,
      endVerse: verse,
    }
  }

  const chapter = parsePositiveInteger(passage)
  if (!chapter) {
    return null
  }

  return {
    book,
    startChapter: chapter,
    endChapter: chapter,
  }
}

export function resolvePassage({
  reference,
  version = "kjv",
}: ResolvePassageInput): ResolvedPassage {
  const bible = versions[version]
  if (!bible) {
    throw new PassageResolutionError(
      `Bible version "${version}" is not available.`
    )
  }

  const parsed = parseBibleReference(reference)
  if (!parsed) {
    throw new PassageResolutionError(
      "Enter a Bible reference like John 3:16 or Psalm 42:1-2."
    )
  }

  const verses = collectVerses(bible.verses, parsed).map(cleanVerse)

  if (verses.length === 0) {
    throw new PassageResolutionError(
      `${formatPassageReference(parsed)} was not found in ${version.toUpperCase()}.`
    )
  }

  return {
    version,
    versionName: bible.metadata.shortname || version.toUpperCase(),
    reference: parsed,
    displayReference: formatPassageReference(parsed),
    verses,
  }
}

export function formatPassageReference(reference: ParsedReference): string {
  const chapter =
    reference.startChapter === reference.endChapter
      ? `${reference.startChapter}`
      : `${reference.startChapter}-${reference.endChapter}`

  if (reference.startVerse === undefined || reference.endVerse === undefined) {
    return `${reference.book} ${chapter}`
  }

  if (reference.startChapter !== reference.endChapter) {
    return `${reference.book} ${reference.startChapter}:${reference.startVerse}-${reference.endChapter}:${reference.endVerse}`
  }

  if (reference.selectedVerses?.length) {
    return `${reference.book} ${reference.startChapter}:${formatVerseGroups(reference.selectedVerses)}`
  }

  if (reference.startVerse === reference.endVerse) {
    return `${reference.book} ${reference.startChapter}:${reference.startVerse}`
  }

  return `${reference.book} ${reference.startChapter}:${reference.startVerse}-${reference.endVerse}`
}

export function normalizeBookName(bookName: string): string {
  const key = normalizeBookLookupKey(bookName)
  return BOOK_ALIASES[key] ?? toTitleCase(key)
}

function collectVerses(
  allVerses: BibleVerse[],
  reference: ParsedReference
): BibleVerse[] {
  const selected = new Set(reference.selectedVerses ?? [])

  return allVerses.filter((verse) => {
    if (verse.book_name !== reference.book) {
      return false
    }

    if (
      verse.chapter < reference.startChapter ||
      verse.chapter > reference.endChapter
    ) {
      return false
    }

    if (reference.selectedVerses?.length) {
      return (
        verse.chapter === reference.startChapter && selected.has(verse.verse)
      )
    }

    if (
      reference.startVerse === undefined ||
      reference.endVerse === undefined
    ) {
      return true
    }

    if (reference.startChapter === reference.endChapter) {
      return (
        verse.verse >= reference.startVerse && verse.verse <= reference.endVerse
      )
    }

    if (verse.chapter === reference.startChapter) {
      return verse.verse >= reference.startVerse
    }

    if (verse.chapter === reference.endChapter) {
      return verse.verse <= reference.endVerse
    }

    return true
  })
}

function cleanVerse(verse: BibleVerse): BibleVerse {
  return {
    ...verse,
    text: cleanVerseText(verse),
  }
}

function cleanVerseText(verse: BibleVerse): string {
  const text = verse.text.replace(/^¶\s*/, "").trim()

  if (verse.book_name !== "Psalms" || verse.verse !== 1) {
    return text
  }

  return text.replace(
    /^(?:To the chief Musician|A Psalm|Maschil|Michtam|A Song|Song|A Prayer|Prayer|Praise|Of David|For the sons)[^.]*\.\s+/i,
    ""
  )
}

function parseCommaSeparatedPassage(
  book: string,
  passage: string
): ParsedReference | null {
  const parts = passage.split(",").map((part) => part.trim())
  const first = parts[0]

  if (!first?.includes(":")) {
    return null
  }

  const [chapterValue, firstVerseValue] = first.split(":")
  const chapter = parsePositiveInteger(chapterValue)
  if (!chapter || !firstVerseValue) {
    return null
  }

  const selectedVerses = expandVersePart(firstVerseValue)
  for (const part of parts.slice(1)) {
    selectedVerses.push(
      ...expandVersePart(part.includes(":") ? (part.split(":")[1] ?? "") : part)
    )
  }

  if (selectedVerses.length === 0) {
    return null
  }

  return {
    book,
    startChapter: chapter,
    endChapter: chapter,
    startVerse: Math.min(...selectedVerses),
    endVerse: Math.max(...selectedVerses),
    selectedVerses,
  }
}

function parseRangedPassage(
  book: string,
  passage: string
): ParsedReference | null {
  const [start, end] = passage.split(/[-–—]/).map((part) => part.trim())
  if (!start || !end) {
    return null
  }

  if (start.includes(":")) {
    const [startChapterValue, startVerseValue] = start.split(":")
    const startChapter = parsePositiveInteger(startChapterValue)
    const startVerse = parsePositiveInteger(startVerseValue)
    if (!startChapter || !startVerse) {
      return null
    }

    if (end.includes(":")) {
      const [endChapterValue, endVerseValue] = end.split(":")
      const endChapter = parsePositiveInteger(endChapterValue)
      const endVerse = parsePositiveInteger(endVerseValue)
      if (!endChapter || !endVerse) {
        return null
      }

      return {
        book,
        startChapter,
        endChapter,
        startVerse,
        endVerse,
      }
    }

    const endVerse = parsePositiveInteger(end)
    if (!endVerse) {
      return null
    }

    return {
      book,
      startChapter,
      endChapter: startChapter,
      startVerse,
      endVerse,
    }
  }

  const startChapter = parsePositiveInteger(start)
  const endChapter = parsePositiveInteger(end)
  if (!startChapter || !endChapter) {
    return null
  }

  return {
    book,
    startChapter,
    endChapter,
  }
}

function expandVersePart(value: string): number[] {
  const normalized = value.trim()
  if (/[-–—]/.test(normalized)) {
    const [startValue, endValue] = normalized.split(/[-–—]/)
    const start = parsePositiveInteger(startValue)
    const end = parsePositiveInteger(endValue)
    if (!start || !end || end < start) {
      return []
    }

    return Array.from({ length: end - start + 1 }, (_, index) => start + index)
  }

  const verse = parsePositiveInteger(normalized)
  return verse ? [verse] : []
}

function normalizeReferenceInput(reference: string): string {
  return reference
    .normalize("NFKC")
    .trim()
    .replace(/\s+/g, " ")
    .replace(/([A-Za-z])\.\s*(\d)/g, "$1 $2")
    .replace(
      /^((?:\d+\s*)?[A-Za-z]+(?:\s+(?:of|and|the|[A-Za-z]+))*)(\d)/i,
      "$1 $2"
    )
    .replace(/(\d)\s*;\s*(\d)/g, "$1:$2")
}

function parsePositiveInteger(value: string | undefined): number | null {
  if (!value) {
    return null
  }

  const parsed = Number(value.trim())
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null
}

function formatVerseGroups(verses: number[]): string {
  const groups: string[] = []
  const uniqueVerses = [...new Set(verses)].sort((a, b) => a - b)
  let start = uniqueVerses[0]
  let previous = uniqueVerses[0]

  for (const verse of uniqueVerses.slice(1)) {
    if (previous !== undefined && verse === previous + 1) {
      previous = verse
      continue
    }

    if (start !== undefined && previous !== undefined) {
      groups.push(start === previous ? `${start}` : `${start}-${previous}`)
    }
    start = verse
    previous = verse
  }

  if (start !== undefined && previous !== undefined) {
    groups.push(start === previous ? `${start}` : `${start}-${previous}`)
  }

  return groups.join(", ")
}

function createBookAliasMap(): Record<string, string> {
  const map: Record<string, string> = {}
  const add = (canonical: string, aliases: string[]) => {
    for (const alias of [canonical, ...aliases]) {
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
  add("1 Chronicles", [
    "1 chronicles",
    "1chronicles",
    "1 chr",
    "1chr",
    "1 chro",
    "1chro",
  ])
  add("2 Chronicles", [
    "2 chronicles",
    "2chronicles",
    "2 chr",
    "2chr",
    "2 chro",
    "2chro",
  ])
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
}

function normalizeBookLookupKey(book: string): string {
  return book
    .normalize("NFKC")
    .trim()
    .replace(/^(first|1st|i)\b\.?/i, "1")
    .replace(/^(second|2nd|ii)\b\.?/i, "2")
    .replace(/^(third|3rd|iii)\b\.?/i, "3")
    .replace(/[.]/g, " ")
    .replace(/^([123])([a-z])/i, "$1 $2")
    .replace(/\s+/g, " ")
    .toLowerCase()
}

function toTitleCase(value: string): string {
  return value
    .split(" ")
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ")
}
