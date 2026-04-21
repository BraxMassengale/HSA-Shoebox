import SwiftUI
import VisionKit

@MainActor
struct ReceiptScanner: UIViewControllerRepresentable {
    let onComplete: @MainActor (Result<[UIImage], Error>) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onComplete: @MainActor @Sendable (Result<[UIImage], Error>) -> Void

        init(onComplete: @escaping @MainActor @Sendable (Result<[UIImage], Error>) -> Void) {
            self.onComplete = onComplete
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            let onComplete = self.onComplete
            Task { @MainActor in
                onComplete(.failure(CancellationError()))
            }
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            let onComplete = self.onComplete
            Task { @MainActor in
                onComplete(.failure(error))
            }
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            let onComplete = self.onComplete
            Task { @MainActor in
                onComplete(.success(images))
            }
        }
    }
}
