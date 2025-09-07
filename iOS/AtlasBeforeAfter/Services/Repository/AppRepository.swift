import Foundation
import UIKit
import UserNotifications

@MainActor
final class AppRepository: ObservableObject {
    @Published private(set) var db: AppDatabase
    private let store = EncryptedJSONStore<AppDatabase>(filePath: "db.json")
    private let fileStore = EncryptedFileStore()

    init() {
        self.db = store.load(defaultValue: AppDatabase())
    }

    func save() {
        do { try store.save(db) } catch { }
    }

    // Patients
    func createPatient(fullName: String, dateOfBirth: Date?) -> Patient {
        let patient = Patient(id: UUID(), fullName: fullName, dateOfBirth: dateOfBirth)
        db.patients.append(patient)
        save()
        return patient
    }

    // Cases
    func createCase(for patientId: UUID, title: String, specialty: String, procedure: Procedure? = nil) -> SurgicalCase {
        let scase = SurgicalCase(id: UUID(), patientId: patientId, title: title, specialty: specialty, procedure: procedure, createdAt: Date(), beforePhoto: nil, afterPhoto: nil)
        db.cases.append(scase)
        save()
        return scase
    }

    func setProcedure(caseId: UUID, procedure: Procedure?) {
        guard let idx = db.cases.firstIndex(where: { $0.id == caseId }) else { return }
        db.cases[idx].procedure = procedure
        save()
    }

    func attachPhoto(to caseId: UUID, image: UIImage, isBefore: Bool) throws {
        guard let idx = db.cases.firstIndex(where: { $0.id == caseId }) else { return }
        guard let data = image.jpegData(compressionQuality: 0.95) else { return }
        let photoId = UUID()
        let relative = "photos/\(caseId.uuidString)/\(isBefore ? "before" : "after")-\(photoId.uuidString).jpg.enc"
        _ = try fileStore.write(data: data, to: relative)
        let asset = PhotoAsset(id: photoId, relativePath: relative, capturedAt: Date(), notes: nil)
        if isBefore {
            db.cases[idx].beforePhoto = asset
        } else {
            db.cases[idx].afterPhoto = asset
        }
        save()
    }

    func loadPhotoData(_ asset: PhotoAsset) -> Data? {
        try? fileStore.read(from: asset.relativePath)
    }

    // Reminders
    func scheduleReminder(for caseId: UUID, at date: Date, message: String) {
        let reminder = Reminder(id: UUID(), caseId: caseId, fireDate: date, message: message)
        db.reminders.append(reminder)
        save()
        let content = UNMutableNotificationContent()
        content.title = "Follow-up: \(message)"
        content.body = "Case follow-up due."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(5, date.timeIntervalSinceNow), repeats: false)
        let req = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { _ in }
        recordAudit(type: .reminderScheduled, caseId: caseId, details: message)
    }

    func cancelReminder(_ id: UUID) {
        db.reminders.removeAll { $0.id == id }
        save()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
        recordAudit(type: .reminderCancelled, caseId: nil, details: id.uuidString)
    }

    // Consent
    func saveConsent(caseId: UUID, patientName: String, procedure: String?, signature: UIImage) throws {
        guard let data = signature.pngData() else { return }
        let id = UUID()
        let relative = "consents/\(caseId.uuidString)/\(id.uuidString).png.enc"
        _ = try fileStore.write(data: data, to: relative)
        let asset = PhotoAsset(id: id, relativePath: relative, capturedAt: Date(), notes: "consent signature")
        let record = ConsentRecord(id: id, caseId: caseId, patientName: patientName, procedure: procedure, signedAt: Date(), signatureAsset: asset)
        db.consents.append(record)
        save()
        recordAudit(type: .consentCaptured, caseId: caseId, details: patientName)
    }

    // Audit
    func recordAudit(type: AuditEventType, caseId: UUID?, details: String?) {
        let ev = AuditEvent(id: UUID(), timestamp: Date(), type: type, caseId: caseId, details: details)
        db.auditEvents.insert(ev, at: 0)
        save()
    }
}
