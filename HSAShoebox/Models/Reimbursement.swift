import Foundation
import SwiftData

@Model
final class Reimbursement {
    #Unique<Reimbursement>([\.id])

    var id: UUID
    var reimbursedDate: Date
    var note: String
    var createdAt: Date
    @Relationship var receipts: [Receipt] = []

    init(
        id: UUID = UUID(),
        reimbursedDate: Date,
        note: String = "",
        createdAt: Date = .now,
        receipts: [Receipt] = []
    ) {
        self.id = id
        self.reimbursedDate = reimbursedDate
        self.note = note
        self.createdAt = createdAt
        self.receipts = receipts
    }

    var totalAmount: Decimal {
        receipts.reduce(0) { $0 + $1.amount }
    }
}
