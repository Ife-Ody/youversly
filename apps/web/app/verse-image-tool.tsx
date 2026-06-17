"use client"

import { useEffect, useMemo, useRef, useState } from "react"
import { HugeiconsIcon } from "@hugeicons/react"
import {
  AiSearch02Icon,
  BookOpen02Icon,
  CanvasIcon,
  Download01Icon,
} from "@hugeicons/core-free-icons"
import type { BibleVersionKey, ResolvedPassage } from "@workspace/bible"
import { Badge } from "@workspace/ui/components/badge"
import { Button } from "@workspace/ui/components/button"
import {
  Field,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@workspace/ui/components/field"
import { Input } from "@workspace/ui/components/input"
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@workspace/ui/components/select"
import { Separator } from "@workspace/ui/components/separator"
import {
  ToggleGroup,
  ToggleGroupItem,
} from "@workspace/ui/components/toggle-group"
import { cn } from "@workspace/ui/lib/utils"
import {
  DEFAULT_VERSE_FONT_SCALE,
  getPosterSize,
  MAX_VERSE_FONT_SCALE,
  MIN_VERSE_FONT_SCALE,
  normalizeVerseFontScale,
  POSTER_TEMPLATES,
  renderVersePoster,
  type PosterAspect,
  type PosterTemplateId,
} from "@/lib/poster-renderer"

const ASPECT_OPTIONS: Array<{ value: PosterAspect; label: string }> = [
  { value: "square", label: "1:1" },
  { value: "portrait", label: "4:5" },
]

const VERSION_OPTIONS: Array<{ value: BibleVersionKey; label: string }> = [
  { value: "kjv", label: "KJV" },
  { value: "asv", label: "ASV" },
  { value: "net", label: "NET" },
]

const STORAGE_KEY = "youversly.editor-state.v1"

interface PassageResponse {
  passage?: ResolvedPassage
  error?: string
}

interface SavedEditorState {
  reference?: string
  version?: BibleVersionKey
  title?: string
  templateId?: PosterTemplateId
  aspect?: PosterAspect
  verseFontScale?: number
  signature?: string
}

export function VerseImageTool() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const defaultTitle = useMemo(() => formatPosterDate(new Date()), [])
  const [reference, setReference] = useState("Psalm 42:1-2")
  const [version, setVersion] = useState<BibleVersionKey>("kjv")
  const [title, setTitle] = useState(defaultTitle)
  const [templateId, setTemplateId] = useState<PosterTemplateId>("garden")
  const [aspect, setAspect] = useState<PosterAspect>("square")
  const [verseFontScale, setVerseFontScale] = useState(DEFAULT_VERSE_FONT_SCALE)
  const [signature, setSignature] = useState("Youversly")
  const [passage, setPassage] = useState<ResolvedPassage | null>(null)
  const [error, setError] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [hasLoadedSavedState, setHasLoadedSavedState] = useState(false)

  const posterSize = getPosterSize(aspect)

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => {
      const savedState = readSavedEditorState()

      if (savedState?.reference) {
        setReference(savedState.reference)
      }
      if (savedState?.version) {
        setVersion(savedState.version)
      }
      if (typeof savedState?.title === "string") {
        setTitle(savedState.title)
      }
      if (savedState?.templateId) {
        setTemplateId(savedState.templateId)
      }
      if (savedState?.aspect) {
        setAspect(savedState.aspect)
      }
      if (typeof savedState?.verseFontScale === "number") {
        setVerseFontScale(normalizeVerseFontScale(savedState.verseFontScale))
      }
      if (typeof savedState?.signature === "string") {
        setSignature(savedState.signature)
      }

      setHasLoadedSavedState(true)
    })

    return () => window.cancelAnimationFrame(frame)
  }, [])

  useEffect(() => {
    if (!hasLoadedSavedState) {
      return
    }

    window.localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        reference,
        version,
        title,
        templateId,
        aspect,
        verseFontScale,
        signature,
      } satisfies SavedEditorState)
    )
  }, [
    aspect,
    hasLoadedSavedState,
    reference,
    signature,
    templateId,
    title,
    verseFontScale,
    version,
  ])

  useEffect(() => {
    const controller = new AbortController()
    const timer = window.setTimeout(async () => {
      setIsLoading(true)
      try {
        const params = new URLSearchParams({ reference, version })
        const response = await fetch(`/api/passage?${params.toString()}`, {
          signal: controller.signal,
        })
        const data = (await response.json()) as PassageResponse

        if (!response.ok || !data.passage) {
          throw new Error(data.error ?? "Unable to resolve that passage.")
        }

        setPassage(data.passage)
        setError("")
      } catch (fetchError) {
        if (controller.signal.aborted) {
          return
        }

        setPassage(null)
        setError(
          fetchError instanceof Error
            ? fetchError.message
            : "Unable to resolve that passage."
        )
      } finally {
        if (!controller.signal.aborted) {
          setIsLoading(false)
        }
      }
    }, 220)

    return () => {
      window.clearTimeout(timer)
      controller.abort()
    }
  }, [reference, version])

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas || !passage) {
      return
    }

    let isCancelled = false

    async function render() {
      await document.fonts.ready
      if (isCancelled || !canvas || !passage) {
        return
      }

      renderVersePoster(canvas, {
        reference: passage.displayReference,
        verses: passage.verses,
        title: title || defaultTitle,
        signature: signature || "Youversly",
        templateId,
        aspect,
        verseFontScale,
        referenceFontFamily:
          getComputedStyle(document.documentElement)
            .getPropertyValue("--font-script")
            .trim() ||
          '"Brush Script MT", "Snell Roundhand", "Segoe Script", cursive',
      })
    }

    void render()

    return () => {
      isCancelled = true
    }
  }, [
    aspect,
    defaultTitle,
    passage,
    signature,
    templateId,
    title,
    verseFontScale,
  ])

  function download(format: "png" | "jpeg") {
    const canvas = canvasRef.current
    if (!canvas || !passage) {
      return
    }

    const mimeType = format === "png" ? "image/png" : "image/jpeg"
    const url = canvas.toDataURL(mimeType, 0.94)
    const link = document.createElement("a")
    link.href = url
    link.download = `${slugify(passage.displayReference)}-${version}.${format === "png" ? "png" : "jpg"}`
    link.click()
  }

  return (
    <main className="min-h-svh bg-[#101010] text-white">
      <div className="mx-auto flex min-h-svh w-full max-w-[1500px] flex-col">
        <header className="flex h-14 shrink-0 items-center justify-between border-b border-white/10 px-4">
          <div className="flex min-w-0 items-center gap-2">
            <div className="flex size-8 items-center justify-center rounded-lg bg-white text-[#111]">
              <HugeiconsIcon icon={BookOpen02Icon} strokeWidth={2} />
            </div>
            <div className="min-w-0">
              <h1 className="truncate text-sm font-semibold">Youversly</h1>
              <p className="truncate text-xs text-white/50">
                Bible verse image studio
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Badge
              variant="secondary"
              className="hidden bg-white/10 text-white sm:inline-flex"
            >
              {posterSize.width} x {posterSize.height}
            </Badge>
            <Button
              variant="secondary"
              size="sm"
              disabled={!passage}
              onClick={() => download("jpeg")}
            >
              <HugeiconsIcon
                icon={Download01Icon}
                strokeWidth={2}
                data-icon="inline-start"
              />
              JPG
            </Button>
            <Button
              size="sm"
              disabled={!passage}
              onClick={() => download("png")}
            >
              <HugeiconsIcon
                icon={Download01Icon}
                strokeWidth={2}
                data-icon="inline-start"
              />
              PNG
            </Button>
          </div>
        </header>

        <div className="grid flex-1 grid-cols-1 lg:grid-cols-[320px_minmax(0,1fr)]">
          <aside className="order-2 border-b border-white/10 bg-[#151515] p-4 lg:order-1 lg:border-r lg:border-b-0">
            <FieldGroup className="gap-5">
              <div className="flex items-center gap-2 text-white">
                <HugeiconsIcon icon={AiSearch02Icon} strokeWidth={2} />
                <h2 className="text-sm font-semibold">Verse</h2>
              </div>

              <Field>
                <FieldLabel htmlFor="title">Title</FieldLabel>
                <Input
                  id="title"
                  value={title}
                  onChange={(event) => setTitle(event.target.value)}
                  placeholder={defaultTitle}
                  className="border-white/15 bg-white/5 text-white placeholder:text-white/35"
                />
                <FieldDescription className="text-white/45">
                  This appears at the top of the image.
                </FieldDescription>
              </Field>

              <Field data-invalid={!!error}>
                <FieldLabel htmlFor="reference">Reference</FieldLabel>
                <Input
                  id="reference"
                  value={reference}
                  onChange={(event) => setReference(event.target.value)}
                  placeholder="John 1:1 or John 1:1-3"
                  aria-invalid={!!error}
                  className="border-white/15 bg-white/5 text-white placeholder:text-white/35"
                />
                <FieldDescription className="text-white/45">
                  Ranges are determined from the reference automatically.
                </FieldDescription>
                <FieldError>{error}</FieldError>
              </Field>

              <Field>
                <FieldLabel>Version</FieldLabel>
                <Select
                  value={version}
                  onValueChange={(value) =>
                    setVersion(value as BibleVersionKey)
                  }
                >
                  <SelectTrigger className="w-full border-white/15 bg-white/5 text-white">
                    <SelectValue placeholder="Select version" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectGroup>
                      {VERSION_OPTIONS.map((option) => (
                        <SelectItem key={option.value} value={option.value}>
                          {option.label}
                        </SelectItem>
                      ))}
                    </SelectGroup>
                  </SelectContent>
                </Select>
              </Field>

              <Field>
                <FieldLabel htmlFor="signature">Signature</FieldLabel>
                <Input
                  id="signature"
                  value={signature}
                  onChange={(event) => setSignature(event.target.value)}
                  placeholder="Youversly"
                  className="border-white/15 bg-white/5 text-white placeholder:text-white/35"
                />
              </Field>

              <Separator className="bg-white/10" />

              <Field>
                <FieldLabel>Aspect</FieldLabel>
                <ToggleGroup
                  type="single"
                  value={aspect}
                  onValueChange={(value) =>
                    value && setAspect(value as PosterAspect)
                  }
                  variant="outline"
                  size="sm"
                  spacing={0}
                  className="w-full"
                >
                  {ASPECT_OPTIONS.map((option) => (
                    <ToggleGroupItem
                      key={option.value}
                      value={option.value}
                      className="flex-1 border-white/15 bg-white/5 text-white data-[state=on]:bg-white data-[state=on]:text-[#111]"
                    >
                      {option.label}
                    </ToggleGroupItem>
                  ))}
                </ToggleGroup>
              </Field>

              <Field>
                <div className="flex items-center justify-between gap-3">
                  <FieldLabel htmlFor="verse-font-size">Text size</FieldLabel>
                  <output
                    htmlFor="verse-font-size"
                    className="text-xs font-medium text-white/60"
                  >
                    {verseFontScale}%
                  </output>
                </div>
                <input
                  id="verse-font-size"
                  type="range"
                  min={MIN_VERSE_FONT_SCALE}
                  max={MAX_VERSE_FONT_SCALE}
                  step={5}
                  value={verseFontScale}
                  onChange={(event) =>
                    setVerseFontScale(
                      normalizeVerseFontScale(event.currentTarget.valueAsNumber)
                    )
                  }
                  className="h-2 w-full accent-white"
                />
                <FieldDescription className="text-white/45">
                  Adjusts the verse text while keeping the default fit.
                </FieldDescription>
              </Field>

              <Field>
                <FieldLabel>Template</FieldLabel>
                <div className="grid grid-cols-1 gap-2">
                  {POSTER_TEMPLATES.map((template) => (
                    <button
                      key={template.id}
                      type="button"
                      onClick={() => setTemplateId(template.id)}
                      className={cn(
                        "flex items-center gap-3 rounded-lg border border-white/10 bg-white/5 p-2 text-left transition-colors hover:bg-white/10",
                        templateId === template.id &&
                          "border-white/70 bg-white/12"
                      )}
                    >
                      <span
                        className="block size-12 rounded-md border border-white/20"
                        style={{
                          background: template.previewBackground,
                        }}
                      />
                      <span className="min-w-0">
                        <span className="block text-sm font-medium">
                          {template.name}
                        </span>
                        <span className="block truncate text-xs text-white/45">
                          {template.description}
                        </span>
                      </span>
                    </button>
                  ))}
                </div>
              </Field>
            </FieldGroup>
          </aside>

          <section className="order-1 flex min-h-[520px] flex-col bg-[#0d0d0d] lg:order-2 lg:min-h-[720px]">
            <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
              <div className="flex min-w-0 items-center gap-2">
                <HugeiconsIcon icon={CanvasIcon} strokeWidth={2} />
                <div className="min-w-0">
                  <h2 className="truncate text-sm font-semibold">Preview</h2>
                  <p className="truncate text-xs text-white/45">
                    {passage
                      ? `${passage.displayReference} · ${passage.verses.length} verse${passage.verses.length === 1 ? "" : "s"}`
                      : isLoading
                        ? "Resolving passage..."
                        : "Enter a valid passage to render."}
                  </p>
                </div>
              </div>
            </div>

            <div className="flex flex-1 items-center justify-center overflow-hidden p-4 sm:p-6">
              <div
                className="w-full"
                style={{
                  maxWidth:
                    aspect === "portrait"
                      ? "min(82vw, calc((100svh - 9rem) * 0.8), 760px)"
                      : "min(82vw, calc(100svh - 9rem), 760px)",
                }}
              >
                <canvas
                  ref={canvasRef}
                  className={cn(
                    "block w-full rounded-lg shadow-2xl ring-1 shadow-black/50 ring-white/10",
                    aspect === "portrait" ? "aspect-[4/5]" : "aspect-square"
                  )}
                />
              </div>
            </div>
          </section>
        </div>
      </div>
    </main>
  )
}

function formatPosterDate(date: Date) {
  const day = date.getDate()
  const suffix =
    day % 10 === 1 && day !== 11
      ? "st"
      : day % 10 === 2 && day !== 12
        ? "nd"
        : day % 10 === 3 && day !== 13
          ? "rd"
          : "th"

  return `${day}${suffix} ${date.toLocaleDateString("en-GB", {
    month: "long",
    year: "numeric",
  })}`
}

function slugify(value: string) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
}

function readSavedEditorState(): SavedEditorState | null {
  try {
    const rawValue = window.localStorage.getItem(STORAGE_KEY)
    if (!rawValue) {
      return null
    }

    const value = JSON.parse(rawValue) as SavedEditorState

    return {
      reference:
        typeof value.reference === "string" ? value.reference : undefined,
      version: isBibleVersionKey(value.version) ? value.version : undefined,
      title: typeof value.title === "string" ? value.title : undefined,
      templateId: isPosterTemplateId(value.templateId)
        ? value.templateId
        : undefined,
      aspect: isPosterAspect(value.aspect) ? value.aspect : undefined,
      verseFontScale:
        typeof value.verseFontScale === "number"
          ? normalizeVerseFontScale(value.verseFontScale)
          : undefined,
      signature:
        typeof value.signature === "string" ? value.signature : undefined,
    }
  } catch {
    return null
  }
}

function isPosterTemplateId(value: unknown): value is PosterTemplateId {
  return POSTER_TEMPLATES.some((template) => template.id === value)
}

function isPosterAspect(value: unknown): value is PosterAspect {
  return ASPECT_OPTIONS.some((option) => option.value === value)
}

function isBibleVersionKey(value: unknown): value is BibleVersionKey {
  return VERSION_OPTIONS.some((option) => option.value === value)
}
