import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView { PreviewUIView() }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.session = session
    }

    final class PreviewUIView: UIView {
        var session: AVCaptureSession? {
            didSet { previewLayer.session = session }
        }

        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame        = bounds
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
