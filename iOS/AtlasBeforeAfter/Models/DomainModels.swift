import Foundation

struct Patient: Identifiable, Codable, Equatable {
    var id: UUID
    var fullName: String
    var dateOfBirth: Date?
}

struct SurgicalCase: Identifiable, Codable, Equatable {
    var id: UUID
    var patientId: UUID
    var title: String
    var specialty: String // e.g., "Oculoplastics"
    var createdAt: Date
    var beforePhoto: PhotoAsset?
    var afterPhoto: PhotoAsset?
}

struct PhotoAsset: Identifiable, Codable, Equatable {
    var id: UUID
    var relativePath: String // path within encrypted store
    var capturedAt: Date
    var notes: String?
}

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID
    var caseId: UUID
    var fireDate: Date
    var message: String
}

struct AppDatabase: Codable {
    var patients: [Patient] = []
    var cases: [SurgicalCase] = []
    var reminders: [Reminder] = []
}
