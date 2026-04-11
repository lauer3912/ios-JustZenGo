//
//  WidgetKit Support
//  FocusTimer
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct FocusWidgetEntry: TimelineEntry {
    let date: Date
    let todaySessions: Int
    let dailyGoal: Int
    let currentStreak: Int
    let isFocusing: Bool
    let timeRemaining: Int?
}

// MARK: - Widget Provider

struct FocusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusWidgetEntry {
        FocusWidgetEntry(
            date: Date(),
            todaySessions: 3,
            dailyGoal: 8,
            currentStreak: 7,
            isFocusing: false,
            timeRemaining: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> Void) {
        let entry = FocusWidgetEntry(
            date: Date(),
            todaySessions: FocusDataManager.shared.statistics.todaySessions,
            dailyGoal: FocusDataManager.shared.settings.dailyGoal,
            currentStreak: FocusDataManager.shared.statistics.currentStreak,
            isFocusing: false,
            timeRemaining: nil
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> Void) {
        let currentDate = Date()
        let entry = FocusWidgetEntry(
            date: currentDate,
            todaySessions: FocusDataManager.shared.statistics.todaySessions,
            dailyGoal: FocusDataManager.shared.settings.dailyGoal,
            currentStreak: FocusDataManager.shared.statistics.currentStreak,
            isFocusing: false,
            timeRemaining: nil
        )
        
        // Update every minute
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Views

struct SmallWidgetView: View {
    var entry: FocusWidgetEntry
    
    var progress: Double {
        Double(entry.todaySessions) / Double(entry.dailyGoal)
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
            }
            
            Text("\(entry.todaySessions)/\(entry.dailyGoal)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            ProgressView(value: progress)
                .tint(.pink)
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(entry.currentStreak)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    var entry: FocusWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: Double(entry.todaySessions) / Double(entry.dailyGoal))
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
                Text("Today's Focus")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    WidgetStat(icon: "flame.fill", value: "\(entry.currentStreak)", label: "Streak", color: .orange)
                    WidgetStat(icon: "clock.fill", value: "\(entry.todaySessions * 25)", label: "Minutes", color: .blue)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct WidgetStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.bold())
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen Widget

struct LockScreenWidgetView: View {
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
            }
            
            Spacer()
            
            if entry.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.currentStreak)")
                        .font(.caption.bold())
                }
            }
        }
    }
}

// MARK: - Widget Bundle

@main
struct FocusTimerWidgets: WidgetBundle {
    var body: some Widget {
        FocusTimerWidget()
        if #available(iOSApplicationExtension 16.0, *) {
            FocusTimerLockScreenWidget()
        }
    }
}

struct FocusTimerWidget: Widget {
    let kind: String = "FocusTimerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            FocusTimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FocusTimer")
        .description("Track your daily focus progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct FocusTimerLockScreenWidget: Widget {
    let kind: String = "FocusTimerLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("FocusTimer")
        .description("See your focus at a glance.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
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
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
