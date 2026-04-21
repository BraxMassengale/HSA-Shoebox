import Foundation
import Testing
@testable import HSAShoebox

struct ReimbursementTests {
    @Test
    func totalAmountSumsReceiptAmounts() {
        let reimbursement = Reimbursement(reimbursedDate: .now)
        reimbursement.receipts = [
            Receipt(merchant: "A", dateOfService: .now, amount: 12.34, category: .doctor, pageImages: [Data()]),
            Receipt(merchant: "B", dateOfService: .now, amount: 45.66, category: .pharmacy, pageImages: [Data()])
        ]

        #expect(reimbursement.totalAmount == Decimal(string: "58.00"))
    }
}
