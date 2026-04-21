import SwiftUI

struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let receipt: Receipt

    @State private var draft: ReceiptDraft
    @State private var showReimbursementSheet = false
    @State private var reimbursedDate = Date.now
    @State private var reimbursementNote = ""

    init(receipt: Receipt) {
        self.receipt = receipt
        _draft = State(initialValue: ReceiptDraft(
            id: receipt.id,
            merchant: receipt.merchant,
            dateOfService: receipt.dateOfService,
            amount: receipt.amount,
            currencyCode: receipt.currencyCode,
            category: receipt.categoryEnum,
            notes: receipt.notes,
            paymentMethod: receipt.paymentMethod,
            pageImages: receipt.pageImages
        ))
    }

    var body: some View {
        Form {
            ReceiptPagePagerView(pageImages: draft.pageImages)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            ReceiptEditorFields(draft: $draft)

            if let reimbursement = receipt.reimbursement {
                Section(Strings.ReceiptDetail.reimbursementBundle) {
                    NavigationLink {
                        ReimbursementDetailView(reimbursement: reimbursement)
                    } label: {
                        LabeledContent("Reimbursed", value: Formatters.dateString(for: reimbursement.reimbursedDate))
                    }
                }
            } else {
                Section {
                    Button {
                        showReimbursementSheet = true
                    } label: {
                        Label(Strings.ReceiptDetail.reimburse, systemImage: "checkmark.circle.fill")
                    }
                    .tint(.green)
                }
            }
        }
        .navigationTitle(receipt.merchant.isEmpty ? Strings.ReceiptDetail.title : receipt.merchant)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Strings.ReceiptDetail.save) {
                    do {
                        try ReceiptActions.update(receipt, from: draft, in: modelContext)
                        Haptics.success()
                    } catch {
                        reimbursementNote = error.localizedDescription
                    }
                }
            }
        }
        .sheet(isPresented: $showReimbursementSheet) {
            NavigationStack {
                Form {
                    DatePicker(Strings.Bundle.reimbursementDate, selection: $reimbursedDate, displayedComponents: .date)
                    TextField(Strings.Bundle.note, text: $reimbursementNote, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
                .navigationTitle(Strings.ReceiptDetail.reimburse)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Strings.ReceiptList.cancel) { showReimbursementSheet = false }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(Strings.ReceiptDetail.reimburse) {
                            do {
                                _ = try ReceiptActions.reimburse(
                                    receipts: [receipt],
                                    on: reimbursedDate,
                                    note: reimbursementNote,
                                    in: modelContext
                                )
                                Haptics.success()
                                showReimbursementSheet = false
                            } catch {
                                reimbursementNote = error.localizedDescription
                            }
                        }
                    }
                }
            }
            .presentationBackground(.regularMaterial)
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptDetailView(receipt: PreviewData.sampleReceipts().first!)
    }
    .modelContainer(PreviewData.container)
}
