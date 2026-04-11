//
//  LevelingSystem.swift
//  FocusTimer
//

import Foundation
import Combine

// MARK: - Level System

class LevelingSystem: ObservableObject {
    static let shared = LevelingSystem()
    
    @Published var currentLevel: Int = 1
    @Published var currentXP: Int = 0
    @Published var totalXPEarned: Int = 0
    
    // XP required for each level (exponential scaling)
    private let xpPerLevel: [Int] = [
        100, 150, 220, 310, 430, 580, 770, 1010, 1310, 1690,  // 1-10
        2170, 2780, 3540, 4490, 5670, 7140, 8960, 11210, 14010, 17480,  // 11-20
        21780, 27080, 33620, 41690, 51600, 63760, 78640, 96860, 119160, 146280,  // 21-30
        179300, 219500, 268500, 328100, 400700, 488700, 595300, 724600, 881300, 1071500,  // 31-40
        1303000, 1583500, 1924000, 2337000, 2837000, 3443000, 4178000, 5070000, 6151000, 7461000,  // 41-50
    ]
    
    var xpForNextLevel: Int {
        guard currentLevel <= xpPerLevel.count else { return xpPerLevel.last! * 2 }
        return xpPerLevel[currentLevel - 1]
    }
    
    var progressToNextLevel: Double {
        let xpNeeded = xpForNextLevel
        return min(Double(currentXP) / Double(xpNeeded), 1.0)
    }
    
    var levelTitle: String {
        switch currentLevel {
        case 1...5: return "Novice"
        case 6...10: return "Apprentice"
        case 11...15: return "Practitioner"
        case 16...20: return "Expert"
        case 21...30: return "Master"
        case 31...50: return "Grand Master"
        case 51...75: return "Legend"
        case 76...99: return "Mythic"
        case 100: return "Immortal"
        default: return "Immortal"
        }
    }
    
    func addXP(_ amount: Int) -> (leveledUp: Bool, newLevel: Int) {
        currentXP += amount
        totalXPEarned += amount
        var leveledUp = false
        
        while currentXP >= xpForNextLevel && currentLevel < 100 {
            currentXP -= xpForNextLevel
            currentLevel += 1
            leveledUp = true
        }
        
        save()
        return (leveledUp, currentLevel)
    }
    
    func getXPForSession(duration: Int, completionRate: Double, challengeBonus: Int) -> Int {
        // Base XP: 10 XP per 5 minutes
        var xp = (duration / 60) * 2
        
        // Completion bonus
        xp += Int(20 * completionRate)
        
        // Challenge bonus
        xp += challengeBonus
        
        // Streak bonus (10% per day, max 100%)
        let streakMultiplier = 1.0 + min(Double(FocusDataManager.shared.statistics.currentStreak) * 0.1, 1.0)
        xp = Int(Double(xp) * streakMultiplier)
        
        return xp
    }
    
    private func save() {
        UserDefaults.standard.set(currentLevel, forKey: "current_level")
        UserDefaults.standard.set(currentXP, forKey: "current_xp")
        UserDefaults.standard.set(totalXPEarned, forKey: "total_xp_earned")
    }
    
    func load() {
        currentLevel = max(1, UserDefaults.standard.integer(forKey: "current_level"))
        currentXP = UserDefaults.standard.integer(forKey: "current_xp")
        totalXPEarned = UserDefaults.standard.integer(forKey: "total_xp_earned")
    }
}
