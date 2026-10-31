import SwiftUI

/// The Youversly mark: a solid open book with a thin spine.
/// Geometry mirrors `packages/brand/logo.svg` (mark bounds 688 × 187 after
/// trimming the 1024 canvas); keep the two in sync.
nonisolated enum BookMark {
  static let orange = Color(red: 1, green: 0.647, blue: 0)
  static let aspectRatio: CGFloat = 688 / 187

  /// Horizontal position of each page's spine-side edge, as a fraction of the mark's width.
  static let leftHinge: CGFloat = 328 / 688
  static let rightHinge: CGFloat = 360 / 688

  enum Side {
    case left, right
  }
}

/// One page of the open book, drawn into the full mark frame so both pages
/// and the spine can be stacked without any manual positioning.
nonisolated struct BookPage: Shape {
  let side: BookMark.Side

  func path(in rect: CGRect) -> Path {
    let s = rect.width / 688
    // Mirror the right page across the mark's centre line.
    let flip: (CGFloat) -> CGFloat = side == .left ? { $0 } : { 688 - $0 }
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: rect.minX + flip(x) * s, y: rect.minY + y * s)
    }

    var path = Path()
    path.move(to: p(328, 71))
    path.addCurve(to: p(72, 6), control1: p(268, 31), control2: p(172, 0))
    path.addCurve(to: p(8, 19), control1: p(44, 8), control2: p(20, 14))
    path.addQuadCurve(to: p(0, 31), control: p(0, 22))
    path.addLine(to: p(0, 86))
    path.addQuadCurve(to: p(10, 93), control: p(0, 96))
    path.addCurve(to: p(252, 90), control1: p(72, 76), control2: p(172, 72))
    path.addCurve(to: p(328, 171), control1: p(292, 100), control2: p(318, 129))
    path.closeSubpath()
    return path
  }
}

nonisolated struct BookSpine: Shape {
  func path(in rect: CGRect) -> Path {
    let s = rect.width / 688
    let spine = CGRect(x: rect.minX + 332 * s, y: rect.minY + 57 * s, width: 24 * s, height: 130 * s)
    return Path(roundedRect: spine, cornerRadius: 12 * s)
  }
}

/// The complete mark. `openness` runs from 0 (pages folded shut against the
/// spine, seen edge-on) to 1 (fully open, the static logo).
struct BookMarkView: View {
  var leftOpenness: Double = 1
  var rightOpenness: Double = 1
  var color: Color = .black

  init(openness: Double = 1, color: Color = .black) {
    leftOpenness = openness
    rightOpenness = openness
    self.color = color
  }

  init(leftOpenness: Double, rightOpenness: Double, color: Color = .black) {
    self.leftOpenness = leftOpenness
    self.rightOpenness = rightOpenness
    self.color = color
  }

  var body: some View {
    ZStack {
      BookPage(side: .left)
        .fill(color)
        .rotation3DEffect(
          .degrees(Self.closedAngle * (1 - leftOpenness)),
          axis: (x: 0, y: 1, z: 0),
          anchor: UnitPoint(x: BookMark.leftHinge, y: 0.5),
          perspective: 0.35
        )
      BookPage(side: .right)
        .fill(color)
        .rotation3DEffect(
          .degrees(-Self.closedAngle * (1 - rightOpenness)),
          axis: (x: 0, y: 1, z: 0),
          anchor: UnitPoint(x: BookMark.rightHinge, y: 0.5),
          perspective: 0.35
        )
      BookSpine()
        .fill(color)
    }
    .aspectRatio(BookMark.aspectRatio, contentMode: .fit)
  }

  /// Just short of edge-on, so a closed book still shows a sliver of page.
  private static let closedAngle: Double = 84
}

#Preview("Open") {
  BookMarkView()
    .frame(width: 240)
    .padding(40)
    .background(BookMark.orange)
}

#Preview("Closed") {
  BookMarkView(openness: 0)
    .frame(width: 240)
    .padding(40)
    .background(BookMark.orange)
}
