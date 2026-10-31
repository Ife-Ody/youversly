import SwiftUI

@main
struct YouverslyApp: App {
  @State private var isShowingIntro = true

  var body: some Scene {
    WindowGroup {
      ZStack {
        EditorView()
        if isShowingIntro {
          LaunchIntroView { isShowingIntro = false }
            .zIndex(1)
        }
      }
    }
  }
}
