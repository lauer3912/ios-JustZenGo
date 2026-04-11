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
        
        // Load saved data
        FocusModeManager.shared.load()
        TimerStackManager.shared.load()
        DailyChallengeManager.shared.load()
        DailyChallengeManager.shared.generateDailyChallenge()
        FocusSoundManager.shared.load()
        SessionLabelManager.shared.load()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
