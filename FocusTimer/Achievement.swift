//
//  Achievement.swift
//  FocusTimer
//

import Foundation
import Combine

// MARK: - Achievement Badge

struct AchievementBadge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let icon: String
    let requirement: Int
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    
    enum AchievementCategory: String, Codable, CaseIterable {
        case consistency = "consistency"
        case volume = "volume"
        case variety = "variety"
        case social = "social"
        case secret = "secret"
        case milestone = "milestone"
        case special = "special"
        
        var displayName: String {
            switch self {
            case .consistency: return "Consistency"
            case .volume: return "Volume"
            case .variety: return "Variety"
            case .social: return "Social"
            case .secret: return "Secret"
            case .milestone: return "Milestone"
            case .special: return "Special"
            }
        }
        
        var icon: String {
            switch self {
            case .consistency: return "flame.fill"
            case .volume: return "chart.bar.fill"
            case .variety: return "sparkles"
            case .social: return "person.2.fill"
            case .secret: return "questionmark.circle.fill"
            case .milestone: return "star.fill"
            case .special: return "gift.fill"
            }
        }
    }
}

// MARK: - Achievement Manager

class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var badges: [AchievementBadge] = []
    @Published var totalUnlocked: Int = 0
    
    init() {
        createAllAchievements()
        load()
    }
    
    private func createAllAchievements() {
        badges = [
            // Consistency badges
            AchievementBadge(id: "streak_3", name: "First Steps", description: "Complete 3 day streak", category: .consistency, icon: "flame", requirement: 3),
            AchievementBadge(id: "streak_7", name: "Week Warrior", description: "Complete 7 day streak", category: .consistency, icon: "flame.fill", requirement: 7),
            AchievementBadge(id: "streak_14", name: "Fortnight Focus", description: "Complete 14 day streak", category: .consistency, icon: "flame.fill", requirement: 14),
            AchievementBadge(id: "streak_30", name: "Monthly Master", description: "Complete 30 day streak", category: .consistency, icon: "flame.fill", requirement: 30),
            AchievementBadge(id: "streak_60", name: "Two Month Titan", description: "Complete 60 day streak", category: .consistency, icon: "flame.fill", requirement: 60),
            AchievementBadge(id: "streak_100", name: "Century Club", description: "Complete 100 day streak", category: .consistency, icon: "flame.fill", requirement: 100),
            AchievementBadge(id: "streak_365", name: "Year of Focus", description: "Complete 365 day streak", category: .consistency, icon: "crown.fill", requirement: 365),
            
            // Volume badges
            AchievementBadge(id: "sessions_10", name: "Getting Started", description: "Complete 10 focus sessions", category: .volume, icon: "circle.fill", requirement: 10),
            AchievementBadge(id: "sessions_50", name: "Half Century", description: "Complete 50 focus sessions", category: .volume, icon: "circle.fill", requirement: 50),
            AchievementBadge(id: "sessions_100", name: "Centurion", description: "Complete 100 focus sessions", category: .volume, icon: "star.fill", requirement: 100),
            AchievementBadge(id: "sessions_500", name: "Productivity Pro", description: "Complete 500 focus sessions", category: .volume, icon: "star.fill", requirement: 500),
            AchievementBadge(id: "sessions_1000", name: "Focus Legend", description: "Complete 1,000 focus sessions", category: .volume, icon: "crown.fill", requirement: 1000),
            AchievementBadge(id: "sessions_5000", name: "Focus Immortal", description: "Complete 5,000 focus sessions", category: .volume, icon: "crown.fill", requirement: 5000),
            
            // Hours badges
            AchievementBadge(id: "hours_10", name: "10 Hour Club", description: "Focus for 10 total hours", category: .volume, icon: "clock.fill", requirement: 10),
            AchievementBadge(id: "hours_50", name: "50 Hour Club", description: "Focus for 50 total hours", category: .volume, icon: "clock.fill", requirement: 50),
            AchievementBadge(id: "hours_100", name: "100 Hour Club", description: "Focus for 100 total hours", category: .volume, icon: "clock.fill", requirement: 100),
            AchievementBadge(id: "hours_500", name: "500 Hour Master", description: "Focus for 500 total hours", category: .volume, icon: "clock.badge.checkmark.fill", requirement: 500),
            AchievementBadge(id: "hours_1000", name: "1000 Hour Legend", description: "Focus for 1,000 total hours", category: .volume, icon: "clock.badge.checkmark.fill", requirement: 1000),
            
            // Variety badges
            AchievementBadge(id: "modes_all", name: "Mode Explorer", description: "Try all focus modes", category: .variety, icon: "sparkles", requirement: 6),
            AchievementBadge(id: "modes_deep_10", name: "Deep Diver", description: "Complete 10 Deep Work sessions", category: .variety, icon: "brain.head.profile", requirement: 10),
            AchievementBadge(id: "modes_creative_10", name: "Creative Spirit", description: "Complete 10 Creative Flow sessions", category: .variety, icon: "paintbrush.fill", requirement: 10),
            AchievementBadge(id: "labels_5", name: "Organizer", description: "Use 5 different session labels", category: .variety, icon: "tag.fill", requirement: 5),
            AchievementBadge(id: "sounds_5", name: "Audiophile", description: "Try 5 different focus sounds", category: .variety, icon: "headphones", requirement: 5),
            AchievementBadge(id: "challenges_10", name: "Challenge Seeker", description: "Complete 10 daily challenges", category: .variety, icon: "star.fill", requirement: 10),
            AchievementBadge(id: "challenges_50", name: "Challenge Champion", description: "Complete 50 daily challenges", category: .variety, icon: "trophy.fill", requirement: 50),
            
            // Milestone badges
            AchievementBadge(id: "first_session", name: "First Focus", description: "Complete your first focus session", category: .milestone, icon: "play.fill", requirement: 1),
            AchievementBadge(id: "first_day_goal", name: "Goal Getter", description: "Hit your daily goal", category: .milestone, icon: "target", requirement: 1),
            AchievementBadge(id: "first_streak", name: "Streak Starter", description: "Start a 3-day streak", category: .milestone, icon: "flame", requirement: 3),
            AchievementBadge(id: "first_xp", name: "XP Hunter", description: "Earn your first 100 XP", category: .milestone, icon: "sparkles", requirement: 100),
            AchievementBadge(id: "level_5", name: "Rising Star", description: "Reach level 5", category: .milestone, icon: "star.fill", requirement: 5),
            AchievementBadge(id: "level_10", name: "Focus Apprentice", description: "Reach level 10", category: .milestone, icon: "star.fill", requirement: 10),
            AchievementBadge(id: "level_25", name: "Focus Expert", description: "Reach level 25", category: .milestone, icon: "star.circle.fill", requirement: 25),
            AchievementBadge(id: "level_50", name: "Focus Master", description: "Reach level 50", category: .milestone, icon: "crown.fill", requirement: 50),
            AchievementBadge(id: "level_100", name: "Focus Legend", description: "Reach level 100", category: .milestone, icon: "crown.fill", requirement: 100),
            
            // Special badges
            AchievementBadge(id: "marathon_first", name: "Marathon Debut", description: "Complete your first Marathon session", category: .special, icon: "figure.run", requirement: 1),
            AchievementBadge(id: "queue_5", name: "Queue Master", description: "Complete a queue with 5+ sessions", category: .special, icon: "list.bullet.rectangle", requirement: 5),
            AchievementBadge(id: "perfect_day", name: "Perfect Day", description: "Complete daily goal with no abandoned sessions", category: .special, icon: "checkmark.seal.fill", requirement: 1),
            AchievementBadge(id: "early_bird", name: "Early Bird", description: "Complete 3 sessions before 9 AM", category: .special, icon: "sunrise.fill", requirement: 3),
            AchievementBadge(id: "night_owl", name: "Night Owl", description: "Complete a session after 10 PM", category: .special, icon: "moon.fill", requirement: 1),
            AchievementBadge(id: "weekend_warrior", name: "Weekend Warrior", description: "Complete 10 sessions on weekends", category: .special, icon: "calendar", requirement: 10),
            AchievementBadge(id: "coin_collector", name: "Coin Collector", description: "Earn 1,000 Focus Coins", category: .special, icon: "bitcoinsign.circle.fill", requirement: 1000),
        ]
    }
    
    func checkAndUnlockAchievements(stats: FocusStatistics, extra: [String: Int]) {
        for i in 0..<badges.count {
            guard !badges[i].isUnlocked else { continue }
            
            var progress = 0
            
            switch badges[i].category {
            case .consistency:
                progress = stats.currentStreak
            case .volume:
                if badges[i].id.contains("sessions") {
                    progress = stats.totalSessions
                } else if badges[i].id.contains("hours") {
                    progress = stats.totalMinutes / 60
                }
            case .milestone:
                if badges[i].id.contains("level") {
                    progress = extra["level"] ?? 0
                } else if badges[i].id.contains("xp") {
                    progress = extra["totalXP"] ?? 0
                } else {
                    progress = stats.totalSessions > 0 ? 1 : 0
                }
            case .variety:
                progress = extra["modesUsed"] ?? 0
            case .special:
                progress = extra[badges[i].id] ?? 0
            default:
                continue
            }
            
            if progress >= badges[i].requirement {
                badges[i].isUnlocked = true
                badges[i].unlockedDate = Date()
                totalUnlocked += 1
            }
        }
        save()
    }
    
    func getUnlockedBadges() -> [AchievementBadge] {
        badges.filter { $0.isUnlocked }
    }
    
    func getLockedBadges() -> [AchievementBadge] {
        badges.filter { !$0.isUnlocked }
    }
    
    func getBadgesByCategory(_ category: AchievementBadge.AchievementCategory) -> [AchievementBadge] {
        badges.filter { $0.category == category }
    }
    
    func getProgress(for badgeId: String) -> Double {
        guard let badge = badges.first(where: { $0.id == badgeId }) else { return 0 }
        // This would be calculated based on current stats
        return 0.0 // Simplified for now
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(badges) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
        UserDefaults.standard.set(totalUnlocked, forKey: "achievements_unlocked")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let decoded = try? JSONDecoder().decode([AchievementBadge].self, from: data) {
            badges = decoded
            totalUnlocked = badges.filter { $0.isUnlocked }.count
        }
    }
}
