import Foundation
import Combine

enum RepState: Equatable {
    case waitingForDown
    case atBottom(frameCount: Int)
    case waitingForUp
}

enum RepCounterWarning: Equatable {
    case none
    case bodyNotVisible
    case goLower
}

final class PushUpRepCounter: ObservableObject {
    @Published private(set) var repCount: Int = 0
    @Published private(set) var warning: RepCounterWarning = .none
    @Published private(set) var currentElbowAngle: Double = 180

    private var state: RepState = .waitingForDown
    private var angleHistory: [Double] = []

    // Thresholds tuned for a phone lying on the floor facing the user:
    // the projected 2D elbow angle bottoms out around 95-115 and tops out around 150-160,
    // so the classic 90/160 gym thresholds never trigger (verified with on-device logs).
    private let downThreshold: Double  = 110
    private let upThreshold: Double    = 145
    private let goLowerBand: Double    = 130
    private let historySize: Int       = 5
    private let minBottomFrames: Int   = 3

    func reset() {
        repCount = 0
        state = .waitingForDown
        angleHistory = []
        warning = .none
    }

    func process(pose: DetectedPose?) {
        guard let pose else { warning = .bodyNotVisible; return }
        // Hips are deliberately NOT required: with the phone on the floor they sit
        // at low confidence during a rep. One confident arm is enough to count.
        guard let rawAngle = pose.elbowAngle() else { warning = .bodyNotVisible; return }
        processAngle(rawAngle)
    }

    // Internal entry point used by unit tests (injects angle directly)
    func processAngle(_ rawAngle: Double) {
        angleHistory.append(rawAngle)
        if angleHistory.count > historySize { angleHistory.removeFirst() }
        let smoothed = angleHistory.reduce(0, +) / Double(angleHistory.count)
        currentElbowAngle = smoothed
        warning = .none

        switch state {
        case .waitingForDown:
            if smoothed < downThreshold {
                state = .atBottom(frameCount: 1)
            } else if smoothed < goLowerBand {
                warning = .goLower
            }

        case .atBottom(let count):
            if smoothed >= downThreshold {
                // Rose back up before holding the bottom long enough — not a valid rep.
                state = .waitingForDown
            } else if count >= minBottomFrames {
                state = .waitingForUp
            } else {
                state = .atBottom(frameCount: count + 1)
            }

        case .waitingForUp:
            if smoothed > upThreshold {
                repCount += 1
                state = .waitingForDown
                angleHistory = []
            }
        }
    }
}
