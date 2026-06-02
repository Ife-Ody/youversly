import type { BibleVerse } from "@workspace/bible"

export type PosterTemplateId = "garden" | "rose" | "parchment"
export type PosterAspect = "square" | "portrait"

export interface PosterTemplate {
  id: PosterTemplateId
  name: string
  description: string
  background: [string, string, string]
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
  background: ["#b7dcc7", "#558972", "#113d31"],
  foreground: "#fffaf0",
  muted: "rgba(255, 250, 240, 0.78)",
  border: "rgba(255, 250, 240, 0.74)",
  accent: "#f0d4ad",
  grain: "rgba(15, 45, 37, 0.16)",
}

export const POSTER_TEMPLATES: PosterTemplate[] = [
  DEFAULT_TEMPLATE,
  {
    id: "rose",
    name: "Rose",
    description: "Dusky rose fading into deep wine.",
    background: ["#c6b3ae", "#8d5c61", "#301326"],
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
    background: ["#f4ecdd", "#d8c2a1", "#77654b"],
    foreground: "#30291f",
    muted: "rgba(48, 41, 31, 0.7)",
    border: "rgba(48, 41, 31, 0.42)",
    accent: "#8c6541",
    grain: "rgba(85, 65, 42, 0.12)",
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
  const textBox = {
    x: size.width * 0.14,
    y: size.height * 0.28,
    width: size.width * 0.72,
    height: size.height * 0.38,
  }
  const fit = fitTextToBox(context, quote, {
    maxWidth: textBox.width,
    maxHeight: textBox.height,
    maxFontSize: Math.round(size.width * 0.072),
    minFontSize: Math.round(size.width * 0.034),
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
  const gradient = context.createLinearGradient(0, 0, width, height)
  gradient.addColorStop(0, template.background[0])
  gradient.addColorStop(0.52, template.background[1])
  gradient.addColorStop(1, template.background[2])
  context.fillStyle = gradient
  context.fillRect(0, 0, width, height)

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
