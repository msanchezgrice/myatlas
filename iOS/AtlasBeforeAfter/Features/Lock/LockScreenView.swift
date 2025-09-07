import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var appLockManager: AppLockManager

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill").font(.system(size: 44)).foregroundStyle(.primary)
                Text("Locked").font(.title2).bold()
                Button {
                    appLockManager.unlockIfPossible()
                } label: {
                    Label("Unlock", systemImage: "faceid")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

#Preview {
    LockScreenView().environmentObject(AppLockManager())
}
