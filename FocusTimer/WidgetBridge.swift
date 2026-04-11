//
//  WidgetBridge.swift
//  FocusTimer
//
//  This file provides shared data structures for WidgetKit.
//  Note: A proper Widget Extension target needs to be created in Xcode
//  for widgets to actually appear on the home screen.
//  The widget code below provides the data layer only.
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry

struct FocusWidgetEntry: TimelineEntry {
    let date: Date
    let todaySessions: Int
    let dailyGoal: Int
    let currentStreak: Int
    let totalMinutesToday: Int
    let isFocusing: Bool
    let timeRemaining: Int?
    let currentModeName: String
}

// MARK: - Widget Provider

struct FocusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusWidgetEntry {
        FocusWidgetEntry(
            date: Date(),
            todaySessions: 3,
            dailyGoal: 8,
            currentStreak: 7,
            totalMinutesToday: 75,
            isFocusing: false,
            timeRemaining: nil,
            currentModeName: "Deep Work"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
        let entry = getEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
        let entry = getEntry()
        
        // Update every minute when focusing, every 15 minutes otherwise
        let interval = entry.isFocusing ? 60.0 : 900.0
        let nextUpdate = Date().addingTimeInterval(interval)
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getEntry() -> FocusWidgetEntry {
        let stats = FocusDataManager.shared.statistics
        let settings = FocusDataManager.shared.settings
        let timerState = TimerManager.shared
        
        return FocusWidgetEntry(
            date: Date(),
            todaySessions: stats.todaySessions,
            dailyGoal: settings.dailyGoal,
            currentStreak: stats.currentStreak,
            totalMinutesToday: stats.todayMinutes,
            isFocusing: false,
            timeRemaining: nil,
            currentModeName: FocusModeManager.shared.currentMode.displayName
        )
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    var entry: FocusWidgetEntry
    
    var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(Double(entry.todaySessions) / Double(entry.dailyGoal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.pink)
                Text("Focus")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Spacer()
                
                if entry.isFocusing {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            
            Spacer()
            
            if entry.isFocusing, let remaining = entry.timeRemaining {
                VStack(spacing: 4) {
                    Text(formatTime(remaining))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.pink)
                    
                    Text(entry.currentModeName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("\(entry.todaySessions)/\(entry.dailyGoal)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                ProgressView(value: progress)
                    .tint(.pink)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(entry.currentStreak) day streak")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct MediumWidgetView: View {
    var entry: FocusWidgetEntry
    
    var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(Double(entry.todaySessions) / Double(entry.dailyGoal), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(entry.todaySessions)")
                        .font(.system(size: 24, weight: .bold))
                    Text("/\(entry.dailyGoal)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.pink)
                    Text("Today's Focus")
                        .font(.headline)
                }
                
                HStack(spacing: 16) {
                    WidgetStatBox(value: "\(entry.currentStreak)", label: "Streak", icon: "flame.fill", color: .orange)
                    WidgetStatBox(value: "\(entry.totalMinutesToday)", label: "Minutes", icon: "clock.fill", color: .blue)
                    WidgetStatBox(value: "\(entry.todaySessions)", label: "Sessions", icon: "checkmark.circle.fill", color: .green)
                }
                
                if entry.isFocusing {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Focusing: \(entry.currentModeName)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    var entry: FocusWidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.pink)
                Text("FocusTimer")
                    .font(.headline)
                Spacer()
                
                if entry.isFocusing {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Main stats
            HStack(spacing: 20) {
                WidgetStatBox(value: "\(entry.todaySessions)", label: "Sessions", icon: "checkmark.circle.fill", color: .green)
                WidgetStatBox(value: "\(entry.totalMinutesToday)", label: "Minutes", icon: "clock.fill", color: .blue)
                WidgetStatBox(value: "\(entry.currentStreak)", label: "Streak", icon: "flame.fill", color: .orange)
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Daily Goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(entry.todaySessions)/\(entry.dailyGoal)")
                        .font(.caption.bold())
                }
                
                ProgressView(value: Double(entry.todaySessions), total: Double(entry.dailyGoal))
                    .tint(.pink)
            }
            
            // Current mode if focusing
            if entry.isFocusing, let remaining = entry.timeRemaining {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.pink)
                    Text(entry.currentModeName)
                        .font(.subheadline)
                    Spacer()
                    Text(formatTime(remaining))
                        .font(.system(.title3, design: .monospaced).bold())
                        .foregroundColor(.pink)
                }
                .padding(12)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct WidgetStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lock Screen Widget

struct LockScreenRectangularView: View {
    var entry: FocusWidgetEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: entry.isFocusing ? "brain.head.profile.fill" : "brain.head.profile")
                .foregroundColor(entry.isFocusing ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                if entry.isFocusing, let remaining = entry.timeRemaining {
                    Text("\(remaining / 60):\(String(format: "%02d", remaining % 60))")
                        .font(.system(.body, design: .monospaced).bold())
                } else {
                    Text("\(entry.todaySessions)/\(entry.dailyGoal) sessions")
                        .font(.body)
                }
                
                if entry.currentStreak > 0 {
                    Text("\(entry.currentStreak) day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if entry.isFocusing {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct LockScreenCircularView: View {
    var entry: FocusWidgetEntry
    
    var progress: Double {
        guard entry.dailyGoal > 0 else { return 0 }
        return min(Double(entry.todaySessions) / Double(entry.dailyGoal), 1.0)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.pink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            if entry.isFocusing, let remaining = entry.timeRemaining {
                VStack(spacing: 0) {
                    Text("\(remaining / 60)")
                        .font(.system(.title3, design: .monospaced).bold())
                    Text("min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    Text("\(entry.todaySessions)")
                        .font(.system(.title3, design: .monospaced).bold())
                    Text("/\(entry.dailyGoal)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Widget Configuration

struct FocusTimerWidget: Widget {
    let kind: String = "FocusTimerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            FocusTimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FocusTimer")
        .description("Track your daily focus progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FocusTimerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: FocusWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Accessor for WidgetKit (used by Widget Extension target)

class WidgetDataAccessor {
    static let shared = WidgetDataAccessor()
    
    func getCurrentEntry() -> FocusWidgetEntry {
        return FocusWidgetEntry(
            date: Date(),
            todaySessions: FocusDataManager.shared.statistics.todaySessions,
            dailyGoal: FocusDataManager.shared.settings.dailyGoal,
            currentStreak: FocusDataManager.shared.statistics.currentStreak,
            totalMinutesToday: FocusDataManager.shared.statistics.todayMinutes,
            isFocusing: false,
            timeRemaining: nil,
            currentModeName: FocusModeManager.shared.currentMode.displayName
        )
    }
}
