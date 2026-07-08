import SwiftUI
import SwiftData
import Combine
import UIKit

// MARK: - Confetti

private struct Confetto: Identifiable {
    let id: Int
    let xFraction: CGFloat
    let size: CGFloat
    let color: Color
    let rotationEnd: Double
    let delay: Double
    let duration: Double
}

// MARK: - ViewModel

@MainActor
final class MatchViewModel: ObservableObject {
    @Published private(set) var repCount: Int = 0
    @Published private(set) var warning: RepCounterWarning = .none
    @Published private(set) var currentPose: DetectedPose?
    @Published private(set) var matchStarted = false

    let cameraManager = CameraManager()
    let repCounter    = PushUpRepCounter()
    let engine: MatchEngine

    private let poseDetector = PoseDetector()
    private var cancellables = Set<AnyCancellable>()
    private var readySince: Date?

    private let readyHoldSeconds: TimeInterval = 1.5
    private let plankAngleThreshold: Double = 140

    init(country: Country) {
        engine = MatchEngine(country: country)

        poseDetector.onPoseDetected = { [weak self] pose in
            DispatchQueue.main.async { self?.handle(pose: pose) }
        }
        cameraManager.delegate = poseDetector

        repCounter.$repCount.assign(to: &$repCount)
        repCounter.$warning.assign(to: &$warning)
        engine.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func handle(pose: DetectedPose?) {
        currentPose = pose

        guard matchStarted else {
            if let angle = pose?.elbowAngle(), angle >= plankAngleThreshold {
                if readySince == nil { readySince = Date() }
                if let since = readySince, Date().timeIntervalSince(since) >= readyHoldSeconds {
                    beginMatch()
                }
            } else {
                readySince = nil
            }
            return
        }

        repCounter.process(pose: pose)
    }

    private func beginMatch() {
        matchStarted = true
        repCounter.reset()
        SoundManager.shared.play("sfx_kickoff")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        engine.start()
    }

    func startForTesting() {
        guard !matchStarted else { return }
        beginMatch()
    }

    func simulateRep() {
        guard matchStarted else { return }
        repCounter.injectRep()
    }

    func simulateEnd() {
        engine.forceEnd()
    }

    func startCamera(cameraFront: Bool) {
        cameraManager.configure(position: cameraFront ? .front : .back)
        cameraManager.startRunning()
    }

    func stopMatch() {
        cameraManager.stopRunning()
        engine.stop()
    }
}

// MARK: - MatchView

struct MatchView: View {
    let country: Country

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allStats: [PlayerStats]
    @AppStorage("cameraPosition") private var cameraFront = true
    @AppStorage(Country.userCountryKey) private var userCountryID = ""
    @AppStorage("playerName") private var playerName = ""

    @StateObject private var vm: MatchViewModel
    @State private var showUserGoal = false
    @State private var showOpponentGoal = false
    @State private var bannerText: String?
    @State private var showResult = false
    @State private var showFUTCard = false
    @State private var readyPulse = false
    @State private var showExitConfirm = false
    @State private var forfeited = false
    @State private var celebrations: [Celebration] = []

    // Visual effects
    @State private var screenFlashColor: Color = .white
    @State private var screenFlashOpacity: Double = 0
    @State private var confettos: [Confetto] = []
    @State private var confettiDrop = false
    @State private var showYellowCard = false
    @State private var showRedCard = false
    @State private var goalShakeOffset: CGFloat = 0
    @State private var cameraShake: CGSize = .zero

    private enum Celebration: Identifiable {
        case rankUp(Rank)
        case achievement(AchievementDef)

        var id: String {
            switch self {
            case .rankUp(let rank):     return "rank_\(rank.rawValue)"
            case .achievement(let def): return "achievement_\(def.id)"
            }
        }
    }

    private var finalUserGoals: Int     { forfeited ? 0 : vm.engine.userGoals }
    private var finalOpponentGoals: Int { forfeited ? 3 : vm.engine.opponentGoals }
    private var didWin: Bool            { forfeited ? false : vm.engine.userWon }
    private let xpPerRep = 5

    init(country: Country) {
        self.country = country
        _vm = StateObject(wrappedValue: MatchViewModel(country: country))
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: vm.cameraManager.captureSession)
                .ignoresSafeArea()

            SkeletonOverlayView(pose: vm.currentPose, mirrored: cameraFront)
                .ignoresSafeArea()

            // Screen flash (goal / opponent score)
            screenFlashColor
                .opacity(screenFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                HStack {
                    Button { showExitConfirm = true } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.65))
                            .clipShape(Circle())
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button { vm.simulateEnd() } label: {
                            Text("END")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.red.opacity(0.85))
                                .clipShape(Capsule())
                        }
                        Button { vm.simulateRep() } label: {
                            Text("+ REP")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.yellow)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                broadcastBar
                    .padding(.horizontal, 16)

                goalProgressBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if let text = bannerText {
                    banner(text).padding(.top, 10)
                }

                Spacer()

                warningBanner.padding(.bottom, 8)

                bottomHUD
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            // Confetti layer (above HUD, below overlays)
            confettiOverlay

            if !vm.matchStarted { getReadyOverlay }
            if showUserGoal     { goalOverlay(text: "GOAL!", color: Color(red: 1.0, green: 0.84, blue: 0.0), isUser: true) }
            if showOpponentGoal { goalOverlay(text: "\(country.flag) SCORED!", color: .white, isUser: false) }
            if showYellowCard   { cardOverlay(color: .yellow, title: "YELLOW CARD", subtitle: "Speed up!") }
            if showRedCard      { cardOverlay(color: .red, title: "RED CARD", subtitle: vm.engine.userGoals > 0 ? "-1 GOAL" : "No goal to lose") }
            if showResult       { resultOverlay }

            if showFUTCard {
                FUTCardView(
                    reps: vm.engine.reps,
                    userGoals: finalUserGoals,
                    opponentGoals: finalOpponentGoals,
                    userCountry: userCountry,
                    opponentCountry: country,
                    playerName: playerName,
                    streak: allStats.first?.currentStreak ?? 0,
                    level: allStats.first?.level ?? 1,
                    onDismiss: {
                        withAnimation { showFUTCard = false }
                        withAnimation { showResult = true }
                    }
                )
                .zIndex(9)
                .transition(.opacity)
            }

            if let celebration = celebrations.first {
                Group {
                    switch celebration {
                    case .rankUp(let rank):
                        RankUpCardView(rank: rank) { advanceCelebration() }
                    case .achievement(let def):
                        AchievementUnlockedCardView(achievement: def) { advanceCelebration() }
                    }
                }
                .id(celebration.id)
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .offset(cameraShake)
        .background(Color.black)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("Leave the match?", isPresented: $showExitConfirm) {
            Button("Forfeit & Leave", role: .destructive) { forfeit() }
            Button("Keep Playing", role: .cancel) {}
        } message: {
            Text("Leaving now counts as a forfeit — the match will be recorded as a 3-0 defeat.")
        }
        .onAppear {
            vm.startCamera(cameraFront: cameraFront)
            readyPulse = true
            vm.startForTesting()
        }
        .onDisappear { vm.stopMatch() }
        .onChange(of: vm.repCount) { _, _ in
            SoundManager.shared.play("sfx_rep", volume: 0.6)
            vm.engine.registerRep()
        }
        .onChange(of: vm.engine.lastEvent) { _, event in
            handleEvent(event)
        }
    }

    // MARK: - Broadcast Bar

    private var userCountry: Country? { Country.find(id: userCountryID) }
    private var timeText: String {
        let t = max(0, vm.engine.timeRemaining)
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private var broadcastBar: some View {
        HStack(spacing: 0) {
            flagBadge(flag: userCountry?.flag ?? "💪",
                      name: userCountry?.name ?? "YOU",
                      accentColor: Color(red: 1.0, green: 0.84, blue: 0.0))

            VStack(spacing: 2) {
                Text("\(vm.engine.userGoals) — \(vm.engine.opponentGoals)")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if vm.engine.isGoldenGoal {
                    Text("⚡ GOLDEN GOAL")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.yellow.opacity(0.2))
                        .clipShape(Capsule())
                } else {
                    Text(timeText)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            vm.engine.isFinalPhase
                                ? .red
                                : Color(red: 1, green: 0.76, blue: 0.2)
                        )
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.3), value: vm.engine.timeRemaining)
                }
            }
            .frame(maxWidth: .infinity)

            flagBadge(flag: country.flag,
                      name: country.name,
                      accentColor: Color(red: 0.35, green: 0.6, blue: 1))
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .padding(.top, 8)
    }

    private func flagBadge(flag: String, name: String, accentColor: Color) -> some View {
        VStack(spacing: 5) {
            Text(flag)
                .font(.system(size: 62))

            Text(name.uppercased())
                .font(.system(size: 9, weight: .black))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 82)
        }
        .padding(.horizontal, 4)
        .frame(width: 92)
    }

    // MARK: - Progress Bar

    private var goalProgressBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<vm.engine.repsPerGoal, id: \.self) { index in
                        let filled = index < vm.engine.repsTowardNextGoal
                        Capsule()
                            .fill(
                                filled
                                    ? AnyShapeStyle(LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.4), Color(red: 1.0, green: 0.84, blue: 0.0)],
                                                                   startPoint: .top, endPoint: .bottom))
                                    : AnyShapeStyle(Color.white.opacity(0.18))
                            )
                            .frame(height: 14)
                            .animation(.snappy(duration: 0.2), value: vm.engine.repsTowardNextGoal)
                    }
                }

                Text("⚽")
                    .font(.system(size: 22))
            }

            if vm.matchStarted {
                cardTimerBar
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var cardTimerBar: some View {
        let limit  = vm.engine.country.difficulty.goalTimeLimit
        let elapsed = vm.engine.goalAttemptSeconds
        let fraction = CGFloat(min(1.0, Double(elapsed) / Double(limit)))
        let pastYellow = elapsed >= vm.engine.country.difficulty.yellowCardThreshold
        let fillColor: Color = pastYellow ? .red : Color(red: 1, green: 0.72, blue: 0)

        return GeometryReader { geo in
            let w = geo.size.width

            // Background track
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.12))
                .frame(width: w, height: 5)
                .position(x: w / 2, y: 21)

            // Filled portion
            RoundedRectangle(cornerRadius: 3)
                .fill(fillColor)
                .frame(width: max(0, w * fraction), height: 5)
                .position(x: max(0, w * fraction) / 2, y: 21)
                .animation(.linear(duration: 1), value: fraction)

            // Yellow card marker at 50%
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.yellow)
                .frame(width: 11, height: 16)
                .position(x: w * 0.5, y: 8)

            // Red card marker at the end
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red)
                .frame(width: 11, height: 16)
                .position(x: w - 5, y: 8)
        }
        .frame(height: 26)
    }

    private func banner(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.yellow)
            .clipShape(Capsule())
            .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Get Ready Overlay

    private var getReadyOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 28) {
                HStack(spacing: 20) {
                    vsFlagCard(flag: userCountry?.flag ?? "💪", name: userCountry?.name ?? "YOU")

                    Text("VS")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))

                    vsFlagCard(flag: country.flag, name: country.name)
                }

                VStack(spacing: 6) {
                    Text("GET IN POSITION")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .scaleEffect(readyPulse ? 1.07 : 0.95)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                            value: readyPulse
                        )

                    Text("Hold push-up position to kick off")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
    }

    private func vsFlagCard(flag: String, name: String) -> some View {
        VStack(spacing: 6) {
            Text(flag)
                .font(.system(size: 68))
            Text(name.uppercased())
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: 90)
        }
    }

    // MARK: - Bottom HUD

    private var bottomHUD: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("TOTAL REPS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.65))
                Text("\(vm.engine.reps)")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()
        }
    }

    private var repProgressCoin: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.98, green: 0.80, blue: 0.30).opacity(0.22),
                            Color(red: 0.83, green: 0.58, blue: 0.10).opacity(0.12)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 75
                    )
                )

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                .padding(7)

            Circle()
                .trim(from: 0,
                      to: Double(vm.engine.repsTowardNextGoal) / Double(vm.engine.repsPerGoal))
                .stroke(
                    LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.4), Color(red: 1.0, green: 0.84, blue: 0.0)],
                                   startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(7)
                .animation(.snappy(duration: 0.25), value: vm.engine.repsTowardNextGoal)

            VStack(spacing: 0) {
                Text("\(vm.engine.repsTowardNextGoal)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: vm.engine.repsTowardNextGoal)
                Text("/ \(vm.engine.repsPerGoal)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
        }
        .frame(width: 150, height: 150)
    }

    // MARK: - Warnings

    @ViewBuilder
    private var warningBanner: some View {
        switch vm.warning {
        case .bodyNotVisible where vm.matchStarted:
            warningPill("Move back — full body not visible")
        case .goLower:
            warningPill("Go lower!")
        default:
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
    }

    // MARK: - Goal Overlay

    private func goalOverlay(text: String, color: Color, isUser: Bool) -> some View {
        let isVisible = isUser ? showUserGoal : showOpponentGoal
        return VStack(spacing: 12) {
            if isUser {
                Text("⚽")
                    .font(.system(size: 80))
                    .scaleEffect(isVisible ? 1 : 0.3)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.52),
                        value: isVisible
                    )
            }
            Text(text)
                .font(.system(size: 72, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
        .offset(x: isUser ? goalShakeOffset : 0)
        .scaleEffect(isVisible ? 1 : 0.2)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: isVisible)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.1).combined(with: .opacity),
            removal: .scale(scale: 1.5).combined(with: .opacity)
        ))
    }

    // MARK: - Card Overlay

    private func cardOverlay(color: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 52, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                )

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .scale(scale: 1.3).combined(with: .opacity)
        ))
    }

    // MARK: - Confetti

    private var confettiOverlay: some View {
        GeometryReader { geo in
            ForEach(confettos) { c in
                RoundedRectangle(cornerRadius: 2)
                    .fill(c.color)
                    .frame(width: c.size, height: c.size * 1.6)
                    .rotationEffect(.degrees(confettiDrop ? c.rotationEnd : 0))
                    .position(
                        x: c.xFraction * geo.size.width,
                        y: confettiDrop ? geo.size.height + 60 : -30
                    )
                    .animation(
                        .easeIn(duration: c.duration).delay(c.delay),
                        value: confettiDrop
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func spawnConfetti() {
        let colors: [Color] = [
            Color(red: 1.0, green: 0.84, blue: 0.0),
            .white,
            Color(red: 0, green: 0.85, blue: 0.45),
            Color(red: 0.15, green: 0.55, blue: 1.0),
            Color(red: 0.85, green: 0.85, blue: 0.85),
            Color(red: 0.13, green: 0.60, blue: 0.22)
        ]
        confettos = (0..<28).map { i in
            let base = CGFloat(i) / 28.0
            return Confetto(
                id: i,
                xFraction: max(0.04, min(0.96, base + CGFloat.random(in: -0.04...0.04))),
                size: CGFloat.random(in: 6...14),
                color: colors[i % colors.count],
                rotationEnd: Double.random(in: 180...540),
                delay: Double.random(in: 0...0.45),
                duration: Double.random(in: 0.85...1.55)
            )
        }
        confettiDrop = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation { confettiDrop = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            confettos = []
            confettiDrop = false
        }
    }

    private func triggerFlash(color: Color) {
        screenFlashColor = color
        withAnimation(.easeOut(duration: 0.08))  { screenFlashOpacity = 0.55 }
        withAnimation(.easeIn(duration: 0.38).delay(0.08)) { screenFlashOpacity = 0 }
    }

    private func triggerGoalFlash() {
        screenFlashColor = .orange
        withAnimation(.easeOut(duration: 0.1)) { screenFlashOpacity = 1.0 }
        withAnimation(.easeIn(duration: 0.4).delay(0.5)) { screenFlashOpacity = 0 }
    }

    private func triggerCameraShake(intensity: CGFloat = 10) {
        let moves: [(CGFloat, CGFloat)] = [
            ( intensity, -intensity * 0.5),
            (-intensity,  intensity * 0.4),
            ( intensity * 0.6, intensity * 0.6),
            (-intensity * 0.4, -intensity * 0.3),
            ( intensity * 0.2,  intensity * 0.2),
            (.zero, .zero)
        ]
        for (i, move) in moves.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    cameraShake = CGSize(width: move.0, height: move.1)
                }
            }
        }
    }

    private func triggerGoalShake() {
        let offsets: [CGFloat] = [14, -14, 10, -10, 6, -6, 0]
        for (i, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                withAnimation(.easeInOut(duration: 0.06)) { goalShakeOffset = offset }
            }
        }
    }

    // MARK: - Result Overlay

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                HStack(spacing: 20) {
                    vsFlagCard(flag: userCountry?.flag ?? "💪", name: userCountry?.name ?? "YOU")

                    VStack(spacing: 6) {
                        Text("\(finalUserGoals) - \(finalOpponentGoals)")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(didWin ? "🏆 VICTORY" : "😤 DEFEAT")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(didWin ? Color(red: 1.0, green: 0.84, blue: 0.0) : .red)
                    }

                    vsFlagCard(flag: country.flag, name: country.name)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 22)

                Text(resultMessage)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                HStack(spacing: 16) {
                    resultStatPill(value: "\(vm.engine.reps)", label: "REPS")
                    resultStatPill(value: "+\(vm.engine.reps * xpPerRep)", label: "XP")
                }
                .padding(.top, 22)

                Spacer()

                Button("Continue") { saveAndDismiss() }
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.13, green: 0.60, blue: 0.22), Color(red: 0.07, green: 0.40, blue: 0.14)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
    }

    private func resultStatPill(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0))
            Text(label)
                .font(.system(size: 10, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 13)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private var resultMessage: String {
        if forfeited {
            return "You forfeited the match — recorded as a 3-0 defeat. Finish the fight next time!"
        }
        let repsShort = vm.engine.repsPerGoal - vm.engine.repsTowardNextGoal
        if vm.engine.userWon {
            return "You conquered \(country.name)! Time for a stronger opponent?"
        } else if vm.engine.userGoals >= vm.engine.opponentGoals - 1 {
            return "So close — only \(repsShort) push-up\(repsShort == 1 ? "" : "s") away from turning it around!"
        } else {
            return "\(country.name) was too fast this time. Train and take revenge!"
        }
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: MatchEvent?) {
        switch event {
        case .userGoal:
            haptic(.success)
            SoundManager.shared.play("sfx_goal")
            flashGoal($showUserGoal)
            spawnConfetti()
        case .opponentGoal:
            haptic(.warning)
            SoundManager.shared.play("sfx_opp_goal")
            flash($showOpponentGoal)
        case .yellowCard:
            haptic(.warning)
            flash($showYellowCard)
            triggerFlash(color: .yellow)
        case .redCard:
            haptic(.error)
            flash($showRedCard)
            triggerFlash(color: .red)
        case .finalPhase:
            haptic(.warning)
            SoundManager.shared.play("sfx_match_point")
            showBanner("⏱ FINAL 15 SECONDS!")
        case .goldenGoal:
            haptic(.warning)
            SoundManager.shared.play("sfx_match_point")
            showBanner("⚡ GOLDEN GOAL — next goal wins!")
        case .matchOver:
            haptic(vm.engine.userWon ? .success : .error)
            SoundManager.shared.play(vm.engine.userWon ? "sfx_victory" : "sfx_defeat")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showFUTCard = true }
            }
        case .none:
            break
        }
    }

    private func showBanner(_ text: String) {
        withAnimation { bannerText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { bannerText = nil }
        }
    }

    private func flash(_ binding: Binding<Bool>) {
        withAnimation(.spring(duration: 0.3)) { binding.wrappedValue = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { binding.wrappedValue = false }
        }
    }

    private func flashGoal(_ binding: Binding<Bool>) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { binding.wrappedValue = true }
        triggerGoalShake()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.2)) { binding.wrappedValue = false }
        }
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    // MARK: - Persistence

    private func saveAndDismiss() {
        let (rankUp, achievements) = persistMatch(
            won: didWin,
            userGoals: finalUserGoals,
            opponentGoals: finalOpponentGoals
        )
        var queue: [Celebration] = []
        if let rankUp { queue.append(.rankUp(rankUp)) }
        queue.append(contentsOf: achievements.map { .achievement($0) })

        if queue.isEmpty {
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.4)) { celebrations = queue }
        }
    }

    private func advanceCelebration() {
        if celebrations.count <= 1 {
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.4)) { celebrations.removeFirst() }
        }
    }

    private func forfeit() {
        vm.stopMatch()
        guard vm.engine.hasStarted, !vm.engine.isMatchOver else {
            dismiss()
            return
        }
        forfeited = true
        SoundManager.shared.play("sfx_defeat")
        haptic(.error)
        withAnimation { showResult = true }
    }

    private func persistMatch(won: Bool, userGoals: Int, opponentGoals: Int) -> (Rank?, [AchievementDef]) {
        let stats = allStats.first ?? {
            let s = PlayerStats(); modelContext.insert(s); return s
        }()
        let oldRank = Rank.rank(for: stats.totalReps)
        stats.totalReps += vm.engine.reps
        stats.totalXP   += vm.engine.reps * xpPerRep
        if vm.engine.reps > stats.bestSession {
            stats.bestSession = vm.engine.reps
        }

        let record = MatchRecord(
            countryName: country.name,
            countryFlag: country.flag,
            userGoals: userGoals,
            opponentGoals: opponentGoals,
            reps: vm.engine.reps,
            won: won,
            xpEarned: vm.engine.reps * xpPerRep
        )
        modelContext.insert(record)
        try? modelContext.save()

        let newRank = Rank.rank(for: stats.totalReps)
        let records = (try? modelContext.fetch(FetchDescriptor<MatchRecord>())) ?? []
        let unlocked = Achievements.registerNewUnlocks(stats: stats, records: records)
        return (newRank > oldRank ? newRank : nil, unlocked)
    }
}
