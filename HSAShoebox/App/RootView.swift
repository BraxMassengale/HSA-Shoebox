import SwiftUI

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppConfiguration.appLockEnabledKey) private var appLockEnabled = false
    @AppStorage(AppConfiguration.appLockPromptSeenKey) private var appLockPromptSeen = false

    @State private var lockService = AppLockService()
    @State private var showFirstRunPrompt = false

    var body: some View {
        ZStack {
            NavigationStack {
                ReceiptListView()
            }

            if lockService.isLocked {
                LockOverlay {
                    Task { await lockService.authenticate(reason: Strings.AppLock.unlockReason) }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: lockService.isLocked)
        .task(id: lockService.isLocked) {
            if lockService.isLocked {
                _ = await lockService.authenticate(reason: Strings.AppLock.unlockReason)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .inactive, .background:
                lockService.lockIfEnabled()
            case .active:
                if !appLockPromptSeen {
                    appLockPromptSeen = true
                    if lockService.canEvaluate() {
                        showFirstRunPrompt = true
                    }
                }
            @unknown default:
                break
            }
        }
        .alert(Strings.AppLock.promptTitle, isPresented: $showFirstRunPrompt) {
            Button(Strings.AppLock.promptEnable) {
                Task {
                    let success = await lockService.authenticate(reason: Strings.AppLock.enableReason)
                    if success {
                        appLockEnabled = true
                    }
                }
            }
            Button(Strings.AppLock.promptSkip, role: .cancel) {}
        } message: {
            Text(Strings.AppLock.promptMessage)
        }
    }
}

private struct LockOverlay: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text(Strings.AppLock.title)
                        .font(.title2.weight(.semibold))
                    Text(Strings.AppLock.message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: onUnlock) {
                    Label(Strings.AppLock.unlock, systemImage: "faceid")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 48)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
