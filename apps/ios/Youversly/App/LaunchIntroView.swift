import SwiftUI

/// Full-screen launch intro on the brand orange (matching the static launch
/// screen): the book starts shut, an upright slab, then its two halves swing
/// open from the spine into the mark. The layer then fades out to reveal the
/// editor already rendered beneath it.
///
/// Runs once per cold launch, so it sits in the "rare" tier: a short spring
/// with a little settle is allowed, the whole thing is over in about a second,
/// and a tap skips it.
struct LaunchIntroView: View {
  var onFinished: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var openness: Double = 0
  @State private var containerWidth: CGFloat = 0
  @State private var isLeaving = false
  @State private var hasFinished = false
  @State private var releaseCount = 0
  @State private var landCount = 0

  var body: some View {
    ZStack {
      BookMark.orange
      BookMarkView(width: min(containerWidth * 0.62, 320), openness: openness)
        .scaleEffect(isLeaving && !reduceMotion ? 1.06 : 1)
    }
    .ignoresSafeArea()
    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { containerWidth = $0 }
    .opacity(isLeaving ? 0 : 1)
    .contentShape(Rectangle())
    .onTapGesture { leave() }
    .accessibilityHidden(true)
    // The covers let go, then settle onto the surface.
    .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: releaseCount)
    .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.8), trigger: landCount)
    .task { await run() }
  }

  private func run() async {
    if reduceMotion {
      // Motion off: show the finished mark, pause, fade.
      openness = 1
      try? await Task.sleep(for: .milliseconds(500))
      leave()
      return
    }

    // Let the shut book register before it moves.
    try? await Task.sleep(for: .milliseconds(260))
    guard !isLeaving else { return }
    releaseCount += 1
    withAnimation(Self.open) { openness = 1 }
    // The halves hit the surface at the end of the spring's first swing.
    try? await Task.sleep(for: .milliseconds(420))
    guard !isLeaving else { return }
    landCount += 1
    // Let the settle finish and the open mark register before leaving.
    try? await Task.sleep(for: .milliseconds(520))
    leave()
  }

  private func leave() {
    guard !isLeaving else { return }
    withAnimation(reduceMotion ? Self.fade : Self.exit) { isLeaving = true }
    Task {
      try? await Task.sleep(for: .milliseconds(reduceMotion ? 260 : 340))
      guard !hasFinished else { return }
      hasFinished = true
      onFinished()
    }
  }

  /// Covers falling open: fast, with a small settle as they land.
  private static let open = Animation.spring(response: 0.62, dampingFraction: 0.72)
  /// Strong ease-out, so the editor is readable almost immediately.
  private static let exit = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.32)
  private static let fade = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
}

#Preview {
  LaunchIntroView {}
}
