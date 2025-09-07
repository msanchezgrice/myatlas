import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @AppStorage("requireBiometrics") private var requireBiometrics: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Require Face ID", isOn: $requireBiometrics)
                Button("Lock Now") { appLockManager.lock() }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView().environmentObject(AppLockManager())
}
