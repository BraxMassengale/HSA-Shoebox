import Foundation
import SwiftData

@Model
final class Receipt {
    #Unique<Receipt>([\.id])

    var id: UUID
    var merchant: String
    var dateOfService: Date
    var amount: Decimal
    var currencyCode: String
    var category: ExpenseCategory.RawValue
    var notes: String
    var paymentMethod: String?
    @Attribute(.externalStorage) var pageImages: [Data]
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .nullify, inverse: \Reimbursement.receipts)
    var reimbursement: Reimbursement?

    init(
        id: UUID = UUID(),
        merchant: String,
        dateOfService: Date,
        amount: Decimal,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        category: ExpenseCategory,
        notes: String = "",
        paymentMethod: String? = nil,
        pageImages: [Data],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        reimbursement: Reimbursement? = nil
    ) {
        self.id = id
        self.merchant = merchant
        self.dateOfService = dateOfService
        self.amount = amount
        self.currencyCode = currencyCode
        self.category = category.rawValue
        self.notes = notes
        self.paymentMethod = paymentMethod
        self.pageImages = pageImages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reimbursement = reimbursement
    }

    var categoryEnum: ExpenseCategory {
        get { ExpenseCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }

    var isReimbursed: Bool {
        reimbursement != nil
    }
}
