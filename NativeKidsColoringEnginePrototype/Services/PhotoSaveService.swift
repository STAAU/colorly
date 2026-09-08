import Foundation
import Photos

enum PhotoSaveError: Error, Sendable {
    case permissionDenied
    case permissionRestricted
    case writeFailed
}

actor PhotoSaveService {
    func savePNG(_ data: Data) async throws {
        let status = await requestAddOnlyAuthorization()
        switch status {
        case .authorized, .limited:
            break
        case .denied:
            throw PhotoSaveError.permissionDenied
        case .restricted:
            throw PhotoSaveError.permissionRestricted
        case .notDetermined:
            throw PhotoSaveError.writeFailed
        @unknown default:
            throw PhotoSaveError.writeFailed
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                let options = PHAssetResourceCreationOptions()
                options.uniformTypeIdentifier = "public.png"
                request.addResource(with: .photo, data: data, options: options)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoSaveError.writeFailed)
                }
            }
        }
    }

    private func requestAddOnlyAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
