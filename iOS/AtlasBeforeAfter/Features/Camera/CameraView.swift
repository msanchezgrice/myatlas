import SwiftUI
import AVFoundation

final class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    @Published var captureError: String?
    private var capturedHandler: ((Data) -> Void)?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            captureError = "Camera unavailable"
            session.commitConfiguration()
            return
        }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
        session.commitConfiguration()
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    func capture(_ handler: @escaping (Data) -> Void) {
        capturedHandler = handler
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            capturedHandler?(data)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = UIScreen.main.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.session = session
    }
}

struct CameraView: View {
    @StateObject private var model = CameraViewModel()
    @EnvironmentObject private var repo: AppRepository
    @State private var toast: String?

    var body: some View {
        ZStack {
            CameraPreview(session: model.session)
                .ignoresSafeArea()

            VStack {
                Spacer()
                Button(action: onCapture) {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                        .shadow(radius: 2)
                }
                .padding(.bottom, 32)
            }

            if let toast { Text(toast).padding().background(.thinMaterial, in: Capsule()).padding(.bottom, 120).frame(maxHeight: .infinity, alignment: .bottom) }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func onCapture() {
        model.capture { data in
            if let img = UIImage(data: data) {
                if let latest = repo.db.cases.last {
                    try? repo.attachPhoto(to: latest.id, image: img, isBefore: latest.beforePhoto == nil)
                    DispatchQueue.main.async { toast = "Saved to \(latest.title)" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                } else {
                    DispatchQueue.main.async { toast = "No case. Add one in Library." }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
                }
            }
        }
    }
}

#Preview { CameraView().environmentObject(AppRepository()) }
