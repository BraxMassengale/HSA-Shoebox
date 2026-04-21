import Foundation
import SwiftData

@MainActor
enum ReceiptActions {
    static func insertReceipt(from draft: ReceiptDraft, in context: ModelContext) throws {
        let receipt = Receipt(
            id: draft.id,
            merchant: draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfService: Calendar.current.startOfDay(for: draft.dateOfService),
            amount: draft.amount,
            currencyCode: draft.currencyCode,
            category: draft.category,
            notes: draft.notes,
            paymentMethod: draft.paymentMethod,
            pageImages: draft.pageImages,
            createdAt: .now,
            updatedAt: .now
        )
        context.insert(receipt)
        try context.save()
    }

    static func update(_ receipt: Receipt, from draft: ReceiptDraft, in context: ModelContext) throws {
        receipt.merchant = draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        receipt.dateOfService = Calendar.current.startOfDay(for: draft.dateOfService)
        receipt.amount = draft.amount
        receipt.currencyCode = draft.currencyCode
        receipt.categoryEnum = draft.category
        receipt.notes = draft.notes
        receipt.paymentMethod = draft.paymentMethod
        receipt.pageImages = draft.pageImages
        receipt.updatedAt = .now

        try context.save()
    }

    @discardableResult
    static func reimburse(
        receipts: [Receipt],
        on reimbursedDate: Date,
        note: String,
        in context: ModelContext
    ) throws -> Reimbursement {
        let reimbursement = Reimbursement(
            reimbursedDate: Calendar.current.startOfDay(for: reimbursedDate),
            note: note
        )

        context.insert(reimbursement)

        for receipt in receipts {
            receipt.reimbursement = reimbursement
            receipt.updatedAt = .now
        }

        reimbursement.receipts = receipts
        try context.save()

        return reimbursement
    }

    static func delete(_ receipt: Receipt, in context: ModelContext) throws {
        let reimbursement = receipt.reimbursement
        reimbursement?.receipts.removeAll { $0.id == receipt.id }
        context.delete(receipt)

        if let reimbursement, reimbursement.receipts.isEmpty {
            context.delete(reimbursement)
        }

        try context.save()
    }
}
