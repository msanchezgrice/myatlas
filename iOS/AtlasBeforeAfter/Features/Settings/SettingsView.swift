import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appLockManager: AppLockManager
    @AppStorage("requireBiometrics") private var requireBiometrics: Bool = true
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = true
    @AppStorage("capture.showGrid") private var showGrid: Bool = true
    @AppStorage("capture.rememberZoom") private var rememberZoom: Bool = true
    @AppStorage("capture.enableGhost") private var enableGhost: Bool = false
    @AppStorage("export.replaceBackground") private var replaceBackground: Bool = false
    @State private var bgColor: Color = .white

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Security")) {
                    Toggle("Require Face ID", isOn: $requireBiometrics)
                    Button("Lock Now") { appLockManager.lock() }
                }
                Section(header: Text("Capture Preferences")) {
                    Toggle("Gridlines", isOn: $showGrid)
                    Toggle("Remember last zoom", isOn: $rememberZoom)
                    Toggle("Ghost overlay (align to prior)", isOn: $enableGhost)
                }
                Section(header: Text("Export")) {
                    Toggle("Replace background on export", isOn: $replaceBackground)
                    ColorPicker("Background color", selection: $bgColor)
                        .disabled(!replaceBackground)
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
            .onChange(of: bgColor) { _ in
                // store hex in UserDefaults to be read by share/export later
                let ui = UIColor(bgColor)
                let comps = ui.cgColor.components ?? [1,1,1,1]
                let hex = String(format: "#%02X%02X%02X", Int(comps[0]*255), Int(comps[1]*255), Int(comps[2]*255))
                UserDefaults.standard.set(hex, forKey: "export.bgColorHex")
            }
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
