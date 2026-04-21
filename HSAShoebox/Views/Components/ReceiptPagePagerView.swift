import SwiftUI

struct ReceiptPagePagerView: View {
    let pageImages: [Data]

    var body: some View {
        TabView {
            ForEach(Array(pageImages.enumerated()), id: \.offset) { index, data in
                ScrollView([.horizontal, .vertical]) {
                    if let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        ContentUnavailableView("Unable to Display Page", systemImage: "photo")
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal)
                .padding(.bottom)
                .containerRelativeFrame(.vertical)
                .accessibilityLabel("Receipt page \(index + 1)")
            }
        }
        .frame(minHeight: 280)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

#Preview {
    ReceiptPagePagerView(pageImages: [PreviewData.sampleImageData()])
        .padding()
}
