//
//  ContentView.swift
//  FocusTimer
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = FocusDataManager.shared
    @StateObject private var modeManager = FocusModeManager.shared
    @StateObject private var stackManager = TimerStackManager.shared
    @StateObject private var challengeManager = DailyChallengeManager.shared
    @StateObject private var soundManager = FocusSoundManager.shared
    @StateObject private var labelManager = SessionLabelManager.shared
    @StateObject private var levelingSystem = LevelingSystem.shared
    @StateObject private var coinManager = FocusCoinManager.shared
    @StateObject private var celebrationManager = CelebrationManager.shared
    @StateObject private var achievementManager = AchievementManager.shared
    
    @State private var timeRemaining: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var isWorkPhase: Bool = true
    @State private var currentSessionIndex: Int = 0
    @State private var timer: Timer? = nil
    @State private var sessionStartTime: Date = Date()
    @State private var showSettings: Bool = false
    @State private var showStatistics: Bool = false
    @State private var showHistory: Bool = false
    @State private var showModeSelector: Bool = false
    @State private var showStackEditor: Bool = false
    @State private var showLabelPicker: Bool = false
    @State private var showProfile: Bool = false
    @State private var showShop: Bool = false
    @State private var showAchievements: Bool = false
    @State private var showIntelligence: Bool = false
    @State private var showProjectPicker: Bool = false
    @State private var showDailyPlanner: Bool = false
    @State private var showRollingPomodoro: Bool = false
    @State private var initialPhaseDuration: Int = 25 * 60 // Track original duration for progress calc
    
    var body: some View {
        ZStack {
            AppleDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                topBar
                
                Spacer()
                
                // Challenge banner
                if let challenge = challengeManager.todayChallenge, !challenge.isCompleted {
                    challengeBanner(challenge)
                }
                
                // Phase label
                phaseLabel
                    .padding(.top, 16)
                
                // Session indicator
                sessionIndicator
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                
                // Timer circle
                timerCircle
                    .padding(.bottom, 32)
                
                // Queue progress
                if stackManager.isQueueMode {
                    queueProgressView
                        .padding(.bottom, 16)
                }
                
                // Control buttons
                controlButtons
                    .padding(.bottom, 24)
                
                // Bottom actions
                bottomActions
                
                Spacer()
                
                // Streak indicator
                if dataManager.statistics.currentStreak > 0 {
                    streakIndicator
                        .padding(.bottom, AppleDesign.Spacing.xxl)
                } else {
                    Spacer().frame(height: 52)
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showStatistics) { StatisticsView() }
        .sheet(isPresented: $showHistory) { HistoryView() }
        .sheet(isPresented: $showModeSelector) { ModeSelectorView() }
        .sheet(isPresented: $showStackEditor) { TimerStackView() }
        .sheet(isPresented: $showLabelPicker) { LabelPickerView() }
        .sheet(isPresented: $showProfile) { ProfileView() }
        .sheet(isPresented: $showShop) { FocusShopView() }
        .sheet(isPresented: $showAchievements) { AchievementsView() }
        .sheet(isPresented: $showIntelligence) { IntelligenceDashboardView() }
        .sheet(isPresented: $showProjectPicker) { ProjectPickerView() }
        .sheet(isPresented: $showDailyPlanner) { DailyPlannerView() }
        .sheet(isPresented: $showRollingPomodoro) { RollingPomodoroView() }
        
        // Celebration overlay
        .overlay(
            Group {
                if celebrationManager.showCelebration, let milestone = celebrationManager.currentMilestone {
                    CelebrationOverlay(milestone: milestone, isShowing: $celebrationManager.showCelebration)
                        .transition(.opacity)
                }
            }
        )
        
        .onAppear {
            challengeManager.generateDailyChallenge()
            loadModeSettings()
            levelingSystem.load()
            coinManager.load()
            achievementManager.load()
            celebrationManager.load()
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: AppleDesign.Spacing.sm) {
            // Mode selector button
            Button(action: { showModeSelector = true }) {
                HStack(spacing: 6) {
                    Image(systemName: modeManager.currentMode.icon)
                        .font(.system(size: 14))
                    Text(modeManager.currentMode.displayName)
                        .font(AppleDesign.Typography.caption1Medium)
                }
                .foregroundColor(modeManager.currentMode.appleColor)
                .padding(.horizontal, AppleDesign.Spacing.sm)
                .padding(.vertical, AppleDesign.Spacing.xxs)
                .background(modeManager.currentMode.appleColor.opacity(0.2))
                .cornerRadius(AppleDesign.Radius.pill)
            }
            
            Spacer()
            
            // Label indicator
            if let label = labelManager.selectedLabel {
                Button(action: { showLabelPicker = true }) {
                    Text(label.name)
                        .font(AppleDesign.Typography.caption1Medium)
                        .foregroundColor(AppleDesign.Colors.textPrimary)
                        .padding(.horizontal, AppleDesign.Spacing.xs)
                        .padding(.vertical, AppleDesign.Spacing.xxs)
                        .background(Color(hex: label.color).opacity(0.3))
                        .cornerRadius(AppleDesign.Radius.small)
                }
            } else {
                Button(action: { showLabelPicker = true }) {
                    Image(systemName: AppleSymbols.tagFill)
                        .font(.system(size: 14))
                        .foregroundColor(AppleDesign.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Daily goal indicator
            HStack(spacing: AppleDesign.Spacing.xxs) {
                Image(systemName: AppleSymbols.target)
                    .font(.system(size: 14))
                Text("\(dataManager.statistics.todaySessions)/\(dataManager.settings.dailyGoal)")
                    .font(AppleDesign.Typography.caption1Medium)
            }
            .foregroundColor(dataManager.statistics.todaySessions >= dataManager.settings.dailyGoal ? AppleDesign.Colors.focusGreen : AppleDesign.Colors.textSecondary)
            
            Spacer()
            
            // Stats buttons group
            HStack(spacing: AppleDesign.Spacing.xxs) {
                Button(action: { showAchievements = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: AppleSymbols.trophyFill)
                            .font(.system(size: 12))
                        Text("\(achievementManager.totalUnlocked)")
                            .font(AppleDesign.Typography.caption1Medium)
                    }
                    .foregroundColor(AppleDesign.Colors.focusYellow)
                    .padding(.horizontal, AppleDesign.Spacing.xs)
                    .padding(.vertical, AppleDesign.Spacing.xxs)
                    .background(AppleDesign.Colors.focusYellow.opacity(0.2))
                    .cornerRadius(AppleDesign.Radius.small)
                }
                
                Button(action: { showShop = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: AppleSymbols.bitcoinsignCircleFill)
                            .font(.system(size: 12))
                        Text("\(coinManager.coins)")
                            .font(AppleDesign.Typography.caption1Medium)
                    }
                    .foregroundColor(AppleDesign.Colors.focusOrange)
                    .padding(.horizontal, AppleDesign.Spacing.xs)
                    .padding(.vertical, AppleDesign.Spacing.xxs)
                    .background(AppleDesign.Colors.focusOrange.opacity(0.2))
                    .cornerRadius(AppleDesign.Radius.small)
                }
                
                Button(action: { showProfile = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: AppleSymbols.starFill)
                            .font(.system(size: 10))
                        Text("Lv.\(levelingSystem.currentLevel)")
                            .font(AppleDesign.Typography.caption2)
                    }
                    .foregroundColor(AppleDesign.Colors.focusPurple)
                    .padding(.horizontal, AppleDesign.Spacing.xs)
                    .padding(.vertical, AppleDesign.Spacing.xxs)
                    .background(AppleDesign.Colors.focusPurple.opacity(0.2))
                    .cornerRadius(AppleDesign.Radius.small)
                }
            }
            
            // Navigation icons
            HStack(spacing: AppleDesign.Spacing.md) {
                Button(action: { showStatistics = true }) {
                    Image(systemName: AppleSymbols.chartBarFill)
                        .font(.system(size: 18))
                        .foregroundColor(AppleDesign.Colors.textSecondary)
                }
                
                Button(action: { showIntelligence = true }) {
                    Image(systemName: AppleSymbols.brainHeadProfile)
                        .font(.system(size: 18))
                        .foregroundColor(AppleDesign.Colors.focusPurple)
                }
                
                Button(action: { showProjectPicker = true }) {
                    Image(systemName: AppleSymbols.folderFill)
                        .font(.system(size: 18))
                        .foregroundColor(AppleDesign.Colors.focusCyan)
                }
                
                Button(action: { showSettings = true }) {
                    Image(systemName: AppleSymbols.gearshapeFill)
                        .font(.system(size: 18))
                        .foregroundColor(AppleDesign.Colors.textSecondary)
                }
            }
            .padding(.leading, AppleDesign.Spacing.sm)
        }
        .padding(.horizontal, AppleDesign.Spacing.lg)
        .padding(.top, AppleDesign.Spacing.md)
    }
    
    // MARK: - Challenge Banner
    
    private func challengeBanner(_ challenge: DailyChallenge) -> some View {
        VStack(spacing: AppleDesign.Spacing.xs) {
            HStack {
                Image(systemName: AppleSymbols.starFill)
                    .font(.system(size: 12))
                    .foregroundColor(AppleDesign.Colors.focusYellow)
                Text(challenge.title)
                    .font(AppleDesign.Typography.subheadlineMedium)
                    .foregroundColor(AppleDesign.Colors.textPrimary)
                Spacer()
                Text("+\(challenge.xpReward) XP")
                    .font(AppleDesign.Typography.caption1Medium)
                    .foregroundColor(AppleDesign.Colors.focusYellow)
            }
            
            Text(challenge.description)
                .font(AppleDesign.Typography.caption1)
                .foregroundColor(AppleDesign.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppleDesign.Colors.backgroundElevated)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppleDesign.Colors.focusYellow)
                        .frame(width: geometry.size.width * challenge.progressPercentage, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(AppleDesign.Spacing.sm)
        .background(AppleDesign.Colors.backgroundSecondary)
        .cornerRadius(AppleDesign.Radius.large)
        .padding(.horizontal, AppleDesign.Spacing.lg)
    }
    
    // MARK: - Phase Label
    
    private var phaseLabel: some View {
        HStack(spacing: AppleDesign.Spacing.xs) {
            Text(phaseLabelText)
                .font(AppleDesign.Typography.title3)
                .foregroundColor(phaseColor)
            
            if stackManager.isQueueMode, let item = stackManager.currentItem {
                Text("• \(item.projectName)")
                    .font(AppleDesign.Typography.subheadline)
                    .foregroundColor(AppleDesign.Colors.textSecondary)
            }
        }
    }
    
    private var phaseLabelText: String {
        if isWorkPhase {
            return "Focus Time"
        } else if currentSessionIndex >= modeManager.getCurrentModeSettings().sessions - 1 {
            return "Long Break"
        } else {
            return "Short Break"
        }
    }
    
    // MARK: - Session Indicator
    
    private var sessionIndicator: some View {
        HStack(spacing: AppleDesign.Spacing.xs) {
            ForEach(0..<modeManager.getCurrentModeSettings().sessions, id: \.self) { index in
                Circle()
                    .fill(index < currentSessionIndex ? AppleDesign.Colors.focusGreen : (index == currentSessionIndex && isWorkPhase ? phaseColor : AppleDesign.Colors.backgroundElevated))
                    .frame(width: 10, height: 10)
                    .scaleEffect(index == currentSessionIndex && isWorkPhase ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentSessionIndex)
            }
        }
    }
    
    // MARK: - Timer Circle
    
    private var timerCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(phaseColor.opacity(0.1))
                .frame(width: 300, height: 300)
            
            // Background track
            Circle()
                .stroke(AppleDesign.Colors.backgroundElevated, lineWidth: 12)
            
            // Progress track
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Inner content
            VStack(spacing: AppleDesign.Spacing.xs) {
                Text(timeString)
                    .font(AppleDesign.Typography.timerLarge)
                    .foregroundColor(AppleDesign.Colors.textPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                Text("\(dataManager.statistics.todayMinutes) min today")
                    .font(AppleDesign.Typography.footnote)
                    .foregroundColor(AppleDesign.Colors.textSecondary)
                
                // Sound indicator
                if soundManager.isPlaying {
                    HStack(spacing: AppleDesign.Spacing.xxs) {
                        Image(systemName: soundManager.currentSound.icon)
                            .font(.system(size: 12))
                        Text(soundManager.currentSound.displayName)
                            .font(AppleDesign.Typography.caption1)
                    }
                    .foregroundColor(AppleDesign.Colors.textSecondary)
                    .padding(.top, AppleDesign.Spacing.xxs)
                }
            }
        }
        .frame(width: 280, height: 280)
    }
    
    // MARK: - Queue Progress
    
    private var queueProgressView: some View {
        VStack(spacing: AppleDesign.Spacing.xxs) {
            Text("Queue: \(stackManager.completedSessionsInQueue)/\(stackManager.totalSessionsInQueue) sessions")
                .font(AppleDesign.Typography.caption1)
                .foregroundColor(AppleDesign.Colors.textSecondary)
            
            ProgressView(value: Double(stackManager.completedSessionsInQueue), total: Double(stackManager.totalSessionsInQueue))
                .tint(AppleDesign.Colors.focusGreen)
        }
        .padding(.horizontal, AppleDesign.Spacing.xxxl)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: AppleDesign.Spacing.xxl) {
            // Reset button
            Button(action: resetTimer) {
                Image(systemName: AppleSymbols.arrowCounterclockwise)
                    .font(.system(size: 24))
                    .foregroundColor(AppleDesign.Colors.textPrimary)
                    .frame(width: 60, height: 60)
                    .background(AppleDesign.Colors.backgroundElevated)
                    .clipShape(Circle())
                    .appleShadow(AppleDesign.Shadow.small)
            }
            .buttonStyle(.plain)
            
            // Play/Pause button
            Button(action: toggleTimer) {
                Image(systemName: isRunning ? AppleSymbols.pauseFill : AppleSymbols.playFill)
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .frame(width: 88, height: 88)
                    .background(phaseColor)
                    .clipShape(Circle())
                    .appleShadow(AppleDesign.Shadow(card: AppleDesign.ShadowStyle(
                        color: phaseColor.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )))
            }
            .buttonStyle(.plain)
            
            // Skip button
            Button(action: skipToNext) {
                Image(systemName: AppleSymbols.forwardFill)
                    .font(.system(size: 24))
                    .foregroundColor(AppleDesign.Colors.textPrimary)
                    .frame(width: 60, height: 60)
                    .background(AppleDesign.Colors.backgroundElevated)
                    .clipShape(Circle())
                    .appleShadow(AppleDesign.Shadow.small)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        HStack(spacing: AppleDesign.Spacing.xxl) {
            // Sound toggle
            Button(action: toggleSound) {
                VStack(spacing: AppleDesign.Spacing.xxs) {
                    Image(systemName: soundManager.isPlaying ? soundManager.currentSound.icon : AppleSymbols.speakerSlashFill)
                        .font(.system(size: 20))
                    Text("Sound")
                        .font(AppleDesign.Typography.caption2)
                }
                .foregroundColor(soundManager.isPlaying ? modeManager.currentMode.appleColor : AppleDesign.Colors.textSecondary)
            }
            
            // Queue toggle
            Button(action: { showStackEditor = true }) {
                VStack(spacing: AppleDesign.Spacing.xxs) {
                    Image(systemName: stackManager.isQueueMode ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                        .font(.system(size: 20))
                    Text("Queue")
                        .font(AppleDesign.Typography.caption2)
                }
                .foregroundColor(stackManager.isQueueMode ? AppleDesign.Colors.focusGreen : AppleDesign.Colors.textSecondary)
            }
            
            // Quick mode switch
            Button(action: quickModeSwitch) {
                VStack(spacing: AppleDesign.Spacing.xxs) {
                    Image(systemName: AppleSymbols.boltFill)
                        .font(.system(size: 20))
                    Text("Quick")
                        .font(AppleDesign.Typography.caption2)
                }
                .foregroundColor(AppleDesign.Colors.textSecondary)
            }
            
            // Daily Planner
            Button(action: { showDailyPlanner = true }) {
                VStack(spacing: AppleDesign.Spacing.xxs) {
                    Image(systemName: AppleSymbols.calendarBadgeClock)
                        .font(.system(size: 20))
                    Text("Plan")
                        .font(AppleDesign.Typography.caption2)
                }
                .foregroundColor(AppleDesign.Colors.textSecondary)
            }
            
            // Rolling Pomodoro
            Button(action: { showRollingPomodoro = true }) {
                VStack(spacing: AppleDesign.Spacing.xxs) {
                    Image(systemName: AppleSymbols.infinity)
                        .font(.system(size: 20))
                    Text("Rolling")
                        .font(AppleDesign.Typography.caption2)
                }
                .foregroundColor(AppleDesign.Colors.textSecondary)
            }
        }
        .padding(.bottom, AppleDesign.Spacing.md)
    }
    
    // MARK: - Streak Indicator
    
    private var streakIndicator: some View {
        HStack(spacing: AppleDesign.Spacing.xs) {
            Image(systemName: AppleSymbols.flameFill)
                .foregroundColor(AppleDesign.Colors.focusOrange)
            Text("\(dataManager.statistics.currentStreak) day streak!")
                .font(AppleDesign.Typography.headlineMedium)
                .foregroundColor(AppleDesign.Colors.textPrimary)
        }
        .padding(.vertical, AppleDesign.Spacing.sm)
        .padding(.horizontal, AppleDesign.Spacing.lg)
        .background(AppleDesign.Colors.backgroundElevated)
        .cornerRadius(AppleDesign.Radius.pill)
        .appleShadow(AppleDesign.Shadow.small)
    }
    
    // MARK: - Computed Properties
    
    private var settings: (work: Int, shortBreak: Int, longBreak: Int, sessions: Int) {
        modeManager.getCurrentModeSettings()
    }
    
    private var phaseColor: Color {
        Color(hex: modeManager.currentMode.accentColor)
    }
    
    private var progress: Double {
        let total = Double(initialPhaseDuration)
        return Double(initialPhaseDuration - timeRemaining) / total
    }
    
    private var currentPhaseDuration: Int {
        if isWorkPhase {
            return settings.work
        } else if currentSessionIndex >= settings.sessions - 1 {
            return settings.longBreak
        } else {
            return settings.shortBreak
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isRunning = true
        sessionStartTime = Date()
        initialPhaseDuration = currentPhaseDuration
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completePhase()
            }
        }
        
        if soundManager.currentSound != .none {
            soundManager.play(sound: soundManager.currentSound)
        }
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        dataManager.cancelAllNotifications()
        soundManager.stop()
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = currentPhaseDuration
    }
    
    private func skipToNext() {
        stopTimer()
        moveToNextPhase()
    }
    
    private func completePhase() {
        stopTimer()
        dataManager.playSound()
        
        if isWorkPhase {
            let session = FocusSession(
                startTime: sessionStartTime,
                endTime: Date(),
                duration: settings.work,
                type: .work,
                completed: true
            )
            dataManager.addSession(session)
            
            // Update challenge progress
            challengeManager.updateProgress(
                sessionsCompleted: dataManager.statistics.todaySessions,
                minutesCompleted: dataManager.statistics.todayMinutes,
                streakMaintained: dataManager.statistics.currentStreak > 0
            )
            
            currentSessionIndex += 1
            if currentSessionIndex >= settings.sessions {
                currentSessionIndex = 0
                isWorkPhase = false
                timeRemaining = settings.longBreak
            } else {
                isWorkPhase = false
                timeRemaining = settings.shortBreak
            }
            
            // Move to next in queue if active
            if stackManager.isQueueMode {
                stackManager.markCurrentCompleted()
                if !stackManager.isQueueMode {
                    // Queue complete
                }
            }
        } else {
            isWorkPhase = true
            timeRemaining = settings.work
        }
    }
    
    private func moveToNextPhase() {
        if isWorkPhase {
            isWorkPhase = false
            timeRemaining = settings.shortBreak
            initialPhaseDuration = settings.shortBreak
        } else {
            isWorkPhase = true
            currentSessionIndex = 0
            timeRemaining = settings.work
            initialPhaseDuration = settings.work
        }
    }
    
    private func loadModeSettings() {
        let s = modeManager.getCurrentModeSettings()
        timeRemaining = s.work
    }
    
    private func toggleSound() {
        if soundManager.isPlaying {
            soundManager.stop()
        } else {
            soundManager.play(sound: .rain)
        }
    }
    
    private func quickModeSwitch() {
        // Cycle through modes
        let modes: [FocusModeType] = [.deepWork, .creativeFlow, .easyDay, .miniSprint]
        if let currentIndex = modes.firstIndex(of: modeManager.currentMode) {
            let nextIndex = (currentIndex + 1) % modes.count
            modeManager.applyMode(modes[nextIndex])
        } else {
            modeManager.applyMode(.deepWork)
        }
        
        if !isRunning {
            let s = modeManager.getCurrentModeSettings()
            timeRemaining = s.work
            initialPhaseDuration = s.work
        }
    }
}

// MARK: - Mode Selector View

struct ModeSelectorView: View {
    @StateObject private var modeManager = FocusModeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppleDesign.Spacing.sm) {
                        ForEach(FocusModeType.allCases) { mode in
                            ModeCard(
                                mode: mode,
                                isSelected: modeManager.currentMode == mode,
                                action: {
                                    modeManager.applyMode(mode)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(AppleDesign.Spacing.md)
                }
            }
            .navigationTitle("Focus Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ModeCard: View {
    let mode: FocusModeType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppleDesign.Spacing.md) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24))
                    .foregroundColor(mode.appleColor)
                    .frame(width: 44, height: 44)
                    .background(mode.appleColor.opacity(0.2))
                    .cornerRadius(AppleDesign.Radius.medium)
                
                VStack(alignment: .leading, spacing: AppleDesign.Spacing.xxs) {
                    Text(mode.displayName)
                        .font(AppleDesign.Typography.headline)
                        .foregroundColor(AppleDesign.Colors.textPrimary)
                    
                    Text(mode.description)
                        .font(AppleDesign.Typography.caption1)
                        .foregroundColor(AppleDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: AppleSymbols.checkmarkCircleFill)
                        .foregroundColor(AppleDesign.Colors.focusGreen)
                }
            }
            .padding(AppleDesign.Spacing.md)
            .background(isSelected ? mode.appleColor.opacity(0.15) : AppleDesign.Colors.backgroundSecondary)
            .cornerRadius(AppleDesign.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppleDesign.Radius.large)
                    .stroke(isSelected ? mode.appleColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Timer Stack View

struct TimerStackView: View {
    @StateObject private var stackManager = TimerStackManager.shared
    @StateObject private var modeManager = FocusModeManager.shared
    @State private var newProjectName: String = ""
    @State private var newSessionCount: Int = 4
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppleDesign.Spacing.lg) {
                    // Add new item
                    VStack(spacing: AppleDesign.Spacing.sm) {
                        TextField("Project Name", text: $newProjectName)
                            .textFieldStyle(.plain)
                            .padding(AppleDesign.Spacing.sm)
                            .background(AppleDesign.Colors.backgroundElevated)
                            .cornerRadius(AppleDesign.Radius.small)
                            .foregroundColor(AppleDesign.Colors.textPrimary)
                        
                        HStack {
                            Text("Sessions:")
                                .foregroundColor(AppleDesign.Colors.textSecondary)
                            Stepper("\(newSessionCount)", value: $newSessionCount, in: 1...12)
                                .foregroundColor(AppleDesign.Colors.textPrimary)
                        }
                        
                        Button(action: addToStack) {
                            Text("Add to Queue")
                                .font(AppleDesign.Typography.subheadlineMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(AppleDesign.Spacing.sm)
                                .background(AppleDesign.Colors.focusGreen)
                                .cornerRadius(AppleDesign.Radius.small)
                        }
                        .disabled(newProjectName.isEmpty)
                    }
                    .padding(AppleDesign.Spacing.md)
                    .background(AppleDesign.Colors.backgroundSecondary)
                    .cornerRadius(AppleDesign.Radius.large)
                    
                    // Current queue
                    if stackManager.stack.isEmpty {
                        VStack(spacing: AppleDesign.Spacing.sm) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(AppleDesign.Colors.backgroundElevated)
                            Text("No items in queue")
                                .foregroundColor(AppleDesign.Colors.textSecondary)
                        }
                        .padding(.vertical, AppleDesign.Spacing.giant)
                    } else {
                        ForEach(Array(stackManager.stack.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                if index == stackManager.currentIndex && stackManager.isQueueMode {
                                    Image(systemName: AppleSymbols.playFill)
                                        .foregroundColor(AppleDesign.Colors.focusGreen)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(item.projectName)
                                        .foregroundColor(AppleDesign.Colors.textPrimary)
                                    Text("\(item.sessionsCount) sessions • \(item.mode.displayName)")
                                        .font(AppleDesign.Typography.caption1)
                                        .foregroundColor(AppleDesign.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if item.isCompleted {
                                    Image(systemName: AppleSymbols.checkmarkCircleFill)
                                        .foregroundColor(AppleDesign.Colors.focusGreen)
                                }
                                
                                Button(action: { stackManager.removeFromStack(at: index) }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(AppleDesign.Colors.textSecondary)
                                }
                            }
                            .padding(AppleDesign.Spacing.sm)
                            .background(AppleDesign.Colors.backgroundSecondary)
                            .cornerRadius(AppleDesign.Radius.small)
                        }
                        
                        if stackManager.isQueueMode {
                            Button(action: { stackManager.clearStack() }) {
                                Text("Cancel Queue")
                                    .foregroundColor(AppleDesign.Colors.focusRed)
                            }
                        } else if !stackManager.stack.isEmpty {
                            Button(action: { stackManager.startQueue() }) {
                                Text("Start Queue")
                                    .font(AppleDesign.Typography.subheadlineMedium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(AppleDesign.Spacing.sm)
                                    .background(modeManager.currentMode.appleColor)
                                    .cornerRadius(AppleDesign.Radius.small)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppleDesign.Spacing.md)
            }
            .navigationTitle("Session Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func addToStack() {
        stackManager.addToStack(
            projectName: newProjectName,
            sessionsCount: newSessionCount,
            mode: modeManager.currentMode
        )
        newProjectName = ""
        newSessionCount = 4
    }
}

// MARK: - Label Picker View

struct LabelPickerView: View {
    @StateObject private var labelManager = SessionLabelManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppleDesign.Spacing.xs) {
                        ForEach(labelManager.labels) { label in
                            Button(action: {
                                labelManager.selectLabel(label)
                                dismiss()
                            }) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: label.color))
                                        .frame(width: 12, height: 12)
                                    Text(label.name)
                                        .foregroundColor(AppleDesign.Colors.textPrimary)
                                    Spacer()
                                    if label.id == labelManager.selectedLabel?.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppleDesign.Colors.focusGreen)
                                    }
                                }
                                .padding(AppleDesign.Spacing.sm)
                                .background(AppleDesign.Colors.backgroundSecondary)
                                .cornerRadius(AppleDesign.Radius.small)
                            }
                        }
                    }
                    .padding(AppleDesign.Spacing.md)
                }
            }
            .navigationTitle("Session Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        labelManager.selectLabel(nil)
                        dismiss()
                    }
                    .foregroundColor(AppleDesign.Colors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}

// MARK: - Profile View

struct ProfileView: View {
    @StateObject private var levelingSystem = LevelingSystem.shared
    @StateObject private var coinManager = FocusCoinManager.shared
    @StateObject private var achievementManager = AchievementManager.shared
    @StateObject private var dataManager = FocusDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppleDesign.Spacing.lg) {
                        // Level card
                        VStack(spacing: AppleDesign.Spacing.md) {
                            ZStack {
                                Circle()
                                    .stroke(AppleDesign.Colors.focusPurple.opacity(0.3), lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: levelingSystem.progressToNextLevel)
                                    .stroke(AppleDesign.Colors.focusPurple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: AppleDesign.Spacing.xxs) {
                                    Text("Lv.\(levelingSystem.currentLevel)")
                                        .font(AppleDesign.Typography.title1)
                                        .foregroundColor(AppleDesign.Colors.textPrimary)
                                    
                                    Text(levelingSystem.levelTitle)
                                        .font(AppleDesign.Typography.caption1)
                                        .foregroundColor(AppleDesign.Colors.focusPurple)
                                }
                            }
                            
                            Text("\(levelingSystem.currentXP) / \(levelingSystem.xpForNextLevel) XP")
                                .font(AppleDesign.Typography.footnote)
                                .foregroundColor(AppleDesign.Colors.textSecondary)
                        }
                        .padding(AppleDesign.Spacing.xxl)
                        .background(AppleDesign.Colors.backgroundSecondary)
                        .cornerRadius(AppleDesign.Radius.xxlarge)
                        
                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppleDesign.Spacing.md) {
                            ProfileStatCard(title: "Total XP", value: "\(levelingSystem.totalXPEarned)", icon: AppleSymbols.sparkles, color: AppleDesign.Colors.focusYellow)
                            ProfileStatCard(title: "Focus Coins", value: "\(coinManager.coins)", icon: AppleSymbols.bitcoinsignCircleFill, color: AppleDesign.Colors.focusOrange)
                            ProfileStatCard(title: "Achievements", value: "\(achievementManager.totalUnlocked)/\(achievementManager.badges.count)", icon: AppleSymbols.trophyFill, color: AppleDesign.Colors.focusPurple)
                            ProfileStatCard(title: "Current Streak", value: "\(dataManager.statistics.currentStreak) days", icon: AppleSymbols.flameFill, color: AppleDesign.Colors.focusRed)
                        }
                        
                        // Streak heatmap
                        StreakHeatmapView()
                        
                        Spacer(minLength: AppleDesign.Spacing.xxxl)
                    }
                    .padding(AppleDesign.Spacing.md)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppleDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(AppleDesign.Typography.title3)
                .foregroundColor(AppleDesign.Colors.textPrimary)
            
            Text(title)
                .font(AppleDesign.Typography.caption1)
                .foregroundColor(AppleDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppleDesign.Spacing.md)
        .background(AppleDesign.Colors.backgroundSecondary)
        .cornerRadius(AppleDesign.Radius.large)
    }
}

// MARK: - Focus Shop View

struct FocusShopView: View {
    @StateObject private var coinManager = FocusCoinManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: FocusCoinItem.ItemCategory = .theme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Coin balance
                    HStack {
                        Image(systemName: AppleSymbols.bitcoinsignCircleFill)
                            .font(.system(size: 24))
                            .foregroundColor(AppleDesign.Colors.focusOrange)
                        
                        Text("\(coinManager.coins)")
                            .font(AppleDesign.Typography.title2)
                            .foregroundColor(AppleDesign.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text("Total earned: \(coinManager.totalEarned)")
                            .font(AppleDesign.Typography.caption1)
                            .foregroundColor(AppleDesign.Colors.textSecondary)
                    }
                    .padding(AppleDesign.Spacing.md)
                    .background(AppleDesign.Colors.backgroundSecondary)
                    
                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppleDesign.Spacing.sm) {
                            ForEach([FocusCoinItem.ItemCategory.theme, .sound, .accessory, .powerup], id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category.rawValue.capitalized)
                                        .font(AppleDesign.Typography.caption1Medium)
                                        .foregroundColor(selectedCategory == category ? .white : AppleDesign.Colors.textSecondary)
                                        .padding(.horizontal, AppleDesign.Spacing.md)
                                        .padding(.vertical, AppleDesign.Spacing.xs)
                                        .background(selectedCategory == category ? AppleDesign.Colors.focusOrange : AppleDesign.Colors.backgroundElevated)
                                        .cornerRadius(AppleDesign.Radius.pill)
                                }
                            }
                        }
                        .padding(.horizontal, AppleDesign.Spacing.md)
                    }
                    .padding(.vertical, AppleDesign.Spacing.sm)
                    
                    // Items grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppleDesign.Spacing.sm) {
                            ForEach(itemsForCategory) { item in
                                ShopItemCard(item: item, isOwned: coinManager.isOwned(item.id)) {
                                    if coinManager.spendCoins(item.price, for: item.id) {
                                        // Purchased
                                    }
                                }
                            }
                        }
                        .padding(AppleDesign.Spacing.md)
                    }
                }
            }
            .navigationTitle("Focus Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var itemsForCategory: [FocusCoinItem] {
        coinManager.shopItems.filter { $0.category == selectedCategory }
    }
}

struct ShopItemCard: View {
    let item: FocusCoinItem
    let isOwned: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(spacing: AppleDesign.Spacing.sm) {
            Image(systemName: item.icon)
                .font(.system(size: 32))
                .foregroundColor(isOwned ? AppleDesign.Colors.focusGreen : AppleDesign.Colors.focusOrange)
                .frame(width: 60, height: 60)
                .background(AppleDesign.Colors.backgroundElevated)
                .cornerRadius(AppleDesign.Radius.medium)
            
            Text(item.name)
                .font(AppleDesign.Typography.subheadlineMedium)
                .foregroundColor(AppleDesign.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(item.description)
                .font(AppleDesign.Typography.caption2)
                .foregroundColor(AppleDesign.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if isOwned {
                Text("Owned")
                    .font(AppleDesign.Typography.caption1Medium)
                    .foregroundColor(AppleDesign.Colors.focusGreen)
                    .padding(.horizontal, AppleDesign.Spacing.sm)
                    .padding(.vertical, AppleDesign.Spacing.xxs)
                    .background(AppleDesign.Colors.focusGreen.opacity(0.2))
                    .cornerRadius(AppleDesign.Radius.small)
            } else {
                Button(action: onPurchase) {
                    HStack(spacing: AppleDesign.Spacing.xxs) {
                        Image(systemName: AppleSymbols.bitcoinsignCircleFill)
                            .font(.system(size: 12))
                        Text("\(item.price)")
                            .font(AppleDesign.Typography.caption1Medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppleDesign.Spacing.sm)
                    .padding(.vertical, AppleDesign.Spacing.xxs)
                    .background(AppleDesign.Colors.focusOrange)
                    .cornerRadius(AppleDesign.Radius.small)
                }
            }
        }
        .padding(AppleDesign.Spacing.md)
        .background(AppleDesign.Colors.backgroundSecondary)
        .cornerRadius(AppleDesign.Radius.large)
    }
}

// MARK: - Achievements View

struct AchievementsView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: AchievementBadge.AchievementCategory = .consistency
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress header
                    HStack {
                        VStack(alignment: .leading, spacing: AppleDesign.Spacing.xxs) {
                            Text("\(achievementManager.totalUnlocked) / \(achievementManager.badges.count)")
                                .font(AppleDesign.Typography.title1)
                                .foregroundColor(AppleDesign.Colors.textPrimary)
                            
                            Text("Achievements Unlocked")
                                .font(AppleDesign.Typography.caption1)
                                .foregroundColor(AppleDesign.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: Double(achievementManager.totalUnlocked) / Double(max(achievementManager.badges.count, 1)))
                            .frame(width: 50, height: 50)
                    }
                    .padding(AppleDesign.Spacing.md)
                    .background(AppleDesign.Colors.backgroundSecondary)
                    
                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppleDesign.Spacing.sm) {
                            ForEach(AchievementBadge.AchievementCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    HStack(spacing: AppleDesign.Spacing.xxs) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 12))
                                        Text(category.displayName)
                                            .font(AppleDesign.Typography.caption1Medium)
                                    }
                                    .foregroundColor(selectedCategory == category ? AppleDesign.Colors.textOnLight : AppleDesign.Colors.textSecondary)
                                    .padding(.horizontal, AppleDesign.Spacing.sm)
                                    .padding(.vertical, AppleDesign.Spacing.xxs)
                                    .background(selectedCategory == category ? AppleDesign.Colors.focusYellow : AppleDesign.Colors.backgroundElevated)
                                    .cornerRadius(AppleDesign.Radius.pill)
                                }
                            }
                        }
                        .padding(.horizontal, AppleDesign.Spacing.md)
                    }
                    .padding(.vertical, AppleDesign.Spacing.sm)
                    
                    // Badges list
                    ScrollView {
                        LazyVStack(spacing: AppleDesign.Spacing.xs) {
                            ForEach(achievementManager.getBadgesByCategory(selectedCategory)) { badge in
                                AchievementBadgeRow(badge: badge)
                            }
                        }
                        .padding(AppleDesign.Spacing.md)
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppleDesign.Colors.backgroundElevated, lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppleDesign.Colors.focusYellow, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(AppleDesign.Typography.caption1Medium)
                .foregroundColor(AppleDesign.Colors.textPrimary)
        }
    }
}

struct AchievementBadgeRow: View {
    let badge: AchievementBadge
    
    var body: some View {
        HStack(spacing: AppleDesign.Spacing.md) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? AppleDesign.Colors.focusYellow.opacity(0.2) : AppleDesign.Colors.backgroundElevated)
                    .frame(width: 50, height: 50)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 20))
                    .foregroundColor(badge.isUnlocked ? AppleDesign.Colors.focusYellow : AppleDesign.Colors.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: AppleDesign.Spacing.xxs) {
                Text(badge.name)
                    .font(AppleDesign.Typography.headline)
                    .foregroundColor(badge.isUnlocked ? AppleDesign.Colors.textPrimary : AppleDesign.Colors.textSecondary)
                
                Text(badge.description)
                    .font(AppleDesign.Typography.caption1)
                    .foregroundColor(AppleDesign.Colors.textSecondary)
                
                if let date = badge.unlockedDate, badge.isUnlocked {
                    Text("Unlocked \(formattedDate(date))")
                        .font(AppleDesign.Typography.caption2)
                        .foregroundColor(AppleDesign.Colors.focusGreen)
                }
            }
            
            Spacer()
            
            if badge.isUnlocked {
                Image(systemName: AppleSymbols.checkmarkCircleFill)
                    .foregroundColor(AppleDesign.Colors.focusGreen)
            } else {
                Text("\(badge.requirement)")
                    .font(AppleDesign.Typography.headline)
                    .foregroundColor(AppleDesign.Colors.textSecondary)
            }
        }
        .padding(AppleDesign.Spacing.md)
        .background(AppleDesign.Colors.backgroundSecondary)
        .cornerRadius(AppleDesign.Radius.large)
        .opacity(badge.isUnlocked ? 1 : 0.7)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Project Picker View

struct ProjectPickerView: View {
    @StateObject private var projectManager = ProjectManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var newProjectName: String = ""
    @State private var selectedColor: String = "FF6B6B"
    
    private let colors = ["FF6B6B", "4ECB71", "5AC8FA", "AF52DE", "FF9500", "FFD60A", "64D2FF", "8E8E93"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppleDesign.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AppleDesign.Spacing.lg) {
                    // Add new project
                    VStack(spacing: AppleDesign.Spacing.sm) {
                        TextField("Project Name", text: $newProjectName)
                            .textFieldStyle(.plain)
                            .padding(AppleDesign.Spacing.sm)
                            .background(AppleDesign.Colors.backgroundElevated)
                            .cornerRadius(AppleDesign.Radius.small)
                            .foregroundColor(AppleDesign.Colors.textPrimary)
                        
                        HStack(spacing: AppleDesign.Spacing.xs) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? AppleDesign.Colors.textPrimary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        
                        Button(action: createProject) {
                            Text("Create Project")
                                .font(AppleDesign.Typography.subheadlineMedium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(AppleDesign.Spacing.sm)
                                .background(AppleDesign.Colors.focusGreen)
                                .cornerRadius(AppleDesign.Radius.small)
                        }
                        .disabled(newProjectName.isEmpty)
                    }
                    .padding(AppleDesign.Spacing.md)
                    .background(AppleDesign.Colors.backgroundSecondary)
                    .cornerRadius(AppleDesign.Radius.large)
                    
                    // Project list
                    if projectManager.projects.isEmpty {
                        VStack(spacing: AppleDesign.Spacing.sm) {
                            Image(systemName: AppleSymbols.folderFill)
                                .font(.system(size: 48))
                                .foregroundColor(AppleDesign.Colors.backgroundElevated)
                            Text("No projects yet")
                                .foregroundColor(AppleDesign.Colors.textSecondary)
                        }
                        .padding(.vertical, AppleDesign.Spacing.giant)
                    } else {
                        ForEach(projectManager.projects.filter { !$0.isArchived }) { project in
                            ProjectRow(
                                project: project,
                                isActive: projectManager.activeProjectId == project.id,
                                onSelect: {
                                    projectManager.setActiveProject(project)
                                    dismiss()
                                },
                                onDelete: {
                                    projectManager.deleteProject(project)
                                }
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppleDesign.Spacing.md)
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func createProject() {
        _ = projectManager.createProject(name: newProjectName, color: selectedColor)
        newProjectName = ""
    }
}

struct ProjectRow: View {
    let project: FocusProject
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppleDesign.Spacing.md) {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(AppleDesign.Typography.headlineMedium)
                        .foregroundColor(AppleDesign.Colors.textPrimary)
                    
                    Text("\(project.sessions) sessions • \(project.formattedTime)")
                        .font(AppleDesign.Typography.caption1)
                        .foregroundColor(AppleDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: AppleSymbols.checkmarkCircleFill)
                        .foregroundColor(AppleDesign.Colors.focusGreen)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(AppleDesign.Colors.focusRed)
                }
            }
            .padding(AppleDesign.Spacing.md)
            .background(isActive ? Color(hex: project.color).opacity(0.15) : AppleDesign.Colors.backgroundSecondary)
            .cornerRadius(AppleDesign.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppleDesign.Radius.large)
                    .stroke(isActive ? Color(hex: project.color).opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
    }
}
