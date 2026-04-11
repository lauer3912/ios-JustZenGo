//
//  LiveActivityBridge.swift
//  FocusTimer
//

import ActivityKit
import SwiftUI

// MARK: - Focus Activity Attributes

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isWorkPhase: Bool
        var timeRemaining: Int
        var sessionName: String
        var totalSessions: Int
        var completedSessions: Int
    }
    
    var startTime: Date
    var modeName: String
}

// MARK: - Live Activity Manager

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<FocusActivityAttributes>?
    
    var isActivityActive: Bool {
        currentActivity != nil
    }
    
    func startActivity(modeName: String, totalSessions: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = FocusActivityAttributes(
            startTime: Date(),
            modeName: modeName
        )
        
        let initialState = FocusActivityAttributes.ContentState(
            isWorkPhase: true,
            timeRemaining: 25 * 60,
            sessionName: "Focus Session",
            totalSessions: totalSessions,
            completedSessions: 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func updateActivity(
        isWorkPhase: Bool,
        timeRemaining: Int,
        sessionName: String,
        completedSessions: Int,
        totalSessions: Int
    ) {
        guard let activity = currentActivity else { return }
        
        let updatedState = FocusActivityAttributes.ContentState(
            isWorkPhase: isWorkPhase,
            timeRemaining: timeRemaining,
            sessionName: sessionName,
            totalSessions: totalSessions,
            completedSessions: completedSessions
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = FocusActivityAttributes.ContentState(
            isWorkPhase: false,
            timeRemaining: 0,
            sessionName: "Completed!",
            totalSessions: 0,
            completedSessions: 0
        )
        
        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        
        currentActivity = nil
    }
}

// MARK: - Live Activity Views

struct FocusLiveActivityView: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Timer circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(context.state.timeRemaining) / (25 * 60))
                    .stroke(
                        context.state.isWorkPhase ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: context.state.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 16))
                    .foregroundColor(context.state.isWorkPhase ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.isWorkPhase ? "Focus Time" : "Break")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(timeString)
                    .font(.system(.title3, design: .monospaced).bold())
                
                Text(context.state.sessionName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Session progress
            VStack(spacing: 2) {
                Text("\(context.state.completedSessions)/\(context.state.totalSessions)")
                    .font(.caption.bold())
                
                Text("sessions")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var timeString: String {
        let minutes = context.state.timeRemaining / 60
        let seconds = context.state.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Dynamic Island Views

struct FocusDynamicIslandExpandedView: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: context.state.isWorkPhase ? "brain.head.profile.fill" : "cup.and.saucer.fill")
                    .foregroundColor(context.state.isWorkPhase ? .red : .green)
                
                Text(context.state.isWorkPhase ? "Focus Mode" : "Break Time")
                    .font(.headline)
                
                Spacer()
                
                Text(timeString)
                    .font(.system(.title, design: .monospaced).bold())
            }
            
            ProgressView(value: Double(25 * 60 - context.state.timeRemaining) / Double(25 * 60))
                .tint(context.state.isWorkPhase ? .red : .green)
            
            HStack {
                Label(context.state.sessionName, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("\(context.state.completedSessions)/\(context.state.totalSessions)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    
    private var timeString: String {
        let minutes = context.state.timeRemaining / 60
        let seconds = context.state.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct FocusDynamicIslandCompactView: View {
    let context: ActivityViewContext<FocusActivityAttributes>
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: context.state.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                .foregroundColor(context.state.isWorkPhase ? .red : .green)
            
            Text(timeString)
                .font(.system(.caption, design: .monospaced).bold())
        }
    }
    
    private var timeString: String {
        let minutes = context.state.timeRemaining / 60
        let seconds = context.state.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
