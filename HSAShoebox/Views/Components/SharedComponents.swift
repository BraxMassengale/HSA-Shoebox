import SwiftUI

struct CurrencyAmountText: View {
    let amount: Decimal
    let currencyCode: String
    let font: Font

    init(amount: Decimal, currencyCode: String, font: Font = .body) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.font = font
    }

    var body: some View {
        Text(Formatters.currencyString(for: amount, currencyCode: currencyCode))
            .font(font.monospacedDigit())
    }
}

struct EmptyStateCard: View {
    let symbolName: String
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolName)
        } description: {
            Text(message)
        } actions: {
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .accessibilityElement(children: .contain)
    }
}

struct TotalHeaderCard: View {
    let total: Decimal
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.ReceiptList.unreimbursedTotal)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            ViewThatFits(in: .horizontal) {
                CurrencyAmountText(amount: total, currencyCode: currencyCode, font: .system(size: 28, weight: .bold, design: .rounded))
                CurrencyAmountText(amount: total, currencyCode: currencyCode, font: .title3.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .accessibilityElement(children: .combine)
    }
}

struct ReceiptThumbnailView: View {
    let imageData: Data?

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.tertiary.opacity(0.3))
                    Image(systemName: "doc.text.viewfinder")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        HStack(spacing: 12) {
            ReceiptThumbnailView(imageData: receipt.pageImages.first)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: receipt.categoryEnum.symbolName)
                        .foregroundStyle(.tint)
                    Text(receipt.merchant.isEmpty ? "Untitled Receipt" : receipt.merchant)
                        .font(.headline)
                        .lineLimit(1)
                }

                Text(Formatters.dateString(for: receipt.dateOfService))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            CurrencyAmountText(amount: receipt.amount, currencyCode: receipt.currencyCode, font: .headline)
                .multilineTextAlignment(.trailing)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(receipt.merchant), \(Formatters.dateString(for: receipt.dateOfService)), \(Formatters.currencyString(for: receipt.amount, currencyCode: receipt.currencyCode))")
    }
}

#Preview("Components") {
    VStack(spacing: 20) {
        TotalHeaderCard(total: 1284.22, currencyCode: "USD")
        ReceiptRowView(receipt: PreviewData.sampleReceipts().first!)
    }
    .padding()
}
