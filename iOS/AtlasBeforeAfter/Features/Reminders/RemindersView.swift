import SwiftUI
import UserNotifications

struct RemindersView: View {
    @EnvironmentObject private var repo: AppRepository
    @State private var selectedCaseId: UUID?
    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date().addingTimeInterval(7*24*3600)
    @State private var message: String = "Follow-up photos"
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("New Reminder")) {
                    Picker("Case", selection: $selectedCaseId) {
                        Text("Select Case").tag(UUID?.none)
                        ForEach(repo.db.cases) { scase in
                            Text(scase.title).tag(UUID?.some(scase.id))
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Message", text: $message)
                    Button {
                        if let id = selectedCaseId { repo.scheduleReminder(for: id, at: date, message: message) }
                    } label: { Label("Schedule", systemImage: "calendar.badge.plus") }
                    .disabled(selectedCaseId == nil)
                }

                if !repo.db.reminders.isEmpty {
                    Section(header: Text("Scheduled")) {
                        ForEach(repo.db.reminders) { r in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(r.message)
                                    Text(r.fireDate.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) { repo.cancelReminder(r.id) } label: { Image(systemName: "trash") }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
        }
    }
}

#Preview { RemindersView().environmentObject(AppRepository()) }
