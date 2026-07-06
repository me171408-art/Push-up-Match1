import Vision
import AVFoundation
import CoreGraphics

struct DetectedPose {
    let joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    var bufferSize: CGSize = CGSize(width: 720, height: 1280)

    /// Normalized location (Vision space, origin bottom-left) if the joint is confidently detected.
    func location(of name: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let point = joints[name], point.confidence > 0.3 else { return nil }
        return point.location
    }

    var isFullBodyVisible: Bool {
        let required: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow,    .rightElbow,
            .leftWrist,    .rightWrist,
            .leftHip,      .rightHip
        ]
        return required.allSatisfy { (joints[$0]?.confidence ?? 0) > 0.3 }
    }

    /// Elbow angle from whichever arm is confidently visible (average if both are).
    /// Falls back to a single arm: with the phone on the floor one wrist is often occluded.
    func elbowAngle() -> Double? {
        let left  = armAngle(shoulder: .leftShoulder,  elbow: .leftElbow,  wrist: .leftWrist)
        let right = armAngle(shoulder: .rightShoulder, elbow: .rightElbow, wrist: .rightWrist)

        switch (left, right) {
        case let (l?, r?): return (l + r) / 2.0
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }

    private func armAngle(
        shoulder: VNHumanBodyPoseObservation.JointName,
        elbow: VNHumanBodyPoseObservation.JointName,
        wrist: VNHumanBodyPoseObservation.JointName
    ) -> Double? {
        guard
            let s = joints[shoulder], s.confidence > 0.3,
            let e = joints[elbow],    e.confidence > 0.3,
            let w = joints[wrist],    w.confidence > 0.3
        else { return nil }
        return angleBetween(a: s.location, vertex: e.location, b: w.location)
    }

    private func angleBetween(a: CGPoint, vertex: CGPoint, b: CGPoint) -> Double {
        let v1 = CGPoint(x: a.x - vertex.x, y: a.y - vertex.y)
        let v2 = CGPoint(x: b.x - vertex.x, y: b.y - vertex.y)
        let dot  = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        guard mag1 > 0, mag2 > 0 else { return 0 }
        let cosAngle = max(-1.0, min(1.0, Double(dot / (mag1 * mag2))))
        return acos(cosAngle) * 180 / .pi
    }
}

final class PoseDetector {
    var onPoseDetected: ((DetectedPose?) -> Void)?

    private let requestHandler = VNSequenceRequestHandler()

    func detect(sampleBuffer: CMSampleBuffer) {
        var bufferSize = CGSize(width: 720, height: 1280)
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            bufferSize = CGSize(
                width: CVPixelBufferGetWidth(pixelBuffer),
                height: CVPixelBufferGetHeight(pixelBuffer)
            )
        }
        let request = VNDetectHumanBodyPoseRequest { [weak self] req, _ in
            guard
                let obs = req.results?.first as? VNHumanBodyPoseObservation,
                let allPoints = try? obs.recognizedPoints(.all)
            else {
                self?.onPoseDetected?(nil)
                return
            }
            self?.onPoseDetected?(DetectedPose(joints: allPoints, bufferSize: bufferSize))
        }
        try? requestHandler.perform([request], on: sampleBuffer)
    }
}

extension PoseDetector: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        detect(sampleBuffer: sampleBuffer)
    }
    func cameraManager(_ manager: CameraManager, didFailWith error: Error) {}
}
