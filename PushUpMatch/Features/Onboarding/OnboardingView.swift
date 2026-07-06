import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var step = 0
    @State private var showSignIn = false
    @State private var nameInput = ""
    @AppStorage("playerName") private var playerName = ""
    @AppStorage("fitnessLevel") private var fitnessLevel = ""
    @AppStorage("topGoal") private var topGoal = ""
    @AppStorage("ageRange") private var ageRange = ""
    @AppStorage("gender") private var gender = ""
    @State private var exerciseHours: Double = 1
    @AppStorage("dailyExerciseHours") private var dailyExerciseHours = 1
    @AppStorage("acquisitionSource") private var acquisitionSource = ""
    @AppStorage("calibrationReps") private var calibrationReps = 0
    @AppStorage("suggestedDifficulty") private var suggestedDifficulty = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var planProgress: Double = 0
    @FocusState private var nameFieldFocused: Bool

    private let totalSteps = 18

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch step {
            case 0:  welcomeStep
            case 1:  coachPage(image: "onboarding_coach",
                               text: "Hello recruit! I can see you\nhave lots of potential.")
            case 2:  coachPage(image: "onboarding_coach2",
                               text: "Just a few questions and\nwe can get started.")
            case 3:  nameStep
            case 4:  ageStep
            case 5:  genderStep
            case 6:  sourceStep
            case 7:  experienceStep
            case 8:  goalStep
            case 9:  hoursStep
            case 10: reviewsStep
            case 11: notificationsStep
            case 12: cameraStep
            case 13: placementStep
            case 14: CalibrationTestView { reps in
                         if let reps {
                             calibrationReps = reps
                             suggestedDifficulty = reps < 10 ? "easy" : (reps < 20 ? "medium" : "hard")
                         } else {
                             // Skipped the test — start newcomers on the easiest tier.
                             suggestedDifficulty = "easy"
                         }
                         advance()
                     }
            case 15: planLoadingStep
            case 16: planStep
            default: countryStep
            }
        }
        .animation(.easeInOut, value: step)
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            Text("PUSH-UP MATCH")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.9), radius: 5, y: 2)

            Text("Rank Up. Get Strong. Become a Warrior")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.9), radius: 4, y: 1)

            Spacer()

            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 250)
                .clipShape(RoundedRectangle(cornerRadius: 36))
                .shadow(color: .black.opacity(0.7), radius: 14, y: 8)

            Spacer()

            Button("Get Started") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Button("I already have an account") { showSignIn = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 3, y: 1)
                .padding(.top, 2)
        }
        .padding(32)
        .sheet(isPresented: $showSignIn) {
            SignInSheet {
                showSignIn = false
                completeOnboarding()
            }
        }
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func coachPage(image: String, text: String) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 30)

            // Speech bubble above the coach's head
            VStack(spacing: 0) {
                TypewriterText(fullText: text)
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
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
            }

            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 460)
                .shadow(color: .black.opacity(0.5), radius: 16, y: 10)
                .padding(.top, 6)
                .id(image)

            Spacer()

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(32)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .id(image)  // separate identity per coach page so the typewriter restarts
    }

    /// Back button + progress bar shared by the question screens.
    private var questionHeader: some View { stepHeader(backSteps: 1) }

    private func stepHeader(backSteps: Int) -> some View {
        HStack(spacing: 14) {
            Button { step -= backSteps } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.white.opacity(0.12))
                    .clipShape(Circle())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.15))
                    Capsule()
                        .fill(.orange)
                        .frame(width: geo.size.width * Double(step + 1) / Double(totalSteps))
                }
            }
            .frame(height: 8)
        }
        .padding(.top, 8)
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("Every warrior has a name.\nWhat is your name?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 36)

            TextField("Your name", text: $nameInput)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .focused($nameFieldFocused)
                .submitLabel(.done)
                .padding(16)
                .background(.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(nameFieldFocused ? Color.orange : .white.opacity(0.2), lineWidth: 1.5)
                )
                .padding(.top, 28)

            Spacer()

            Button("Continue") {
                playerName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                nameFieldFocused = false
                advance()
            }
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .onAppear { nameFieldFocused = true }
    }

    private var ageStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("How old are you?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 36)

            VStack(spacing: 12) {
                ageOption("Under 18", key: "u18")
                ageOption("18 - 24",  key: "18-24")
                ageOption("25 - 34",  key: "25-34")
                ageOption("35 - 44",  key: "35-44")
                ageOption("45+",      key: "45plus")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(ageRange.isEmpty)
                .opacity(ageRange.isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func ageOption(_ title: String, key: String) -> some View {
        selectableOption(title, isSelected: ageRange == key) { ageRange = key }
    }

    private var genderStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("What is your gender?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 36)

            VStack(spacing: 12) {
                genderOption("Male",              key: "male")
                genderOption("Female",            key: "female")
                genderOption("Prefer not to say", key: "unspecified")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(gender.isEmpty)
                .opacity(gender.isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func genderOption(_ title: String, key: String) -> some View {
        selectableOption(title, isSelected: gender == key) { gender = key }
    }

    private var experienceStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("How experienced are you\nwith working out?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 36)

            VStack(spacing: 12) {
                experienceOption("I've never worked out", key: "never")
                experienceOption("I've tried before",     key: "tried")
                experienceOption("I train regularly",     key: "regular")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(fitnessLevel.isEmpty)
                .opacity(fitnessLevel.isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func experienceOption(_ title: String, key: String) -> some View {
        selectableOption(title, isSelected: fitnessLevel == key) { fitnessLevel = key }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("What's your top goal\nwith Push-Up Match?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 36)

            VStack(spacing: 12) {
                goalOption("To be Healthy",               key: "healthy")
                goalOption("Lose Weight",                 key: "weight")
                goalOption("To be Stronger",              key: "stronger")
                goalOption("A Fit Body",                  key: "fit")
                goalOption("Make my country a champion",  key: "champion")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(topGoal.isEmpty)
                .opacity(topGoal.isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func goalOption(_ title: String, key: String) -> some View {
        selectableOption(title, isSelected: topGoal == key) { topGoal = key }
    }

    private func selectableOption(_ title: String, isSelected: Bool, select: @escaping () -> Void) -> some View {
        Button {
            select()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? .black : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.black)
                }
            }
            .padding(16)
            .background(isSelected ? Color.orange : Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.orange : .white.opacity(0.2), lineWidth: 1.5)
            )
        }
    }

    private var sourceStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("Where did you hear\nabout Push-Up Match?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 36)

            VStack(spacing: 12) {
                sourceOption("TikTok",          key: "tiktok")
                sourceOption("Instagram",       key: "instagram")
                sourceOption("App Store",       key: "appstore")
                sourceOption("Friend / Family", key: "friend")
                sourceOption("Other",           key: "other")
            }
            .padding(.top, 28)

            Spacer()

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(acquisitionSource.isEmpty)
                .opacity(acquisitionSource.isEmpty ? 0.5 : 1)
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func sourceOption(_ title: String, key: String) -> some View {
        selectableOption(title, isSelected: acquisitionSource == key) { acquisitionSource = key }
    }

    // MARK: – Personalized plan

    private var goalLabel: String {
        switch topGoal {
        case "healthy":  return "To be Healthy"
        case "weight":   return "Lose Weight"
        case "stronger": return "To be Stronger"
        case "fit":      return "A Fit Body"
        case "champion": return "Make my country a champion"
        default:         return "Get Stronger"
        }
    }

    private var experienceLabel: String {
        switch fitnessLevel {
        case "never":   return "Beginner"
        case "tried":   return "Intermediate"
        case "regular": return "Advanced"
        default:        return "Beginner"
        }
    }

    private func daysTo(_ reps: Int) -> Int {
        let repsPerDay = 30 * max(1, dailyExerciseHours)
        return max(1, Int((Double(reps) / Double(repsPerDay)).rounded(.up)))
    }

    private var planLoadingStep: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: planProgress)
                    .stroke(
                        LinearGradient(colors: [.orange, Color(red: 0.85, green: 0.4, blue: 0.1)],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: planProgress)

                Text("\(Int(planProgress * 100))%")
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: planProgress)
            }
            .frame(width: 210, height: 210)

            Text(playerName.isEmpty
                 ? "We're building your\npersonal battle plan…"
                 : "\(playerName), we're building your\npersonal battle plan…")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 34)

            Text(planLoadingStatus)
                .font(.subheadline)
                .foregroundStyle(.orange)
                .padding(.top, 10)
                .animation(.easeInOut, value: planLoadingStatus)

            Spacer()
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .task {
            planProgress = 0
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.prepare()
            var lastTick = 0
            while planProgress < 1 {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 60...150)))
                planProgress = min(1, planProgress + Double.random(in: 0.015...0.05))
                let quarter = Int(planProgress * 4)
                if quarter > lastTick {
                    lastTick = quarter
                    haptic.impactOccurred(intensity: 0.5)
                }
            }
            try? await Task.sleep(for: .milliseconds(500))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            step += 1
        }
    }

    private var planLoadingStatus: String {
        switch planProgress {
        case ..<0.35:  return "Analyzing your answers…"
        case ..<0.7:   return "Scouting your opponents…"
        case ..<0.98:  return "Calibrating your training load…"
        default:       return "Done!"
        }
    }

    private var planStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Back skips the loading screen so the user can redo the calibration test.
            stepHeader(backSteps: 2)

            Text(playerName.isEmpty ? "Your Battle Plan is Ready!" : "\(playerName)'s Battle Plan is Ready!")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 32)

            VStack(spacing: 10) {
                planRow(icon: "target",       title: "Goal",           value: goalLabel)
                planRow(icon: "clock.fill",   title: "Daily training", value: "\(dailyExerciseHours)h / day")
                planRow(icon: "figure.strengthtraining.traditional",
                        title: "Starting level", value: experienceLabel)
            }
            .padding(.top, 24)

            Text("PROJECTED RANK PROGRESS")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.orange)
                .padding(.top, 26)

            HStack(spacing: 12) {
                projectionBadge(.gold,   days: daysTo(Rank.gold.minReps))
                projectionBadge(.master, days: daysTo(Rank.master.minReps))
                projectionBadge(.legend, days: daysTo(Rank.legend.minReps))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)

            Spacer()

            Button("Let's Do It!") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func planRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption2.bold())
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.55))
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func projectionBadge(_ rank: Rank, days: Int) -> some View {
        VStack(spacing: 6) {
            RankBadgeView(rank: rank, size: 56)
                .frame(height: 64)
            Text(rank.rawValue)
                .font(.caption.bold())
                .foregroundStyle(rank.color)
            Text("~\(days) day\(days == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: – Notifications

    private var notificationsStep: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 70))
                .foregroundStyle(.orange)
                .shadow(color: .orange.opacity(0.5), radius: 16)

            Text("Never Miss a Match")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 22)

            VStack(alignment: .leading, spacing: 12) {
                notificationBullet("Daily training reminder at 19:00")
                notificationBullet("Protect your streak")
                notificationBullet("Keep your country on top")
            }
            .padding(.top, 20)

            Spacer()

            Button("Enable Reminders") {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    if granted {
                        NotificationManager.shared.scheduleDailyReminder()
                    }
                    notificationsEnabled = granted
                    step += 1
                }
            }
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button("Maybe Later") {
                notificationsEnabled = false
                advance()
            }
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

    private func notificationBullet(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var hoursStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            if !playerName.isEmpty {
                Text("\(playerName), let's plan your training")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 28)
            }

            Text("How many hours a day\ndo you plan to exercise?")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, playerName.isEmpty ? 36 : 8)

            Spacer()

            Text(hoursLabel)
                .font(.system(size: 150, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, Color(red: 0.85, green: 0.4, blue: 0.1)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: exerciseHours)
                .frame(maxWidth: .infinity)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 12) {
                Text("1")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Slider(value: $exerciseHours, in: 1...6, step: 1)
                    .tint(.orange)
                    .onChange(of: exerciseHours) { _, _ in
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                Text("6+")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.bottom, 28)

            Button("Continue") {
                dailyExerciseHours = Int(exerciseHours)
                advance()
            }
            .font(.title3.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(.orange)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private var hoursLabel: String {
        let hours = Int(exerciseHours)
        return hours >= 6 ? "6h+" : "\(hours)h"
    }

    private var reviewsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            questionHeader

            Text("Warriors Love\nPush-Up Match")
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    reviewCard("Every push-up counts — the camera never misses a rep.",
                               author: "arda.fit")
                    reviewCard("Beat Brazil 3-2 with a golden goal. Best workout of my life!",
                               author: "matchday_kaan")
                    reviewCard("I train every day now just to keep my country on top.",
                               author: "warrior.mete")
                    reviewCard("Feels like a real match — the last 15 seconds are pure adrenaline.",
                               author: "gymrat_eren")
                }
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            Button("Continue") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    private func reviewCard(_ text: String, author: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
            Text("\"\(text)\"")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(red: 0.07, green: 0.12, blue: 0.3))
                .fixedSize(horizontal: false, vertical: true)
            Text(author)
                .font(.caption.bold())
                .foregroundStyle(.gray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }

    private var cameraStep: some View {
        onboardingPage(
            icon: "camera.fill",
            headline: "Camera Access",
            headlineColor: .white,
            body: "Push-Up Match uses your camera to count reps. All processing happens on-device — nothing is ever uploaded or stored.",
            cta: "Continue"
        )
    }

    private var placementStep: some View {
        VStack(spacing: 0) {
            questionHeader

            Spacer()

            placementIllustration
                .frame(height: 280)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 10, y: 6)

            Text("Prepare for Battle")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
                .padding(.top, 28)

            Text("Place your phone on the floor facing you\nin a well-lit area.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Spacer()

            Button("Next") { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(24)
        .background {
            Image("onboarding_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }

    /// Line-art illustration: a phone leaning against the wall on the floor.
    private var placementIllustration: some View {
        Canvas { context, size in
            let faint  = Color.white.opacity(0.45)
            let bright = Color.white.opacity(0.9)

            // Room: wall corner + floor edges
            var room = Path()
            room.move(to: CGPoint(x: size.width * 0.70, y: 0))
            room.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.64))
            room.move(to: CGPoint(x: 0, y: size.height * 0.56))
            room.addLine(to: CGPoint(x: size.width, y: size.height * 0.72))
            room.move(to: CGPoint(x: 0, y: size.height * 0.80))
            room.addLine(to: CGPoint(x: size.width, y: size.height * 0.98))
            context.stroke(room, with: .color(faint), lineWidth: 1.5)

            // Phone leaning back against the wall
            let w = size.width * 0.17
            let h = size.height * 0.56
            var phone = Path(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h),
                             cornerRadius: w * 0.24)
            // Speaker notch
            phone.move(to: CGPoint(x: -w * 0.16, y: -h / 2 + h * 0.06))
            phone.addLine(to: CGPoint(x: w * 0.16, y: -h / 2 + h * 0.06))
            // Side button
            phone.move(to: CGPoint(x: w / 2 + 2, y: -h * 0.14))
            phone.addLine(to: CGPoint(x: w / 2 + 2, y: h * 0.02))

            let transform = CGAffineTransform(translationX: size.width * 0.55,
                                              y: size.height * 0.40)
                .rotated(by: .pi / 20)
            context.stroke(phone.applying(transform), with: .color(bright), lineWidth: 2)
        }
        .padding(20)
    }

    private var countryStep: some View {
        MyCountryPickerView { _ in completeOnboarding() }
    }

    /// Advance to the next step with a haptic tap — used by every Continue button.
    private func advance() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        step += 1
    }

    private func completeOnboarding() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        isPresented = true
    }

    private func onboardingPage(icon: String?, headline: String, headlineColor: Color, body: String, cta: String) -> some View {
        VStack(spacing: 28) {
            Spacer()
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
            }
            Text(headline)
                .font(.system(size: icon == nil ? 48 : 34, weight: .black, design: .rounded))
                .foregroundStyle(headlineColor)
            Text(body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            Spacer()
            Button(cta) { advance() }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(32)
    }
}

/// Types text in letter by letter with a light haptic tick per character.
struct TypewriterText: View {
    let fullText: String
    var interval: Duration = .milliseconds(45)

    @State private var visibleCount = 0

    var body: some View {
        ZStack {
            // Invisible full text reserves the final size so the bubble doesn't grow.
            Text(fullText).opacity(0)
            Text(String(fullText.prefix(visibleCount)))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.prepare()
            let characters = Array(fullText)
            for index in 1...characters.count {
                try? await Task.sleep(for: interval)
                visibleCount = index
                if !characters[index - 1].isWhitespace {
                    haptic.impactOccurred(intensity: 0.55)
                }
            }
        }
    }
}

/// Downward-pointing speech bubble tail.
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Sign-in options for returning users: Sign in with Apple (live) and
/// Google (needs a GoogleSignIn SDK + OAuth client ID to activate).
struct SignInSheet: View {
    let onSignedIn: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showGoogleInfo = false
    @State private var showAppleError = false

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("Welcome Back, Warrior")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.top, 6)

            Text("Sign in to continue your campaign.")
                .font(.subheadline)
                .foregroundStyle(.gray)

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        showAppleError = true
                        return
                    }
                    let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    Task { @MainActor in
                        AuthManager.shared.signIn(
                            provider: .apple,
                            userID: credential.user,
                            displayName: name.isEmpty ? nil : name
                        )
                        onSignedIn()
                    }
                case .failure:
                    // User cancelled or auth failed — stay on the sheet.
                    break
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                showGoogleInfo = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "g.circle.fill")
                        .font(.title3)
                    Text("Continue with Google")
                        .font(.body.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(.white)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(red: 0.09, green: 0.09, blue: 0.11))
        .alert("Google Sign-In", isPresented: $showGoogleInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Google sign-in is coming soon. Please use Sign in with Apple for now.")
        }
        .alert("Sign-in failed", isPresented: $showAppleError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Something went wrong. Please try again.")
        }
    }
}
