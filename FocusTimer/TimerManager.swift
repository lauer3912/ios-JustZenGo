//
//  TimerManager.swift
//  FocusTimer
//
//  Global timer state manager for cross-component access
//

import Foundation
import Combine
import UserNotifications

class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    // MARK: - Published State
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var remainingSeconds: Int = 25 * 60
    @Published var isWorkPhase: Bool = true
    @Published var currentSessionIndex: Int = 0
    @Published var totalSessionsInStack: Int = 1
    @Published var currentSessionLabel: String = ""
    @Published var currentModeName: String = "Deep Work"
    @Published var totalSecondsForPhase: Int = 25 * 60
    
    // MARK: - Private
    private var timer: Timer?
    private var sessionStartTime: Date = Date()
    private var workDuration: Int = 25 * 60
    private var breakDuration: Int = 5 * 60
    private var longBreakDuration: Int = 15 * 60
    private var sessionsBeforeLongBreak: Int = 4
    
    private let dataManager = FocusDataManager.shared
    private let modeManager = FocusModeManager.shared
    private let stackManager = TimerStackManager.shared
    private let soundManager = FocusSoundManager.shared
    private let labelManager = SessionLabelManager.shared
    private let levelingSystem = LevelingSystem.shared
    private let coinManager = FocusCoinManager.shared
    private let celebrationManager = CelebrationManager.shared
    private let achievementManager = AchievementManager.shared
    private let projectManager = ProjectManager.shared
    private let dailyChallenge = DailyChallengeManager.shared
    
    // MARK: - Callbacks for UI updates
    // Note: Callers should use [weak self] in closures to avoid retain cycles
    var onTimerUpdate: (() -> Void)?
    var onPhaseChange: ((Bool) -> Void)?
    var onSessionComplete: (() -> Void)?
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        let mode = modeManager.currentMode
        workDuration = mode.workDuration
        breakDuration = mode.shortBreakDuration
        longBreakDuration = mode.longBreakDuration
        sessionsBeforeLongBreak = mode.sessionsUntilLongBreak
        currentModeName = mode.displayName
        remainingSeconds = workDuration
        totalSecondsForPhase = workDuration
    }
    
    // MARK: - Timer Controls
    
    func start() {
        guard !isRunning else { return }
        
        if isPaused {
            // Resume from pause
            isPaused = false
        } else {
            // Fresh start
            loadSettings()
            isWorkPhase = true
            currentSessionIndex = 0
            sessionStartTime = Date()
            
            // Load label if any
            if let label = labelManager.selectedLabel {
                currentSessionLabel = label.name
            }
        }
        
        isRunning = true
        scheduleTimer()
        requestNotificationPermission()
    }
    
    func pause() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func stop() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        resetTimer()
    }
    
    func resetTimer() {
        loadSettings()
        remainingSeconds = workDuration
        totalSecondsForPhase = workDuration
        isWorkPhase = true
        currentSessionIndex = 0
        currentSessionLabel = ""
        sessionStartTime = Date()
    }
    
    func skipToNext() {
        handleSessionComplete()
    }
    
    func toggle() {
        if isRunning {
            pause()
        } else {
            start()
        }
    }
    
    // MARK: - Private Methods
    
    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func tick() {
        guard isRunning else { return }
        
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            onTimerUpdate?()
        } else {
            handleSessionComplete()
        }
    }
    
    private func handleSessionComplete() {
        let wasWorkPhase = isWorkPhase
        
        if wasWorkPhase {
            // Work phase ended - record session
            recordSession()
            
            // Check if stack queue has more sessions
            if stackManager.isQueueMode, stackManager.currentItem != nil {
                // Move to next in queue
                stackManager.moveToNext()
                if let nextItem = stackManager.currentItem {
                    let sessionDuration = getModeDuration(for: nextItem.mode)
                    remainingSeconds = sessionDuration
                    totalSecondsForPhase = sessionDuration
                    currentSessionLabel = nextItem.projectName
                    isWorkPhase = true
                    soundManager.play(sound: FocusSoundType.none) // Transition sound placeholder
                    onPhaseChange?(true)
                }
            } else if currentSessionIndex >= sessionsBeforeLongBreak - 1 {
                // Long break
                remainingSeconds = longBreakDuration
                totalSecondsForPhase = longBreakDuration
                isWorkPhase = false
                currentSessionIndex = 0
                soundManager.stop()
                onPhaseChange?(false)
            } else {
                // Regular break
                remainingSeconds = breakDuration
                totalSecondsForPhase = breakDuration
                isWorkPhase = false
                soundManager.stop()
                onPhaseChange?(false)
            }
        } else {
            // Break ended - start new work phase
            if currentSessionIndex < sessionsBeforeLongBreak - 1 {
                currentSessionIndex += 1
            }
            
            remainingSeconds = workDuration
            totalSecondsForPhase = workDuration
            isWorkPhase = true
            sessionStartTime = Date()
            soundManager.play(sound: FocusSoundType.none)
            onPhaseChange?(true)
        }
        
        sendNotification(wasWorkPhase: wasWorkPhase)
        onSessionComplete?()
    }
    
    private func recordSession() {
        guard isWorkPhase else { return }
        
        let minutes = workDuration / 60
        let actualMinutes = max(1, Int(Date().timeIntervalSince(sessionStartTime) / 60))
        
        // Create and record session
        let session = FocusSession(
            id: UUID(),
            startTime: sessionStartTime,
            endTime: Date(),
            duration: actualMinutes,
            type: .work,
            completed: true,
            labelId: labelManager.selectedLabel?.id
        )
        dataManager.addSession(session)
        
        // Update daily challenge
        dailyChallenge.updateProgress(
            sessionsCompleted: dataManager.statistics.todaySessions,
            minutesCompleted: actualMinutes,
            streakMaintained: dataManager.statistics.currentStreak > 0
        )
        
        // Update XP
        let xpEarned = levelingSystem.addXP(actualMinutes * 10)
        
        // Award coins
        coinManager.earnCoins(actualMinutes, reason: "Session completed")
        
        // Check achievements
        achievementManager.checkAndUnlockAchievements(
            stats: dataManager.statistics,
            extra: ["todayMinutes": actualMinutes]
        )
        
        // Update project if active
        if projectManager.activeProject != nil {
            projectManager.logSession(minutes: actualMinutes)
        }
        
        // Check milestones
        celebrationManager.onSessionCompleted()
        if dataManager.statistics.todaySessions >= dataManager.settings.dailyGoal {
            celebrationManager.onDailyGoalAchieved()
        }
        celebrationManager.checkMilestones(
            stats: dataManager.statistics,
            level: levelingSystem.currentLevel
        )
    }
    
    private func sendNotification(wasWorkPhase: Bool) {
        let content = UNMutableNotificationContent()
        
        if wasWorkPhase {
            content.title = "Focus Session Complete! 🎉"
            content.body = isWorkPhase ? "Break time!" : "Ready to focus again?"
            content.sound = .default
        } else {
            content.title = "Break Over"
            content.body = "Ready to focus again?"
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    // MARK: - Progress
    
    var progress: Double {
        guard totalSecondsForPhase > 0 else { return 0 }
        return Double(totalSecondsForPhase - remainingSeconds) / Double(totalSecondsForPhase)
    }
    
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var sessionInfo: String {
        if stackManager.isQueueMode {
            return "Session \(currentSessionIndex + 1)/\(stackManager.totalSessionsInQueue)"
        } else {
            return "Session \(currentSessionIndex + 1)/\(sessionsBeforeLongBreak)"
        }
    }
    
    private func getModeDuration(for mode: FocusModeType) -> Int {
        // Use FocusModeType computed property directly
        return mode.workDuration
    }
}
