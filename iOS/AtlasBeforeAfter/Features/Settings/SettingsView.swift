import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @AppStorage("requireBiometrics") private var requireBiometrics: Bool = true
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Security")) {
                    Toggle("Require Face ID", isOn: $requireBiometrics)
                    Button("Lock Now") { appLockManager.lock() }
                }
                Section(header: Text("Compliance")) {
                    NavigationLink("Audit Log") { AuditLogView() }
                }
                Section {
                    Button(role: .destructive) {
                        didCompleteOnboarding = false
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct AuditLogView: View {
    @EnvironmentObject private var repo: AppRepository

    var body: some View {
        List(repo.db.auditEvents) { ev in
            VStack(alignment: .leading, spacing: 4) {
                Text(ev.type.rawValue).font(.headline)
                Text(ev.timestamp.formatted()).font(.caption).foregroundStyle(.secondary)
                if let details = ev.details { Text(details).font(.subheadline) }
            }
        }
        .navigationTitle("Audit Log")
    }
}

#Preview {
    SettingsView().environmentObject(AppLockManager()).environmentObject(AppRepository())
}
