import SwiftUI
import Vision

/// Draws the detected body skeleton (yellow joints + white bones) over the camera preview.
/// Converts Vision's normalized coordinates (origin bottom-left, in buffer space)
/// to view coordinates matching an aspect-fill camera preview.
struct SkeletonOverlayView: View {
    let pose: DetectedPose?
    let mirrored: Bool

    private static let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder,  .rightShoulder),
        (.leftShoulder,  .leftElbow),   (.leftElbow,  .leftWrist),
        (.rightShoulder, .rightElbow),  (.rightElbow, .rightWrist),
        (.leftShoulder,  .leftHip),     (.rightShoulder, .rightHip),
        (.leftHip,       .rightHip),
        (.leftHip,       .leftKnee),    (.leftKnee,   .leftAnkle),
        (.rightHip,      .rightKnee),   (.rightKnee,  .rightAnkle)
    ]

    private static let jointNames: [VNHumanBodyPoseObservation.JointName] = [
        .leftShoulder, .rightShoulder,
        .leftElbow,    .rightElbow,
        .leftWrist,    .rightWrist,
        .leftHip,      .rightHip,
        .leftKnee,     .rightKnee,
        .leftAnkle,    .rightAnkle
    ]

    var body: some View {
        Canvas { context, size in
            guard let pose else { return }

            let buffer = pose.bufferSize
            guard buffer.width > 0, buffer.height > 0 else { return }

            // Aspect-fill mapping: same scaling the preview layer applies.
            let scale = max(size.width / buffer.width, size.height / buffer.height)
            let displayed = CGSize(width: buffer.width * scale, height: buffer.height * scale)
            let offset = CGPoint(
                x: (size.width - displayed.width) / 2,
                y: (size.height - displayed.height) / 2
            )

            func viewPoint(_ name: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
                guard let normalized = pose.location(of: name) else { return nil }
                let x = mirrored ? 1 - normalized.x : normalized.x
                return CGPoint(
                    x: offset.x + x * displayed.width,
                    y: offset.y + (1 - normalized.y) * displayed.height
                )
            }

            for (from, to) in Self.bones {
                guard let a = viewPoint(from), let b = viewPoint(to) else { continue }
                var path = Path()
                path.move(to: a)
                path.addLine(to: b)
                context.stroke(
                    path,
                    with: .color(.white),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
            }

            for name in Self.jointNames {
                guard let center = viewPoint(name) else { continue }
                let radius: CGFloat = 11
                let rect = CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                )
                context.fill(Path(ellipseIn: rect), with: .color(Color(red: 1.0, green: 0.78, blue: 0.2)))
                context.stroke(
                    Path(ellipseIn: rect),
                    with: .color(Color(red: 0.12, green: 0.12, blue: 0.16)),
                    lineWidth: 3
                )
            }
        }
        .allowsHitTesting(false)
    }
}
