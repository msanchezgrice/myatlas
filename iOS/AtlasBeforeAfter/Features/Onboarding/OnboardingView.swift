import SwiftUI

struct OnboardingView: View {
    @Binding var didCompleteOnboarding: Bool
    @AppStorage("requireBiometrics") private var requireBiometrics: Bool = true
    @State private var providerName: String = ""
    @State private var clinicName: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Provider")) {
                    TextField("Name", text: $providerName)
                    TextField("Clinic", text: $clinicName)
                }
                Section(footer: Text("Face ID helps protect PHI on this device.")) {
                    Toggle("Require Face ID", isOn: $requireBiometrics)
                }
                Section {
                    Button {
                        didCompleteOnboarding = true
                    } label: {
                        Text("Get Started").frame(maxWidth: .infinity)
                    }
                    .disabled(providerName.isEmpty)
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

#Preview {
    OnboardingView(didCompleteOnboarding: .constant(false))
}
