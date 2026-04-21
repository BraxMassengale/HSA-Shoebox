import SwiftUI
import VisionKit

struct ScanSheet: View {
    @AppStorage(AppConfiguration.defaultCurrencyKey) private var defaultCurrencyCode = Locale.current.currency?.identifier ?? "USD"
    @AppStorage(AppConfiguration.defaultCategoryKey) private var defaultCategoryRawValue = ExpenseCategory.other.rawValue
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = ScanViewModel()

    var body: some View {
        Group {
            if let draft = viewModel.draft {
                EditReceiptSheet(draft: draft) { updatedDraft in
                    do {
                        try ReceiptActions.insertReceipt(from: updatedDraft, in: modelContext)
                        Haptics.success()
                        dismiss()
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
            } else if viewModel.isProcessing {
                ContentUnavailableView {
                    Label(Strings.Scan.processing, systemImage: "text.viewfinder")
                } description: {
                    Text(Strings.Scan.processingMessage)
                }
            } else if let errorMessage = viewModel.errorMessage {
                ContentUnavailableView {
                    Label(Strings.Scan.scanFailed, systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button(Strings.Scan.retry) {
                        viewModel.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if VNDocumentCameraViewController.isSupported {
                ReceiptScanner { result in
                    switch result {
                    case .success(let images):
                        Task {
                            await viewModel.process(
                                scannedImages: images,
                                defaultCurrencyCode: defaultCurrencyCode,
                                defaultCategory: ExpenseCategory(rawValue: defaultCategoryRawValue) ?? .other
                            )
                        }
                    case .failure(let error):
                        if error is CancellationError {
                            dismiss()
                        } else {
                            viewModel.handle(error: error)
                        }
                    }
                }
                .ignoresSafeArea()
            } else {
                ContentUnavailableView(Strings.Scan.unsupported, systemImage: "camera.metering.unknown")
            }
        }
        .presentationBackground(.regularMaterial)
    }
}

#Preview {
    ScanSheet()
        .modelContainer(PreviewData.container)
}
