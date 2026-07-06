import SwiftUI
import SwiftData
import Combine
import UIKit

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

    /// How long the player must hold push-up position before kickoff.
    private let readyHoldSeconds: TimeInterval = 1.5
    /// Arms extended in plank — same gate as the calibration test.
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
            // Kickoff gate: hold the top of a push-up (arms extended) briefly.
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

    func startCamera(cameraFront: Bool) {
        cameraManager.configure(position: cameraFront ? .front : .back)
        cameraManager.startRunning()
    }

    func stopMatch() {
        cameraManager.stopRunning()
        engine.stop()
    }
}

struct MatchView: View {
    let country: Country

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allStats: [PlayerStats]
    @AppStorage("cameraPosition") private var cameraFront = true
    @AppStorage(Country.userCountryKey) private var userCountryID = ""

    @StateObject private var vm: MatchViewModel
    @State private var showUserGoal = false
    @State private var showOpponentGoal = false
    @State private var bannerText: String?
    @State private var showResult = false
    @State private var readyPulse = false
    @State private var showExitConfirm = false
    @State private var forfeited = false
    @State private var celebrations: [Celebration] = []

    /// Post-match celebration cards, shown one at a time (rank-up first).
    private enum Celebration: Identifiable {
        case rankUp(Rank)
        case achievement(AchievementDef)

        var id: String {
            switch self {
            case .rankUp(let rank):       return "rank_\(rank.rawValue)"
            case .achievement(let def):   return "achievement_\(def.id)"
            }
        }
    }

    private var finalUserGoals: Int { forfeited ? 0 : vm.engine.userGoals }
    private var finalOpponentGoals: Int { forfeited ? 3 : vm.engine.opponentGoals }
    private var didWin: Bool { forfeited ? false : vm.engine.userWon }

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

            VStack(spacing: 0) {
                HStack {
                    Button { showExitConfirm = true } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                scoreboard
                    .padding(.horizontal, 16)

                goalProgressBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if let text = bannerText {
                    banner(text)
                        .padding(.top, 10)
                }

                Spacer()

                warningBanner
                    .padding(.bottom, 8)

                bottomHUD
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
            }

            if !vm.matchStarted { getReadyOverlay }
            if showUserGoal { goalOverlay(text: "GOAL!", color: .orange) }
            if showOpponentGoal { goalOverlay(text: "\(country.name) scored!", color: .red) }
            if showResult { resultOverlay }

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

    // MARK: – Scoreboard

    private var userCountry: Country? { Country.find(id: userCountryID) }

    private var timeText: String {
        "\(max(0, vm.engine.timeRemaining))"
    }

    private var scoreboard: some View {
        HStack(spacing: 14) {
            sideBadge(flag: userCountry?.flag ?? "💪", name: userCountry?.name ?? "YOU")

            VStack(spacing: 2) {
                Text("\(vm.engine.userGoals) - \(vm.engine.opponentGoals)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                if vm.engine.isGoldenGoal {
                    Text("GOLDEN GOAL")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                } else {
                    Text(timeText)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(vm.engine.isFinalPhase ? .red : .orange)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.3), value: vm.engine.timeRemaining)
                }
            }
            .frame(maxWidth: .infinity)

            sideBadge(flag: country.flag, name: country.name)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.black.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.top, 8)
    }

    private func sideBadge(flag: String, name: String) -> some View {
        VStack(spacing: 5) {
            Text(flag)
                .font(.system(size: 72))
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            Text(name)
                .font(.footnote.bold())
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: 104)
    }

    /// One segment per rep toward the next goal; fills with each push-up and
    /// empties when the engine resets the counter after a goal.
    private var goalProgressBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<vm.engine.repsPerGoal, id: \.self) { index in
                    Capsule()
                        .fill(index < vm.engine.repsTowardNextGoal
                              ? AnyShapeStyle(
                                    LinearGradient(colors: [.yellow, .orange],
                                                   startPoint: .top, endPoint: .bottom))
                              : AnyShapeStyle(Color.white.opacity(0.22)))
                        .frame(height: 12)
                        .shadow(color: index < vm.engine.repsTowardNextGoal
                                ? .orange.opacity(0.7) : .clear,
                                radius: 4)
                }
            }

            Text("⚽")
                .font(.system(size: 20))
                .opacity(vm.engine.repsTowardNextGoal >= vm.engine.repsPerGoal - 1 ? 1 : 0.45)
                .scaleEffect(vm.engine.repsTowardNextGoal >= vm.engine.repsPerGoal - 1 ? 1.2 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.55))
        .clipShape(Capsule())
        .animation(.snappy(duration: 0.3), value: vm.engine.repsTowardNextGoal)
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

    // MARK: – Get ready overlay

    private var getReadyOverlay: some View {
        VStack(spacing: 10) {
            Text("GET IN PUSH-UP POSITION")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .shadow(color: .black, radius: 6)
                .scaleEffect(readyPulse ? 1.06 : 0.96)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: readyPulse)

            Text("The match kicks off when you're ready")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black, radius: 4)
        }
        .padding(.horizontal, 32)
        .allowsHitTesting(false)
    }

    // MARK: – Bottom HUD

    private var bottomHUD: some View {
        ZStack {
            repProgressCoin

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
    }

    /// Translucent coin showing progress toward the next goal (e.g. 7/10) —
    /// keeps the camera view visible behind it.
    private var repProgressCoin: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.80, blue: 0.30).opacity(0.30),
                                 Color(red: 0.83, green: 0.58, blue: 0.10).opacity(0.30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Circle()
                .trim(from: 0, to: Double(vm.engine.repsTowardNextGoal) / Double(vm.engine.repsPerGoal))
                .stroke(.orange, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(7)
                .animation(.snappy(duration: 0.25), value: vm.engine.repsTowardNextGoal)

            VStack(spacing: 0) {
                Text("\(vm.engine.repsTowardNextGoal)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: vm.engine.repsTowardNextGoal)
                Text("/ \(vm.engine.repsPerGoal)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 4, y: 1)
        }
        .frame(width: 120, height: 120)
    }

    // MARK: – Warnings

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

    // MARK: – Overlays

    private func goalOverlay(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 44, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .shadow(color: .black, radius: 6)
            .padding(24)
            .background(.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .transition(.scale.combined(with: .opacity))
    }

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(didWin ? "🏆 VICTORY!" : "😤 DEFEAT")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(didWin ? .orange : .red)

                Text("\(finalUserGoals) - \(finalOpponentGoals)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("vs \(country.flag) \(country.name)")
                    .font(.title3.bold())
                    .foregroundStyle(.gray)

                Text(resultMessage)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 4) {
                    Text("\(vm.engine.reps) reps")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                    Text("+\(vm.engine.reps * xpPerRep) XP")
                        .font(.headline)
                        .foregroundStyle(.yellow)
                }

                Button("Continue") { saveAndDismiss() }
                    .font(.title3.bold())
                    .padding(.horizontal, 44)
                    .padding(.vertical, 14)
                    .background(.orange)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 6)
            }
        }
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

    // MARK: – Event handling

    private func handleEvent(_ event: MatchEvent?) {
        switch event {
        case .userGoal:
            haptic(.success)
            SoundManager.shared.play("sfx_goal")
            flash($showUserGoal)
        case .opponentGoal:
            haptic(.warning)
            SoundManager.shared.play("sfx_opp_goal")
            flash($showOpponentGoal)
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
            withAnimation { showResult = true }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation { binding.wrappedValue = false }
        }
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    // MARK: – Persistence

    private func saveAndDismiss() {
        let (rankUp, achievements) = persistMatch(won: didWin, userGoals: finalUserGoals, opponentGoals: finalOpponentGoals)
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
            withAnimation(.easeInOut(duration: 0.4)) {
                celebrations.removeFirst()
            }
        }
    }

    /// Quitting mid-match is a forfeit: a fixed 3-0 defeat, shown on the result
    /// screen. Reps and XP earned so far are still credited. Leaving before
    /// kickoff costs nothing.
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

    /// Returns the new rank when this match crossed a threshold, plus any
    /// achievements unlocked by it.
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
