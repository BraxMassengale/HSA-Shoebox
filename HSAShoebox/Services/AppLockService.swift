import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class AppLockService {
    var isLocked: Bool
    var lastErrorMessage: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isLocked = defaults.bool(forKey: AppConfiguration.appLockEnabledKey)
    }

    var isEnabled: Bool {
        defaults.bool(forKey: AppConfiguration.appLockEnabledKey)
    }

    func lockIfEnabled() {
        if isEnabled {
            isLocked = true
        }
    }

    func canEvaluate() -> Bool {
        var error: NSError?
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            lastErrorMessage = policyError?.localizedDescription
            return false
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                lastErrorMessage = nil
                isLocked = false
            }
            return success
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }
}
