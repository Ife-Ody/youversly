import Photos
import UIKit

nonisolated enum PhotoSaverError: Error, LocalizedError {
  case notAuthorized

  var errorDescription: String? {
    switch self {
    case .notAuthorized:
      "Allow Youversly to add to your photo library in Settings to save posters."
    }
  }
}

enum PhotoSaver {
  static func save(_ image: UIImage) async throws {
    let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    guard status == .authorized || status == .limited else {
      throw PhotoSaverError.notAuthorized
    }
    try await PHPhotoLibrary.shared().performChanges {
      PHAssetChangeRequest.creationRequestForAsset(from: image)
    }
  }
}
