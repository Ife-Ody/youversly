import CoreTransferable
import Foundation

/// A rendered poster as a PNG file, for the share sheet.
nonisolated struct PosterFile: Transferable, Sendable {
  var data: Data
  var fileName: String

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .png) { file in file.data }
      .suggestedFileName { file in file.fileName }
  }
}
