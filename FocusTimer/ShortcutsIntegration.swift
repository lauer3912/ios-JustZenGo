//
//  ShortcutsIntegration.swift
//  FocusTimer
//

import Foundation
import Combine
import AppIntents

// MARK: - Focus Shortcuts

@available(iOS 16.0, *)
struct StartFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Start a new focus session with FocusTimer")
    
    @Parameter(title: "Mode")
    var mode: String?
    
    @Parameter(title: "Duration (minutes)")
    var duration: Int?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start \(\.$mode) focus for \(\.$duration) minutes")
    }
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            // Start focus session with specified parameters
            NotificationCenter.default.post(
                name: .startFocusSession,
                object: nil,
                userInfo: [
                    "mode": mode ?? "deepWork",
                    "duration": duration ?? 25
                ]
            )
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct StopFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Focus Session"
    static var description = IntentDescription("Stop the current focus session")
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .stopFocusSession, object: nil)
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct GetFocusStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Focus Statistics"
    static var description = IntentDescription("Get today's focus statistics")
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let stats = FocusDataManager.shared.statistics
        let response = "Today: \(stats.todaySessions) sessions, \(stats.todayMinutes) minutes. Streak: \(stats.currentStreak) days."
        return .result(value: response)
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct FocusTimerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFocusSessionIntent(),
            phrases: [
                "Start focus session in \(.applicationName)",
                "Start focusing with \(.applicationName)",
                "Begin pomodoro in \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "brain.head.profile"
        )
        
        AppShortcut(
            intent: StopFocusSessionIntent(),
            phrases: [
                "Stop focus session in \(.applicationName)",
                "Stop focusing with \(.applicationName)"
            ],
            shortTitle: "Stop Focus",
            systemImageName: "stop.fill"
        )
        
        AppShortcut(
            intent: GetFocusStatsIntent(),
            phrases: [
                "How did I focus today in \(.applicationName)",
                "Show my focus stats in \(.applicationName)"
            ],
            shortTitle: "Focus Stats",
            systemImageName: "chart.bar.fill"
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let startFocusSession = Notification.Name("startFocusSession")
    static let stopFocusSession = Notification.Name("stopFocusSession")
}

// MARK: - URL Scheme Handler

class URLSchemeHandler {
    static let scheme = "focustimer"
    
    static func handle(url: URL) -> Bool {
        guard url.scheme == scheme else { return false }
        
        guard let host = url.host else { return false }
        
        switch host {
        case "start":
            // focustimer://start?mode=deepWork&duration=25
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let mode = components?.queryItems?.first(where: { $0.name == "mode" })?.value ?? "deepWork"
            let duration = Int(components?.queryItems?.first(where: { $0.name == "duration" })?.value ?? "25") ?? 25
            
            NotificationCenter.default.post(
                name: .startFocusSession,
                object: nil,
                userInfo: ["mode": mode, "duration": duration]
            )
            return true
            
        case "stop":
            NotificationCenter.default.post(name: .stopFocusSession, object: nil)
            return true
            
        case "stats":
            // Could open stats view
            return true
            
        default:
            return false
        }
    }
    
    static var launchURL: URL? {
        URL(string: "\(scheme)://start")
    }
}
