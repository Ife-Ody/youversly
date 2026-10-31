import Foundation
import Observation
import UIKit

/// Persisted editor settings. Same key and shape as the web app's localStorage entry.
nonisolated struct SavedEditorState: Codable, Hashable, Sendable {
  var reference: String?
  var version: BibleVersionKey?
  var title: String?
  var templateId: PosterTemplateID?
  var aspect: PosterAspect?
  var verseFontSize: Int?
  var verseFontScale: Double?
  var signature: String?

  static let storageKey = "youversly.editor-state.v1"
}

@Observable
final class EditorModel {
  var reference: String { didSet { persist() } }
  var version: BibleVersionKey { didSet { persist() } }
  var title: String { didSet { persist() } }
  var templateID: PosterTemplateID { didSet { persist() } }
  var aspect: PosterAspect { didSet { persist() } }
  var verseFontSize: Int { didSet { persist() } }
  var signature: String { didSet { persist() } }

  private(set) var passage: ResolvedPassage?
  private(set) var errorMessage = ""
  private(set) var isLoading = false
  private(set) var poster: UIImage?

  let defaultTitle: String
  private let library: BibleLibrary
  private let defaults: UserDefaults
  private var isRestoring = true

  init(library: BibleLibrary = BibleLibrary(), defaults: UserDefaults = .standard, now: Date = .now) {
    self.library = library
    self.defaults = defaults
    defaultTitle = Self.posterDate(now)

    let saved = Self.readSavedState(from: defaults)
    reference = saved?.reference ?? "Psalm 42:1-2"
    version = saved?.version ?? .kjv
    title = saved?.title ?? defaultTitle
    templateID = saved?.templateId ?? .garden
    aspect = saved?.aspect ?? .square
    signature = saved?.signature ?? "Youversly"
    verseFontSize =
      if let size = saved?.verseFontSize {
        TextLayout.normalizeVerseFontSize(Double(size))
      } else if let scale = saved?.verseFontScale {
        TextLayout.verseFontSize(fromScale: scale)
      } else {
        TextLayout.defaultVerseFontSize
      }
    isRestoring = false
  }

  // MARK: - Derived state

  /// Changing any of these should re-resolve the passage.
  struct LookupKey: Hashable {
    var reference: String
    var version: BibleVersionKey
  }

  var lookupKey: LookupKey { LookupKey(reference: reference, version: version) }

  /// Changing any of these should re-render the poster.
  var payload: PosterPayload? {
    guard let passage else { return nil }
    return PosterPayload(
      reference: passage.displayReference,
      verses: passage.verses,
      title: title.isEmpty ? defaultTitle : title,
      signature: signature.isEmpty ? "Youversly" : signature,
      templateID: templateID,
      aspect: aspect,
      verseFontSize: verseFontSize)
  }

  var statusText: String {
    if let passage {
      let count = passage.verses.count
      return "\(passage.displayReference) · \(count) verse\(count == 1 ? "" : "s")"
    }
    return isLoading ? "Resolving passage…" : "Enter a valid passage to render."
  }

  var exportFileName: String {
    guard let passage else { return "youversly.png" }
    return "\(Self.slugify(passage.displayReference))-\(version.rawValue).png"
  }

  // MARK: - Actions

  /// Debounced lookup; cancel the task to abandon it (SwiftUI's `.task(id:)` does this).
  func resolvePassage() async {
    do {
      try await Task.sleep(for: .milliseconds(220))
    } catch {
      return
    }

    isLoading = true
    defer { isLoading = false }

    do {
      let resolved = try await library.resolve(reference: reference, version: version)
      guard !Task.isCancelled else { return }
      passage = resolved
      errorMessage = ""
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      passage = nil
      errorMessage =
        (error as? PassageResolutionError)?.message ?? "Unable to resolve that passage."
    }
  }

  func renderPoster() {
    poster = payload.map(PosterRenderer.render)
  }

  // MARK: - Persistence

  private func persist() {
    guard !isRestoring else { return }
    let state = SavedEditorState(
      reference: reference, version: version, title: title, templateId: templateID,
      aspect: aspect, verseFontSize: verseFontSize, signature: signature)
    if let data = try? JSONEncoder().encode(state) {
      defaults.set(data, forKey: SavedEditorState.storageKey)
    }
  }

  private static func readSavedState(from defaults: UserDefaults) -> SavedEditorState? {
    guard let data = defaults.data(forKey: SavedEditorState.storageKey) else { return nil }
    return try? JSONDecoder().decode(SavedEditorState.self, from: data)
  }

  // MARK: - Formatting

  /// "31st October 2026", matching `formatPosterDate` on the web.
  static func posterDate(_ date: Date) -> String {
    let calendar = Calendar(identifier: .gregorian)
    let day = calendar.component(.day, from: date)
    let suffix =
      switch (day % 10, day) {
      case (1, let d) where d != 11: "st"
      case (2, let d) where d != 12: "nd"
      case (3, let d) where d != 13: "rd"
      default: "th"
      }

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_GB")
    formatter.calendar = calendar
    formatter.dateFormat = "MMMM yyyy"
    return "\(day)\(suffix) \(formatter.string(from: date))"
  }

  static func slugify(_ value: String) -> String {
    value.lowercased()
      .replacing(regex: #"[^a-z0-9]+"#, with: "-")
      .replacing(regex: #"^-|-$"#, with: "")
  }
}
