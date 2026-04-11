//
//  AICoach.swift
//  FocusTimer
//

import Foundation
import Combine

// MARK: - AI Coach Message

struct CoachMessage: Codable, Identifiable {
    let id: UUID
    let text: String
    let type: MessageType
    let timestamp: Date
    
    enum MessageType: String, Codable {
        case greeting = "greeting"
        case encouragement = "encouragement"
        case tip = "tip"
        case concern = "concern"
        case celebration = "celebration"
    }
}

// MARK: - AI Coach

class AICoach: ObservableObject {
    static let shared = AICoach()
    
    @Published var messages: [CoachMessage] = []
    @Published var lastCheckIn: Date?
    @Published var streakDays: Int = 0
    @Published var todaysMood: String = "neutral"
    
    private let dataManager = FocusDataManager.shared
    private let intelligence = FocusIntelligence.shared
    private let leveling = LevelingSystem.shared
    
    // Pre-written messages for different scenarios
    private let encouragements = [
        "You're doing amazing! Every session brings you closer to your goals.",
        "Focus is a skill, and you're getting better every day.",
        "Remember: small progress is still progress. Keep going!",
        "Your dedication is inspiring. Stay focused!",
        "The only bad session is the one that didn't happen.",
        "You've got this! One pomodoro at a time.",
        "Consistency beats intensity. Keep showing up!"
    ]
    
    private let tips = [
        "Try the 2-minute rule: if it takes less than 2 minutes, do it now.",
        "Break your biggest task into tiny pieces - it's less overwhelming.",
        "Schedule your most important task first thing in the morning.",
        "Take breaks! Your brain needs rest to stay sharp.",
        "Stay hydrated - even mild dehydration can affect focus.",
        "Try working in 90-minute blocks aligned with your ultradian rhythm.",
        "Put your phone in another room during deep work sessions."
    ]
    
    private let concerns = [
        "I noticed you've missed a few sessions lately. What's getting in the way?",
        "You've been ending sessions early. Want to try shorter focus times?",
        "It looks like this week has been tough. Remember: any focus is better than none.",
        "Your streak is at risk! Even a short session counts.",
        "I've seen more abandoned sessions recently. Want to talk about it?"
    ]
    
    func generateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 5..<12:
            greeting = "Good morning! Ready to make today count?"
        case 12..<17:
            greeting = "Good afternoon! Keep up the great work."
        case 17..<21:
            greeting = "Good evening! Evening focus sessions can be very productive."
        default:
            greeting = "Night owl mode! Just don't forget to sleep eventually."
        }
        
        messages.append(CoachMessage(
            id: UUID(),
            text: greeting,
            type: .greeting,
            timestamp: Date()
        ))
    }
    
    func checkIn() -> String? {
        lastCheckIn = Date()
        
        let stats = dataManager.statistics
        let streak = stats.currentStreak
        
        // Determine what to say based on context
        if streak > 0 && streak % 7 == 0 {
            return "Wow, \(streak) days in a row! You're unstoppable!"
        }
        
        if stats.todaySessions == 0 {
            let concern = concerns.randomElement()!
            messages.append(CoachMessage(
                id: UUID(),
                text: concern,
                type: .concern,
                timestamp: Date()
            ))
            return concern
        }
        
        if stats.todaySessions >= dataManager.settings.dailyGoal {
            let celebration = "You hit your daily goal! Amazing work today!"
            messages.append(CoachMessage(
                id: UUID(),
                text: celebration,
                type: .celebration,
                timestamp: Date()
            ))
            return celebration
        }
        
        // Random encouragement or tip
        if Bool.random() {
            let msg = encouragements.randomElement()!
            messages.append(CoachMessage(
                id: UUID(),
                text: msg,
                type: .encouragement,
                timestamp: Date()
            ))
            return msg
        } else {
            let msg = tips.randomElement()!
            messages.append(CoachMessage(
                id: UUID(),
                text: msg,
                type: .tip,
                timestamp: Date()
            ))
            return msg
        }
    }
    
    func onSessionComplete() -> String? {
        let stats = dataManager.statistics
        let sessionCount = stats.todaySessions
        
        if sessionCount == 1 {
            return "First session of the day complete! Great start!"
        }
        
        if sessionCount == dataManager.settings.dailyGoal {
            return "🎉 Daily goal achieved! You're on fire today!"
        }
        
        if sessionCount > 0 && sessionCount % 4 == 0 {
            return "\(sessionCount) sessions today! You're crushing it!"
        }
        
        let msg = encouragements.randomElement()!
        messages.append(CoachMessage(
            id: UUID(),
            text: msg,
            type: .encouragement,
            timestamp: Date()
        ))
        return msg
    }
    
    func onStreakAtRisk() -> String {
        let msg = "⚠️ Your \(dataManager.statistics.currentStreak)-day streak is about to break! Open the app to save it!"
        messages.append(CoachMessage(
            id: UUID(),
            text: msg,
            type: .concern,
            timestamp: Date()
        ))
        return msg
    }
    
    func getSmartSuggestion() -> String {
        intelligence.analyze()
        
        if let peakHour = intelligence.peakHours.first {
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            var components = DateComponents()
            components.hour = peakHour
            if let date = Calendar.current.date(from: components) {
                return "Schedule deep work around \(formatter.string(from: date)) - that's your peak focus time."
            }
        }
        
        if intelligence.completionRate < 0.7 {
            return "Try switching to Mini Sprint mode (15 min) - shorter sessions might help you finish more."
        }
        
        let msg = tips.randomElement()!
        return msg
    }
    
    func clearOldMessages() {
        // Keep only last 20 messages
        if messages.count > 20 {
            messages = Array(messages.suffix(20))
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "coach_messages")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "coach_messages"),
           let decoded = try? JSONDecoder().decode([CoachMessage].self, from: data) {
            messages = decoded
        }
    }
}
