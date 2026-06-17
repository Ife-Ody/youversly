import type { BibleVerse } from "@workspace/bible"

export type PosterTemplateId =
  | "garden"
  | "rose"
  | "parchment"
  | "mist"
  | "daybreak"
export type PosterAspect = "square" | "portrait"

type ColorStop = {
  offset: number
  color: string
}

type LinearBackgroundLayer = {
  type: "linear"
  from: readonly [number, number]
  to: readonly [number, number]
  stops: ColorStop[]
}

type RadialBackgroundLayer = {
  type: "radial"
  center: readonly [number, number]
  radius: number
  stops: ColorStop[]
}

type PosterBackgroundLayer = LinearBackgroundLayer | RadialBackgroundLayer

export interface PosterTemplate {
  id: PosterTemplateId
  name: string
  description: string
  background: PosterBackgroundLayer[]
  previewBackground: string
  foreground: string
  muted: string
  border: string
  accent: string
  grain: string
}

export interface PosterPayload {
  reference: string
  verses: BibleVerse[]
  title: string
  signature: string
  templateId: PosterTemplateId
  aspect: PosterAspect
  verseFontScale?: number
  referenceFontFamily?: string
}

export interface TextFitResult {
  fontSize: number
  lineHeight: number
  lines: string[]
}

const DEFAULT_TEMPLATE: PosterTemplate = {
  id: "garden",
  name: "Garden",
  description: "Muted green with a soft devotional finish.",
  background: [
    {
      type: "linear",
      from: [0, 0],
      to: [1, 1],
      stops: [
        { offset: 0, color: "#b7dcc7" },
        { offset: 0.52, color: "#558972" },
        { offset: 1, color: "#113d31" },
      ],
    },
  ],
  previewBackground: "linear-gradient(135deg, #b7dcc7, #558972 52%, #113d31)",
  foreground: "#fffaf0",
  muted: "rgba(255, 250, 240, 0.78)",
  border: "rgba(255, 250, 240, 0.74)",
  accent: "#f0d4ad",
  grain: "rgba(15, 45, 37, 0.16)",
}

export const DEFAULT_VERSE_FONT_SCALE = 100
export const MIN_VERSE_FONT_SCALE = 80
export const MAX_VERSE_FONT_SCALE = 130

export const POSTER_TEMPLATES: PosterTemplate[] = [
  DEFAULT_TEMPLATE,
  {
    id: "rose",
    name: "Rose",
    description: "Dusky rose fading into deep wine.",
    background: [
      {
        type: "linear",
        from: [0, 0],
        to: [1, 1],
        stops: [
          { offset: 0, color: "#c6b3ae" },
          { offset: 0.52, color: "#8d5c61" },
          { offset: 1, color: "#301326" },
        ],
      },
    ],
    previewBackground: "linear-gradient(135deg, #c6b3ae, #8d5c61 52%, #301326)",
    foreground: "#fff7ef",
    muted: "rgba(255, 247, 239, 0.78)",
    border: "rgba(255, 247, 239, 0.7)",
    accent: "#f4d7a9",
    grain: "rgba(43, 14, 29, 0.18)",
  },
  {
    id: "parchment",
    name: "Parchment",
    description: "Light editorial texture for calm sharing.",
    background: [
      {
        type: "linear",
        from: [0, 0],
        to: [1, 1],
        stops: [
          { offset: 0, color: "#f4ecdd" },
          { offset: 0.52, color: "#d8c2a1" },
          { offset: 1, color: "#77654b" },
        ],
      },
    ],
    previewBackground: "linear-gradient(135deg, #f4ecdd, #d8c2a1 52%, #77654b)",
    foreground: "#30291f",
    muted: "rgba(48, 41, 31, 0.7)",
    border: "rgba(48, 41, 31, 0.42)",
    accent: "#8c6541",
    grain: "rgba(85, 65, 42, 0.12)",
  },
  {
    id: "mist",
    name: "Mist",
    description: "Layered teal, ink, and violet atmosphere.",
    background: [
      {
        type: "linear",
        from: [0, 0],
        to: [1, 1],
        stops: [
          { offset: 0, color: "#061b35" },
          { offset: 0.5, color: "#162f4a" },
          { offset: 1, color: "#070713" },
        ],
      },
      {
        type: "radial",
        center: [0.14, 0.62],
        radius: 0.8,
        stops: [
          { offset: 0, color: "rgba(48, 139, 139, 0.82)" },
          { offset: 0.48, color: "rgba(38, 108, 123, 0.34)" },
          { offset: 1, color: "rgba(48, 139, 139, 0)" },
        ],
      },
      {
        type: "radial",
        center: [0.58, 0.4],
        radius: 0.72,
        stops: [
          { offset: 0, color: "rgba(42, 72, 111, 0.56)" },
          { offset: 0.62, color: "rgba(34, 55, 91, 0.26)" },
          { offset: 1, color: "rgba(42, 72, 111, 0)" },
        ],
      },
      {
        type: "radial",
        center: [0.9, 0.13],
        radius: 0.54,
        stops: [
          { offset: 0, color: "rgba(79, 37, 96, 0.44)" },
          { offset: 1, color: "rgba(79, 37, 96, 0)" },
        ],
      },
      {
        type: "linear",
        from: [0, 0],
        to: [0, 1],
        stops: [
          { offset: 0, color: "rgba(3, 9, 20, 0.45)" },
          { offset: 0.54, color: "rgba(3, 9, 20, 0)" },
          { offset: 1, color: "rgba(3, 9, 20, 0.28)" },
        ],
      },
    ],
    previewBackground:
      "radial-gradient(circle at 14% 62%, rgba(48, 139, 139, 0.82), rgba(38, 108, 123, 0.34) 48%, transparent 72%), radial-gradient(circle at 58% 40%, rgba(42, 72, 111, 0.56), transparent 70%), radial-gradient(circle at 90% 13%, rgba(79, 37, 96, 0.44), transparent 58%), linear-gradient(135deg, #061b35, #162f4a 50%, #070713)",
    foreground: "#f5f0e6",
    muted: "rgba(245, 240, 230, 0.76)",
    border: "rgba(245, 240, 230, 0.58)",
    accent: "#d7bd8c",
    grain: "rgba(226, 244, 236, 0.1)",
  },
  {
    id: "daybreak",
    name: "Daybreak",
    description: "Soft sunrise gradients with quiet depth.",
    background: [
      {
        type: "linear",
        from: [0, 0],
        to: [1, 1],
        stops: [
          { offset: 0, color: "#f3d1ba" },
          { offset: 0.46, color: "#d39a83" },
          { offset: 1, color: "#394b65" },
        ],
      },
      {
        type: "radial",
        center: [0.2, 0.14],
        radius: 0.66,
        stops: [
          { offset: 0, color: "rgba(255, 244, 199, 0.72)" },
          { offset: 0.48, color: "rgba(241, 174, 128, 0.36)" },
          { offset: 1, color: "rgba(241, 174, 128, 0)" },
        ],
      },
      {
        type: "radial",
        center: [0.82, 0.82],
        radius: 0.7,
        stops: [
          { offset: 0, color: "rgba(45, 82, 111, 0.52)" },
          { offset: 1, color: "rgba(45, 82, 111, 0)" },
        ],
      },
    ],
    previewBackground:
      "radial-gradient(circle at 20% 14%, rgba(255, 244, 199, 0.72), rgba(241, 174, 128, 0.36) 48%, transparent 70%), radial-gradient(circle at 82% 82%, rgba(45, 82, 111, 0.52), transparent 68%), linear-gradient(135deg, #f3d1ba, #d39a83 46%, #394b65)",
    foreground: "#fffaf0",
    muted: "rgba(255, 250, 240, 0.76)",
    border: "rgba(255, 250, 240, 0.58)",
    accent: "#f2d28f",
    grain: "rgba(88, 54, 42, 0.12)",
  },
]

export function getPosterSize(aspect: PosterAspect) {
  return aspect === "portrait"
    ? { width: 1080, height: 1350 }
    : { width: 1080, height: 1080 }
}

export function renderVersePoster(
  canvas: HTMLCanvasElement,
  payload: PosterPayload
) {
  const size = getPosterSize(payload.aspect)
  canvas.width = size.width
  canvas.height = size.height

  const context = canvas.getContext("2d")
  if (!context) {
    return
  }

  const template = getPosterTemplate(payload.templateId)
  drawBackground(context, size.width, size.height, template)
  drawFrame(context, size.width, size.height, template)
  drawBotanicalCorners(context, size.width, size.height, template)

  context.textAlign = "center"
  context.fillStyle = template.muted
  context.font = `700 ${Math.round(size.width * 0.031)}px "Times New Roman", Georgia, serif`
  context.letterSpacing = "10px"
  context.fillText(
    payload.title.toUpperCase(),
    size.width / 2,
    size.height * 0.082
  )

  context.letterSpacing = "0px"
  context.fillStyle = template.foreground
  const referenceFont =
    payload.referenceFontFamily ||
    '"Brush Script MT", "Snell Roundhand", "Segoe Script", cursive'
  context.font = `400 ${Math.round(size.width * 0.07)}px ${referenceFont}`
  context.fillText(payload.reference, size.width / 2, size.height * 0.205)

  const quote = payload.verses.map((verse) => verse.text).join(" ")
  const verseFontScale = normalizeVerseFontScale(payload.verseFontScale) / 100
  const textBox = {
    x: size.width * 0.14,
    y: size.height * 0.28,
    width: size.width * 0.72,
    height: size.height * 0.38,
  }
  const fit = fitTextToBox(context, quote, {
    maxWidth: textBox.width,
    maxHeight: textBox.height,
    maxFontSize: Math.round(size.width * 0.072 * verseFontScale),
    minFontSize: Math.round(size.width * 0.034 * verseFontScale),
    fontFamily: '"Merriweather", Georgia, serif',
    fontWeight: "400",
  })

  context.fillStyle = template.foreground
  context.font = `${fit.fontSize}px "Merriweather", Georgia, serif`
  context.textAlign = "center"
  drawCenteredLines(
    context,
    fit.lines,
    size.width / 2,
    textBox.y,
    fit.lineHeight
  )

  drawOpenBook(
    context,
    size.width / 2,
    size.height * 0.765,
    size.width * 0.15,
    template
  )

  context.fillStyle = template.muted
  context.font = `700 ${Math.round(size.width * 0.026)}px "Times New Roman", Georgia, serif`
  context.letterSpacing = "8px"
  context.fillText(
    payload.signature.toUpperCase(),
    size.width / 2,
    size.height * 0.91
  )

  context.letterSpacing = "0px"
}

export function fitTextToBox(
  context: Pick<CanvasRenderingContext2D, "font" | "measureText">,
  text: string,
  options: {
    maxWidth: number
    maxHeight: number
    maxFontSize: number
    minFontSize: number
    fontFamily: string
    fontWeight: string
  }
): TextFitResult {
  for (
    let fontSize = options.maxFontSize;
    fontSize >= options.minFontSize;
    fontSize -= 2
  ) {
    context.font = `${options.fontWeight} ${fontSize}px ${options.fontFamily}`
    const lineHeight = Math.round(fontSize * 1.28)
    const lines = wrapTextLines(context, `“${text}”`, options.maxWidth)

    if (lines.length * lineHeight <= options.maxHeight) {
      return { fontSize, lineHeight, lines }
    }
  }

  context.font = `${options.fontWeight} ${options.minFontSize}px ${options.fontFamily}`
  const lineHeight = Math.round(options.minFontSize * 1.25)
  return {
    fontSize: options.minFontSize,
    lineHeight,
    lines: wrapTextLines(context, `“${text}”`, options.maxWidth),
  }
}

export function normalizeVerseFontScale(value: unknown) {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return DEFAULT_VERSE_FONT_SCALE
  }

  return Math.min(
    MAX_VERSE_FONT_SCALE,
    Math.max(MIN_VERSE_FONT_SCALE, Math.round(value))
  )
}

export function wrapTextLines(
  context: Pick<CanvasRenderingContext2D, "measureText">,
  text: string,
  maxWidth: number
): string[] {
  const words = text.replace(/\s+/g, " ").trim().split(" ")
  const lines: string[] = []
  let currentLine = ""

  for (const word of words) {
    const candidate = currentLine ? `${currentLine} ${word}` : word

    if (context.measureText(candidate).width <= maxWidth || !currentLine) {
      currentLine = candidate
      continue
    }

    lines.push(currentLine)
    currentLine = word
  }

  if (currentLine) {
    lines.push(currentLine)
  }

  return lines
}

export function getPosterTemplate(templateId: PosterTemplateId) {
  return (
    POSTER_TEMPLATES.find((template) => template.id === templateId) ??
    DEFAULT_TEMPLATE
  )
}

function drawBackground(
  context: CanvasRenderingContext2D,
  width: number,
  height: number,
  template: PosterTemplate
) {
  template.background.forEach((layer) => {
    const gradient =
      layer.type === "linear"
        ? context.createLinearGradient(
            layer.from[0] * width,
            layer.from[1] * height,
            layer.to[0] * width,
            layer.to[1] * height
          )
        : context.createRadialGradient(
            layer.center[0] * width,
            layer.center[1] * height,
            0,
            layer.center[0] * width,
            layer.center[1] * height,
            layer.radius * Math.max(width, height)
          )

    layer.stops.forEach((stop) => {
      gradient.addColorStop(stop.offset, stop.color)
    })

    context.fillStyle = gradient
    context.fillRect(0, 0, width, height)
  })

  context.fillStyle = template.grain
  for (let y = 0; y < height; y += 8) {
    for (let x = (y / 8) % 2 === 0 ? 0 : 4; x < width; x += 8) {
      context.fillRect(x, y, 1, 1)
    }
  }
}

function drawFrame(
  context: CanvasRenderingContext2D,
  width: number,
  height: number,
  template: PosterTemplate
) {
  const margin = width * 0.085
  context.strokeStyle = template.border
  context.lineWidth = 2
  context.beginPath()
  context.moveTo(margin, height * 0.13)
  context.lineTo(width * 0.82, height * 0.13)
  context.moveTo(margin, height * 0.13)
  context.lineTo(margin, height * 0.48)
  context.moveTo(width - margin, height * 0.5)
  context.lineTo(width - margin, height * 0.855)
  context.lineTo(width * 0.21, height * 0.855)
  context.stroke()
}

function drawBotanicalCorners(
  context: CanvasRenderingContext2D,
  width: number,
  height: number,
  template: PosterTemplate
) {
  context.strokeStyle = template.border
  context.lineWidth = 1.5
  drawLeafCluster(context, width * 0.94, height * 0.03, width * 0.11, 1)
  drawLeafCluster(context, width * 0.05, height * 0.7, width * 0.12, -1)
}

function drawLeafCluster(
  context: CanvasRenderingContext2D,
  x: number,
  y: number,
  radius: number,
  direction: 1 | -1
) {
  for (let index = 0; index < 3; index += 1) {
    const offset = index * radius * 0.55
    context.beginPath()
    context.ellipse(
      x + direction * offset,
      y + offset,
      radius,
      radius * 0.42,
      direction * (Math.PI / 4 + index * 0.2),
      0,
      Math.PI * 2
    )
    context.stroke()

    for (let rib = -3; rib <= 3; rib += 1) {
      context.beginPath()
      context.moveTo(x + direction * offset, y + offset)
      context.lineTo(
        x + direction * (offset + radius * 0.85),
        y + offset + rib * radius * 0.11
      )
      context.stroke()
    }
  }
}

function drawCenteredLines(
  context: CanvasRenderingContext2D,
  lines: string[],
  centerX: number,
  startY: number,
  lineHeight: number
) {
  lines.forEach((line, index) => {
    context.fillText(line, centerX, startY + index * lineHeight)
  })
}

function drawOpenBook(
  context: CanvasRenderingContext2D,
  centerX: number,
  centerY: number,
  width: number,
  template: PosterTemplate
) {
  const height = width * 0.32
  context.fillStyle = template.accent
  context.strokeStyle = "rgba(49, 32, 19, 0.42)"
  context.lineWidth = 2

  context.beginPath()
  context.moveTo(centerX, centerY - height * 0.15)
  context.quadraticCurveTo(
    centerX - width * 0.28,
    centerY - height * 0.5,
    centerX - width * 0.5,
    centerY
  )
  context.quadraticCurveTo(
    centerX - width * 0.22,
    centerY - height * 0.05,
    centerX,
    centerY + height * 0.22
  )
  context.closePath()
  context.fill()
  context.stroke()

  context.beginPath()
  context.moveTo(centerX, centerY - height * 0.15)
  context.quadraticCurveTo(
    centerX + width * 0.28,
    centerY - height * 0.5,
    centerX + width * 0.5,
    centerY
  )
  context.quadraticCurveTo(
    centerX + width * 0.22,
    centerY - height * 0.05,
    centerX,
    centerY + height * 0.22
  )
  context.closePath()
  context.fill()
  context.stroke()
}
