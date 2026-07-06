import Testing
@testable import PushUpMatch

@MainActor
struct PushUpRepCounterTests {

    // Helper: pump N frames at a given angle
    private func pump(_ counter: PushUpRepCounter, angle: Double, frames: Int) {
        for _ in 0..<frames { counter.processAngle(angle) }
    }

    @Test func oneFullRep() {
        let counter = PushUpRepCounter()
        pump(counter, angle: 85, frames: 5)   // hold at bottom (≥3 frames needed)
        pump(counter, angle: 165, frames: 5)  // extend up
        #expect(counter.repCount == 1)
    }

    @Test func partialRepNotCounted() {
        let counter = PushUpRepCounter()
        pump(counter, angle: 110, frames: 5)  // not below the 110° down threshold
        pump(counter, angle: 165, frames: 5)
        #expect(counter.repCount == 0)
    }

    @Test func multipleRepsCount() {
        let counter = PushUpRepCounter()
        for _ in 0..<3 {
            pump(counter, angle: 85, frames: 5)
            pump(counter, angle: 165, frames: 5)
        }
        #expect(counter.repCount == 3)
    }

    @Test func missingPoseSetsWarning() {
        let counter = PushUpRepCounter()
        counter.process(pose: nil)
        #expect(counter.warning == .bodyNotVisible)
        #expect(counter.repCount == 0)
    }

    @Test func singleFrameAtBottomNotCounted() {
        // Needs minBottomFrames (3) to register — 1 frame must not count
        let counter = PushUpRepCounter()
        counter.processAngle(85)   // 1 frame at bottom
        pump(counter, angle: 165, frames: 5)
        #expect(counter.repCount == 0)
    }

    @Test func goLowerWarningInBand() {
        let counter = PushUpRepCounter()
        pump(counter, angle: 115, frames: 5)  // in the 110–130 "go lower" band
        #expect(counter.warning == .goLower)
    }

    @Test func resetClearsAll() {
        let counter = PushUpRepCounter()
        pump(counter, angle: 85, frames: 5)
        pump(counter, angle: 165, frames: 5)
        #expect(counter.repCount == 1)
        counter.reset()
        #expect(counter.repCount == 0)
        #expect(counter.warning == .none)
    }
}
