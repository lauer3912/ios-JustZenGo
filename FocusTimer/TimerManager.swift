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
    private let challengeManager = DailyChallengeManager.shared
    private let soundManager = FocusSoundManager.shared
    private let achievementManager = AchievementManager.shared
    private let levelingSystem = LevelingSystem.shared
    private let coinManager = FocusCoinManager.shared
    private let celebrationManager = CelebrationManager.shared
    private let projectManager = ProjectManager.shared
    
    // MARK: - Callbacks for UI updates
    var onTimerUpdate: (() -> Void)?
    var onPhaseChange: ((Bool) -> Void)?
    var onSessionComplete: (() -> Void)?
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        let mode = modeManager.currentMode ?? modeManager.modes.first
        if let mode = mode {
            workDuration = mode.work
            breakDuration = mode.breakLength
            longBreakDuration = mode.longBreak
            sessionsBeforeLongBreak = mode.sessionsBeforeLongBreak
            currentModeName = mode.name
        }
        remainingSeconds = workDuration
        totalSecondsForPhase = workDuration
    }
    
    // MARK: - Timer Controls
    
    func start() {
        guard !isRunning else { return }
        
        if isPaused {
            // Resume
            isPaused = false
        } else {
            // Fresh start
            loadSettings()
            isWorkPhase = true
            currentSessionIndex = 0
            sessionStartTime = Date()
            
            // Load label if any
            if let label = SessionLabelManager.shared.currentLabel {
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
            // Work phase ended
            recordSession()
            
            // Check if stack has more sessions
            if stackManager.isQueueMode && currentSessionIndex < stackManager.currentQueue.count - 1 {
                currentSessionIndex += 1
                let nextItem = stackManager.currentQueue[currentSessionIndex]
                remainingSeconds = nextItem.duration * 60
                totalSecondsForPhase = nextItem.duration * 60
                currentSessionLabel = nextItem.label
                isWorkPhase = true
                soundManager.playTransitionSound()
                onPhaseChange?(true)
            } else if currentSessionIndex >= sessionsBeforeLongBreak - 1 {
                // Long break
                remainingSeconds = longBreakDuration
                totalSecondsForPhase = longBreakDuration
                isWorkPhase = false
                currentSessionIndex = 0
                soundManager.playBreakEndSound()
                onPhaseChange?(false)
            } else {
                // Regular break
                remainingSeconds = breakDuration
                totalSecondsForPhase = breakDuration
                isWorkPhase = false
                soundManager.playBreakEndSound()
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
            soundManager.playWorkStartSound()
            onPhaseChange?(true)
        }
        
        sendNotification(wasWorkPhase: wasWorkPhase)
        onSessionComplete?()
    }
    
    private func recordSession() {
        guard isWorkPhase else { return }
        
        let minutes = workDuration / 60
        let actualMinutes = Int(Date().timeIntervalSince(sessionStartTime) / 60)
        
        // Update data manager
        dataManager.recordSession(
            duration: actualMinutes,
            label: currentSessionLabel.isEmpty ? nil : currentSessionLabel,
            mode: currentModeName
        )
        
        // Update challenge
        challengeManager.recordCompletedSession(mode: currentModeName)
        
        // Update XP and coins
        let xpEarned = levelingSystem.addXP(xp: actualMinutes * 10)
        let coinsEarned = coinManager.addCoins(amount: actualMinutes)
        
        // Check achievements
        achievementManager.checkAndUnlock(sessionCount: dataManager.statistics.totalSessions)
        
        // Update project if active
        if let project = projectManager.activeProject {
            projectManager.addTimeToProject(minutes: actualMinutes)
        }
        
        // Play celebration
        celebrationManager.checkAndCelebrate(
            sessions: dataManager.statistics.todaySessions,
            streak: dataManager.statistics.currentStreak,
            totalSessions: dataManager.statistics.totalSessions
        )
    }
    
    private func sendNotification(wasWorkPhase: Bool) {
        let content = UNMutableNotificationContent()
        
        if wasWorkPhase {
            content.title = "Focus Session Complete! 🎉"
            content.body = "Great work! Time for a \(isWorkPhase ? "break" : "break")."
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
            return "Session \(currentSessionIndex + 1)/\(stackManager.currentQueue.count)"
        } else {
            return "Session \(currentSessionIndex + 1)/\(sessionsBeforeLongBreak)"
        }
    }
}
