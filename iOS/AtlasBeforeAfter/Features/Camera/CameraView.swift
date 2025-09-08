import SwiftUI
import AVFoundation
import CoreMotion

final class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var currentDevice: AVCaptureDevice?
    @Published var captureError: String?
    @Published var isAuthorized: Bool = false
    @Published var isReady: Bool = false
    private var capturedHandler: ((Data) -> Void)?
    private let motion = CMMotionManager()
    @Published var isLevel: Bool = false
    @Published var autoSnapEnabled: Bool = false
    private var stableFrames: Int = 0

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
        currentDevice = device

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
        startLevelMonitoring()
    }

    func stop() { guard session.isRunning else { return }; session.stopRunning(); motion.stopDeviceMotionUpdates() }

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

extension CameraViewModel {
    fileprivate func startLevelMonitoring() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        let threshold = (2.0 * .pi) / 180.0 // 2 degrees
        motion.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self else { return }
            guard let dm = motion else { self.isLevel = false; return }
            let roll = abs(dm.attitude.roll)
            let pitch = abs(dm.attitude.pitch)
            if roll < threshold && pitch < threshold {
                self.stableFrames += 1
            } else {
                self.stableFrames = 0
            }
            self.isLevel = self.stableFrames >= 5
        }
    }

    func setZoom(factor: CGFloat) {
        guard let device = currentDevice else { return }
        do {
            try device.lockForConfiguration()
            let clamped = min(max(1.0, factor), device.activeFormat.videoMaxZoomFactor)
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch { }
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

private enum OverlayPreset: String, CaseIterable {
    case frontal, leftProfile, rightProfile, threeQuarterLeft, threeQuarterRight
    var title: String {
        switch self {
        case .frontal: return "Frontal"
        case .leftProfile: return "L Profile"
        case .rightProfile: return "R Profile"
        case .threeQuarterLeft: return "L 3/4"
        case .threeQuarterRight: return "R 3/4"
        }
    }
}

private struct AlignmentOverlay: View {
    let preset: OverlayPreset
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // Base grid (light)
            Path { p in
                for i in 1...2 { let x = w * CGFloat(i) / 3; p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h)) }
                for i in 1...2 { let y = h * CGFloat(i) / 3; p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y)) }
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 0.5)

            // Eye line
            Path { p in
                let eyeY = h * 0.42
                p.move(to: CGPoint(x: 16, y: eyeY))
                p.addLine(to: CGPoint(x: w - 16, y: eyeY))
            }
            .stroke(Color.green.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))

            // Preset verticals
            Path { p in
                switch preset {
                case .frontal:
                    let mid = w / 2
                    p.move(to: CGPoint(x: mid, y: 0)); p.addLine(to: CGPoint(x: mid, y: h))
                case .leftProfile:
                    let x = w * 0.35
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                case .rightProfile:
                    let x = w * 0.65
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                case .threeQuarterLeft:
                    let x = w * 0.43
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                case .threeQuarterRight:
                    let x = w * 0.57
                    p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: h))
                }
            }
            .stroke(Color.yellow.opacity(0.7), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

struct CameraView: View {
    @StateObject private var model = CameraViewModel()
    @EnvironmentObject private var repo: AppRepository
    @State private var toast: String?
    @AppStorage("capture.showGrid") private var showGrid: Bool = true
    @AppStorage("capture.rememberZoom") private var rememberZoom: Bool = true
    @AppStorage("capture.enableGhost") private var enableGhost: Bool = false
    @AppStorage("capture.autoSnap") private var autoSnap: Bool = false
    @AppStorage("capture.zoomFactor") private var storedZoom: Double = 1.0
    @AppStorage("capture.overlayPreset") private var overlayPresetRaw: String = OverlayPreset.frontal.rawValue
    @State private var currentZoom: CGFloat = 1.0
    @State private var lastCaptured: UIImage?

    private var overlayPreset: OverlayPreset {
        OverlayPreset(rawValue: overlayPresetRaw) ?? .frontal
    }
    @State private var showPicker: Bool = false

    var body: some View {
        ZStack {
            CameraPreview(session: model.session)
                .ignoresSafeArea()
                .background(Color(.systemBackground))
            if showGrid { AlignmentOverlay(preset: overlayPreset).ignoresSafeArea() }
            if enableGhost, let ghost = lastCaptured {
                Image(uiImage: ghost)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.25)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Menu {
                        ForEach(OverlayPreset.allCases, id: \.rawValue) { p in
                            Button(p.title) { overlayPresetRaw = p.rawValue }
                        }
                    } label: {
                        Image(systemName: "rectangle.dashed")
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                    Spacer()
                    Button { enableGhost.toggle() } label: {
                        Image(systemName: enableGhost ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
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
                    // Zoom segmented
                    HStack(spacing: 8) {
                        ForEach([1.0, 2.0, 3.0], id: \.self) { z in
                            Button(String(format: "%.0fx", z)) {
                                currentZoom = z
                                model.setZoom(factor: currentZoom)
                                if rememberZoom { storedZoom = Double(z) }
                            }
                            .padding(8)
                            .background((abs(currentZoom - z) < 0.01) ? Color.white.opacity(0.9) : Color.black.opacity(0.2))
                            .foregroundStyle((abs(currentZoom - z) < 0.01) ? .black : .white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(6)
                    .background(.thinMaterial, in: Capsule())

                    Button(action: onCapture) {
                        Circle()
                            .fill((model.isAuthorized && model.isReady && model.session.isRunning) ? (model.isLevel && autoSnap ? .green : .white) : .gray)
                            .frame(width: 72, height: 72)
                            .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                            .shadow(radius: 2)
                    }
                    .disabled(!(model.isAuthorized && model.isReady && model.session.isRunning))
                    // Auto‑snap toggle
                    Button { autoSnap.toggle() } label: {
                        Image(systemName: autoSnap ? "bolt.circle.fill" : "bolt.circle")
                            .padding(10)
                            .background(.thinMaterial, in: Circle())
                    }
                }
                .padding(.bottom, 24)
            }

            if let toast { Text(toast).padding().background(.thinMaterial, in: Capsule()).padding(.bottom, 120).frame(maxHeight: .infinity, alignment: .bottom) }
            if let err = model.captureError { Text(err).padding().background(.thinMaterial, in: Capsule()).padding(.top, 80).frame(maxHeight: .infinity, alignment: .top) }
        }
        .onAppear {
            model.requestAndPrepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                model.start()
                if rememberZoom { currentZoom = CGFloat(max(1.0, storedZoom)); model.setZoom(factor: currentZoom) }
            }
        }
        .onDisappear { model.stop() }
        .onChange(of: model.isLevel) { isLevel in
            if isLevel && autoSnap { onCapture() }
        }
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
            lastCaptured = img
            DispatchQueue.main.async { toast = "Saved to \(latest.title)" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
        } else {
            DispatchQueue.main.async { toast = "No case. Add one in Library." }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { toast = nil }
        }
    }
}

#Preview { CameraView().environmentObject(AppRepository()) }
