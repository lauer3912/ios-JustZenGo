//
//  ReminderManager.swift
//  FocusTimer
//

import Foundation
import UserNotifications
import Combine

// MARK: - Reminder Manager

class ReminderManager: ObservableObject {
    static let shared = ReminderManager()
    
    @Published var pendingReminders: [ScheduledReminder] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let dataManager = FocusDataManager.shared
    
    struct ScheduledReminder: Identifiable {
        let id: String
        let title: String
        let body: String
        let triggerDate: Date
        let type: ReminderType
        var isScheduled: Bool = true
        
        enum ReminderType: String {
            case morning = "morning"
            case evening = "evening"
            case streak = "streak"
            case milestone = "milestone"
            case custom = "custom"
        }
    }
    
    init() {
        loadPendingReminders()
    }
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Reminder permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Schedule Reminders
    
    func scheduleMorningReminder(at time: Date) {
        let id = "morning_focus_reminder"
        cancelReminder(id: id)
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "☀️ Good Morning!"
        content.body = "Ready to start your focus journey today? You have \(dataManager.settings.dailyGoal) sessions to go!"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
        
        let reminder = ScheduledReminder(id: id, title: "Morning Reminder", body: content.body, triggerDate: time, type: .morning)
        pendingReminders.removeAll { $0.id == id }
        pendingReminders.append(reminder)
    }
    
    func scheduleEveningReminder(at time: Date) {
        let id = "evening_focus_reminder"
        cancelReminder(id: id)
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "🌙 Evening Focus Check"
        content.body = getEveningMessage()
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
        
        let reminder = ScheduledReminder(id: id, title: "Evening Reminder", body: content.body, triggerDate: time, type: .evening)
        pendingReminders.removeAll { $0.id == id }
        pendingReminders.append(reminder)
    }
    
    func scheduleStreakReminder() {
        let id = "streak_reminder"
        cancelReminder(id: id)
        
        // Schedule for tomorrow at 9 AM if user hasn't done any sessions today
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "🔥 Don't Break Your Streak!"
        content.body = "You haven't focused today. Keep your \(dataManager.statistics.currentStreak)-day streak alive!"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
        
        let reminder = ScheduledReminder(id: id, title: "Streak Reminder", body: content.body, triggerDate: Date().addingTimeInterval(86400), type: .streak)
        pendingReminders.append(reminder)
    }
    
    func scheduleMilestoneReminder(badgeName: String) {
        let id = "milestone_\(UUID().uuidString.prefix(8))"
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Milestone Unlocked!"
        content.body = "Congratulations! You've earned: \(badgeName)"
        content.sound = .default
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
        
        let reminder = ScheduledReminder(id: id, title: "Milestone: \(badgeName)", body: content.body, triggerDate: Date(), type: .milestone)
        pendingReminders.append(reminder)
    }
    
    func scheduleCustomReminder(title: String, body: String, at date: Date) -> String {
        let id = "custom_\(UUID().uuidString.prefix(8))"
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        notificationCenter.add(request)
        
        let reminder = ScheduledReminder(id: id, title: title, body: body, triggerDate: date, type: .custom)
        pendingReminders.append(reminder)
        
        return id
    }
    
    // MARK: - Cancel Reminders
    
    func cancelReminder(id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        pendingReminders.removeAll { $0.id == id }
    }
    
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
        pendingReminders.removeAll()
    }
    
    // MARK: - Update Reminders Based on Settings
    
    func updateRemindersFromSettings() {
        let settings = dataManager.settings
        
        if settings.reminderEnabled {
            if let morningTime = settings.morningReminderTime {
                scheduleMorningReminder(at: morningTime)
            }
            if let eveningTime = settings.eveningReminderTime {
                scheduleEveningReminder(at: eveningTime)
            }
        } else {
            cancelReminder(id: "morning_focus_reminder")
            cancelReminder(id: "evening_focus_reminder")
        }
    }
    
    // MARK: - Smart Reminders
    
    func checkAndScheduleSmartReminders() {
        let stats = dataManager.statistics
        let settings = dataManager.settings
        
        // If no sessions today and it's after 5 PM, remind
        if stats.todaySessions == 0 && Calendar.current.component(.hour, from: Date()) >= 17 {
            let id = "evening_catchup"
            cancelReminder(id: id)
            
            let content = UNMutableNotificationContent()
            content.title = "📝 Quick Focus?"
            content.body = "You haven't focused today. Even one 25-minute session keeps the streak alive!"
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            
            // Trigger in 30 minutes
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1800, repeats: false)
            
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            notificationCenter.add(request)
        }
        
        // If streak is about to break (3+ days), send encouragement
        if stats.currentStreak >= 3 && stats.todaySessions == 0 {
            scheduleStreakReminder()
        }
    }
    
    // MARK: - Helper
    
    private func getEveningMessage() -> String {
        let stats = dataManager.statistics
        let goal = dataManager.settings.dailyGoal
        
        if stats.todaySessions >= goal {
            return "Amazing! You've hit your \(goal) session goal today! 🌟"
        } else if stats.todaySessions > 0 {
            let remaining = goal - stats.todaySessions
            return "You have \(remaining) more session\(remaining == 1 ? "" : "s") to reach your daily goal. You've got this!"
        } else {
            return "No sessions today? It's not too late - start your first one!"
        }
    }
    
    private func loadPendingReminders() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingReminders = requests.compactMap { request -> ScheduledReminder? in
                    guard let notificationTrigger = request.trigger as? UNCalendarNotificationTrigger,
                          let date = Calendar.current.date(from: notificationTrigger.dateComponents) else {
                        return nil
                    }
                    let type: ScheduledReminder.ReminderType
                    if request.identifier.contains("morning") { type = .morning }
                    else if request.identifier.contains("evening") { type = .evening }
                    else if request.identifier.contains("streak") { type = .streak }
                    else if request.identifier.contains("milestone") { type = .milestone }
                    else { type = .custom }
                    
                    return ScheduledReminder(
                        id: request.identifier,
                        title: request.content.title,
                        body: request.content.body,
                        triggerDate: date,
                        type: type
                    )
                }
            }
        }
    }
}
