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
    @State private var showEditor = false
    @State private var editorImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let scase = repo.db.cases.first(where: { $0.id == caseId }) {
                    GeometryReader { geo in
                        let width = geo.size.width
                        let targetHeight = max(340, min(560, width * 1.0))
                        CompareView(before: displayBefore(for: scase),
                                    after: scase.afterPhoto.flatMap(repo.loadPhotoData).flatMap(UIImage.init(data:)))
                            .frame(maxWidth: .infinity)
                            .frame(height: targetHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                    }
                    .frame(height: 560)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(caseTitle).font(.title3).bold()
                        if let proc = scase.procedure { Text(proc.rawValue).font(.subheadline).foregroundStyle(.secondary) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button("Import Before") { showBeforePicker = true }
                        Button("Import After") { showAfterPicker = true }
                        Button("Edit Before") {
                            if let scase = repo.db.cases.first(where: { $0.id == caseId }),
                               let data = scase.beforePhoto.flatMap(repo.loadPhotoData),
                               let img = UIImage(data: data) { editorImage = img; showEditor = true }
                        }
                        .disabled(repo.db.cases.first(where: { $0.id == caseId })?.beforePhoto == nil)
                        Spacer(minLength: 0)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)

                    // Tags (simple)
                    if let before = scase.beforePhoto {
                        TagRow(asset: before)
                            .environmentObject(repo)
                            .padding(.horizontal)
                    }
                    if let after = scase.afterPhoto {
                        TagRow(asset: after)
                            .environmentObject(repo)
                            .padding(.horizontal)
                    }
                } else {
                    Text("Case not found").foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Preview Standardized") { standardize(previewOnly: true) }
                    Button("Replace Before with Standardized") { standardize(previewOnly: false) }
                } label: { Label("Standardize", systemImage: "wand.and.stars") }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button { scheduleFollowUp() } label: { Label("Schedule", systemImage: "calendar.badge.plus") }
                    .buttonStyle(.bordered)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                Button { showingConsent = true } label: { Label("Consent", systemImage: "checkmark.seal") }
                    .buttonStyle(.bordered)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                Button { shareCase() } label: { Label("Share", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
                    .labelStyle(.titleAndIcon)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .disabled(shareItems.isEmpty)
            }
            .font(.body.weight(.semibold))
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingConsent) { ConsentView(caseId: caseId).environmentObject(repo) }
        .sheet(isPresented: $showingShare) { ActivityView(activityItems: shareItems) }
        .sheet(isPresented: $showBeforePicker) { PhotoPicker { img in try? repo.attachPhoto(to: caseId, image: img, isBefore: true); refreshSharePreview() } }
        .sheet(isPresented: $showAfterPicker) { PhotoPicker { img in try? repo.attachPhoto(to: caseId, image: img, isBefore: false); refreshSharePreview() } }
        .sheet(isPresented: $showEditor) {
            if let editorImage { ImageEditorView(image: editorImage) { edited in try? repo.attachPhoto(to: caseId, image: edited, isBefore: true); standardizedBefore = edited; refreshSharePreview() } }
        }
        .onAppear { refreshSharePreview() }
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
        if !items.isEmpty { showingShare = true }
    }

    private func refreshSharePreview() {
        guard let scase = repo.db.cases.first(where: { $0.id == caseId }) else { shareItems = []; return }
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
    }
}

private struct TagRow: View {
    @EnvironmentObject private var repo: AppRepository
    let asset: PhotoAsset
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags").font(.subheadline).bold()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(asset.tags, id: \.self) { t in
                            Text(t).font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            HStack {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    repo.addTag(trimmed, to: asset)
                    newTag = ""
                }
            }
        }
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
                    .offset(x: min(width - 1, max(1, width * progress - 1)))
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.15)))
                    .frame(width: 28, height: 28)
                    .offset(x: min(width - 14, max(14, width * progress - 14)))
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
