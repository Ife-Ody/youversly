import CoreText
import UIKit

nonisolated struct PosterPayload: Hashable, Sendable {
  var reference: String
  var verses: [BibleVerse]
  var title: String
  var signature: String
  var templateID: PosterTemplateID
  var aspect: PosterAspect
  /// Nil means "fit the verse into its box", matching the web default.
  var verseFontSize: Int?
}

/// Fonts for the poster. The web app uses Merriweather and Dancing Script from
/// Google Fonts; these are the system fallbacks it declares. Swap the names here
/// to use bundled fonts.
nonisolated enum PosterFont {
  static func title(_ size: CGFloat) -> UIFont {
    UIFont(name: "TimesNewRomanPS-BoldMT", size: size) ?? serif(size, weight: .bold)
  }

  static func reference(_ size: CGFloat) -> UIFont {
    UIFont(name: "SnellRoundhand", size: size) ?? serif(size, weight: .regular)
  }

  static func verse(_ size: CGFloat) -> UIFont {
    UIFont(name: "Georgia", size: size) ?? serif(size, weight: .regular)
  }

  private static func serif(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
    let base = UIFont.systemFont(ofSize: size, weight: weight)
    guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
    return UIFont(descriptor: descriptor, size: size)
  }
}

/// Core Graphics port of `renderVersePoster` in `apps/web/lib/poster-renderer.ts`.
/// Coordinates are in poster pixels with the origin at the top left, as on the web canvas.
nonisolated enum PosterRenderer {
  static func render(_ payload: PosterPayload) -> UIImage {
    let size = payload.aspect.size
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true

    return UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
      draw(payload, in: rendererContext.cgContext, size: size)
    }
  }

  static func pngData(_ payload: PosterPayload) -> Data? {
    render(payload).pngData()
  }

  static func draw(_ payload: PosterPayload, in context: CGContext, size: CGSize) {
    let width = size.width
    let height = size.height
    let template = PosterTemplate.named(payload.templateID)

    drawBackground(in: context, width: width, height: height, template: template)
    drawFrame(in: context, width: width, height: height, template: template)
    drawBotanicalCorners(in: context, width: width, height: height, template: template)

    drawText(
      payload.title.uppercased(),
      font: PosterFont.title((width * 0.031).rounded()),
      color: template.muted, kern: 10,
      centerX: width / 2, baselineY: height * 0.082, in: context)

    drawText(
      payload.reference,
      font: PosterFont.reference((width * 0.07).rounded()),
      color: template.foreground, kern: 0,
      centerX: width / 2, baselineY: height * 0.205, in: context)

    let quote = payload.verses.map(\.text).joined(separator: " ")
    let textBox = CGRect(
      x: width * 0.14, y: height * 0.28, width: width * 0.72, height: height * 0.38)
    let measure: TextLayout.Measure = { text, fontSize in
      measureWidth(text, font: PosterFont.verse(CGFloat(fontSize)), kern: 0)
    }
    let fit =
      if let verseFontSize = payload.verseFontSize {
        TextLayout.layoutText(
          quote, fontSize: TextLayout.normalizeVerseFontSize(Double(verseFontSize)),
          maxWidth: textBox.width, measure: measure)
      } else {
        TextLayout.fitTextToBox(
          quote,
          maxWidth: textBox.width,
          maxHeight: textBox.height,
          maxFontSize: TextLayout.defaultVerseFontSize,
          minFontSize: Int((width * 0.034).rounded()),
          measure: measure)
      }

    let verseFont = PosterFont.verse(CGFloat(fit.fontSize))
    let startY = TextLayout.centeredTextBlockStartY(
      boxY: textBox.minY, boxHeight: textBox.height,
      lineCount: fit.lines.count, lineHeight: fit.lineHeight, fontSize: fit.fontSize)
    for (index, line) in fit.lines.enumerated() {
      drawText(
        line, font: verseFont, color: template.foreground, kern: 0,
        centerX: width / 2, baselineY: startY + CGFloat(index * fit.lineHeight), in: context)
    }

    drawOpenBook(
      in: context, centerX: width / 2, centerY: height * 0.85, width: width * 0.15,
      template: template)

    drawText(
      payload.signature.uppercased(),
      font: PosterFont.title((width * 0.026).rounded()),
      color: template.muted, kern: 8,
      centerX: width / 2, baselineY: height * 0.91, in: context)
  }

  // MARK: - Background

  static func drawBackground(
    in context: CGContext, width: CGFloat, height: CGFloat, template: PosterTemplate
  ) {
    let bounds = CGRect(x: 0, y: 0, width: width, height: height)
    let options: CGGradientDrawingOptions = [.drawsBeforeStartLocation, .drawsAfterEndLocation]

    for layer in template.background {
      guard let gradient = makeGradient(layer.stops) else { continue }
      context.saveGState()
      context.clip(to: bounds)
      switch layer {
      case .linear(let from, let to, _):
        context.drawLinearGradient(
          gradient,
          start: CGPoint(x: from.x * width, y: from.y * height),
          end: CGPoint(x: to.x * width, y: to.y * height),
          options: options)
      case .radial(let center, let radius, _):
        let point = CGPoint(x: center.x * width, y: center.y * height)
        context.drawRadialGradient(
          gradient,
          startCenter: point, startRadius: 0,
          endCenter: point, endRadius: radius * max(width, height),
          options: options)
      }
      context.restoreGState()
    }

    // Grain: a 1px dot every 8px in a checker pattern.
    var dots: [CGRect] = []
    dots.reserveCapacity(Int(width / 8) * Int(height / 8))
    var y: CGFloat = 0
    while y < height {
      var x: CGFloat = Int(y / 8) % 2 == 0 ? 0 : 4
      while x < width {
        dots.append(CGRect(x: x, y: y, width: 1, height: 1))
        x += 8
      }
      y += 8
    }
    context.setFillColor(template.grain.cgColor)
    context.fill(dots)
  }

  private static func makeGradient(_ stops: [ColorStop]) -> CGGradient? {
    let colors = stops.map(\.color.cgColor) as CFArray
    let locations = stops.map(\.offset)
    return CGGradient(
      colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: locations)
  }

  // MARK: - Decoration

  private static func drawFrame(
    in context: CGContext, width: CGFloat, height: CGFloat, template: PosterTemplate
  ) {
    let margin = width * 0.085
    context.setStrokeColor(template.border.cgColor)
    context.setLineWidth(2)
    context.beginPath()
    context.move(to: CGPoint(x: margin, y: height * 0.13))
    context.addLine(to: CGPoint(x: width * 0.82, y: height * 0.13))
    context.move(to: CGPoint(x: margin, y: height * 0.13))
    context.addLine(to: CGPoint(x: margin, y: height * 0.48))
    context.move(to: CGPoint(x: width - margin, y: height * 0.5))
    context.addLine(to: CGPoint(x: width - margin, y: height * 0.855))
    context.addLine(to: CGPoint(x: width * 0.21, y: height * 0.855))
    context.strokePath()
  }

  private static func drawBotanicalCorners(
    in context: CGContext, width: CGFloat, height: CGFloat, template: PosterTemplate
  ) {
    context.setStrokeColor(template.border.cgColor)
    context.setLineWidth(1.5)
    drawLeafCluster(
      in: context, x: width * 0.94, y: height * 0.03, radius: width * 0.11, direction: 1)
    drawLeafCluster(
      in: context, x: width * 0.05, y: height * 0.7, radius: width * 0.12, direction: -1)
  }

  private static func drawLeafCluster(
    in context: CGContext, x: CGFloat, y: CGFloat, radius: CGFloat, direction: CGFloat
  ) {
    for index in 0..<3 {
      let offset = CGFloat(index) * radius * 0.55
      let center = CGPoint(x: x + direction * offset, y: y + offset)
      let rotation = direction * (.pi / 4 + CGFloat(index) * 0.2)

      let leaf = CGMutablePath()
      let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: rotation)
      leaf.addEllipse(
        in: CGRect(x: -radius, y: -radius * 0.42, width: radius * 2, height: radius * 0.84),
        transform: transform)
      context.addPath(leaf)
      context.strokePath()

      context.beginPath()
      for rib in -3...3 {
        context.move(to: center)
        context.addLine(
          to: CGPoint(
            x: x + direction * (offset + radius * 0.85),
            y: y + offset + CGFloat(rib) * radius * 0.11))
      }
      context.strokePath()
    }
  }

  private static func drawOpenBook(
    in context: CGContext, centerX: CGFloat, centerY: CGFloat, width: CGFloat,
    template: PosterTemplate
  ) {
    let height = width * 0.32
    context.setFillColor(template.accent.cgColor)
    context.setStrokeColor(PosterColor("rgba(49, 32, 19, 0.42)").cgColor)
    context.setLineWidth(2)

    for side in [CGFloat(-1), 1] {
      context.beginPath()
      context.move(to: CGPoint(x: centerX, y: centerY - height * 0.15))
      context.addQuadCurve(
        to: CGPoint(x: centerX + side * width * 0.5, y: centerY),
        control: CGPoint(x: centerX + side * width * 0.28, y: centerY - height * 0.5))
      context.addQuadCurve(
        to: CGPoint(x: centerX, y: centerY + height * 0.22),
        control: CGPoint(x: centerX + side * width * 0.22, y: centerY - height * 0.05))
      context.closePath()
      context.drawPath(using: .fillStroke)
    }
  }

  // MARK: - Text

  static func measureWidth(_ text: String, font: UIFont, kern: CGFloat) -> CGFloat {
    let line = CTLineCreateWithAttributedString(attributedString(text, font: font, kern: kern))
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
  }

  /// Draws `text` centred on `centerX` with its baseline at `baselineY`, like
  /// canvas `fillText` with `textAlign = "center"`.
  private static func drawText(
    _ text: String, font: UIFont, color: PosterColor, kern: CGFloat,
    centerX: CGFloat, baselineY: CGFloat, in context: CGContext
  ) {
    let attributed = attributedString(text, font: font, kern: kern, color: color)
    let line = CTLineCreateWithAttributedString(attributed)
    let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))

    context.saveGState()
    context.textMatrix = .identity
    context.translateBy(x: centerX - width / 2, y: baselineY)
    context.scaleBy(x: 1, y: -1)
    context.textPosition = .zero
    CTLineDraw(line, context)
    context.restoreGState()
  }

  private static func attributedString(
    _ text: String, font: UIFont, kern: CGFloat, color: PosterColor? = nil
  ) -> NSAttributedString {
    var attributes: [NSAttributedString.Key: Any] = [.font: font, .kern: kern]
    if let color {
      attributes[.foregroundColor] = UIColor(cgColor: color.cgColor)
    }
    return NSAttributedString(string: text, attributes: attributes)
  }
}
