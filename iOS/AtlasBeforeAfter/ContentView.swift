import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @StateObject private var repo = AppRepository()

    var body: some View {
        ZStack {
            TabView {
                LibraryView()
                    .environmentObject(repo)
                    .tabItem { Label("Library", systemImage: "photo.on.rectangle.angled") }

                CameraView()
                    .environmentObject(repo)
                    .tabItem { Label("Camera", systemImage: "camera") }

                RemindersView()
                    .tabItem { Label("Reminders", systemImage: "bell.badge") }

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
            }

            if appLockManager.isLocked {
                LockScreenView()
            }
        }
        .onAppear {
            appLockManager.unlockIfPossible()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppLockManager())
}
