import Foundation
import SwiftData

@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
        let container = try! ModelContainer(
            for: Receipt.self,
            Reimbursement.self,
            configurations: configuration
        )

        let context = container.mainContext
        let reimbursement = sampleReimbursement()
        let receipts = sampleReceipts(reimbursement: reimbursement)
        context.insert(reimbursement)
        receipts.forEach(context.insert)
        try! context.save()

        return container
    }()

    static func sampleReceipts(reimbursement: Reimbursement? = nil) -> [Receipt] {
        let reimbursedReceipt = Receipt(
            merchant: "Bright Dental",
            dateOfService: Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now,
            amount: 128.44,
            category: .dental,
            notes: "Cleaning and x-rays",
            pageImages: [sampleImageData()],
            reimbursement: reimbursement
        )

        let pendingReceipt = Receipt(
            merchant: "Mercy Clinic",
            dateOfService: Calendar.current.date(byAdding: .day, value: -18, to: .now) ?? .now,
            amount: 84.12,
            category: .doctor,
            notes: "Office copay",
            pageImages: [sampleImageData()]
        )

        let pharmacyReceipt = Receipt(
            merchant: "Care Pharmacy",
            dateOfService: Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now,
            amount: 26.79,
            category: .pharmacy,
            notes: "Prescription refill",
            pageImages: [sampleImageData()]
        )

        reimbursement?.receipts = [reimbursedReceipt]

        return [pendingReceipt, pharmacyReceipt, reimbursedReceipt]
    }

    static func sampleReimbursement() -> Reimbursement {
        let reimbursement = Reimbursement(reimbursedDate: .now, note: "Annual reimbursement")
        let receipt = Receipt(
            merchant: "Eye Center",
            dateOfService: Calendar.current.date(byAdding: .day, value: -40, to: .now) ?? .now,
            amount: 212.50,
            category: .vision,
            pageImages: [sampleImageData()],
            reimbursement: reimbursement
        )
        reimbursement.receipts = [receipt]
        return reimbursement
    }

    static func sampleDraft() -> ReceiptDraft {
        ReceiptDraft(
            merchant: "City Hospital Lab",
            dateOfService: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
            amount: 42.00,
            currencyCode: "USD",
            category: .labWork,
            notes: "Bloodwork",
            pageImages: [sampleImageData()]
        )
    }

    static func sampleImageData() -> Data {
        let base64 = """
        iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WlM5CwAAAAASUVORK5CYII=
        """

        return Data(base64Encoded: base64) ?? Data()
    }
}
