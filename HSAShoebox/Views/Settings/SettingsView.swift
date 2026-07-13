import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppConfiguration.defaultCurrencyKey) private var defaultCurrencyCode = Locale.current.currency?.identifier ?? "USD"
    @AppStorage(AppConfiguration.defaultCategoryKey) private var defaultCategoryRawValue = ExpenseCategory.other.rawValue
    @AppStorage(AppConfiguration.appLockEnabledKey) private var appLockEnabled = false
    @Query(sort: \Receipt.dateOfService, order: .reverse) private var receipts: [Receipt]
    @Query(sort: \Reimbursement.reimbursedDate, order: .reverse) private var reimbursements: [Reimbursement]

    @State private var syncMonitor = CloudKitStatusMonitor()
    @State private var lockService = AppLockService()
    @State private var exportURL: URL?
    @State private var isExporting = false

    var body: some View {
        Form {
            Section(Strings.Settings.syncStatus) {
                LabeledContent {
                    Label(syncMonitor.title, systemImage: syncMonitor.symbolName)
                        .labelStyle(.titleAndIcon)
                } label: {
                    Text(Strings.Settings.syncStatus)
                }
            }

            Section {
                TextField(Strings.Settings.defaultCurrency, text: currencyBinding)
                    .textInputAutocapitalization(.characters)

                Picker(Strings.Settings.defaultCategory, selection: $defaultCategoryRawValue) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Text(category.displayName).tag(category.rawValue)
                    }
                }
            }

            Section {
                Toggle(Strings.Settings.appLock, isOn: appLockBinding)
                    .disabled(!lockService.canEvaluate())
            } header: {
                Text(Strings.Settings.security)
            } footer: {
                Text(lockService.canEvaluate() ? Strings.Settings.appLockFootnote : Strings.Settings.appLockUnavailable)
            }

            Section {
                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label(Strings.Settings.exportAllData, systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        isExporting = true
                        do {
                            exportURL = try DataExportService().export(
                                receipts: receipts,
                                reimbursements: reimbursements
                            )
                        } catch {
                            exportURL = nil
                        }
                        isExporting = false
                    } label: {
                        Label(Strings.Settings.exportAllData, systemImage: "archivebox")
                    }
                }

                if isExporting {
                    ProgressView(Strings.Settings.exportInProgress)
                }
            }

            Section(Strings.Settings.about) {
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    LabeledContent("Version", value: "\(version) (\(build))")
                }

                Text(Strings.Settings.privacy)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Strings.Settings.title)
        .task {
            syncMonitor.start()
        }
    }

    private var currencyBinding: Binding<String> {
        Binding {
            defaultCurrencyCode
        } set: { newValue in
            defaultCurrencyCode = String(newValue.uppercased().prefix(3))
        }
    }

    private var appLockBinding: Binding<Bool> {
        Binding {
            appLockEnabled
        } set: { newValue in
            if newValue {
                Task {
                    let success = await lockService.authenticate(reason: Strings.AppLock.enableReason)
                    appLockEnabled = success
                }
            } else {
                appLockEnabled = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(PreviewData.container)
}
