import SwiftUI

struct EditorView: View {
  @State private var model = EditorModel()
  @State private var saveMessage: String?
  @State private var isSaving = false

  var body: some View {
    NavigationStack {
      Form {
        previewSection
        verseSection
        layoutSection
        templateSection
      }
      .navigationTitle("Youversly")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { toolbarContent }
      .task(id: model.lookupKey) { await model.resolvePassage() }
      .onChange(of: model.payload, initial: true) { model.renderPoster() }
      .alert(
        "Save to Photos", isPresented: Binding(
          get: { saveMessage != nil }, set: { if !$0 { saveMessage = nil } })
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(saveMessage ?? "")
      }
    }
  }

  // MARK: - Sections

  private var previewSection: some View {
    Section {
      VStack(spacing: 12) {
        ZStack {
          if let poster = model.poster {
            Image(uiImage: poster)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
              .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
          } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .fill(.quaternary)
              .aspectRatio(
                model.aspect.size.width / model.aspect.size.height, contentMode: .fit)
              .overlay {
                if model.isLoading {
                  ProgressView()
                } else {
                  Image(systemName: "book.closed")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                }
              }
          }
        }
        .frame(maxWidth: 520)
        .animation(.default, value: model.aspect)

        HStack {
          Text(model.statusText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
          Spacer()
          Text("\(Int(model.aspect.size.width)) × \(Int(model.aspect.size.height))")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.tertiary)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
      .listRowBackground(Color.clear)
    }
  }

  private var verseSection: some View {
    Section {
      LabeledContent("Title") {
        TextField(model.defaultTitle, text: $model.title)
          .multilineTextAlignment(.trailing)
      }

      VStack(alignment: .leading, spacing: 4) {
        LabeledContent("Reference") {
          TextField("John 1:1 or John 1:1-3", text: $model.reference)
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
        }
        if !model.errorMessage.isEmpty {
          Text(model.errorMessage)
            .font(.footnote)
            .foregroundStyle(.red)
        }
      }

      Picker("Version", selection: $model.version) {
        ForEach(BibleVersionKey.allCases) { version in
          Text(version.label).tag(version)
        }
      }
      .pickerStyle(.segmented)

      LabeledContent("Signature") {
        TextField("Youversly", text: $model.signature)
          .multilineTextAlignment(.trailing)
      }
    } header: {
      Label("Verse", systemImage: "text.book.closed")
    } footer: {
      Text("Ranges and comma-separated verses are read from the reference automatically.")
    }
  }

  private var layoutSection: some View {
    Section {
      Picker("Aspect", selection: $model.aspect) {
        ForEach(PosterAspect.allCases) { aspect in
          Text(aspect.label).tag(aspect)
        }
      }
      .pickerStyle(.segmented)

      VStack(alignment: .leading, spacing: 6) {
        HStack {
          Text("Text size")
          Spacer()
          Text("\(model.verseFontSize)px")
            .font(.footnote.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        Slider(
          value: Binding(
            get: { Double(model.verseFontSize) },
            set: { model.verseFontSize = TextLayout.normalizeVerseFontSize($0) }),
          in: Double(TextLayout.minVerseFontSize)...Double(TextLayout.maxVerseFontSize),
          step: 1)
      }
    } header: {
      Label("Layout", systemImage: "rectangle.portrait")
    } footer: {
      Text("Text size is in poster pixels.")
    }
  }

  private var templateSection: some View {
    Section {
      ForEach(PosterTemplate.all) { template in
        Button {
          model.templateID = template.id
        } label: {
          HStack(spacing: 12) {
            TemplateSwatch(template: template)
              .frame(width: 48, height: 48)
              .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
              .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .strokeBorder(.white.opacity(0.2))
              }
            VStack(alignment: .leading, spacing: 2) {
              Text(template.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
              Text(template.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer()
            if model.templateID == template.id {
              Image(systemName: "checkmark")
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(model.templateID == template.id ? .isSelected : [])
      }
    } header: {
      Label("Template", systemImage: "paintpalette")
    }
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Button {
        Task { await saveToPhotos() }
      } label: {
        if isSaving {
          ProgressView()
        } else {
          Label("Save to Photos", systemImage: "square.and.arrow.down")
        }
      }
      .disabled(model.poster == nil || isSaving)
    }

    ToolbarItem(placement: .topBarTrailing) {
      if let poster = model.poster, let data = poster.pngData() {
        ShareLink(
          item: PosterFile(data: data, fileName: model.exportFileName),
          preview: SharePreview(
            model.passage?.displayReference ?? "Youversly", image: Image(uiImage: poster))
        ) {
          Label("Share", systemImage: "square.and.arrow.up")
        }
      } else {
        Button {} label: { Label("Share", systemImage: "square.and.arrow.up") }
          .disabled(true)
      }
    }
  }

  private func saveToPhotos() async {
    guard let poster = model.poster else { return }
    isSaving = true
    defer { isSaving = false }
    do {
      try await PhotoSaver.save(poster)
      saveMessage = "Saved \(model.passage?.displayReference ?? "poster") to your photo library."
    } catch {
      saveMessage = error.localizedDescription
    }
  }
}

#Preview {
  EditorView()
}
