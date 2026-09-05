import AVFoundation
import SwiftUI
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    /// Return true to accept and stop scanning.
    var validate: (String) -> Bool
    var onAccepted: (String) -> Void
    var onRejected: (() -> Void)?

    func makeUIViewController(context: Context) -> ScannerController {
        let c = ScannerController()
        c.validate = validate
        c.onAccepted = onAccepted
        c.onRejected = onRejected
        return c
    }

    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {
        uiViewController.validate = validate
        uiViewController.onAccepted = onAccepted
        uiViewController.onRejected = onRejected
    }
}

final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var validate: ((String) -> Bool)?
    var onAccepted: ((String) -> Void)?
    var onRejected: (() -> Void)?

    private let session = AVCaptureSession()
    private var didAccept = false
    private var lastRejectAt: Date = .distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] ok in
                DispatchQueue.main.async { if ok { self?.configure() } }
            }
        default:
            break
        }
    }

    private func configure() {
        guard session.inputs.isEmpty else { return }
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
            DispatchQueue.main.async {
                WakeAudioController.shared.reassert()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.compactMap { $0 as? AVCaptureVideoPreviewLayer }.forEach {
            $0.frame = view.bounds
        }
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didAccept,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue
        else { return }

        let ok = validate?(value) ?? true
        if !ok {
            let now = Date()
            if now.timeIntervalSince(lastRejectAt) > 1.2 {
                lastRejectAt = now
                onRejected?()
            }
            return
        }

        didAccept = true
        session.stopRunning()
        onAccepted?(value)
    }
}
