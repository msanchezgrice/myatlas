import SwiftUI

@main
struct AtlasBeforeAfterApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLockManager = AppLockManager()
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if didCompleteOnboarding {
                    ContentView()
                        .environmentObject(appLockManager)
                } else {
                    OnboardingView(didCompleteOnboarding: $didCompleteOnboarding)
                        .environmentObject(appLockManager)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase != .active {
                appLockManager.lock()
            }
        }
    }
}
