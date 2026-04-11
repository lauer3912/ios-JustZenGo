//
//  ThemeManager.swift
//  FocusTimer
//

import Foundation
import Combine
import SwiftUI

// MARK: - App Theme

struct AppTheme: Codable, Identifiable {
    let id: String
    let name: String
    let backgroundColor: String
    let cardColor: String
    let accentColor: String
    let textColor: String
    let secondaryTextColor: String
    let successColor: String
    let warningColor: String
    let errorColor: String
    let isDark: Bool
    
    static let `default` = AppTheme(
        id: "default",
        name: "Midnight",
        backgroundColor: "1C1C1E",
        cardColor: "2C2C2E",
        accentColor: "FF6B6B",
        textColor: "FFFFFF",
        secondaryTextColor: "8E8E93",
        successColor: "4ECB71",
        warningColor: "FFD60A",
        errorColor: "FF3B30",
        isDark: true
    )
}

// MARK: - Theme Presets

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .default
    @Published var ownedThemes: [String] = ["default"]
    
    let allThemes: [AppTheme] = [
        AppTheme(
            id: "default",
            name: "Midnight",
            backgroundColor: "1C1C1E",
            cardColor: "2C2C2E",
            accentColor: "FF6B6B",
            textColor: "FFFFFF",
            secondaryTextColor: "8E8E93",
            successColor: "4ECB71",
            warningColor: "FFD60A",
            errorColor: "FF3B30",
            isDark: true
        ),
        AppTheme(
            id: "ocean",
            name: "Ocean",
            backgroundColor: "0A1628",
            cardColor: "1A2F4A",
            accentColor: "5AC8FA",
            textColor: "FFFFFF",
            secondaryTextColor: "8E8E93",
            successColor: "4ECB71",
            warningColor: "FFD60A",
            errorColor: "FF6B6B",
            isDark: true
        ),
        AppTheme(
            id: "forest",
            name: "Forest",
            backgroundColor: "0D1F0D",
            cardColor: "1A3A1A",
            accentColor: "4ECB71",
            textColor: "FFFFFF",
            secondaryTextColor: "8E8E93",
            successColor: "7ED957",
            warningColor: "FFD60A",
            errorColor: "FF6B6B",
            isDark: true
        ),
        AppTheme(
            id: "sunset",
            name: "Sunset",
            backgroundColor: "1A0A14",
            cardColor: "2A1520",
            accentColor: "FF9500",
            textColor: "FFFFFF",
            secondaryTextColor: "8E8E93",
            successColor: "4ECB71",
            warningColor: "FFD60A",
            errorColor: "FF3B30",
            isDark: true
        ),
        AppTheme(
            id: "aurora",
            name: "Aurora",
            backgroundColor: "0F0F1A",
            cardColor: "1A1A2E",
            accentColor: "AF52DE",
            textColor: "FFFFFF",
            secondaryTextColor: "8E8E93",
            successColor: "4ECB71",
            warningColor: "FFD60A",
            errorColor: "FF6B6B",
            isDark: true
        ),
        AppTheme(
            id: "midnight_blue",
            name: "Midnight Blue",
            backgroundColor: "0D1B2A",
            cardColor: "1B263B",
            accentColor: "64D2FF",
            textColor: "FFFFFF",
            secondaryTextColor: "8E8E93",
            successColor: "4ECB71",
            warningColor: "FFD60A",
            errorColor: "FF6B6B",
            isDark: true
        ),
        AppTheme(
            id: "light",
            name: "Daylight",
            backgroundColor: "F2F2F7",
            cardColor: "FFFFFF",
            accentColor: "FF6B6B",
            textColor: "000000",
            secondaryTextColor: "6C6C70",
            successColor: "34C759",
            warningColor: "FF9500",
            errorColor: "FF3B30",
            isDark: false
        ),
        AppTheme(
            id: "nordic",
            name: "Nordic",
            backgroundColor: "1E1E2E",
            cardColor: "2E2E3E",
            accentColor: "88C0D0",
            textColor: "ECEFF4",
            secondaryTextColor: "8E8E93",
            successColor: "A3BE8C",
            warningColor: "EBCB8B",
            errorColor: "BF616A",
            isDark: true
        ),
        AppTheme(
            id: "neon",
            name: "Cyberpunk",
            backgroundColor: "0D0221",
            cardColor: "150734",
            accentColor: "FF00FF",
            textColor: "FFFFFF",
            secondaryTextColor: "00FFFF",
            successColor: "00FF00",
            warningColor: "FFFF00",
            errorColor: "FF0044",
            isDark: true
        ),
        AppTheme(
            id: "candy",
            name: "Candy",
            backgroundColor: "FFF0F5",
            cardColor: "FFFFFF",
            accentColor: "FF69B4",
            textColor: "4A4A4A",
            secondaryTextColor: "8E8E93",
            successColor: "98FB98",
            warningColor: "FFD700",
            errorColor: "FF6B6B",
            isDark: false
        )
    ]
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        save()
    }
    
    func unlockTheme(_ themeId: String) {
        if !ownedThemes.contains(themeId) {
            ownedThemes.append(themeId)
            save()
        }
    }
    
    func isOwned(_ themeId: String) -> Bool {
        ownedThemes.contains(themeId)
    }
    
    func getTheme(_ id: String) -> AppTheme? {
        allThemes.first { $0.id == id }
    }
    
    private func save() {
        UserDefaults.standard.set(currentTheme.id, forKey: "current_theme_id")
        UserDefaults.standard.set(ownedThemes, forKey: "owned_themes")
    }
    
    func load() {
        if let themeId = UserDefaults.standard.string(forKey: "current_theme_id"),
           let theme = allThemes.first(where: { $0.id == themeId }) {
            currentTheme = theme
        }
        if let owned = UserDefaults.standard.array(forKey: "owned_themes") as? [String] {
            ownedThemes = owned
        }
    }
}

// MARK: - Theme Colors Extension

extension AppTheme {
    var backgroundSwiftUIColor: Color { Color(hex: backgroundColor) }
    var cardSwiftUIColor: Color { Color(hex: cardColor) }
    var accentSwiftUIColor: Color { Color(hex: accentColor) }
    var textSwiftUIColor: Color { Color(hex: textColor) }
    var secondaryTextSwiftUIColor: Color { Color(hex: secondaryTextColor) }
    var successSwiftUIColor: Color { Color(hex: successColor) }
    var warningSwiftUIColor: Color { Color(hex: warningColor) }
    var errorSwiftUIColor: Color { Color(hex: errorColor) }
}
