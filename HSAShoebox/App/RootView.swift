import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            ReceiptListView()
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
