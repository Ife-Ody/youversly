export type BibleVersionKey = "kjv" | "asv" | "net"

export interface BibleVerse {
  book_name: string
  chapter: number
  verse: number
  text: string
}

export interface BibleVersion {
  metadata: {
    name: string
    shortname: string
  }
  verses: BibleVerse[]
}

export interface ParsedReference {
  book: string
  startChapter: number
  endChapter: number
  startVerse?: number
  endVerse?: number
  selectedVerses?: number[]
}

export interface ResolvedPassage {
  version: BibleVersionKey
  versionName: string
  reference: ParsedReference
  displayReference: string
  verses: BibleVerse[]
}

export interface ResolvePassageInput {
  reference: string
  version?: BibleVersionKey
}
