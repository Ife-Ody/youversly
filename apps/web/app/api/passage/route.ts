import { resolvePassage, type BibleVersionKey } from "@workspace/bible"

export async function GET(request: Request) {
  const url = new URL(request.url)
  const reference = url.searchParams.get("reference") ?? ""
  const version = (url.searchParams.get("version") ?? "kjv") as BibleVersionKey

  try {
    const passage = resolvePassage({ reference, version })
    return Response.json({ passage })
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Unable to resolve that Bible passage."

    return Response.json({ error: message }, { status: 400 })
  }
}
