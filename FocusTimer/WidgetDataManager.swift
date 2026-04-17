//
//  WidgetDataManager.swift
//  FocusTimer
//
//  Shared data manager for Widget and App communication via App Groups
//

import Foundation
import WidgetKit

// MARK: - App Group Suite Name

let appGroupSuiteName = "group.com.ggsheng.FocusTimer"

// MARK: - Widget Data Keys

enum WidgetDataKey: String {
    case sessionsToday = "widget_sessions_today"
    case streakDays = "widget_streak_days"
    case focusScore = "widget_focus_score"
    case totalFocusMinutes = "widget_total_focus_minutes"
    case todayFocusMinutes = "widget_today_focus_minutes"
    case currentStreak = "widget_current_streak"
    case longestStreak = "widget_longest_streak"
    case level = "widget_level"
    case coins = "widget_coins"
    case achievementsUnlocked = "widget_achievements_unlocked"
    case totalAchievements = "widget_total_achievements"
    case lastUpdated = "widget_last_updated"
    case isTimerRunning = "widget_is_timer_running"
    case currentModeName = "widget_current_mode_name"
    case timeRemaining = "widget_time_remaining"
    case totalDuration = "widget_total_duration"
    case projectName = "widget_project_name"
    case sessionsCompleted = "widget_sessions_completed"
}

// MARK: - Widget Data Manager

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupSuiteName)
    }
    
    // MARK: - Write Methods (called from main app)
    
    func updateFocusData(
        sessionsToday: Int,
        streakDays: Int,
        focusScore: Int,
        todayFocusMinutes: Int,
        currentStreak: Int,
        longestStreak: Int,
        level: Int,
        coins: Int,
        achievementsUnlocked: Int,
        totalAchievements: Int
    ) {
        let data: [String: Any] = [
            WidgetDataKey.sessionsToday.rawValue: sessionsToday,
            WidgetDataKey.streakDays.rawValue: streakDays,
            WidgetDataKey.focusScore.rawValue: focusScore,
            WidgetDataKey.todayFocusMinutes.rawValue: todayFocusMinutes,
            WidgetDataKey.currentStreak.rawValue: currentStreak,
            WidgetDataKey.longestStreak.rawValue: longestStreak,
            WidgetDataKey.level.rawValue: level,
            WidgetDataKey.coins.rawValue: coins,
            WidgetDataKey.achievementsUnlocked.rawValue: achievementsUnlocked,
            WidgetDataKey.totalAchievements.rawValue: totalAchievements,
            WidgetDataKey.lastUpdated.rawValue: Date().timeIntervalSince1970
        ]
        
        userDefaults?.set(data, forKey: "widget_focus_data")
        userDefaults?.synchronize()
        
        // Reload widget timeline
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateTimerState(
        isRunning: Bool,
        modeName: String,
        timeRemaining: Int,
        totalDuration: Int,
        projectName: String,
        sessionsCompleted: Int
    ) {
        let data: [String: Any] = [
            WidgetDataKey.isTimerRunning.rawValue: isRunning,
            WidgetDataKey.currentModeName.rawValue: modeName,
            WidgetDataKey.timeRemaining.rawValue: timeRemaining,
            WidgetDataKey.totalDuration.rawValue: totalDuration,
            WidgetDataKey.projectName.rawValue: projectName,
            WidgetDataKey.sessionsCompleted.rawValue: sessionsCompleted,
            WidgetDataKey.lastUpdated.rawValue: Date().timeIntervalSince1970
        ]
        
        userDefaults?.set(data, forKey: "widget_timer_state")
        userDefaults?.synchronize()
        
        // Reload widget timeline
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Read Methods (called from Widget)
    
    static func getFocusData() -> WidgetFocusData {
        guard let userDefaults = UserDefaults(suiteName: appGroupSuiteName),
              let data = userDefaults.dictionary(forKey: "widget_focus_data") else {
            return WidgetFocusData.defaultData
        }
        
        return WidgetFocusData(
            sessionsToday: data[WidgetDataKey.sessionsToday.rawValue] as? Int ?? 0,
            streakDays: data[WidgetDataKey.streakDays.rawValue] as? Int ?? 0,
            focusScore: data[WidgetDataKey.focusScore.rawValue] as? Int ?? 0,
            todayFocusMinutes: data[WidgetDataKey.todayFocusMinutes.rawValue] as? Int ?? 0,
            currentStreak: data[WidgetDataKey.currentStreak.rawValue] as? Int ?? 0,
            longestStreak: data[WidgetDataKey.longestStreak.rawValue] as? Int ?? 0,
            level: data[WidgetDataKey.level.rawValue] as? Int ?? 1,
            coins: data[WidgetDataKey.coins.rawValue] as? Int ?? 0,
            achievementsUnlocked: data[WidgetDataKey.achievementsUnlocked.rawValue] as? Int ?? 0,
            totalAchievements: data[WidgetDataKey.totalAchievements.rawValue] as? Int ?? 0
        )
    }
    
    static func getTimerState() -> WidgetTimerState {
        guard let userDefaults = UserDefaults(suiteName: appGroupSuiteName),
              let data = userDefaults.dictionary(forKey: "widget_timer_state") else {
            return WidgetTimerState.defaultState
        }
        
        return WidgetTimerState(
            isRunning: data[WidgetDataKey.isTimerRunning.rawValue] as? Bool ?? false,
            modeName: data[WidgetDataKey.currentModeName.rawValue] as? String ?? "Focus",
            timeRemaining: data[WidgetDataKey.timeRemaining.rawValue] as? Int ?? 0,
            totalDuration: data[WidgetDataKey.totalDuration.rawValue] as? Int ?? 0,
            projectName: data[WidgetDataKey.projectName.rawValue] as? String ?? "General",
            sessionsCompleted: data[WidgetDataKey.sessionsCompleted.rawValue] as? Int ?? 0
        )
    }
    
    // MARK: - Quick Update from Managers
    
    func syncFromManagers() {
        let stats = FocusDataManager.shared.getTodayStats()
        let leveling = LevelingSystem.shared
        let coins = FocusCoinManager.shared
        let achievements = AchievementManager.shared
        
        updateFocusData(
            sessionsToday: stats.sessionsCompleted,
            streakDays: stats.currentStreak,
            focusScore: calculateFocusScore(from: stats),
            todayFocusMinutes: stats.totalFocusMinutes,
            currentStreak: stats.currentStreak,
            longestStreak: stats.longestStreak,
            level: leveling.currentLevel,
            coins: coins.totalCoins,
            achievementsUnlocked: achievements.totalUnlocked,
            totalAchievements: achievements.badges.count
        )
    }
    
    private func calculateFocusScore(from stats: FocusStatistics) -> Int {
        // Simple focus score calculation
        let sessionScore = min(stats.sessionsCompleted * 10, 40)
        let streakScore = min(stats.currentStreak * 5, 30)
        let timeScore = min(stats.totalFocusMinutes / 5, 30)
        return min(sessionScore + streakScore + timeScore, 100)
    }
}

// MARK: - Data Models

struct WidgetFocusData {
    let sessionsToday: Int
    let streakDays: Int
    let focusScore: Int
    let todayFocusMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let level: Int
    let coins: Int
    let achievementsUnlocked: Int
    let totalAchievements: Int
    
    var formattedFocusTime: String {
        let hours = todayFocusMinutes / 60
        let minutes = todayFocusMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    static let defaultData = WidgetFocusData(
        sessionsToday: 0,
        streakDays: 0,
        focusScore: 0,
        todayFocusMinutes: 0,
        currentStreak: 0,
        longestStreak: 0,
        level: 1,
        coins: 0,
        achievementsUnlocked: 0,
        totalAchievements: 0
    )
}

struct WidgetTimerState {
    let isRunning: Bool
    let modeName: String
    let timeRemaining: Int
    let totalDuration: Int
    let projectName: String
    let sessionsCompleted: Int
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(totalDuration))
    }
    
    static let defaultState = WidgetTimerState(
        isRunning: false,
        modeName: "Focus",
        timeRemaining: 0,
        totalDuration: 0,
        projectName: "General",
        sessionsCompleted: 0
    )
}
