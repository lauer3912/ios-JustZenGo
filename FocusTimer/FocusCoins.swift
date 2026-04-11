//
//  FocusCoins.swift
//  FocusTimer
//

import Foundation
import Combine
import SwiftUI

// MARK: - Focus Coin Item

struct FocusCoinItem: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let category: ItemCategory
    let icon: String
    let isPremium: Bool = false
    
    enum ItemCategory: String, Codable {
        case theme = "theme"
        case sound = "sound"
        case accessory = "accessory"
        case badge = "badge"
        case powerup = "powerup"
    }
}

// MARK: - User Inventory Item

struct UserInventoryItem: Codable, Identifiable {
    let id: String
    let itemId: String
    var isEquipped: Bool = false
    let purchasedDate: Date
}

// MARK: - Focus Coin Manager

class FocusCoinManager: ObservableObject {
    static let shared = FocusCoinManager()
    
    @Published var coins: Int = 0
    @Published var totalEarned: Int = 0
    @Published var totalSpent: Int = 0
    @Published var inventory: [UserInventoryItem] = []
    @Published var equippedTheme: String = "default"
    
    let shopItems: [FocusCoinItem] = [
        // Themes
        FocusCoinItem(id: "theme_ocean", name: "Ocean Blue", description: "Calm ocean waves theme", price: 100, category: .theme, icon: "drop.fill"),
        FocusCoinItem(id: "theme_forest", name: "Forest Green", description: "Peaceful forest theme", price: 100, category: .theme, icon: "leaf.fill"),
        FocusCoinItem(id: "theme_sunset", name: "Sunset Glow", description: "Warm sunset gradient", price: 150, category: .theme, icon: "sun.horizon.fill"),
        FocusCoinItem(id: "theme_aurora", name: "Aurora", description: "Northern lights theme", price: 300, category: .theme, icon: "sparkles"),
        FocusCoinItem(id: "theme_midnight", name: "Midnight Purple", description: "Deep purple night theme", price: 200, category: .theme, icon: "moon.stars.fill"),
        FocusCoinItem(id: "theme_candy", name: "Candy Pop", description: "Playful candy colors", price: 200, category: .theme, icon: "lollipop.fill"),
        FocusCoinItem(id: "theme_metal", name: "Cyberpunk", description: "Futuristic neon theme", price: 400, category: .theme, icon: "bolt.fill"),
        FocusCoinItem(id: "theme_nature", name: "Zen Garden", description: "Minimalist zen theme", price: 250, category: .theme, icon: "leaf.circle.fill"),
        
        // Sounds
        FocusCoinItem(id: "sound_rain_heavy", name: "Heavy Rain", description: "Intense rainfall sounds", price: 50, category: .sound, icon: "cloud.rain.fill"),
        FocusCoinItem(id: "sound_thunder", name: "Thunderstorm", description: "Thunder with rain", price: 75, category: .sound, icon: "cloud.bolt.rain.fill"),
        FocusCoinItem(id: "sound_cafe", name: "Busy Cafe", description: "Lively coffee shop", price: 50, category: .sound, icon: "cup.and.saucer.fill"),
        FocusCoinItem(id: "sound_train", name: "Train Journey", description: "Rhythmic train on tracks", price: 50, category: .sound, icon: "tram.fill"),
        FocusCoinItem(id: "sound_piano", name: "Ambient Piano", description: "Soft piano melodies", price: 100, category: .sound, icon: "pianokeys"),
        
        // Accessories
        FocusCoinItem(id: "acc_plant", name: "Desktop Plant", description: "Cute growing plant", price: 200, category: .accessory, icon: "leaf.fill"),
        FocusCoinItem(id: "acc_clock", name: "Digital Clock", description: "Minimalist clock widget", price: 150, category: .accessory, icon: "clock.fill"),
        FocusCoinItem(id: "acc_quotes", name: "Motivational Quotes", description: "Daily quote display", price: 100, category: .accessory, icon: "quote.bubble.fill"),
        FocusCoinItem(id: "acc_candles", name: "Candle Ambiance", description: "Flickering candle effect", price: 175, category: .accessory, icon: "flame.fill"),
        
        // Power-ups
        FocusCoinItem(id: "power_xp_boost", name: "XP Boost (1hr)", description: "2x XP for 1 hour", price: 50, category: .powerup, icon: "arrow.up.circle.fill"),
        FocusCoinItem(id: "power_streak_shield", name: "Streak Shield", description: "Protect streak for 1 day", price: 100, category: .powerup, icon: "shield.fill"),
        FocusCoinItem(id: "power_time_extend", name: "Time Extend", description: "Add +5 min to session", price: 25, category: .powerup, icon: "clock.badge.plus"),
    ]
    
    func earnCoins(_ amount: Int, reason: String) {
        coins += amount
        totalEarned += amount
        save()
    }
    
    func spendCoins(_ amount: Int, for itemId: String) -> Bool {
        guard coins >= amount else { return false }
        
        coins -= amount
        totalSpent += amount
        
        let inventoryItem = UserInventoryItem(
            id: UUID().uuidString,
            itemId: itemId,
            purchasedDate: Date()
        )
        inventory.append(inventoryItem)
        
        save()
        return true
    }
    
    func isOwned(_ itemId: String) -> Bool {
        inventory.contains { $0.itemId == itemId }
    }
    
    func equipItem(_ itemId: String) {
        // First equip the item
        if let index = inventory.firstIndex(where: { $0.itemId == itemId }) {
            inventory[index].isEquipped = true
        }
        
        // Find the item details
        guard let item = shopItems.first(where: { $0.id == itemId }) else { return }
        
        // Unequip others in same category
        for i in 0..<inventory.count {
            if let otherItem = shopItems.first(where: { $0.id == inventory[i].itemId }),
               otherItem.category == item.category && inventory[i].itemId != itemId {
                inventory[i].isEquipped = false
            }
        }
        
        if item.category == .theme {
            equippedTheme = itemId
        }
        
        save()
    }
    
    func getCoinsForSession(sessionsCompleted: Int, challengeCompleted: Bool, streakBonus: Bool) -> Int {
        var earned = sessionsCompleted * 5 // 5 coins per session
        
        if challengeCompleted {
            earned += 10 // Bonus for completing daily challenge
        }
        
        if streakBonus {
            earned += earned / 2 // 50% streak bonus
        }
        
        return earned
    }
    
    private func save() {
        UserDefaults.standard.set(coins, forKey: "focus_coins")
        UserDefaults.standard.set(totalEarned, forKey: "coins_earned")
        UserDefaults.standard.set(totalSpent, forKey: "coins_spent")
        UserDefaults.standard.set(equippedTheme, forKey: "equipped_theme")
        if let encoded = try? JSONEncoder().encode(inventory) {
            UserDefaults.standard.set(encoded, forKey: "inventory")
        }
    }
    
    func load() {
        coins = UserDefaults.standard.integer(forKey: "focus_coins")
        totalEarned = UserDefaults.standard.integer(forKey: "coins_earned")
        totalSpent = UserDefaults.standard.integer(forKey: "coins_spent")
        equippedTheme = UserDefaults.standard.string(forKey: "equipped_theme") ?? "default"
        if let data = UserDefaults.standard.data(forKey: "inventory"),
           let decoded = try? JSONDecoder().decode([UserInventoryItem].self, from: data) {
            inventory = decoded
        }
    }
}
