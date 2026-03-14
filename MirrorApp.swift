import SwiftUI
import AVFoundation
import CoreMediaIO

@main
struct iPhoneMirrorApp: App {
    @StateObject private var captureManager = CaptureManager()
    @AppStorage("SelectedAnimation") private var selectedAnimation: AnimationType = .cursor
    
    var body: some Scene {
        WindowGroup {
            ContentView(captureManager: captureManager)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandMenu("Device") {
                Button(action: {
                    captureManager.selectedDeviceID = nil
                }) {
                    Text("Auto Detect")
                    if captureManager.selectedDeviceID == nil {
                        Image(systemName: "checkmark")
                    }
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                
                Divider()
                
                ForEach(captureManager.availableDevices, id: \.uniqueID) { device in
                    Button(action: {
                        captureManager.selectedDeviceID = device.uniqueID
                    }) {
                        Text(device.localizedName + (device.hasMediaType(.muxed) ? " (Screen)" : " (Camera)"))
                        if captureManager.selectedDeviceID == device.uniqueID {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            CommandMenu("Highlight") {
                ForEach(AnimationType.allCases) { type in
                    Button(action: {
                        selectedAnimation = type
                    }) {
                        Text(type.rawValue)
                        if selectedAnimation == type {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}

func enableScreenCaptureDevices() {
    var prop = CMIOObjectPropertyAddress(
        mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
        mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
        mElement: CMIOObjectPropertyElement(0) // Master/Main element
    )
    var allow: UInt32 = 1
    CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, UInt32(MemoryLayout.size(ofValue: allow)), &allow)
}

enum AnimationType: String, CaseIterable, Identifiable {
    case none = "None (Off)"
    case cursor = "Giant Cursor"
    case hand = "Giant Hand"
    case circle = "Giant Circle"
    
    var id: String { self.rawValue }
}

struct TapData: Identifiable {
    let id = UUID()
    let location: CGPoint
}

struct ClickAnimationView: View {
    let tap: TapData
    let type: AnimationType
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Group {
            switch type {
            case .none:
                EmptyView()
            case .cursor:
                Image(systemName: "cursorarrow")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 2)
            case .hand:
                Image(systemName: "hand.point.up.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .shadow(color: .black, radius: 2)
            case .circle:
                Circle()
                    .stroke(Color.red, lineWidth: 10)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black, radius: 2)
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .position(tap.location)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.8
                opacity = 0
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var captureManager: CaptureManager
    @AppStorage("SelectedAnimation") private var selectedAnimation: AnimationType = .cursor
    @State private var taps: [TapData] = []
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if captureManager.hasDevice {
                PreviewView(session: captureManager.session, videoSize: captureManager.videoSize)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        ZStack {
                            Color.white.opacity(0.001) // Ensure it captures clicks without blocking video
                            ForEach(taps) { tap in
                                ClickAnimationView(tap: tap, type: selectedAnimation)
                            }
                        }
                    )
                    .gesture(
                        selectedAnimation == .none ? nil :
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let tap = TapData(location: value.location)
                                taps.append(tap)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    taps.removeAll { $0.id == tap.id }
                                }
                            }
                    )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    Text("Connect your iPhone via USB")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("You can select your camera from the 'Device' menu in the Mac menu bar.\nYou may need to unlock your iPhone and 'Trust' this computer.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .frame(minWidth: 200, minHeight: 200)
    }
}

class CaptureManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var hasDevice = false
    @Published var availableDevices: [AVCaptureDevice] = []
    @Published var videoSize: CGSize = .zero
    @Published var selectedDeviceID: String? = UserDefaults.standard.string(forKey: "SelectedDeviceID") {
        didSet {
            if selectedDeviceID != oldValue {
                if let id = selectedDeviceID {
                    UserDefaults.standard.set(id, forKey: "SelectedDeviceID")
                } else {
                    UserDefaults.standard.removeObject(forKey: "SelectedDeviceID")
                }
                setupSession()
            }
        }
    }
    
    let session: AVCaptureSession
    private var videoDiscoverySession: AVCaptureDevice.DiscoverySession!
    private var muxedDiscoverySession: AVCaptureDevice.DiscoverySession!
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    override init() {
        enableScreenCaptureDevices()
        session = AVCaptureSession()
        super.init()
        
        videoDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external, .builtInWideAngleCamera], 
            mediaType: .video,
            position: .unspecified
        )
        
        muxedDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external], 
            mediaType: .muxed,
            position: .unspecified
        )
        
        availableDevices = CaptureManager.getAllDevices(videoSession: videoDiscoverySession, muxedSession: muxedDiscoverySession)
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupSession()
                } else {
                    print("Camera access denied")
                }
            }
        }
        
        // Listen to connection changes
        NotificationCenter.default.addObserver(self, selector: #selector(devicesChanged), name: AVCaptureDevice.wasConnectedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(devicesChanged), name: AVCaptureDevice.wasDisconnectedNotification, object: nil)

    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func getAllDevices(videoSession: AVCaptureDevice.DiscoverySession, muxedSession: AVCaptureDevice.DiscoverySession) -> [AVCaptureDevice] {
        var devices = videoSession.devices
        for d in muxedSession.devices {
            if !devices.contains(where: { $0.uniqueID == d.uniqueID }) {
                devices.append(d)
            }
        }
        return devices
    }
    

    
    @objc func devicesChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.availableDevices = CaptureManager.getAllDevices(videoSession: self.videoDiscoverySession, muxedSession: self.muxedDiscoverySession)
            self.setupSession()
        }
    }
    
    func setupSession() {
        session.beginConfiguration()
        
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        var selectedDevice: AVCaptureDevice? = nil
        let devices = self.availableDevices
        
        if let id = selectedDeviceID, let device = devices.first(where: { $0.uniqueID == id }) {
            selectedDevice = device
        } else {
            // Auto Select
            if let muxed = devices.first(where: { $0.hasMediaType(.muxed) && ($0.localizedName.contains("iPhone") || $0.localizedName.contains("iPad") || $0.manufacturer.contains("Apple")) }) {
                selectedDevice = muxed
            } else if let iosDevice = devices.first(where: { $0.localizedName.contains("iPhone") || $0.localizedName.contains("iPad") || $0.manufacturer.contains("Apple") }) {
                selectedDevice = iosDevice
            }
            if selectedDevice == nil {
                selectedDevice = devices.first
            }
        }
        
        if let device = selectedDevice, let input = try? AVCaptureDeviceInput(device: device) {
            if session.canAddInput(input) {
                session.addInput(input)
                hasDevice = true
                print("Added input: \(device.localizedName)")
            } else {
                hasDevice = false
                print("Cannot add input for \(device.localizedName)")
            }
        } else {
            hasDevice = false
            print("No device found")
        }
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        }

        session.sessionPreset = .high
        session.commitConfiguration()
        
        if hasDevice && !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } else if !hasDevice && session.isRunning {
            session.stopRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let newSize = CGSize(width: width, height: height)
        
        if self.videoSize != newSize {
            DispatchQueue.main.async {
                self.videoSize = newSize
            }
        }
    }
}

class PreviewNSView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoSize: CGSize = .zero {
        didSet {
            guard videoSize.width > 0 && videoSize.height > 0, oldValue != videoSize else { return }
            adjustWindowAspect()
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.window?.isMovableByWindowBackground = true
        adjustWindowAspect()
    }
    
    override func layout() {
        super.layout()
        previewLayer?.frame = bounds
    }
    
    private func adjustWindowAspect() {
        guard let window = self.window, videoSize.width > 0 && videoSize.height > 0 else { return }
        window.contentAspectRatio = videoSize
        
        var currentFrame = window.frame
        let newWidth = currentFrame.height * (videoSize.width / videoSize.height)
        
        if abs(currentFrame.width - newWidth) > 1 {
            let dx = (currentFrame.width - newWidth) / 2
            currentFrame.size.width = newWidth
            currentFrame.origin.x += dx
            window.setFrame(currentFrame, display: true, animate: true)
        }
    }
}

struct PreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    let videoSize: CGSize
    
    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspect
        view.layer?.addSublayer(previewLayer)
        view.previewLayer = previewLayer
        return view
    }
    
    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        nsView.previewLayer?.session = session
        nsView.videoSize = videoSize
    }
}
