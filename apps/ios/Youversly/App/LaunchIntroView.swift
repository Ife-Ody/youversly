import SwiftUI

/// Full-screen launch intro: the book mark starts shut on the brand orange
/// (matching the static launch screen), swings open, then the whole layer
/// fades out to reveal the editor already rendered beneath it.
///
/// Runs once per cold launch, so it sits in the "rare" tier: a short spring
/// is allowed, but the whole thing is over in about a second and a tap skips it.
struct LaunchIntroView: View {
  var onFinished: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var leftOpenness: Double = 0
  @State private var rightOpenness: Double = 0
  @State private var isLeaving = false
  @State private var hasFinished = false

  var body: some View {
    ZStack {
      BookMark.orange
      BookMarkView(leftOpenness: leftOpenness, rightOpenness: rightOpenness)
        .containerRelativeFrame(.horizontal) { width, _ in min(width * 0.56, 300) }
        .scaleEffect(isLeaving && !reduceMotion ? 1.06 : 1)
    }
    .ignoresSafeArea()
    .opacity(isLeaving ? 0 : 1)
    .contentShape(Rectangle())
    .onTapGesture { leave() }
    .accessibilityHidden(true)
    .task { await run() }
  }

  private func run() async {
    if reduceMotion {
      // Motion off: show the finished mark, pause, fade.
      leftOpenness = 1
      rightOpenness = 1
      try? await Task.sleep(for: .milliseconds(500))
      leave()
      return
    }

    try? await Task.sleep(for: .milliseconds(120))
    guard !isLeaving else { return }
    withAnimation(Self.open) { leftOpenness = 1 }
    try? await Task.sleep(for: .milliseconds(90))
    withAnimation(Self.open) { rightOpenness = 1 }
    // Let the spring settle and the open mark register before leaving.
    try? await Task.sleep(for: .milliseconds(780))
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

  /// Pages feel hinged and physical; a little settle, no visible bounce.
  private static let open = Animation.spring(response: 0.6, dampingFraction: 0.82)
  /// Strong ease-out, so the editor is readable almost immediately.
  private static let exit = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.32)
  private static let fade = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.25)
}

#Preview {
  LaunchIntroView {}
}
