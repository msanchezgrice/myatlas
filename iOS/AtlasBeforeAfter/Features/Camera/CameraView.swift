import SwiftUI
import AVFoundation

final class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    @Published var captureError: String?
    @Published var isAuthorized: Bool = false
    @Published var isReady: Bool = false
    private var capturedHandler: ((Data) -> Void)?

    override init() {
        super.init()
    }

    func requestAndPrepare() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.configureSession() }
                }
            }
        default:
            isAuthorized = false
            captureError = "Camera permission denied. Enable in Settings."
        }
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
        isReady = true
    }

    func start() {
        guard isAuthorized, isReady, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    func capture(_ handler: @escaping (Data) -> Void) {
        guard session.isRunning else { captureError = "Camera not ready"; return }
        guard photoOutput.connections.contains(where: { $0.isEnabled }) else { captureError = "No active camera connection"; return }
        capturedHandler = handler
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            capturedHandler?(data)
        } else if let error { captureError = error.localizedDescription }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = (uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer) {
            layer.session = session
            layer.frame = uiView.bounds
        }
    }
}

private struct AlignmentOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { p in
                for i in 1...2 { let x = w * CGFloat(i) / 3; p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h)) }
                for i in 1...2 { let y = h * CGFloat(i) / 3; p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y)) }
            }
            .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}

struct CameraView: View {
    @StateObject private var model = CameraViewModel()
    @EnvironmentObject private var repo: AppRepository
    @State private var toast: String?
    @State private var showGrid: Bool = true

    var body: some View {
        ZStack {
            CameraPreview(session: model.session)
                .ignoresSafeArea()
            if showGrid { AlignmentOverlay().ignoresSafeArea() }

            VStack {
                HStack {
                    Spacer()
                    Button { showGrid.toggle() } label: {
                        Image(systemName: showGrid ? "square.grid.3x3" : "square")
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                }
                .padding()
                Spacer()
                Button(action: onCapture) {
                    Circle()
                        .fill(model.isAuthorized && model.isReady && model.session.isRunning ? .white : .gray)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                        .shadow(radius: 2)
                }
                .padding(.bottom, 32)
                .disabled(!(model.isAuthorized && model.isReady && model.session.isRunning))
            }

            if let toast { Text(toast).padding().background(.thinMaterial, in: Capsule()).padding(.bottom, 120).frame(maxHeight: .infinity, alignment: .bottom) }
            if let err = model.captureError { Text(err).padding().background(.thinMaterial, in: Capsule()).padding(.top, 80).frame(maxHeight: .infinity, alignment: .top) }
        }
        .onAppear { model.requestAndPrepare(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { model.start() } }
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
