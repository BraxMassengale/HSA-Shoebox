import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ScanViewModel {
    var draft: ReceiptDraft?
    var isProcessing = false
    var errorMessage: String?

    private let ocrService: OCRService
    private let parser: OCRParser

    init(ocrService: OCRService = OCRService(), parser: OCRParser = OCRParser()) {
        self.ocrService = ocrService
        self.parser = parser
    }

    func process(
        scannedImages: [UIImage],
        defaultCurrencyCode: String,
        defaultCategory: ExpenseCategory
    ) async {
        errorMessage = nil
        draft = nil
        isProcessing = true

        let jpegImages = scannedImages.compactMap { $0.jpegData(compressionQuality: 0.85) }

        guard jpegImages.isEmpty == false else {
            errorMessage = Strings.Scan.scanFailed
            isProcessing = false
            return
        }

        let recognizedText = await ocrService.recognizeText(in: jpegImages)
        let parsed = parser.parse(lines: recognizedText.combinedLines)

        draft = ReceiptDraft(
            merchant: parsed.merchant,
            dateOfService: parsed.dateOfService ?? .now,
            amount: parsed.amount ?? 0,
            currencyCode: defaultCurrencyCode,
            category: defaultCategory,
            notes: recognizedText.combinedLines.joined(separator: "\n"),
            pageImages: jpegImages
        )
        isProcessing = false
    }

    func handle(error: Error) {
        if error is CancellationError {
            errorMessage = nil
        } else {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        draft = nil
        isProcessing = false
        errorMessage = nil
    }
}
