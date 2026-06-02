import asv from "./asv.json"
import kjv from "./kjv.json"
import net from "./net.json"
import type { BibleVersion, BibleVersionKey } from "../types"

export const versions: Record<BibleVersionKey, BibleVersion> = {
  kjv: kjv as BibleVersion,
  asv: asv as BibleVersion,
  net: net as BibleVersion,
}

export const bibleVersionOptions = [
  { value: "kjv", label: "KJV" },
  { value: "asv", label: "ASV" },
  { value: "net", label: "NET" },
] as const
