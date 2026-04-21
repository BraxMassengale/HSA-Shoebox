import SwiftUI

struct ReceiptEditorFields: View {
    @Binding var draft: ReceiptDraft
    @State private var amountText = ""

    var body: some View {
        Section(Strings.ReceiptDetail.details) {
            TextField(Strings.Form.merchant, text: $draft.merchant)
                .textInputAutocapitalization(.words)
                .accessibilityLabel(Strings.Form.merchant)

            DatePicker(Strings.Form.dateOfService, selection: $draft.dateOfService, displayedComponents: .date)
                .accessibilityLabel(Strings.Form.dateOfService)

            TextField(Strings.Form.amount, text: amountBinding)
                .keyboardType(.decimalPad)
                .accessibilityLabel(Strings.Form.amount)

            TextField(Strings.Form.currency, text: currencyBinding)
                .textInputAutocapitalization(.characters)
                .accessibilityLabel(Strings.Form.currency)

            Picker(Strings.Form.category, selection: $draft.category) {
                ForEach(ExpenseCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.symbolName)
                        .tag(category)
                }
            }
            .accessibilityLabel(Strings.Form.category)

            TextField(Strings.Form.paymentMethod, text: paymentMethodBinding)
                .textInputAutocapitalization(.words)
                .accessibilityLabel(Strings.Form.paymentMethod)
        }

        Section(Strings.Form.notes) {
            TextField(Strings.Form.notes, text: $draft.notes, axis: .vertical)
                .lineLimit(4, reservesSpace: true)
                .accessibilityLabel(Strings.Form.notes)
        }
        .onAppear {
            amountText = NSDecimalNumber(decimal: draft.amount).stringValue
        }
        .onChange(of: draft.amount) {
            amountText = NSDecimalNumber(decimal: draft.amount).stringValue
        }
    }

    private var amountBinding: Binding<String> {
        Binding {
            amountText
        } set: { newValue in
            amountText = newValue
            let sanitized = newValue
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
            if let decimal = Decimal(string: sanitized, locale: Locale.current) {
                draft.amount = decimal
            }
        }
    }

    private var currencyBinding: Binding<String> {
        Binding {
            draft.currencyCode
        } set: { newValue in
            draft.currencyCode = String(newValue.uppercased().prefix(3))
        }
    }

    private var paymentMethodBinding: Binding<String> {
        Binding {
            draft.paymentMethod ?? ""
        } set: { newValue in
            draft.paymentMethod = newValue.isEmpty ? nil : newValue
        }
    }
}

#Preview {
    Form {
        ReceiptEditorFields(draft: .constant(PreviewData.sampleDraft()))
    }
}
