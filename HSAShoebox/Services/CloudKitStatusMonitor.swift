import CloudKit
import Foundation
import Observation

@MainActor
@Observable
final class CloudKitStatusMonitor {
    private let container: CKContainer
    private var notificationsTask: Task<Void, Never>?

    var status: CKAccountStatus = .couldNotDetermine

    init(containerIdentifier: String = AppConfiguration.cloudKitContainerIdentifier) {
        self.container = CKContainer(identifier: containerIdentifier)
    }
    func start() {
        notificationsTask?.cancel()
        notificationsTask = Task { [weak self] in
            guard let self else { return }
            await self.refresh()

            for await _ in NotificationCenter.default.notifications(named: Notification.Name.CKAccountChanged) {
                await self.refresh()
            }
        }
    }

    func refresh() async {
        status = await withCheckedContinuation { continuation in
            container.accountStatus { status, _ in
                continuation.resume(returning: status)
            }
        }
    }

    var title: String {
        switch status {
        case .available: Strings.Settings.syncAvailable
        case .noAccount: Strings.Settings.syncNoAccount
        case .restricted: Strings.Settings.syncRestricted
        case .temporarilyUnavailable: Strings.Settings.syncTemporarilyUnavailable
        case .couldNotDetermine: Strings.Settings.syncUnknown
        @unknown default: Strings.Settings.syncUnknown
        }
    }

    var symbolName: String {
        switch status {
        case .available: "checkmark.icloud"
        case .noAccount: "icloud.slash"
        case .restricted: "exclamationmark.icloud"
        case .temporarilyUnavailable: "icloud.and.arrow.down"
        case .couldNotDetermine: "icloud"
        @unknown default: "icloud"
        }
    }
}
