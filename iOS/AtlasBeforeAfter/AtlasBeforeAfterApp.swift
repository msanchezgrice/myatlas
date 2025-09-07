import SwiftUI

@main
struct AtlasBeforeAfterApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLockManager = AppLockManager()
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @StateObject private var repo = AppRepository()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if didCompleteOnboarding {
                    ContentView()
                        .environmentObject(appLockManager)
                        .environmentObject(repo)
                        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
                            if UIScreen.main.isCaptured {
                                repo.recordAudit(type: .screenCaptureDetected, caseId: nil, details: "Screen capture active")
                            }
                        }
                } else {
                    OnboardingView(didCompleteOnboarding: $didCompleteOnboarding)
                        .environmentObject(appLockManager)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background { appLockManager.lock() }
        }
    }
}
