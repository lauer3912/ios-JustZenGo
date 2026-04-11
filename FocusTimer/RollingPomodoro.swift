//
//  RollingPomodoro.swift
//  FocusTimer
//
//  Rolling Pomodoro - continuous timer with micro-breaks
//

import Foundation
import Combine

class RollingPomodoroManager: ObservableObject {
    static let shared = RollingPomodoroManager()
    
    // MARK: - Published State
    @Published var isActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentPhase: RollingPhase = .work
    @Published var timeRemaining: Int = 25 * 60
    @Published var totalWorkTime: Int = 0 // Total accumulated work time
    @Published var sessionCount: Int = 0
    @Published var microBreakDuration: Int = 60 // 1 minute micro-break
    @Published var autoResume: Bool = true
    
    // MARK: - Private
    private var timer: Timer?
    private var phaseStartTime: Date = Date()
    
    enum RollingPhase: String {
        case work = "Work"
        case microBreak = "Micro Break"
        
        var color: String {
            switch self {
            case .work: return "FF6B6B"
            case .microBreak: return "4ECB71"
            }
        }
    }
    
    private let dataManager = FocusDataManager.shared
    private let modeManager = FocusModeManager.shared
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Controls
    
    func start(workDuration: Int = 25 * 60) {
        guard !isActive else { return }
        
        isActive = true
        isPaused = false
        currentPhase = .work
        timeRemaining = workDuration
        totalWorkTime = 0
        sessionCount = 0
        phaseStartTime = Date()
        
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    func stop() {
        isActive = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        // Record final session if we did any work
        if totalWorkTime > 0 {
            recordAccumulatedSession()
        }
    }
    
    func skipMicroBreak() {
        guard currentPhase == .microBreak else { return }
        startWorkPhase()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func tick() {
        guard !isPaused else { return }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
            
            // Track work time
            if currentPhase == .work {
                totalWorkTime += 1
            }
        } else {
            handlePhaseEnd()
        }
    }
    
    private func handlePhaseEnd() {
        switch currentPhase {
        case .work:
            sessionCount += 1
            
            // Record this work session
            recordWorkSession()
            
            // Start micro-break
            startMicroBreakPhase()
            
        case .microBreak:
            // End micro-break, start new work phase
            startWorkPhase()
        }
    }
    
    private func startWorkPhase() {
        let workDuration = modeManager.currentMode.workDuration
        currentPhase = .work
        timeRemaining = workDuration
        phaseStartTime = Date()
    }
    
    private func startMicroBreakPhase() {
        currentPhase = .microBreak
        timeRemaining = microBreakDuration
        
        // Auto-resume after micro-break if enabled
        if autoResume {
            // The timer continues automatically
        }
    }
    
    // MARK: - Recording
    
    private func recordWorkSession() {
        let session = FocusSession(
            id: UUID(),
            startTime: phaseStartTime,
            endTime: Date(),
            duration: modeManager.currentMode.workDuration / 60,
            type: .work,
            completed: true,
            labelId: nil
        )
        dataManager.addSession(session)
    }
    
    private func recordAccumulatedSession() {
        // Record any remaining work time
        if totalWorkTime >= 60 { // At least 1 minute
            let session = FocusSession(
                id: UUID(),
                startTime: Date().addingTimeInterval(-Double(totalWorkTime)),
                endTime: Date(),
                duration: totalWorkTime / 60,
                type: .work,
                completed: totalWorkTime >= modeManager.currentMode.workDuration,
                labelId: nil
            )
            dataManager.addSession(session)
        }
    }
    
    // MARK: - Settings
    
    func setMicroBreakDuration(_ seconds: Int) {
        microBreakDuration = max(30, min(180, seconds)) // 30 sec to 3 min
        save()
    }
    
    func setAutoResume(_ enabled: Bool) {
        autoResume = enabled
        save()
    }
    
    // MARK: - Computed
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        let totalDuration = currentPhase == .work 
            ? modeManager.currentMode.workDuration 
            : microBreakDuration
        return Double(totalDuration - timeRemaining) / Double(totalDuration)
    }
    
    var totalWorkTimeFormatted: String {
        let hours = totalWorkTime / 3600
        let minutes = (totalWorkTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    // MARK: - Persistence
    
    private func save() {
        UserDefaults.standard.set(microBreakDuration, forKey: "rolling_micro_break_duration")
        UserDefaults.standard.set(autoResume, forKey: "rolling_auto_resume")
    }
    
    private func loadSettings() {
        microBreakDuration = UserDefaults.standard.integer(forKey: "rolling_micro_break_duration")
        if microBreakDuration == 0 { microBreakDuration = 60 }
        autoResume = UserDefaults.standard.object(forKey: "rolling_auto_resume") as? Bool ?? true
    }
}
