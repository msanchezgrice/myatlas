import Foundation
import LocalAuthentication
import SwiftUI

final class AppLockManager: ObservableObject {
    @Published var isLocked: Bool = true
    @AppStorage("requireBiometrics") private var requireBiometrics: Bool = true

    func lock() {
        DispatchQueue.main.async { [weak self] in
            self?.isLocked = true
        }
    }

    func unlockIfPossible() {
        if requireBiometrics {
            authenticate()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isLocked = false
            }
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication
        guard context.canEvaluatePolicy(policy, error: &error) else {
            DispatchQueue.main.async { [weak self] in
                self?.isLocked = false
            }
            return
        }
        context.evaluatePolicy(policy, localizedReason: "Unlock to access patient data") { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isLocked = !success
            }
        }
    }
}
