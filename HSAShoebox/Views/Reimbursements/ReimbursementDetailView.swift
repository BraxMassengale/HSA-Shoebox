import SwiftUI

struct ReimbursementDetailView: View {
    let reimbursement: Reimbursement

    @State private var exportURL: URL?

    var body: some View {
        List {
            Section(Strings.Bundle.total) {
                LabeledContent(Strings.Bundle.reimbursementDate, value: Formatters.dateString(for: reimbursement.reimbursedDate))
                CurrencyAmountText(
                    amount: reimbursement.totalAmount,
                    currencyCode: reimbursement.receipts.first?.currencyCode ?? "USD",
                    font: .title3.bold()
                )
                if reimbursement.note.isEmpty == false {
                    Text(reimbursement.note)
                        .foregroundStyle(.secondary)
                }
            }

            Section(Strings.Bundle.receipts) {
                ForEach(reimbursement.receipts) { receipt in
                    ReceiptRowView(receipt: receipt)
                }
            }
        }
        .navigationTitle(Strings.Bundle.bundleTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label(Strings.Bundle.exportPDF, systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        do {
                            exportURL = try PDFExportService().export(reimbursement: reimbursement)
                        } catch {
                            exportURL = nil
                        }
                    } label: {
                        Label(Strings.Bundle.exportPDF, systemImage: "doc.richtext")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReimbursementDetailView(reimbursement: PreviewData.sampleReimbursement())
    }
    .modelContainer(PreviewData.container)
}
