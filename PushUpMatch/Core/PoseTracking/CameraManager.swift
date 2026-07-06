import AVFoundation

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
    func cameraManager(_ manager: CameraManager, didFailWith error: Error)
}

final class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.pushupmatch.camera", qos: .userInitiated)

    var captureSession: AVCaptureSession { session }

    func configure(position: AVCaptureDevice.Position = .front) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { self.configureSession(position: position) }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.sessionQueue.async { self.configureSession(position: position) } }
            }
        default:
            break
        }
    }

    func startRunning() {
        sessionQueue.async { if !self.session.isRunning { self.session.startRunning() } }
    }

    func stopRunning() {
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
    }

    private func configureSession(position: AVCaptureDevice.Position) {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { session.commitConfiguration(); return }

        session.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        session.commitConfiguration()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
}
