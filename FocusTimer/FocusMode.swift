//
//  FocusMode.swift
//  FocusTimer
//

import Foundation

// MARK: - Focus Mode

enum FocusModeType: String, CaseIterable, Codable, Identifiable {
    case deepWork = "deep_work"
    case creativeFlow = "creative_flow"
    case easyDay = "easy_day"
    case miniSprint = "mini_sprint"
    case marathon = "marathon"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .deepWork: return "Deep Work"
        case .creativeFlow: return "Creative Flow"
        case .easyDay: return "Easy Day"
        case .miniSprint: return "Mini Sprint"
        case .marathon: return "Marathon"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .creativeFlow: return "paintbrush.fill"
        case .easyDay: return "sun.max.fill"
        case .miniSprint: return "hare.fill"
        case .marathon: return "figure.run"
        case .custom: return "slider.horizontal.3"
        }
    }
    
    var description: String {
        switch self {
        case .deepWork: return "50 min focus, 10 min break — for complex tasks"
        case .creativeFlow: return "90 min focus, 20 min break — enter the zone"
        case .easyDay: return "15 min focus, 3 min break — low pressure sessions"
        case .miniSprint: return "15 min focus, 5 min break — quick wins"
        case .marathon: return "3 hour focus, 15 min break — extreme deep work"
        case .custom: return "Your custom ratio"
        }
    }
    
    var workDuration: Int {
        switch self {
        case .deepWork: return 50 * 60
        case .creativeFlow: return 90 * 60
        case .easyDay: return 15 * 60
        case .miniSprint: return 15 * 60
        case .marathon: return 180 * 60
        case .custom: return 25 * 60
        }
    }
    
    var shortBreakDuration: Int {
        switch self {
        case .deepWork: return 10 * 60
        case .creativeFlow: return 20 * 60
        case .easyDay: return 3 * 60
        case .miniSprint: return 5 * 60
        case .marathon: return 15 * 60
        case .custom: return 5 * 60
        }
    }
    
    var longBreakDuration: Int {
        switch self {
        case .deepWork: return 20 * 60
        case .creativeFlow: return 30 * 60
        case .easyDay: return 10 * 60
        case .miniSprint: return 15 * 60
        case .marathon: return 30 * 60
        case .custom: return 15 * 60
        }
    }
    
    var sessionsUntilLongBreak: Int {
        switch self {
        case .deepWork: return 4
        case .creativeFlow: return 3
        case .easyDay: return 4
        case .miniSprint: return 3
        case .marathon: return 2
        case .custom: return 4
        }
    }
    
    var accentColor: String {
        switch self {
        case .deepWork: return "FF6B6B"
        case .creativeFlow: return "AF52DE"
        case .easyDay: return "4ECB71"
        case .miniSprint: return "5AC8FA"
        case .marathon: return "FF9500"
        case .custom: return "FFD60A"
        }
    }
}

// MARK: - Focus Mode Manager

class FocusModeManager: ObservableObject {
    static let shared = FocusModeManager()
    
    @Published var currentMode: FocusModeType = .deepWork
    @Published var customModeSettings: CustomModeSettings = .default
    
    struct CustomModeSettings: Codable {
        var workDuration: Int = 25 * 60
        var breakDuration: Int = 5 * 60
        var longBreakDuration: Int = 15 * 60
        var sessionsUntilLongBreak: Int = 4
        var name: String = "My Mode"
        
        static var `default`: CustomModeSettings { CustomModeSettings() }
    }
    
    func getCurrentModeSettings() -> (work: Int, shortBreak: Int, longBreak: Int, sessions: Int) {
        if currentMode == .custom {
            return (
                work: customModeSettings.workDuration,
                shortBreak: customModeSettings.breakDuration,
                longBreak: customModeSettings.longBreakDuration,
                sessions: customModeSettings.sessionsUntilLongBreak
            )
        }
        return (
            work: currentMode.workDuration,
            shortBreak: currentMode.shortBreakDuration,
            longBreak: currentMode.longBreakDuration,
            sessions: currentMode.sessionsUntilLongBreak
        )
    }
    
    func applyMode(_ mode: FocusModeType) {
        currentMode = mode
        save()
    }
    
    func saveCustomSettings(_ settings: CustomModeSettings) {
        customModeSettings = settings
        currentMode = .custom
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(currentMode) {
            UserDefaults.standard.set(encoded, forKey: "focus_mode")
        }
        if let encoded = try? JSONEncoder().encode(customModeSettings) {
            UserDefaults.standard.set(encoded, forKey: "custom_mode_settings")
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "focus_mode"),
           let mode = try? JSONDecoder().decode(FocusModeType.self, from: data) {
            currentMode = mode
        }
        if let data = UserDefaults.standard.data(forKey: "custom_mode_settings"),
           let settings = try? JSONDecoder().decode(CustomModeSettings.self, from: data) {
            customModeSettings = settings
        }
    }
}
