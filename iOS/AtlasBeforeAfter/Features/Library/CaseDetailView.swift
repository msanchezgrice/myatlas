import SwiftUI
import Vision

struct CaseDetailView: View {
    @EnvironmentObject private var repo: AppRepository
    let caseId: UUID
    @State private var standardizedBefore: UIImage?
    @State private var showingConsent = false
    @State private var showingShare = false
    @State private var shareItems: [Any] = []
    @State private var showBeforePicker = false
    @State private var showAfterPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let scase = repo.db.cases.first(where: { $0.id == caseId }) {
                    CompareView(before: displayBefore(for: scase),
                                after: scase.afterPhoto.flatMap(repo.loadPhotoData).flatMap(UIImage.init(data:)))
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))

                    HStack(spacing: 12) {
                        Button("Schedule…") { scheduleFollowUp() }
                        Spacer()
                        Button("Consent") { showingConsent = true }
                        Button("Share") { shareCase() }
                    }
                    .buttonStyle(.bordered)

                    HStack(spacing: 12) {
                        Button("Import Before") { showBeforePicker = true }
                        Button("Import After") { showAfterPicker = true }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Case not found").foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(caseTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Preview Standardized") { standardize(previewOnly: true) }
                    Button("Replace Before with Standardized") { standardize(previewOnly: false) }
                } label: { Text("Standardize") }
            }
        }
        .sheet(isPresented: $showingConsent) { ConsentView(caseId: caseId).environmentObject(repo) }
        .sheet(isPresented: $showingShare) { ActivityView(activityItems: shareItems) }
        .sheet(isPresented: $showBeforePicker) {
            PhotoPicker { img in try? repo.attachPhoto(to: caseId, image: img, isBefore: true) }
        }
        .sheet(isPresented: $showAfterPicker) {
            PhotoPicker { img in try? repo.attachPhoto(to: caseId, image: img, isBefore: false) }
        }
    }

    private var caseTitle: String {
        repo.db.cases.first(where: { $0.id == caseId })?.title ?? "Case"
    }

    private func displayBefore(for scase: SurgicalCase) -> UIImage? {
        if let standardizedBefore { return standardizedBefore }
        return scase.beforePhoto.flatMap(repo.loadPhotoData).flatMap(UIImage.init(data:))
    }

    private func standardize(previewOnly: Bool) {
        guard let scase = repo.db.cases.first(where: { $0.id == caseId }),
              let data = scase.beforePhoto.flatMap(repo.loadPhotoData),
              let image = UIImage(data: data) else { return }
        let processor = VisionStandardizer()
        guard let output = processor.standardize(image) else { return }
        if previewOnly { standardizedBefore = output }
        else { standardizedBefore = output; try? repo.attachPhoto(to: caseId, image: output, isBefore: true) }
    }

    private func scheduleFollowUp() {
        let date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date().addingTimeInterval(7*24*3600)
        repo.scheduleReminder(for: caseId, at: date, message: "1 week after photos")
    }

    private func shareCase() {
        guard let scase = repo.db.cases.first(where: { $0.id == caseId }) else { return }
        let share = ShareService()
        var items: [Any] = []
        if let before = displayBefore(for: scase) {
            let wm = ShareService.Watermark(provider: "Provider", clinic: "Clinic", caseTitle: scase.title)
            let img = share.watermarked(before, with: wm)
            if let url = share.writeTempPNG(img) { items.append(url) }
        }
        if let after = scase.afterPhoto.flatMap(repo.loadPhotoData).flatMap(UIImage.init(data:)) {
            let wm = ShareService.Watermark(provider: "Provider", clinic: "Clinic", caseTitle: scase.title)
            let img = share.watermarked(after, with: wm)
            if let url = share.writeTempPNG(img) { items.append(url) }
        }
        shareItems = items
        repo.recordAudit(type: .shareExport, caseId: caseId, details: "exported \(items.count) images")
        showingShare = true
    }
}

private struct CompareView: View {
    let before: UIImage?
    let after: UIImage?
    @State private var progress: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let width = max(1, geo.size.width)
            let height = max(1, geo.size.height)
            ZStack(alignment: .leading) {
                if let after {
                    Image(uiImage: after)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: height)
                        .clipped()
                } else { Color.secondary.opacity(0.1) }

                if let before {
                    Image(uiImage: before)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width * progress, height: height)
                        .clipped()
                }
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .offset(x: width * progress - 1)
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.15)))
                    .frame(width: 28, height: 28)
                    .offset(x: width * progress - 14)
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        let ratio = value.location.x / width
                        progress = ratio.isFinite ? min(1, max(0, ratio)) : 0.5
                    })
            }
        }
        .animation(.easeInOut(duration: 0.15), value: progress)
    }
}

#Preview {
    CaseDetailView(caseId: UUID()).environmentObject(AppRepository())
}
