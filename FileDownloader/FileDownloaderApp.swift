//import SwiftUI
//import Photos
//
//class FileDownloader: ObservableObject {
//    @Published var downloadProgress: Float = 0
//    @Published var isDownloading = false
//    @Published var downloadComplete = false
//    @Published var downloadedFilePath = ""
//    @Published var errorMessage = ""
//
//    func downloadFile(from urlString: String) {
//        downloadProgress = 0
//        downloadComplete = false
//        errorMessage = ""
//
//        guard let url = URL(string: urlString) else {
//            errorMessage = "Invalid URL"
//            return
//        }
//
//        isDownloading = true
//
//        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
//            DispatchQueue.main.async {
//                self.isDownloading = false
//            }
//
//            if let error = error {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Download failed: \(error.localizedDescription)"
//                }
//                return
//            }
//
//            guard let localURL = localURL else {
//                DispatchQueue.main.async {
//                    self.errorMessage = "Download failed: No file found"
//                }
//                return
//            }
//
//            self.saveFile(from: localURL, originalURL: url)
//        }
//
//        task.progress.observe(\.fractionCompleted) { progress, _ in
//            DispatchQueue.main.async {
//                self.downloadProgress = Float(progress.fractionCompleted)
//            }
//        }
//
//        task.resume()
//    }
//
//    private func saveFile(from localURL: URL, originalURL: URL) {
//        let fileExtension = originalURL.pathExtension.lowercased()
//
//        switch fileExtension {
//        case "jpg", "jpeg", "png", "gif":
//            saveImageToGallery(from: localURL)
//        case "mp4", "mov", "avi":
//            saveVideoToGallery(from: localURL)
//        default:
//            saveDocument(from: localURL, originalURL: originalURL)
//        }
//    }
//
//    private func saveImageToGallery(from localURL: URL) {
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: localURL)
//        }) { success, error in
//            DispatchQueue.main.async {
//                if success {
//                    self.downloadComplete = true
//                    self.downloadedFilePath = "Saved to Gallery"
//                } else if let error = error {
//                    self.errorMessage = "Couldn't save image: \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//
//    private func saveVideoToGallery(from localURL: URL) {
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
//        }) { success, error in
//            DispatchQueue.main.async {
//                if success {
//                    self.downloadComplete = true
//                    self.downloadedFilePath = "Saved to Gallery"
//                } else if let error = error {
//                    self.errorMessage = "Couldn't save video: \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//
//    private func saveDocument(from localURL: URL, originalURL: URL) {
//        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        let fileName = originalURL.lastPathComponent
//        let destinationURL = documentsPath.appendingPathComponent(fileName)
//
//        do {
//            if FileManager.default.fileExists(atPath: destinationURL.path) {
//                try FileManager.default.removeItem(at: destinationURL)
//            }
//
//            try FileManager.default.moveItem(at: localURL, to: destinationURL)
//
//            DispatchQueue.main.async {
//                self.downloadComplete = true
//                self.downloadedFilePath = destinationURL.path
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.errorMessage = "Couldn't save file: \(error.localizedDescription)"
//            }
//        }
//    }
//}
//
