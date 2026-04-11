//
//  FocusDataManager.swift
//  FocusTimer
//

import Foundation
import Combine
import UserNotifications
import AVFoundation

// MARK: - Models

struct FocusSession: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let duration: Int
    let type: SessionType
    var completed: Bool
    var labelId: UUID?
    
    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil, duration: Int, type: SessionType, completed: Bool = false, labelId: UUID? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.type = type
        self.completed = completed
        self.labelId = labelId
    }
}

enum SessionType: String, Codable {
    case work
    case shortBreak
    case longBreak
}

// MARK: - Settings

struct FocusSettings: Codable {
    var workDuration: Int = 25 * 60
    var shortBreakDuration: Int = 5 * 60
    var longBreakDuration: Int = 15 * 60
    var sessionsUntilLongBreak: Int = 4
    var dailyGoal: Int = 8
    var soundEnabled: Bool = true
    var notificationEnabled: Bool = true
    
    static var `default`: FocusSettings { FocusSettings() }
}

// MARK: - Statistics

struct FocusStatistics {
    var todaySessions: Int = 0
    var todayMinutes: Int = 0
    var weekSessions: Int = 0
    var weekMinutes: Int = 0
    var totalSessions: Int = 0
    var totalMinutes: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
}

// MARK: - Data Manager

class FocusDataManager: ObservableObject {
    static let shared = FocusDataManager()
    
    @Published var sessions: [FocusSession] = []
    @Published var settings: FocusSettings = .default
    @Published var statistics: FocusStatistics = FocusStatistics()
    
    private let sessionsKey = "focus_sessions"
    private let settingsKey = "focus_settings"
    private let streakKey = "focus_streak"
    private let lastActiveDateKey = "last_active_date"
    
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        loadData()
        updateStatistics()
        requestNotificationPermission()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
            sessions = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(FocusSettings.self, from: data) {
            settings = decoded
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    // MARK: - Statistics
    
    func updateStatistics() {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        let todaySessions = sessions.filter { $0.type == .work && $0.completed && calendar.isDate($0.startTime, inSameDayAs: now) }
        let weekSessions = sessions.filter { $0.type == .work && $0.completed && $0.startTime >= startOfWeek }
        
        statistics.todaySessions = todaySessions.count
        statistics.todayMinutes = todaySessions.reduce(0) { $0 + $1.duration } / 60
        statistics.weekSessions = weekSessions.count
        statistics.weekMinutes = weekSessions.reduce(0) { $0 + $1.duration } / 60
        statistics.totalSessions = sessions.filter { $0.type == .work && $0.completed }.count
        statistics.totalMinutes = sessions.filter { $0.type == .work && $0.completed }.reduce(0) { $0 + $1.duration } / 60
        
        updateStreak()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let now = Date()
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        
        while true {
            let sessionsOnDate = sessions.filter {
                $0.type == .work && $0.completed && calendar.isDate($0.startTime, inSameDayAs: checkDate)
            }
            
            let goalMet = sessionsOnDate.count >= settings.dailyGoal
            
            if goalMet {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if calendar.isDateInToday(checkDate) {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        statistics.currentStreak = streak
        if streak > statistics.longestStreak {
            statistics.longestStreak = streak
        }
    }
    
    // MARK: - Sessions
    
    func addSession(_ session: FocusSession) {
        sessions.append(session)
        saveSessions()
        updateStatistics()
    }
    
    func getTodaySessions() -> [FocusSession] {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { $0.type == .work && $0.completed && calendar.isDate($0.startTime, inSameDayAs: now) }
    }
    
    func getWeekSessions() -> [FocusSession] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        return sessions.filter { $0.type == .work && $0.completed && $0.startTime >= startOfWeek }
    }
    
    // MARK: - Notifications
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        guard settings.notificationEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Sound
    
    func playSound() {
        guard settings.soundEnabled else { return }
        
        AudioServicesPlaySystemSound(1007)
    }
}
