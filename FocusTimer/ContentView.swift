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
            Color(hex: modeManager.getCurrentModeSettings().work == 90 * 60 ? "2C1A3D" : (modeManager.getCurrentModeSettings().work == 50 * 60 ? "1C1C2E" : "1C1C1E"))
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
                        .padding(.bottom, 32)
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
        HStack {
            // Mode selector button
            Button(action: { showModeSelector = true }) {
                HStack(spacing: 6) {
                    Image(systemName: modeManager.currentMode.icon)
                        .font(.system(size: 14))
                    Text(modeManager.currentMode.displayName)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(hex: modeManager.currentMode.accentColor))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: modeManager.currentMode.accentColor).opacity(0.2))
                .cornerRadius(16)
            }
            
            Spacer()
            
            // Label indicator
            if let label = labelManager.selectedLabel {
                Button(action: { showLabelPicker = true }) {
                    Text(label.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: label.color).opacity(0.3))
                        .cornerRadius(8)
                }
            } else {
                Button(action: { showLabelPicker = true }) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
            
            Spacer()
            
            // Daily goal indicator
            HStack(spacing: 4) {
                Image(systemName: "target")
                    .font(.system(size: 14))
                Text("\(dataManager.statistics.todaySessions)/\(dataManager.settings.dailyGoal)")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(dataManager.statistics.todaySessions >= dataManager.settings.dailyGoal ? Color(hex: "4ECB71") : Color(hex: "8E8E93"))
            
            Spacer()
            
            Button(action: { showAchievements = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                    Text("\(achievementManager.totalUnlocked)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: "FFD60A"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "FFD60A").opacity(0.2))
                .cornerRadius(12)
            }
            
            Button(action: { showShop = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 14))
                    Text("\(coinManager.coins)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: "FF9500"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "FF9500").opacity(0.2))
                .cornerRadius(12)
            }
            
            Button(action: { showProfile = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("Lv.\(levelingSystem.currentLevel)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: "AF52DE"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "AF52DE").opacity(0.2))
                .cornerRadius(12)
            }
            
            Button(action: { showStatistics = true }) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Button(action: { showIntelligence = true }) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            Button(action: { showProjectPicker = true }) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "5AC8FA"))
            }
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(.leading, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Challenge Banner
    
    private func challengeBanner(_ challenge: DailyChallenge) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                Text(challenge.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("+\(challenge.xpReward) XP")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
            }
            
            Text(challenge.description)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "3A3A3C"))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FFD60A"))
                        .frame(width: geometry.size.width * challenge.progressPercentage, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Phase Label
    
    private var phaseLabel: some View {
        HStack(spacing: 8) {
            Text(phaseLabelText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(phaseColor)
            
            if stackManager.isQueueMode, let item = stackManager.currentItem {
                Text("• \(item.projectName)")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
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
        HStack(spacing: 8) {
            ForEach(0..<modeManager.getCurrentModeSettings().sessions, id: \.self) { index in
                Circle()
                    .fill(index < currentSessionIndex ? Color(hex: "4ECB71") : (index == currentSessionIndex && isWorkPhase ? phaseColor : Color(hex: "3A3A3C")))
                    .frame(width: 10, height: 10)
            }
        }
    }
    
    // MARK: - Timer Circle
    
    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "3A3A3C"), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(nil, value: progress)
            
            VStack(spacing: 8) {
                Text(timeString)
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                Text("\(dataManager.statistics.todayMinutes) min today")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                // Sound indicator
                if soundManager.isPlaying {
                    HStack(spacing: 4) {
                        Image(systemName: soundManager.currentSound.icon)
                            .font(.system(size: 12))
                        Text(soundManager.currentSound.displayName)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "8E8E93"))
                }
            }
        }
        .frame(width: 280, height: 280)
    }
    
    // MARK: - Queue Progress
    
    private var queueProgressView: some View {
        VStack(spacing: 4) {
            Text("Queue: \(stackManager.completedSessionsInQueue)/\(stackManager.totalSessionsInQueue) sessions")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
            
            ProgressView(value: Double(stackManager.completedSessionsInQueue), total: Double(stackManager.totalSessionsInQueue))
                .tint(Color(hex: "4ECB71"))
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 32) {
            // Reset button
            Button(action: resetTimer) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color(hex: "3A3A3C"))
                    .clipShape(Circle())
            }
            
            // Play/Pause button
            Button(action: toggleTimer) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .frame(width: 88, height: 88)
                    .background(phaseColor)
                    .clipShape(Circle())
            }
            
            // Skip button
            Button(action: skipToNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color(hex: "3A3A3C"))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        HStack(spacing: 32) {
            // Sound toggle
            Button(action: toggleSound) {
                VStack(spacing: 4) {
                    Image(systemName: soundManager.isPlaying ? soundManager.currentSound.icon : "speaker.slash.fill")
                        .font(.system(size: 20))
                    Text("Sound")
                        .font(.system(size: 10))
                }
                .foregroundColor(soundManager.isPlaying ? Color(hex: modeManager.currentMode.accentColor) : Color(hex: "8E8E93"))
            }
            
            // Queue toggle
            Button(action: { showStackEditor = true }) {
                VStack(spacing: 4) {
                    Image(systemName: stackManager.isQueueMode ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                        .font(.system(size: 20))
                    Text("Queue")
                        .font(.system(size: 10))
                }
                .foregroundColor(stackManager.isQueueMode ? Color(hex: "4ECB71") : Color(hex: "8E8E93"))
            }
            
            // Quick mode switch
            Button(action: quickModeSwitch) {
                VStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20))
                    Text("Quick")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: "8E8E93"))
            }
            
            // Daily Planner
            Button(action: { showDailyPlanner = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                    Text("Plan")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: "8E8E93"))
            }
            
            // Rolling Pomodoro
            Button(action: { showRollingPomodoro = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "infinity")
                        .font(.system(size: 20))
                    Text("Rolling")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Streak Indicator
    
    private var streakIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(dataManager.statistics.currentStreak) day streak!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(Color(hex: "3A3A3C"))
        .cornerRadius(20)
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
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
                    .padding(16)
                }
            }
            .navigationTitle("Focus Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
            HStack(spacing: 16) {
                Image(systemName: mode.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: mode.accentColor))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: mode.accentColor).opacity(0.2))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(mode.description)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "4ECB71"))
                }
            }
            .padding(16)
            .background(isSelected ? Color(hex: mode.accentColor).opacity(0.15) : Color(hex: "2C2C2E"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: mode.accentColor).opacity(0.5) : Color.clear, lineWidth: 2)
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Add new item
                    VStack(spacing: 12) {
                        TextField("Project Name", text: $newProjectName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(hex: "3A3A3C"))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Sessions:")
                                .foregroundColor(Color(hex: "8E8E93"))
                            Stepper("\(newSessionCount)", value: $newSessionCount, in: 1...12)
                                .foregroundColor(.white)
                        }
                        
                        Button(action: addToStack) {
                            Text("Add to Queue")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "4ECB71"))
                                .cornerRadius(8)
                        }
                        .disabled(newProjectName.isEmpty)
                    }
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(16)
                    
                    // Current queue
                    if stackManager.stack.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "3A3A3C"))
                            Text("No items in queue")
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .padding(.vertical, 40)
                    } else {
                        ForEach(Array(stackManager.stack.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                if index == stackManager.currentIndex && stackManager.isQueueMode {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(Color(hex: "4ECB71"))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(item.projectName)
                                        .foregroundColor(.white)
                                    Text("\(item.sessionsCount) sessions • \(item.mode.displayName)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "8E8E93"))
                                }
                                
                                Spacer()
                                
                                if item.isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "4ECB71"))
                                }
                                
                                Button(action: { stackManager.removeFromStack(at: index) }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color(hex: "8E8E93"))
                                }
                            }
                            .padding(12)
                            .background(Color(hex: "2C2C2E"))
                            .cornerRadius(8)
                        }
                        
                        if stackManager.isQueueMode {
                            Button(action: { stackManager.clearStack() }) {
                                Text("Cancel Queue")
                                    .foregroundColor(Color(hex: "FF6B6B"))
                            }
                        } else if !stackManager.stack.isEmpty {
                            Button(action: { stackManager.startQueue() }) {
                                Text("Start Queue")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color(hex: modeManager.currentMode.accentColor))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Session Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 8) {
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
                                        .foregroundColor(.white)
                                    Spacer()
                                    if label.id == labelManager.selectedLabel?.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(Color(hex: "4ECB71"))
                                    }
                                }
                                .padding(12)
                                .background(Color(hex: "2C2C2E"))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
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
                    .foregroundColor(Color(hex: "8E8E93"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Level card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color(hex: "AF52DE").opacity(0.3), lineWidth: 8)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: levelingSystem.progressToNextLevel)
                                    .stroke(Color(hex: "AF52DE"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: 4) {
                                    Text("Lv.\(levelingSystem.currentLevel)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(levelingSystem.levelTitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "AF52DE"))
                                }
                            }
                            
                            Text("\(levelingSystem.currentXP) / \(levelingSystem.xpForNextLevel) XP")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .padding(24)
                        .background(Color(hex: "2C2C2E"))
                        .cornerRadius(20)
                        
                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ProfileStatCard(title: "Total XP", value: "\(levelingSystem.totalXPEarned)", icon: "sparkles", color: .yellow)
                            ProfileStatCard(title: "Focus Coins", value: "\(coinManager.coins)", icon: "bitcoinsign.circle.fill", color: .orange)
                            ProfileStatCard(title: "Achievements", value: "\(achievementManager.totalUnlocked)/\(achievementManager.badges.count)", icon: "trophy.fill", color: .purple)
                            ProfileStatCard(title: "Current Streak", value: "\(dataManager.statistics.currentStreak) days", icon: "flame.fill", color: .red)
                        }
                        
                        // Streak heatmap
                        StreakHeatmapView()
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Coin balance
                    HStack {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "FF9500"))
                        
                        Text("\(coinManager.coins)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("Total earned: \(coinManager.totalEarned)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    
                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([FocusCoinItem.ItemCategory.theme, .sound, .accessory, .powerup], id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category.rawValue.capitalized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : Color(hex: "8E8E93"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? Color(hex: "FF9500") : Color(hex: "3A3A3C"))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Items grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(itemsForCategory) { item in
                                ShopItemCard(item: item, isOwned: coinManager.isOwned(item.id)) {
                                    if coinManager.spendCoins(item.price, for: item.id) {
                                        // Purchased
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Focus Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
        VStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 32))
                .foregroundColor(isOwned ? Color(hex: "4ECB71") : Color(hex: "FF9500"))
                .frame(width: 60, height: 60)
                .background(Color(hex: "3A3A3C"))
                .cornerRadius(12)
            
            Text(item.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(item.description)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8E8E93"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if isOwned {
                Text("Owned")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "4ECB71"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "4ECB71").opacity(0.2))
                    .cornerRadius(12)
            } else {
                Button(action: onPurchase) {
                    HStack(spacing: 4) {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .font(.system(size: 12))
                        Text("\(item.price)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FF9500"))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(achievementManager.totalUnlocked) / \(achievementManager.badges.count)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Achievements Unlocked")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        
                        Spacer()
                        
                        CircularProgressView(progress: Double(achievementManager.totalUnlocked) / Double(max(achievementManager.badges.count, 1)))
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    
                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AchievementBadge.AchievementCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                            .font(.system(size: 12))
                                        Text(category.displayName)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(selectedCategory == category ? .white : Color(hex: "8E8E93"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color(hex: "FFD60A") : Color(hex: "3A3A3C"))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Badges list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(achievementManager.getBadgesByCategory(selectedCategory)) { badge in
                                AchievementBadgeRow(badge: badge)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
                .stroke(Color(hex: "3A3A3C"), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color(hex: "FFD60A"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct AchievementBadgeRow: View {
    let badge: AchievementBadge
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Color(hex: "FFD60A").opacity(0.2) : Color(hex: "3A3A3C"))
                    .frame(width: 50, height: 50)
                
                Image(systemName: badge.icon)
                    .font(.system(size: 20))
                    .foregroundColor(badge.isUnlocked ? Color(hex: "FFD60A") : Color(hex: "8E8E93"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(badge.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(badge.isUnlocked ? .white : Color(hex: "8E8E93"))
                
                Text(badge.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                if let date = badge.unlockedDate, badge.isUnlocked {
                    Text("Unlocked \(formattedDate(date))")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "4ECB71"))
                }
            }
            
            Spacer()
            
            if badge.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "4ECB71"))
            } else {
                Text("\(badge.requirement)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(12)
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
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Add new project
                    VStack(spacing: 12) {
                        TextField("Project Name", text: $newProjectName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(hex: "3A3A3C"))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        
                        Button(action: createProject) {
                            Text("Create Project")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "4ECB71"))
                                .cornerRadius(8)
                        }
                        .disabled(newProjectName.isEmpty)
                    }
                    .padding()
                    .background(Color(hex: "2C2C2E"))
                    .cornerRadius(16)
                    
                    // Project list
                    if projectManager.projects.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "3A3A3C"))
                            Text("No projects yet")
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                        .padding(.vertical, 40)
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
                .padding()
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "FF6B6B"))
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
            HStack(spacing: 16) {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(project.sessions) sessions • \(project.formattedTime)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "4ECB71"))
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(Color(hex: "FF6B6B"))
                }
            }
            .padding(16)
            .background(isActive ? Color(hex: project.color).opacity(0.15) : Color(hex: "2C2C2E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color(hex: project.color).opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
    }
}
