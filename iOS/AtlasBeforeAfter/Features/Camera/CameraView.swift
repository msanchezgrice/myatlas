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
        #if targetEnvironment(simulator)
        // Simulator has no camera
        isAuthorized = false
        isReady = false
        captureError = "Camera unavailable"
        #else
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
        #endif
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
        if #available(iOS 16.0, *) {
            photoOutput.maxPhotoDimensions = .init(width: 4032, height: 3024)
        }
        session.commitConfiguration()

        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) { device.focusMode = .continuousAutoFocus }
            if device.isExposureModeSupported(.continuousAutoExposure) { device.exposureMode = .continuousAutoExposure }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) { device.whiteBalanceMode = .continuousAutoWhiteBalance }
            if device.isLowLightBoostSupported { device.automaticallyEnablesLowLightBoostWhenAvailable = true }
            device.videoZoomFactor = 1.0
            device.unlockForConfiguration()
        } catch { }

        isReady = true
    }

    func start() {
        guard isAuthorized, isReady, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    func stop() { guard session.isRunning else { return }; session.stopRunning() }

    func capture(_ handler: @escaping (Data) -> Void) {
        #if targetEnvironment(simulator)
        captureError = "Use Import on Simulator"
        #else
        guard session.isRunning else { captureError = "Camera not ready"; return }
        guard photoOutput.connections.contains(where: { $0.isEnabled }) else { captureError = "No active camera connection"; return }
        capturedHandler = handler
        let settings = AVCapturePhotoSettings()
        if #available(iOS 16.0, *) { settings.photoQualityPrioritization = .quality }
        photoOutput.capturePhoto(with: settings, delegate: self)
        #endif
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() { capturedHandler?(data) }
        else if let error { captureError = error.localizedDescription }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        #if !targetEnvironment(simulator)
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        #endif
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        #if !targetEnvironment(simulator)
        if let layer = (uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer) {
            layer.session = session
            layer.frame = uiView.bounds
        }
        #endif
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
    @State private var showPicker: Bool = false

    var body: some View {
        ZStack {
            CameraPreview(session: model.session)
                .ignoresSafeArea()
                .background(Color(.systemBackground))
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
                HStack(spacing: 20) {
                    #if targetEnvironment(simulator)
                    Button("Import") { showPicker = true }
                        .buttonStyle(.borderedProminent)
                    #endif
                    Button(action: onCapture) {
                        Circle()
                            .fill(model.isAuthorized && model.isReady && model.session.isRunning ? .white : .gray)
                            .frame(width: 72, height: 72)
                            .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                            .shadow(radius: 2)
                    }
                    .disabled(!(model.isAuthorized && model.isReady && model.session.isRunning))
                }
                .padding(.bottom, 32)
            }

            if let toast { Text(toast).padding().background(.thinMaterial, in: Capsule()).padding(.bottom, 120).frame(maxHeight: .infinity, alignment: .bottom) }
            if let err = model.captureError { Text(err).padding().background(.thinMaterial, in: Capsule()).padding(.top, 80).frame(maxHeight: .infinity, alignment: .top) }
        }
        .onAppear { model.requestAndPrepare(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { model.start() } }
        .onDisappear { model.stop() }
        .sheet(isPresented: $showPicker) {
            PhotoPicker { img in
                saveCaptured(img)
            }
        }
    }

    private func onCapture() {
        model.capture { data in
            if let img = UIImage(data: data) { saveCaptured(img) }
        }
    }

    private func saveCaptured(_ img: UIImage) {
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

#Preview { CameraView().environmentObject(AppRepository()) }
