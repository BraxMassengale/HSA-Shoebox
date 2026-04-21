import SwiftUI

struct ReimbursementComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let receipts: [Receipt]
    let onComplete: @MainActor (Reimbursement) -> Void

    @State private var reimbursedDate = Date.now
    @State private var note = ""

    private var total: Decimal {
        receipts.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(Strings.Bundle.total) {
                    CurrencyAmountText(amount: total, currencyCode: receipts.first?.currencyCode ?? "USD", font: .title3.bold())
                }

                Section {
                    DatePicker(Strings.Bundle.reimbursementDate, selection: $reimbursedDate, displayedComponents: .date)
                    TextField(Strings.Bundle.note, text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section(Strings.Bundle.receipts) {
                    ForEach(receipts) { receipt in
                        ReceiptRowView(receipt: receipt)
                    }
                }
            }
            .navigationTitle(Strings.Bundle.composerTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.ReceiptList.cancel) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Bundle.save) {
                        do {
                            let reimbursement = try ReceiptActions.reimburse(
                                receipts: receipts,
                                on: reimbursedDate,
                                note: note,
                                in: modelContext
                            )
                            Haptics.success()
                            onComplete(reimbursement)
                            dismiss()
                        } catch {
                            note = "\(note)\n\(error.localizedDescription)"
                        }
                    }
                }
            }
        }
        .presentationBackground(.regularMaterial)
    }
}

#Preview {
    ReimbursementComposerView(receipts: PreviewData.sampleReceipts()) { _ in }
        .modelContainer(PreviewData.container)
}
