import SwiftUI

/// Small preview of a template's background, drawn with the real renderer.
struct TemplateSwatch: View {
  var template: PosterTemplate

  var body: some View {
    Canvas { graphics, size in
      graphics.withCGContext { context in
        PosterRenderer.drawBackground(
          in: context, width: size.width, height: size.height, template: template)
      }
    }
  }
}
