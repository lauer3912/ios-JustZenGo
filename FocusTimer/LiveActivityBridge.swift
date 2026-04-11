//
//  LiveActivityBridge.swift
//  FocusTimer
//

import ActivityKit
import SwiftUI
import Combine

// MARK: - Focus Activity Attributes

struct FocusActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isWorkPhase: Bool
        var timeRemaining: Int
        var sessionName: String
        var totalSessions: Int
        var completedSessions: Int
        var totalDuration: Int // Total session duration in seconds
    }
    
    var startTime: Date
    var modeName: String
}

// MARK: - Live Activity Manager

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<FocusActivityAttributes>?
    @Published var isActivitySupported: Bool = false
    private var currentTotalDuration: Int = 25 * 60
    
    private var updateTimer: Timer?
    
    init() {
        isActivitySupported = ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    var isActivityActive: Bool {
        currentActivity != nil
    }
    
    func startActivity(modeName: String, totalSessions: Int, initialTime: Int = 25 * 60, totalDuration: Int = 25 * 60) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }
        
        // End any existing activity first
        endActivity()
        
        let attributes = FocusActivityAttributes(
            startTime: Date(),
            modeName: modeName
        )
        
        let initialState = FocusActivityAttributes.ContentState(
            isWorkPhase: true,
            timeRemaining: initialTime,
            sessionName: "Focus Session",
            totalSessions: totalSessions,
            completedSessions: 0,
            totalDuration: totalDuration
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            isActivitySupported = true
            currentTotalDuration = totalDuration
        } catch {
            print("Failed to start Live Activity: \(error)")
            isActivitySupported = false
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
            completedSessions: completedSessions,
            totalDuration: currentTotalDuration
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
            completedSessions: 0,
            totalDuration: currentTotalDuration
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

// MARK: - Live Activity View (for Lock Screen)

struct FocusLiveActivityView: View {
    let state: FocusActivityAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 16) {
            // Timer circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(state.timeRemaining) / max(CGFloat(state.totalDuration), 1))
                    .stroke(
                        state.isWorkPhase ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: state.isWorkPhase ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(size: 16))
                    .foregroundColor(state.isWorkPhase ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(state.isWorkPhase ? "Focus Time" : "Break")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(timeString)
                    .font(.system(.title3, design: .monospaced).bold())
                
                Text(state.sessionName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Session progress
            VStack(spacing: 2) {
                Text("\(state.completedSessions)/\(state.totalSessions)")
                    .font(.caption.bold())
                
                Text("sessions")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var timeString: String {
        let minutes = state.timeRemaining / 60
        let seconds = state.timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
