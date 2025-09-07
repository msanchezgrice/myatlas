import SwiftUI
import UserNotifications

struct RemindersView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Follow-up Reminders").font(.title3).bold()
                Button("Allow Notifications") {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
                }
                Button("Schedule test reminder (5s)") {
                    let content = UNMutableNotificationContent()
                    content.title = "Follow-up photos"
                    content.body = "Time to capture after photos."
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                    let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(req)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Reminders")
        }
    }
}

#Preview { RemindersView() }
