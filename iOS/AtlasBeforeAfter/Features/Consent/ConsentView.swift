import SwiftUI
import PencilKit

struct ConsentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var repo: AppRepository
    let caseId: UUID

    @State private var patientName: String = ""
    @State private var procedure: String = ""
    @State private var canvasView = PKCanvasView()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Form {
                    TextField("Patient Name", text: $patientName)
                    TextField("Procedure (optional)", text: $procedure)
                }
                SignatureCanvas(canvasView: $canvasView)
                    .frame(height: 220)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    .padding(.horizontal)
                Text("Sign above").font(.footnote).foregroundStyle(.secondary)
                Spacer()
            }
            .navigationTitle("Consent")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(patientName.isEmpty || canvasView.drawing.bounds.isEmpty) }
            }
        }
    }

    private func save() {
        let img = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
        try? repo.saveConsent(caseId: caseId, patientName: patientName, procedure: procedure.isEmpty ? nil : procedure, signature: img)
        dismiss()
    }
}

private struct SignatureCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 3)
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) { }
}
