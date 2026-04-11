//
//  FocusTimerApp.swift
//  FocusTimer
//

import SwiftUI

@main
struct FocusTimerApp: App {
    init() {
        // Initialize all managers at app startup
        _ = FocusDataManager.shared
        _ = FocusModeManager.shared
        _ = TimerStackManager.shared
        _ = DailyChallengeManager.shared
        _ = FocusSoundManager.shared
        _ = SessionLabelManager.shared
        _ = LevelingSystem.shared
        _ = FocusCoinManager.shared
        _ = CelebrationManager.shared
        _ = AchievementManager.shared
        _ = FocusIntelligence.shared
        _ = ProjectManager.shared
        _ = AICoach.shared
        _ = HealthIntegration.shared
        _ = CalendarIntegration.shared
        _ = LiveActivityManager.shared
        _ = ThemeManager.shared
        _ = TimerManager.shared
        _ = DailyPlanner.shared
        _ = RollingPomodoroManager.shared
        
        // Load saved data
        FocusModeManager.shared.load()
        TimerStackManager.shared.load()
        DailyChallengeManager.shared.load()
        DailyChallengeManager.shared.generateDailyChallenge()
        FocusSoundManager.shared.load()
        SessionLabelManager.shared.load()
        LevelingSystem.shared.load()
        FocusCoinManager.shared.load()
        CelebrationManager.shared.load()
        AchievementManager.shared.load()
        FocusIntelligence.shared.load()
        ProjectManager.shared.load()
        AICoach.shared.load()
        CalendarIntegration.shared.fetchTodayEvents()
        ThemeManager.shared.load()
        
        // Initial analysis
        FocusIntelligence.shared.analyze()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
