import Foundation

struct ReceiptDraft: Identifiable, Codable, Sendable {
    var id: UUID
    var merchant: String
    var dateOfService: Date
    var amount: Decimal
    var currencyCode: String
    var category: ExpenseCategory
    var notes: String
    var paymentMethod: String?
    var pageImages: [Data]

    init(
        id: UUID = UUID(),
        merchant: String = "",
        dateOfService: Date = .now,
        amount: Decimal = 0,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        category: ExpenseCategory = .other,
        notes: String = "",
        paymentMethod: String? = nil,
        pageImages: [Data] = []
    ) {
        self.id = id
        self.merchant = merchant
        self.dateOfService = dateOfService
        self.amount = amount
        self.currencyCode = currencyCode
        self.category = category
        self.notes = notes
        self.paymentMethod = paymentMethod
        self.pageImages = pageImages
    }
}
