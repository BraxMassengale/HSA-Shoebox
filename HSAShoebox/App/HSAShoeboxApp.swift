import SwiftData
import SwiftUI

@main
struct HSAShoeboxApp: App {
    private let sharedModelContainer = AppModelContainer.shared.container

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(sharedModelContainer)
        }
    }
}

enum AppConfiguration {
    static let cloudKitContainerInfoKey = "CloudKitContainerIdentifier"
    static let fallbackCloudKitContainer = "iCloud.com.example.HSAShoebox"
    static let defaultCurrencyKey = "defaultCurrencyCode"
    static let defaultCategoryKey = "defaultExpenseCategory"

    static var cloudKitContainerIdentifier: String {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: cloudKitContainerInfoKey) as? String,
            value.isEmpty == false
        else {
            return fallbackCloudKitContainer
        }

        return value
    }
}

@MainActor
struct AppModelContainer {
    static let shared = AppModelContainer()

    let container: ModelContainer

    init() {
        let schema = Schema([
            Receipt.self,
            Reimbursement.self
        ])

        do {
            let configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(AppConfiguration.cloudKitContainerIdentifier)
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            do {
                let localConfiguration = ModelConfiguration(
                    schema: schema,
                    cloudKitDatabase: .none
                )
                container = try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                fatalError("Unable to create model container: \(error.localizedDescription)")
            }
        }
    }
}
