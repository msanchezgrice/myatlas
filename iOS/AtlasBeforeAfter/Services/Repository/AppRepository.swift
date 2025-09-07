import Foundation
import UIKit

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
    func createCase(for patientId: UUID, title: String, specialty: String) -> SurgicalCase {
        let scase = SurgicalCase(id: UUID(), patientId: patientId, title: title, specialty: specialty, createdAt: Date(), beforePhoto: nil, afterPhoto: nil)
        db.cases.append(scase)
        save()
        return scase
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
}
