import SwiftUI

struct ImageEditorView: View {
    let image: UIImage
    var onDone: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var rotation: Angle = .zero
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            VStack {
                GeometryReader { geo in
                    let size = geo.size
                    ZStack {
                        Color.black.opacity(0.95).ignoresSafeArea()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.width, height: size.height)
                            .rotationEffect(rotation)
                            .scaleEffect(scale)
                    }
                }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Rotate").font(.caption)
                            Slider(value: Binding(get: { rotation.degrees }, set: { rotation = .degrees($0) }), in: -45...45)
                        }
                        HStack {
                            Text("Zoom").font(.caption)
                            Slider(value: $scale, in: 0.5...2.0)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { onDone(renderEdited()); dismiss() } }
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func renderEdited() -> UIImage {
        let renderer = ImageRenderer(content: Image(uiImage: image).resizable().scaledToFit().rotationEffect(rotation).scaleEffect(scale))
        let targetSize = CGSize(width: image.size.width, height: image.size.height)
        renderer.proposedSize = .init(targetSize)
        renderer.scale = image.scale
        return renderer.uiImage ?? image
    }
}

#Preview { ImageEditorView(image: UIImage(systemName: "photo")!, onDone: { _ in }) }

