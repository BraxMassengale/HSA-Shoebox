import SwiftData
import SwiftUI

private enum ReceiptFilterScope: String, CaseIterable, Identifiable {
    case all
    case unreimbursed
    case reimbursed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: Strings.ReceiptList.all
        case .unreimbursed: Strings.ReceiptList.unreimbursed
        case .reimbursed: Strings.ReceiptList.reimbursed
        }
    }
}

private struct ReimbursementRequest: Identifiable {
    let id = UUID()
    let receipts: [Receipt]
}

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Receipt.dateOfService, order: .reverse), SortDescriptor(\Receipt.createdAt, order: .reverse)]) private var receipts: [Receipt]

    @State private var filterScope: ReceiptFilterScope = .all
    @State private var searchText = ""
    @State private var selectedReceiptIDs = Set<UUID>()
    @State private var showScanSheet = false
    @State private var showSettings = false
    @State private var reimbursementRequest: ReimbursementRequest?
    @State private var pendingDeletion: Receipt?

    private var filteredReceipts: [Receipt] {
        receipts.filter { receipt in
            let matchesScope: Bool = switch filterScope {
            case .all: true
            case .unreimbursed: receipt.reimbursement == nil
            case .reimbursed: receipt.reimbursement != nil
            }

            let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let haystack = "\(receipt.merchant) \(receipt.notes) \(receipt.categoryEnum.displayName)".localizedLowercase
            let matchesSearch = normalizedSearch.isEmpty || haystack.contains(normalizedSearch.localizedLowercase)

            return matchesScope && matchesSearch
        }
    }

    private var groupedReceipts: [(Date, [Receipt])] {
        Dictionary(grouping: filteredReceipts, by: { Formatters.sortableSectionDate(for: $0.dateOfService) })
            .sorted(by: { $0.key > $1.key })
    }

    private var unreimbursedTotal: Decimal {
        receipts
            .filter { $0.reimbursement == nil }
            .reduce(0) { $0 + $1.amount }
    }

    private var currencyCode: String {
        receipts.first?.currencyCode ?? Locale.current.currency?.identifier ?? "USD"
    }

    var body: some View {
        List(selection: $selectedReceiptIDs) {
            Section {
                Picker("Filter", selection: $filterScope) {
                    ForEach(ReceiptFilterScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Receipt filter")
            }

            if filteredReceipts.isEmpty {
                emptyState
            } else {
                ForEach(groupedReceipts, id: \.0) { month, monthReceipts in
                    Section(Formatters.monthYearString(for: month)) {
                        ForEach(monthReceipts) { receipt in
                            NavigationLink {
                                ReceiptDetailView(receipt: receipt)
                            } label: {
                                ReceiptRowView(receipt: receipt)
                            }
                            .tag(receipt.id)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if receipt.reimbursement == nil {
                                    Button {
                                        reimbursementRequest = ReimbursementRequest(receipts: [receipt])
                                    } label: {
                                        Label(Strings.ReceiptList.markReimbursed, systemImage: "checkmark.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingDeletion = receipt
                                } label: {
                                    Label(Strings.ReceiptList.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Strings.App.receipts)
        .searchable(text: $searchText, prompt: Strings.ReceiptList.searchPrompt)
        .safeAreaInset(edge: .top) {
            TotalHeaderCard(total: unreimbursedTotal, currencyCode: currencyCode)
                .background(.bar)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Label(Strings.App.settings, systemImage: "gearshape")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScanSheet = true
                } label: {
                    Label(Strings.ReceiptList.scan, systemImage: "doc.viewfinder")
                }
            }

            ToolbarItem(placement: .bottomBar) {
                if selectedReceiptIDs.isEmpty == false {
                    Button(Strings.ReceiptList.createBundle) {
                        let selected = receipts.filter { selectedReceiptIDs.contains($0.id) && $0.reimbursement == nil }
                        if selected.isEmpty == false {
                            reimbursementRequest = ReimbursementRequest(receipts: selected)
                        }
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(isPresented: $showScanSheet) {
            ScanSheet()
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(item: $reimbursementRequest) { request in
            ReimbursementComposerView(receipts: request.receipts) { _ in
                selectedReceiptIDs.removeAll()
            }
        }
        .confirmationDialog(
            Strings.ReceiptList.deleteConfirmationTitle,
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if $0 == false { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { receipt in
            Button(Strings.ReceiptList.confirmDelete, role: .destructive) {
                do {
                    try ReceiptActions.delete(receipt, in: modelContext)
                    Haptics.warning()
                } catch {
                    pendingDeletion = nil
                }
            }
            Button(Strings.ReceiptList.cancel, role: .cancel) {}
        } message: { _ in
            Text(Strings.ReceiptList.deleteConfirmationMessage)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if searchText.isEmpty == false {
            EmptyStateCard(
                symbolName: "magnifyingglass",
                title: Strings.ReceiptList.noSearchResultsTitle,
                message: Strings.ReceiptList.noSearchResultsMessage,
                buttonTitle: Strings.ReceiptList.scan
            ) {
                showScanSheet = true
            }
        } else if filterScope == .unreimbursed {
            EmptyStateCard(
                symbolName: "checkmark.circle",
                title: Strings.ReceiptList.noUnreimbursedTitle,
                message: Strings.ReceiptList.noUnreimbursedMessage,
                buttonTitle: Strings.ReceiptList.scan
            ) {
                showScanSheet = true
            }
        } else {
            EmptyStateCard(
                symbolName: "archivebox",
                title: Strings.ReceiptList.noReceiptsTitle,
                message: Strings.ReceiptList.noReceiptsMessage,
                buttonTitle: Strings.ReceiptList.scan
            ) {
                showScanSheet = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptListView()
    }
    .modelContainer(PreviewData.container)
}
