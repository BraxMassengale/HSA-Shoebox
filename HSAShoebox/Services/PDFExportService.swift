import AVFoundation
import Foundation
import UIKit

struct PDFExportService: Sendable {
    func export(reimbursement: Reimbursement) throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appending(path: "bundle-\(reimbursement.id.uuidString).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        try renderer.writePDF(to: destination) { context in
            writeCoverPage(for: reimbursement, context: context)

            for receipt in reimbursement.receipts.sorted(by: { $0.dateOfService < $1.dateOfService }) {
                for (index, pageData) in receipt.pageImages.enumerated() {
                    writeReceiptPage(
                        receipt: receipt,
                        pageData: pageData,
                        pageIndex: index,
                        context: context
                    )
                }
            }
        }

        return destination
    }

    private func writeCoverPage(for reimbursement: Reimbursement, context: UIGraphicsPDFRendererContext) {
        context.beginPage()

        let title = "Reimbursement Bundle"
        let subtitle = """
        Date: \(Formatters.dateString(for: reimbursement.reimbursedDate))
        Total: \(Formatters.currencyString(for: reimbursement.totalAmount, currencyCode: reimbursement.receipts.first?.currencyCode ?? "USD"))
        Receipts: \(reimbursement.receipts.count)
        """

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .largeTitle).bold(),
            .foregroundColor: UIColor.label
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.secondaryLabel
        ]

        title.draw(in: CGRect(x: 44, y: 52, width: 520, height: 60), withAttributes: titleAttributes)
        subtitle.draw(in: CGRect(x: 44, y: 128, width: 520, height: 120), withAttributes: bodyAttributes)

        if reimbursement.note.isEmpty == false {
            reimbursement.note.draw(
                in: CGRect(x: 44, y: 232, width: 520, height: 180),
                withAttributes: bodyAttributes
            )
        }

        var tableTop: CGFloat = 440
        for receipt in reimbursement.receipts.sorted(by: { $0.dateOfService < $1.dateOfService }) {
            let line = "\(receipt.merchant)  •  \(Formatters.dateString(for: receipt.dateOfService))  •  \(Formatters.currencyString(for: receipt.amount, currencyCode: receipt.currencyCode))"
            line.draw(in: CGRect(x: 44, y: tableTop, width: 520, height: 24), withAttributes: bodyAttributes)
            tableTop += 28
        }
    }

    private func writeReceiptPage(
        receipt: Receipt,
        pageData: Data,
        pageIndex: Int,
        context: UIGraphicsPDFRendererContext
    ) {
        context.beginPage()

        let caption = "\(receipt.merchant) • \(Formatters.dateString(for: receipt.dateOfService)) • \(Formatters.currencyString(for: receipt.amount, currencyCode: receipt.currencyCode)) • \(receipt.categoryEnum.displayName) • Page \(pageIndex + 1)"
        caption.draw(
            in: CGRect(x: 28, y: 24, width: 556, height: 44),
            withAttributes: [
                .font: UIFont.preferredFont(forTextStyle: .headline),
                .foregroundColor: UIColor.label
            ]
        )

        guard let image = UIImage(data: pageData) else { return }

        let availableRect = CGRect(x: 28, y: 84, width: 556, height: 680)
        let drawingRect = AVMakeRect(aspectRatio: image.size, insideRect: availableRect)
        image.draw(in: drawingRect)
    }
}

private extension UIFont {
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else {
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
