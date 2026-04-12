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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct FocusTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusTimerEntry {
        FocusTimerEntry(date: Date(), sessionsToday: 4, streakDays: 7, focusScore: 85)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusTimerEntry) -> Void) {
        let entry = FocusTimerEntry(date: Date(), sessionsToday: 4, streakDays: 7, focusScore: 85)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusTimerEntry>) -> Void) {
        let entry = FocusTimerEntry(date: Date(), sessionsToday: 4, streakDays: 7, focusScore: 85)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct FocusTimerEntry: TimelineEntry {
    let date: Date
    let sessionsToday: Int
    let streakDays: Int
    let focusScore: Int
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
        default:
            smallWidget
        }
    }
    
    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.red)
                Text("FocusTimer")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Text("\(entry.sessionsToday)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("sessions today")
                .font(.caption2)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                Text("\(entry.streakDays) day streak")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }
    
    var mediumWidget: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.red)
                    Text("FocusTimer")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("\(entry.sessionsToday)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("sessions today")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Divider()
                .background(Color.gray)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.streakDays) days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(entry.focusScore)%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("2h 15m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(.black, for: .widget)
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
            // Lock screen / banner UI
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
