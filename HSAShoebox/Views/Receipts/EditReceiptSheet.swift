import SwiftUI

struct EditReceiptSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ReceiptDraft
    let onSave: @MainActor (ReceiptDraft) -> Void

    init(draft: ReceiptDraft, onSave: @escaping @MainActor (ReceiptDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                ReceiptPagePagerView(pageImages: draft.pageImages)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                ReceiptEditorFields(draft: $draft)
            }
            .navigationTitle(Strings.Scan.editTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.ReceiptList.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Scan.save) {
                        onSave(draft)
                    }
                    .disabled(draft.pageImages.isEmpty || draft.amount <= 0)
                }
            }
        }
        .presentationBackground(.regularMaterial)
    }
}

#Preview {
    EditReceiptSheet(draft: PreviewData.sampleDraft()) { _ in }
}
