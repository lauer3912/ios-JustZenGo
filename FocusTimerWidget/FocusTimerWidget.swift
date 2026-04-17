//
//  FocusTimerWidget.swift
//  FocusTimerWidget
//

import WidgetKit
import SwiftUI

@main
struct FocusTimerWidgetBundle: WidgetBundle {
    var body: some Widget {
        FocusTimerWidget()
        FocusTimerLiveActivity()
    }
}

// MARK: - Widget

struct FocusTimerWidget: Widget {
    let kind: String = "FocusTimerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusTimerProvider()) { entry in
            FocusTimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Timer")
        .description("Track your focus sessions at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - App Group Suite Name

let widgetAppGroupSuiteName = "group.com.ggsheng.FocusTimer"

// MARK: - Timeline Provider

struct FocusTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusTimerEntry {
        FocusTimerEntry(
            date: Date(),
            focusData: WidgetFocusData.defaultData,
            timerState: WidgetTimerState.defaultState
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusTimerEntry) -> Void) {
        let focusData = getWidgetFocusData()
        let timerState = getWidgetTimerState()
        let entry = FocusTimerEntry(date: Date(), focusData: focusData, timerState: timerState)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusTimerEntry>) -> Void) {
        let focusData = getWidgetFocusData()
        let timerState = getWidgetTimerState()
        
        let entry = FocusTimerEntry(date: Date(), focusData: focusData, timerState: timerState)
        
        // Update every minute if timer is running, otherwise every 15 minutes
        let interval: TimeInterval = timerState.isRunning ? 60 : 900
        let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(interval), to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Direct UserDefaults Access

private func getWidgetFocusData() -> WidgetFocusData {
    guard let userDefaults = UserDefaults(suiteName: widgetAppGroupSuiteName),
          let data = userDefaults.dictionary(forKey: "widget_focus_data") else {
        return WidgetFocusData.defaultData
    }
    
    return WidgetFocusData(
        sessionsToday: data["widget_sessions_today"] as? Int ?? 0,
        streakDays: data["widget_streak_days"] as? Int ?? 0,
        focusScore: data["widget_focus_score"] as? Int ?? 0,
        todayFocusMinutes: data["widget_today_focus_minutes"] as? Int ?? 0,
        currentStreak: data["widget_current_streak"] as? Int ?? 0,
        longestStreak: data["widget_longest_streak"] as? Int ?? 0,
        level: data["widget_level"] as? Int ?? 1,
        coins: data["widget_coins"] as? Int ?? 0,
        achievementsUnlocked: data["widget_achievements_unlocked"] as? Int ?? 0,
        totalAchievements: data["widget_total_achievements"] as? Int ?? 0
    )
}

private func getWidgetTimerState() -> WidgetTimerState {
    guard let userDefaults = UserDefaults(suiteName: widgetAppGroupSuiteName),
          let data = userDefaults.dictionary(forKey: "widget_timer_state") else {
        return WidgetTimerState.defaultState
    }
    
    return WidgetTimerState(
        isRunning: data["widget_is_timer_running"] as? Bool ?? false,
        modeName: data["widget_current_mode_name"] as? String ?? "Focus",
        timeRemaining: data["widget_time_remaining"] as? Int ?? 0,
        totalDuration: data["widget_total_duration"] as? Int ?? 0,
        projectName: data["widget_project_name"] as? String ?? "General",
        sessionsCompleted: data["widget_sessions_completed"] as? Int ?? 0
    )
}

// MARK: - Entry

struct FocusTimerEntry: TimelineEntry {
    let date: Date
    let focusData: WidgetFocusData
    let timerState: WidgetTimerState
}

// MARK: - Data Models

struct WidgetFocusData {
    let sessionsToday: Int
    let streakDays: Int
    let focusScore: Int
    let todayFocusMinutes: Int
    let currentStreak: Int
    let longestStreak: Int
    let level: Int
    let coins: Int
    let achievementsUnlocked: Int
    let totalAchievements: Int
    
    var formattedFocusTime: String {
        let hours = todayFocusMinutes / 60
        let minutes = todayFocusMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    static let defaultData = WidgetFocusData(
        sessionsToday: 0,
        streakDays: 0,
        focusScore: 0,
        todayFocusMinutes: 0,
        currentStreak: 0,
        longestStreak: 0,
        level: 1,
        coins: 0,
        achievementsUnlocked: 0,
        totalAchievements: 0
    )
}

struct WidgetTimerState {
    let isRunning: Bool
    let modeName: String
    let timeRemaining: Int
    let totalDuration: Int
    let projectName: String
    let sessionsCompleted: Int
    
    var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (Double(timeRemaining) / Double(totalDuration))
    }
    
    static let defaultState = WidgetTimerState(
        isRunning: false,
        modeName: "Focus",
        timeRemaining: 0,
        totalDuration: 0,
        projectName: "General",
        sessionsCompleted: 0
    )
}

// MARK: - Widget View

struct FocusTimerWidgetEntryView: View {
    var entry: FocusTimerEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryRectangular:
            rectangularWidget
        case .accessoryInline:
            inlineWidget
        default:
            smallWidget
        }
    }
    
    // MARK: - Small Widget
    
    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.red)
                    .font(.caption)
                Text("FocusTimer")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if entry.timerState.isRunning {
                Text(entry.timerState.formattedTime)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text(entry.timerState.modeName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("\(entry.focusData.sessionsToday)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("sessions today")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if entry.timerState.isRunning {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("In Progress")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("\(entry.focusData.streakDays) day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // MARK: - Medium Widget
    
    var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("FocusTimer")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if entry.timerState.isRunning {
                    Text(entry.timerState.formattedTime)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Text(entry.timerState.modeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.timerState.projectName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(entry.focusData.sessionsToday)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("sessions today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(entry.focusData.formattedFocusTime + " focused")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                StatRow(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "\(entry.focusData.streakDays) days",
                    subtitle: "streak"
                )
                
                StatRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "\(entry.focusData.focusScore)%",
                    subtitle: "focus score"
                )
                
                StatRow(
                    icon: "clock.fill",
                    iconColor: .blue,
                    title: entry.focusData.formattedFocusTime,
                    subtitle: "today"
                )
                
                StatRow(
                    icon: "trophy.fill",
                    iconColor: .purple,
                    title: "\(entry.focusData.achievementsUnlocked)/\(entry.focusData.totalAchievements)",
                    subtitle: "achievements"
                )
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // MARK: - Circular Widget (Lock Screen)
    
    var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                if entry.timerState.isRunning {
                    Text(entry.timerState.formattedTime)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                    Image(systemName: "timer")
                        .font(.caption2)
                } else {
                    Text("\(entry.focusData.sessionsToday)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("sessions")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Rectangular Widget (Lock Screen)
    
    var rectangularWidget: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text("FocusTimer")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                
                if entry.timerState.isRunning {
                    Text(entry.timerState.formattedTime)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                    Text(entry.timerState.modeName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else {
                    Text("\(entry.focusData.sessionsToday) sessions")
                        .font(.system(size: 14, weight: .semibold))
                    Text(entry.focusData.formattedFocusTime + " today")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if entry.focusData.streakDays > 0 {
                VStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.focusData.streakDays)")
                        .font(.system(size: 10, weight: .bold))
                }
            }
        }
    }
    
    // MARK: - Inline Widget
    
    var inlineWidget: some View {
        if entry.timerState.isRunning {
            Text("⏱ \(entry.timerState.formattedTime) - \(entry.timerState.modeName)")
        } else {
            Text("⏱ \(entry.focusData.sessionsToday) sessions • \(entry.focusData.formattedFocusTime) focused")
        }
    }
}

// MARK: - Helper Views

struct StatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(iconColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Live Activity

struct FocusTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timerMode: String
        var timeRemaining: Int
        var totalDuration: Int
        var isRunning: Bool
        var sessionsCompleted: Int
    }
    
    var projectName: String
}

struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerAttributes.self) { context in
            HStack {
                VStack(alignment: .leading) {
                    Text(context.attributes.projectName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(context.state.timerMode)
                        .font(.headline)
                    Text("\(context.state.timeRemaining / 60):\(String(format: "%02d", context.state.timeRemaining % 60))")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                }
                Spacer()
                Image(systemName: context.state.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
            }
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.timerMode)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.timeRemaining / 60):\(String(format: "%02d", context.state.timeRemaining % 60))")
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.timeRemaining) / Double(context.state.totalDuration))
                        .tint(.red)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                Text("\(context.state.timeRemaining / 60)m")
                    .font(.caption)
            }
        }
    }
}
