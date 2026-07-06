import SwiftUI
import Combine
import UIKit

@MainActor
final class CalibrationViewModel: ObservableObject {
    @Published private(set) var repCount = 0
    @Published private(set) var warning: RepCounterWarning = .none
    @Published private(set) var currentPose: DetectedPose?

    let cameraManager = CameraManager()
    let repCounter    = PushUpRepCounter()

    private let poseDetector = PoseDetector()

    init() {
        poseDetector.onPoseDetected = { [weak self] pose in
            DispatchQueue.main.async {
                self?.currentPose = pose
                self?.repCounter.process(pose: pose)
            }
        }
        cameraManager.delegate = poseDetector
        repCounter.$repCount.assign(to: &$repCount)
        repCounter.$warning.assign(to: &$warning)
    }

    func start(cameraFront: Bool) {
        repCounter.reset()
        cameraManager.configure(position: cameraFront ? .front : .back)
        cameraManager.startRunning()
    }

    func stop() {
        cameraManager.stopRunning()
    }
}

/// 30-second max push-up test at the end of onboarding. The result seeds the
/// recommended opponent difficulty. Skippable.
struct CalibrationTestView: View {
    /// Called with the rep count, or nil when the user skips.
    let onFinished: (Int?) -> Void

    private enum Phase {
        case intro
        case waitingForPosition
        case testing
        case done
    }

    @StateObject private var vm = CalibrationViewModel()
    @AppStorage("cameraPosition") private var cameraFront = true
    @State private var phase: Phase = .intro
    @State private var timeLeft = 30
    @State private var timer: Timer?
    @State private var readyFrames = 0

    // Arms extended in plank ≈ elbow angle near the counter's up threshold.
    private let plankAngleThreshold: Double = 140
    // ~0.7 s of consecutive in-position frames at 30 fps before the clock starts.
    private let requiredReadyFrames = 20

    var body: some View {
        ZStack {
            if phase == .intro {
                introView
            } else {
                testView
            }
        }
        .onDisappear {
            timer?.invalidate()
            vm.stop()
        }
    }

    // MARK: – Intro

    private var introView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)

            VStack(spacing: 0) {
                TypewriterText(fullText: "Show me what you've got!\n30 seconds, max push-ups.")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.07, green: 0.12, blue: 0.3))
                    .multilineTextAlignment(.center)
                    .fixedSize()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)

                Triangle()
                    .fill(.white)
                    .frame(width: 26, height: 14)
            }

            Image("onboarding_coach3")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 400)
                .shadow(color: .black.opacity(0.5), radius: 16, y: 10)
                .padding(.top, 6)

            Spacer()

            Button("Start the Test") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                startTest()
            }
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button("Skip for now") { onFinished(nil) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 10)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    // MARK: – Test + result

    private var testView: some View {
        ZStack {
            CameraPreviewView(session: vm.cameraManager.captureSession)
                .ignoresSafeArea()

            SkeletonOverlayView(pose: vm.currentPose, mirrored: cameraFront)
                .ignoresSafeArea()

            VStack {
                if phase == .testing {
                    Text("\(timeLeft)")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(timeLeft <= 5 ? .red : .orange)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.3), value: timeLeft)
                        .padding(.top, 12)
                        .shadow(color: .black, radius: 6)
                }

                if phase == .testing {
                    formWarning
                        .padding(.top, 12)
                }

                Spacer()

                if phase == .waitingForPosition {
                    positionPrompt
                        .padding(.bottom, 40)
                } else {
                    Text("\(vm.repCount)")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: vm.repCount)
                        .shadow(color: .black, radius: 8)
                    Text("PUSH-UPS")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(.orange)
                        .padding(.bottom, 40)
                }
            }

            if phase == .done { resultOverlay }
        }
        .background(Color.black)
        .onReceive(vm.$currentPose) { pose in
            guard phase == .waitingForPosition else { return }
            if let angle = pose?.elbowAngle(), angle >= plankAngleThreshold {
                readyFrames += 1
                if readyFrames >= requiredReadyFrames { beginCountdown() }
            } else {
                readyFrames = 0
            }
        }
    }

    /// Live form feedback during the test, same wording as the match screen.
    @ViewBuilder
    private var formWarning: some View {
        switch vm.warning {
        case .bodyNotVisible:
            warningPill("Move back — full body not visible")
        case .goLower:
            warningPill("Go lower!")
        case .none:
            EmptyView()
        }
    }

    private func warningPill(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.red.opacity(0.85))
            .clipShape(Capsule())
            .transition(.opacity)
    }

    private var positionPrompt: some View {
        VStack(spacing: 12) {
            Text("Get into push-up position")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black, radius: 6)

            Text("The clock starts automatically")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black, radius: 4)

            // Fills while the pose is held; resets if the user moves out of position.
            Capsule()
                .fill(.white.opacity(0.2))
                .frame(width: 180, height: 10)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.orange)
                        .frame(width: 180 * min(1, Double(readyFrames) / Double(requiredReadyFrames)))
                }
                .animation(.linear(duration: 0.1), value: readyFrames)
        }
        .padding(20)
        .background(.black.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("💪 \(vm.repCount) PUSH-UPS")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.orange)

                Text(assessment)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button("Continue") { onFinished(vm.repCount) }
                    .font(.title3.bold())
                    .padding(.horizontal, 44)
                    .padding(.vertical, 14)
                    .background(.orange)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 8)
            }
        }
    }

    private var assessment: String {
        switch vm.repCount {
        case 0..<10:  return "Solid start, recruit! We'll warm you up in the Easy tier."
        case 10..<20: return "Impressive! You're ready for Medium-tier opponents."
        default:      return "Outstanding! The Hard tier giants better watch out."
        }
    }

    private func startTest() {
        vm.start(cameraFront: cameraFront)
        readyFrames = 0
        phase = .waitingForPosition
    }

    /// Fires once the user has held the push-up position long enough.
    private func beginCountdown() {
        vm.repCounter.reset()
        SoundManager.shared.play("sfx_kickoff")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        phase = .testing
        timeLeft = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
    }

    private func tick() {
        guard phase == .testing else { return }
        timeLeft -= 1
        if timeLeft <= 0 {
            timer?.invalidate()
            vm.stop()
            SoundManager.shared.play(vm.repCount > 0 ? "sfx_goal" : "sfx_match_point")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { phase = .done }
        }
    }
}
