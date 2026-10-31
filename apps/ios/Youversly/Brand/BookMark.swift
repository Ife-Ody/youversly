import SwiftUI

/// The Youversly mark: a solid open book with a thin spine.
/// Geometry mirrors `packages/brand/logo.svg` (mark bounds 688 × 187 after
/// trimming the 1024 canvas); keep the two in sync.
nonisolated enum BookMark {
  static let orange = Color(red: 1, green: 0.647, blue: 0)
  static let width: CGFloat = 688
  static let height: CGFloat = 187
  static let aspectRatio: CGFloat = width / height

  /// Where each half hinges when the book opens: the top of its spine-side edge.
  static let leftHinge = CGPoint(x: 328, y: 71)
  static let rightHinge = CGPoint(x: 360, y: 71)

  /// Length and thickness of one half when it is folded shut.
  static let closedLength: CGFloat = 328
  static let closedThickness: CGFloat = 100

  enum Side {
    case left, right
  }
}

/// One half of the book, drawn into the full mark frame so the halves and
/// spine stack with no manual positioning.
///
/// `openness` morphs the outline: 0 is a plain slab (the closed cover),
/// 1 is the curved page of the finished mark. The two outlines share one
/// segment structure so every control point can be interpolated.
nonisolated struct BookHalf: Shape {
  let side: BookMark.Side
  var openness: Double = 1

  var animatableData: Double {
    get { openness }
    set { openness = newValue }
  }

  /// Page outline, local to the left half (x grows away from the spine).
  private static let page: [CGPoint] = [
    CGPoint(x: 328, y: 71),                                        // start, at the spine
    CGPoint(x: 268, y: 31), CGPoint(x: 172, y: 0), CGPoint(x: 72, y: 6),    // top edge
    CGPoint(x: 44, y: 8), CGPoint(x: 20, y: 14), CGPoint(x: 8, y: 19),      // toward the corner
    CGPoint(x: 0, y: 22), CGPoint(x: 0, y: 31),                             // rounded corner
    CGPoint(x: 0, y: 86),                                                   // fore-edge
    CGPoint(x: 0, y: 96), CGPoint(x: 10, y: 93),                            // rounded corner
    CGPoint(x: 72, y: 76), CGPoint(x: 172, y: 72), CGPoint(x: 252, y: 90),  // bottom edge
    CGPoint(x: 292, y: 100), CGPoint(x: 318, y: 129), CGPoint(x: 328, y: 171), // into the fold
  ]

  /// The same outline flattened into a 328 × 100 slab with softened outer corners.
  private static let slab: [CGPoint] = [
    CGPoint(x: 328, y: 71),
    CGPoint(x: 268, y: 71), CGPoint(x: 172, y: 71), CGPoint(x: 72, y: 71),
    CGPoint(x: 44, y: 71), CGPoint(x: 20, y: 71), CGPoint(x: 8, y: 71),
    CGPoint(x: 0, y: 71), CGPoint(x: 0, y: 79),
    CGPoint(x: 0, y: 163),
    CGPoint(x: 0, y: 171), CGPoint(x: 8, y: 171),
    CGPoint(x: 72, y: 171), CGPoint(x: 172, y: 171), CGPoint(x: 252, y: 171),
    CGPoint(x: 292, y: 171), CGPoint(x: 318, y: 171), CGPoint(x: 328, y: 171),
  ]

  func path(in rect: CGRect) -> Path {
    let s = rect.width / BookMark.width
    let t = CGFloat(min(max(openness, 0), 1))
    let flip: (CGFloat) -> CGFloat = side == .left ? { $0 } : { BookMark.width - $0 }
    func p(_ i: Int) -> CGPoint {
      let a = Self.slab[i], b = Self.page[i]
      let x = a.x + (b.x - a.x) * t
      let y = a.y + (b.y - a.y) * t
      return CGPoint(x: rect.minX + flip(x) * s, y: rect.minY + y * s)
    }

    var path = Path()
    path.move(to: p(0))
    path.addCurve(to: p(3), control1: p(1), control2: p(2))
    path.addCurve(to: p(6), control1: p(4), control2: p(5))
    path.addQuadCurve(to: p(8), control: p(7))
    path.addLine(to: p(9))
    path.addQuadCurve(to: p(11), control: p(10))
    path.addCurve(to: p(14), control1: p(12), control2: p(13))
    path.addCurve(to: p(17), control1: p(15), control2: p(16))
    path.closeSubpath()
    return path
  }
}

nonisolated struct BookSpine: Shape {
  func path(in rect: CGRect) -> Path {
    let s = rect.width / BookMark.width
    let spine = CGRect(x: rect.minX + 332 * s, y: rect.minY + 57 * s, width: 24 * s, height: 130 * s)
    return Path(roundedRect: spine, cornerRadius: 12 * s)
  }
}

/// The complete mark. `openness` runs from 0 (shut: the two halves stand
/// back to back as one upright slab, spine tucked inside) to 1 (the static logo).
/// Each half swings a quarter turn about the top of the spine, in the plane of
/// the screen, and the spine extends out of the fold as the halves land.
struct BookMarkView: View {
  /// Laid-out width in points; height follows the mark's aspect ratio.
  var width: CGFloat
  var openness: Double = 1
  var color: Color = .black

  var body: some View {
    let closed = 1 - openness
    let unit = width / BookMark.width  // points per mark unit
    let w = BookMark.width, h = BookMark.height
    ZStack {
      BookHalf(side: .left, openness: openness)
        .fill(color)
        .rotationEffect(.degrees(90 * closed), anchor: UnitPoint(x: BookMark.leftHinge.x / w, y: BookMark.leftHinge.y / h))
        .offset(x: Self.spineGap / 2 * closed * unit)
      BookHalf(side: .right, openness: openness)
        .fill(color)
        .rotationEffect(.degrees(-90 * closed), anchor: UnitPoint(x: BookMark.rightHinge.x / w, y: BookMark.rightHinge.y / h))
        .offset(x: -Self.spineGap / 2 * closed * unit)
      BookSpine()
        .fill(color)
        .scaleEffect(x: 1, y: openness, anchor: .top)
    }
    .frame(width: width, height: width / BookMark.aspectRatio)
    // Keep the visual centre still while the shape changes from a tall slab to a wide mark.
    .offset(y: Self.centreShift * closed * unit)
  }

  /// Distance between the two hinge edges; the halves close over it so the shut book is one slab.
  private static let spineGap = BookMark.rightHinge.x - BookMark.leftHinge.x
  /// How far the shut slab's centre sits above the open mark's centre, in mark units.
  private static let centreShift: CGFloat = {
    let shutCentre = BookMark.leftHinge.y - BookMark.closedLength / 2
    let openCentre = BookMark.height / 2
    return openCentre - shutCentre
  }()
}

#Preview("Open") {
  BookMarkView(width: 240)
    .padding(40)
    .background(BookMark.orange)
}

#Preview("Closed") {
  BookMarkView(width: 240, openness: 0)
    .padding(80)
    .background(BookMark.orange)
}
