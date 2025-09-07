import Foundation

struct Patient: Identifiable, Codable, Equatable {
    var id: UUID
    var fullName: String
    var dateOfBirth: Date?
}

enum Procedure: String, Codable, CaseIterable, Identifiable {
    case upperBlepharoplasty = "Upper Blepharoplasty"
    case lowerBlepharoplasty = "Lower Blepharoplasty"
    case ptosisRepair = "Ptosis Repair"
    case browLift = "Brow Lift"
    case ectropionRepair = "Ectropion Repair"
    case entropionRepair = "Entropion Repair"
    case dacryocystorhinostomy = "Dacryocystorhinostomy (DCR)"
    case canthoplasty = "Canthoplasty/Canthopexy"
    case orbitalDecompression = "Orbital Decompression"

    var id: String { rawValue }
}

struct SurgicalCase: Identifiable, Codable, Equatable {
    var id: UUID
    var patientId: UUID
    var title: String
    var specialty: String // e.g., "Oculoplastics"
    var procedure: Procedure?
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

enum AuditEventType: String, Codable {
    case shareExport
    case reminderScheduled
    case reminderCancelled
    case consentCaptured
    case screenCaptureDetected
}

struct AuditEvent: Identifiable, Codable, Equatable {
    var id: UUID
    var timestamp: Date
    var type: AuditEventType
    var caseId: UUID?
    var details: String?
}

struct ConsentRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var caseId: UUID
    var patientName: String
    var procedure: String?
    var signedAt: Date
    var signatureAsset: PhotoAsset
}

struct AppDatabase: Codable {
    var patients: [Patient] = []
    var cases: [SurgicalCase] = []
    var reminders: [Reminder] = []
    var consents: [ConsentRecord] = []
    var auditEvents: [AuditEvent] = []
}
