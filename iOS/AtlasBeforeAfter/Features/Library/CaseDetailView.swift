import SwiftUI

struct CaseDetailView: View {
    @EnvironmentObject private var repo: AppRepository
    let caseId: UUID

    var body: some View {
        VStack(spacing: 16) {
            if let scase = repo.db.cases.first(where: { $0.id == caseId }) {
                Text(scase.title).font(.title3).bold()
                CompareView(before: scase.beforePhoto.flatMap(repo.loadPhotoData).flatMap(UIImage.init(data:)),
                            after: scase.afterPhoto.flatMap(repo.loadPhotoData).flatMap(UIImage.init(data:)))
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                Spacer()
            } else {
                Text("Case not found").foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Case")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CompareView: View {
    let before: UIImage?
    let after: UIImage?
    @State private var progress: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                if let after {
                    Image(uiImage: after)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Color.secondary.opacity(0.1)
                }
                if let before {
                    Image(uiImage: before)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width * progress, height: geo.size.height)
                        .clipped()
                }
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .offset(x: geo.size.width * progress - 1)
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.15)))
                    .frame(width: 28, height: 28)
                    .offset(x: geo.size.width * progress - 14)
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                        progress = min(1, max(0, value.location.x / geo.size.width))
                    })
            }
        }
        .animation(.easeInOut(duration: 0.15), value: progress)
    }
}

#Preview {
    CaseDetailView(caseId: UUID()).environmentObject(AppRepository())
}
