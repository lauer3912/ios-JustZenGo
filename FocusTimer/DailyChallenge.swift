//
//  DailyChallenge.swift
//  FocusTimer
//

import Foundation

// MARK: - Daily Challenge

struct DailyChallenge: Codable {
    let id: UUID
    let title: String
    let description: String
    let targetSessions: Int
    let targetMinutes: Int?
    let xpReward: Int
    let challengeType: ChallengeType
    let date: Date
    var isCompleted: Bool = false
    var progress: Int = 0
    
    enum ChallengeType: String, Codable {
        case sessionCount = "session_count"
        case timeBased = "time_based"
        case streakBased = "streak_based"
        case modeBased = "mode_based"
        case special = "special"
    }
    
    init(title: String, description: String, targetSessions: Int, targetMinutes: Int? = nil, xpReward: Int, challengeType: ChallengeType, date: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.targetSessions = targetSessions
        self.targetMinutes = targetMinutes
        self.xpReward = xpReward
        self.challengeType = challengeType
        self.date = date
    }
    
    var progressPercentage: Double {
        if let target = targetMinutes {
            return min(Double(progress) / Double(target), 1.0)
        }
        return min(Double(progress) / Double(targetSessions), 1.0)
    }
}

// MARK: - Daily Challenge Manager

class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()
    
    @Published var todayChallenge: DailyChallenge?
    @Published var totalXPEarned: Int = 0
    @Published var challengesCompleted: Int = 0
    
    private let challengeTemplates: [(title: String, desc: String, type: DailyChallenge.ChallengeType, target: Int, xp: Int)] = [
        ("Early Bird", "Complete 3 sessions before noon", .sessionCount, 3, 50),
        ("Marathon Runner", "Focus for 120 minutes total today", .timeBased, 120, 75),
        ("Consistency King", "Complete your daily goal sessions", .sessionCount, 8, 60),
        ("Streak Defender", "Don't break your streak today", .streakBased, 1, 40),
        ("Deep Diver", "Try a 90-minute Deep Work session", .modeBased, 1, 80),
        ("Speed Demon", "Complete 5 mini sprints", .sessionCount, 5, 45),
        ("Afternoon Power", "Complete 4 sessions after 2 PM", .sessionCount, 4, 55),
        ("Perfect Day", "Hit your daily goal with no abandoned sessions", .special, 1, 100),
        ("Century Club", "Focus for 100 minutes total", .timeBased, 100, 70),
        ("Double Down", "Complete 2 back-to-back sessions", .sessionCount, 2, 35),
        ("Night Owl", "Complete a session after 8 PM", .special, 1, 45),
        ("First Step", "Complete your very first focus session", .sessionCount, 1, 20),
        ("Morning Ritual", "Start 3 sessions before 10 AM", .sessionCount, 3, 50),
        ("Break Taker", "Take 4 proper breaks today", .special, 4, 30),
        ("Quality Over Quantity", "Complete 3 sessions with 100% focus quality", .special, 3, 65)
    ]
    
    func generateDailyChallenge() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already have today's challenge
        if let existing = todayChallenge, calendar.isDate(existing.date, inSameDayAs: today) {
            return
        }
        
        // Use day of year to deterministically select a challenge
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        let index = dayOfYear % challengeTemplates.count
        let template = challengeTemplates[index]
        
        todayChallenge = DailyChallenge(
            title: template.title,
            description: template.desc,
            targetSessions: template.target,
            xpReward: template.xp,
            challengeType: template.type,
            date: today
        )
        
        save()
    }
    
    func updateProgress(sessionsCompleted: Int, minutesCompleted: Int, streakMaintained: Bool) {
        guard var challenge = todayChallenge else { return }
        
        switch challenge.challengeType {
        case .sessionCount:
            challenge.progress = sessionsCompleted
        case .timeBased:
            challenge.progress = minutesCompleted
        case .streakBased:
            challenge.progress = streakMaintained ? 1 : 0
        case .modeBased:
            challenge.progress = sessionsCompleted
        case .special:
            challenge.progress = sessionsCompleted
        }
        
        // Check completion
        if challenge.progressPercentage >= 1.0 && !challenge.isCompleted {
            challenge.isCompleted = true
            totalXPEarned += challenge.xpReward
            challengesCompleted += 1
        }
        
        todayChallenge = challenge
        save()
    }
    
    func resetIfNewDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existing = todayChallenge, !calendar.isDate(existing.date, inSameDayAs: today) {
            todayChallenge = nil
            generateDailyChallenge()
        }
    }
    
    private func save() {
        if let challenge = todayChallenge,
           let encoded = try? JSONEncoder().encode(challenge) {
            UserDefaults.standard.set(encoded, forKey: "daily_challenge")
        }
        UserDefaults.standard.set(totalXPEarned, forKey: "total_xp_earned")
        UserDefaults.standard.set(challengesCompleted, forKey: "challenges_completed")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "daily_challenge"),
           let decoded = try? JSONDecoder().decode(DailyChallenge.self, from: data) {
            todayChallenge = decoded
        }
        totalXPEarned = UserDefaults.standard.integer(forKey: "total_xp_earned")
        challengesCompleted = UserDefaults.standard.integer(forKey: "challenges_completed")
    }
}
