import Foundation
import ImageIO
import Vision

struct RecognizedReceiptText: Sendable {
    var pageLines: [[String]]

    var combinedLines: [String] {
        pageLines.flatMap { $0 }
    }
}

struct OCRService: Sendable {
    func recognizeText(in pageImages: [Data]) async -> RecognizedReceiptText {
        await withTaskGroup(of: (Int, [String]).self, returning: RecognizedReceiptText.self) { group in
            for (index, data) in pageImages.enumerated() {
                group.addTask {
                    let lines = Self.recognizeSynchronously(in: data)
                    return (index, lines)
                }
            }

            var pages = Array(repeating: [String](), count: pageImages.count)
            for await (index, lines) in group {
                pages[index] = lines
            }

            return RecognizedReceiptText(pageLines: pages)
        }
    }

    private static func recognizeSynchronously(in imageData: Data) -> [String] {
        guard
            let source = CGImageSourceCreateWithData(imageData as CFData, nil),
            let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return []
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
            return request.results?
                .compactMap { $0.topCandidates(1).first?.string }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false } ?? []
        } catch {
            return []
        }
    }
}
