import Foundation

struct DataExportService: Sendable {
    private let zipWriter = ZipArchiveWriter()

    func export(receipts: [Receipt], reimbursements: [Reimbursement]) throws -> URL {
        let records = receipts.sorted(by: { $0.dateOfService < $1.dateOfService }).map(ExportReceiptRecord.init)
        let bundles = reimbursements.sorted(by: { $0.reimbursedDate < $1.reimbursedDate }).map(ExportReimbursementRecord.init)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let payload = ExportPayload(receipts: records, reimbursements: bundles)
        let jsonData = try encoder.encode(payload)
        let csvData = CSVWriter().makeCSV(for: records)

        var entries: [ZipArchiveWriter.ArchiveEntry] = [
            .init(path: "receipts.json", data: jsonData),
            .init(path: "receipts.csv", data: csvData)
        ]

        for receipt in receipts {
            for (pageIndex, imageData) in receipt.pageImages.enumerated() {
                entries.append(
                    .init(
                        path: "images/\(receipt.id.uuidString)_\(pageIndex + 1).jpg",
                        data: imageData
                    )
                )
            }
        }

        let destination = FileManager.default.temporaryDirectory
            .appending(path: "shoebox-export-\(UUID().uuidString).zip")
        try zipWriter.writeArchive(entries: entries, to: destination)

        return destination
    }
}

private struct ExportPayload: Codable, Sendable {
    var receipts: [ExportReceiptRecord]
    var reimbursements: [ExportReimbursementRecord]
}

private struct ExportReceiptRecord: Codable, Sendable {
    var id: UUID
    var merchant: String
    var date: Date
    var amount: Decimal
    var currencyCode: String
    var category: String
    var reimbursed: Bool
    var reimbursedDate: Date?
    var reimbursementID: UUID?
    var notes: String
    var paymentMethod: String?
    var imageFiles: [String]

    init(_ receipt: Receipt) {
        id = receipt.id
        merchant = receipt.merchant
        date = receipt.dateOfService
        amount = receipt.amount
        currencyCode = receipt.currencyCode
        category = receipt.category
        reimbursed = receipt.reimbursement != nil
        reimbursedDate = receipt.reimbursement?.reimbursedDate
        reimbursementID = receipt.reimbursement?.id
        notes = receipt.notes
        paymentMethod = receipt.paymentMethod
        imageFiles = receipt.pageImages.indices.map { "\(receipt.id.uuidString)_\($0 + 1).jpg" }
    }
}

private struct ExportReimbursementRecord: Codable, Sendable {
    var id: UUID
    var reimbursedDate: Date
    var note: String
    var receiptIDs: [UUID]
    var totalAmount: Decimal

    init(_ reimbursement: Reimbursement) {
        id = reimbursement.id
        reimbursedDate = reimbursement.reimbursedDate
        note = reimbursement.note
        receiptIDs = reimbursement.receipts.map(\.id)
        totalAmount = reimbursement.totalAmount
    }
}

private struct CSVWriter {
    func makeCSV(for records: [ExportReceiptRecord]) -> Data {
        let rows = records.map { record in
            [
                record.id.uuidString,
                record.merchant,
                ISO8601DateFormatter().string(from: record.date),
                NSDecimalNumber(decimal: record.amount).stringValue,
                record.category,
                record.reimbursed.description,
                record.reimbursedDate.map { ISO8601DateFormatter().string(from: $0) } ?? "",
                record.notes
            ].map(escape).joined(separator: ",")
        }

        let header = "id,merchant,date,amount,category,reimbursed,reimbursedDate,notes"
        let body = ([header] + rows).joined(separator: "\n")
        return Data(body.utf8)
    }

    private func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
