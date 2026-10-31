import CoreGraphics
import Foundation

nonisolated enum PosterTemplateID: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
  case garden
  case rose
  case parchment
  case mist
  case daybreak

  var id: Self { self }
}

nonisolated enum PosterAspect: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
  case square
  case portrait

  var id: Self { self }

  var label: String {
    switch self {
    case .square: "1:1"
    case .portrait: "4:5"
    }
  }

  var size: CGSize {
    switch self {
    case .square: CGSize(width: 1080, height: 1080)
    case .portrait: CGSize(width: 1080, height: 1350)
    }
  }
}

nonisolated struct ColorStop: Hashable, Sendable {
  var offset: CGFloat
  var color: PosterColor

  init(_ offset: CGFloat, _ color: String) {
    self.offset = offset
    self.color = PosterColor(color)
  }
}

/// Positions are fractions of the poster size, as in the web renderer.
nonisolated enum PosterBackgroundLayer: Hashable, Sendable {
  case linear(from: CGPoint, to: CGPoint, stops: [ColorStop])
  case radial(center: CGPoint, radius: CGFloat, stops: [ColorStop])

  var stops: [ColorStop] {
    switch self {
    case .linear(_, _, let stops), .radial(_, _, let stops): stops
    }
  }
}

nonisolated struct PosterTemplate: Hashable, Sendable, Identifiable {
  var id: PosterTemplateID
  var name: String
  var description: String
  var background: [PosterBackgroundLayer]
  var foreground: PosterColor
  var muted: PosterColor
  var border: PosterColor
  var accent: PosterColor
  var grain: PosterColor

  init(
    id: PosterTemplateID, name: String, description: String,
    background: [PosterBackgroundLayer],
    foreground: String, muted: String, border: String, accent: String, grain: String
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.background = background
    self.foreground = PosterColor(foreground)
    self.muted = PosterColor(muted)
    self.border = PosterColor(border)
    self.accent = PosterColor(accent)
    self.grain = PosterColor(grain)
  }

  static let all: [PosterTemplate] = [
    .garden, .rose, .parchment, .mist, .daybreak,
  ]

  static func named(_ id: PosterTemplateID) -> PosterTemplate {
    all.first { $0.id == id } ?? .garden
  }

  private static let diagonal = (from: CGPoint(x: 0, y: 0), to: CGPoint(x: 1, y: 1))

  static let garden = PosterTemplate(
    id: .garden,
    name: "Garden",
    description: "Muted green with a soft devotional finish.",
    background: [
      .linear(
        from: diagonal.from, to: diagonal.to,
        stops: [
          ColorStop(0, "#b7dcc7"), ColorStop(0.52, "#558972"), ColorStop(1, "#113d31"),
        ])
    ],
    foreground: "#fffaf0",
    muted: "rgba(255, 250, 240, 0.78)",
    border: "rgba(255, 250, 240, 0.74)",
    accent: "#f0d4ad",
    grain: "rgba(15, 45, 37, 0.16)")

  static let rose = PosterTemplate(
    id: .rose,
    name: "Rose",
    description: "Dusky rose fading into deep wine.",
    background: [
      .linear(
        from: diagonal.from, to: diagonal.to,
        stops: [
          ColorStop(0, "#c6b3ae"), ColorStop(0.52, "#8d5c61"), ColorStop(1, "#301326"),
        ])
    ],
    foreground: "#fff7ef",
    muted: "rgba(255, 247, 239, 0.78)",
    border: "rgba(255, 247, 239, 0.7)",
    accent: "#f4d7a9",
    grain: "rgba(43, 14, 29, 0.18)")

  static let parchment = PosterTemplate(
    id: .parchment,
    name: "Parchment",
    description: "Light editorial texture for calm sharing.",
    background: [
      .linear(
        from: diagonal.from, to: diagonal.to,
        stops: [
          ColorStop(0, "#f4ecdd"), ColorStop(0.52, "#d8c2a1"), ColorStop(1, "#77654b"),
        ])
    ],
    foreground: "#30291f",
    muted: "rgba(48, 41, 31, 0.7)",
    border: "rgba(48, 41, 31, 0.42)",
    accent: "#8c6541",
    grain: "rgba(85, 65, 42, 0.12)")

  static let mist = PosterTemplate(
    id: .mist,
    name: "Mist",
    description: "Layered teal, ink, and violet atmosphere.",
    background: [
      .linear(
        from: diagonal.from, to: diagonal.to,
        stops: [
          ColorStop(0, "#061b35"), ColorStop(0.5, "#162f4a"), ColorStop(1, "#070713"),
        ]),
      .radial(
        center: CGPoint(x: 0.14, y: 0.62), radius: 0.8,
        stops: [
          ColorStop(0, "rgba(48, 139, 139, 0.82)"),
          ColorStop(0.48, "rgba(38, 108, 123, 0.34)"),
          ColorStop(1, "rgba(48, 139, 139, 0)"),
        ]),
      .radial(
        center: CGPoint(x: 0.58, y: 0.4), radius: 0.72,
        stops: [
          ColorStop(0, "rgba(42, 72, 111, 0.56)"),
          ColorStop(0.62, "rgba(34, 55, 91, 0.26)"),
          ColorStop(1, "rgba(42, 72, 111, 0)"),
        ]),
      .radial(
        center: CGPoint(x: 0.9, y: 0.13), radius: 0.54,
        stops: [
          ColorStop(0, "rgba(79, 37, 96, 0.44)"),
          ColorStop(1, "rgba(79, 37, 96, 0)"),
        ]),
      .linear(
        from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 1),
        stops: [
          ColorStop(0, "rgba(3, 9, 20, 0.45)"),
          ColorStop(0.54, "rgba(3, 9, 20, 0)"),
          ColorStop(1, "rgba(3, 9, 20, 0.28)"),
        ]),
    ],
    foreground: "#f5f0e6",
    muted: "rgba(245, 240, 230, 0.76)",
    border: "rgba(245, 240, 230, 0.58)",
    accent: "#d7bd8c",
    grain: "rgba(226, 244, 236, 0.1)")

  static let daybreak = PosterTemplate(
    id: .daybreak,
    name: "Daybreak",
    description: "Soft sunrise gradients with quiet depth.",
    background: [
      .linear(
        from: diagonal.from, to: diagonal.to,
        stops: [
          ColorStop(0, "#f3d1ba"), ColorStop(0.46, "#d39a83"), ColorStop(1, "#394b65"),
        ]),
      .radial(
        center: CGPoint(x: 0.2, y: 0.14), radius: 0.66,
        stops: [
          ColorStop(0, "rgba(255, 244, 199, 0.72)"),
          ColorStop(0.48, "rgba(241, 174, 128, 0.36)"),
          ColorStop(1, "rgba(241, 174, 128, 0)"),
        ]),
      .radial(
        center: CGPoint(x: 0.82, y: 0.82), radius: 0.7,
        stops: [
          ColorStop(0, "rgba(45, 82, 111, 0.52)"),
          ColorStop(1, "rgba(45, 82, 111, 0)"),
        ]),
    ],
    foreground: "#fffaf0",
    muted: "rgba(255, 250, 240, 0.76)",
    border: "rgba(255, 250, 240, 0.58)",
    accent: "#f2d28f",
    grain: "rgba(88, 54, 42, 0.12)")
}
