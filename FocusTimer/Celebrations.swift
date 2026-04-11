//
//  MilestoneCelebrations.swift
//  FocusTimer
//

import SwiftUI
import UIKit

// MARK: - Milestone Type

enum MilestoneType {
    case sessionCompleted
    case streakMilestone(Int)
    case levelUp(Int)
    case achievementUnlocked(String)
    case dailyGoal
    case weeklyGoal
    case totalHours(Int)
    case totalSessions(Int)
    case firstOfDay
    
    var title: String {
        switch self {
        case .sessionCompleted: return "Session Complete!"
        case .streakMilestone(let days): return "\(days) Day Streak!"
        case .levelUp(let level): return "Level Up! Lv.\(level)"
        case .achievementUnlocked(let name): return "Achievement: \(name)"
        case .dailyGoal: return "Daily Goal Achieved!"
        case .weeklyGoal: return "Weekly Goal Achieved!"
        case .totalHours(let hours): return "\(hours) Hours of Focus!"
        case .totalSessions(let sessions): return "\(sessions) Sessions!"
        case .firstOfDay: return "First Session Today!"
        }
    }
    
    var subtitle: String {
        switch self {
        case .sessionCompleted: return "Great work! Keep going."
        case .streakMilestone(let days): return "You're on fire!"
        case .levelUp(let level): return "Keep climbing!"
        case .achievementUnlocked: return "Badge unlocked"
        case .dailyGoal: return "You hit your target!"
        case .weeklyGoal: return "Amazing week!"
        case .totalHours: return "Total focus time"
        case .totalSessions: return "Lifetime sessions"
        case .firstOfDay: return "Nice start!"
        }
    }
    
    var icon: String {
        switch self {
        case .sessionCompleted: return "checkmark.circle.fill"
        case .streakMilestone: return "flame.fill"
        case .levelUp: return "arrow.up.circle.fill"
        case .achievementUnlocked: return "star.fill"
        case .dailyGoal: return "target"
        case .weeklyGoal: return "calendar"
        case .totalHours: return "clock.fill"
        case .totalSessions: return "number.circle.fill"
        case .firstOfDay: return "sun.max.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sessionCompleted: return Color(hex: "4ECB71")
        case .streakMilestone: return Color(hex: "FF9500")
        case .levelUp: return Color(hex: "AF52DE")
        case .achievementUnlocked: return Color(hex: "FFD60A")
        case .dailyGoal: return Color(hex: "4ECB71")
        case .weeklyGoal: return Color(hex: "5AC8FA")
        case .totalHours: return Color(hex: "FF9500")
        case .totalSessions: return Color(hex: "64D2FF")
        case .firstOfDay: return Color(hex: "FFD60A")
        }
    }
}

// MARK: - Celebration Manager

class CelebrationManager: ObservableObject {
    static let shared = CelebrationManager()
    
    @Published var showCelebration: Bool = false
    @Published var currentMilestone: MilestoneType?
    
    private var lastStreakMilestone: Int = 0
    private var lastLevelMilestone: Int = 0
    private var lastTotalHours: Int = 0
    private var lastTotalSessions: Int = 0
    private var todaySessionCount: Int = 0
    
    func triggerCelebration(_ milestone: MilestoneType) {
        currentMilestone = milestone
        showCelebration = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showCelebration = false
        }
    }
    
    func checkMilestones(stats: FocusStatistics, level: Int) {
        // Check streak milestones
        let streakMilestones = [3, 7, 14, 30, 60, 100, 365]
        for milestone in streakMilestones {
            if stats.currentStreak >= milestone && lastStreakMilestone < milestone {
                lastStreakMilestone = milestone
                triggerCelebration(.streakMilestone(milestone))
            }
        }
        
        // Check level milestones
        let levelMilestones = [5, 10, 25, 50, 100]
        for milestone in levelMilestones {
            if level >= milestone && lastLevelMilestone < milestone {
                lastLevelMilestone = milestone
                triggerCelebration(.levelUp(milestone))
            }
        }
        
        // Check total hours milestones
        let hourMilestones = [10, 50, 100, 500, 1000]
        let totalHours = stats.totalMinutes / 60
        for milestone in hourMilestones {
            if totalHours >= milestone && lastTotalHours < milestone {
                lastTotalHours = milestone
                triggerCelebration(.totalHours(milestone))
            }
        }
        
        // Check total sessions milestones
        let sessionMilestones = [10, 50, 100, 500, 1000, 5000]
        for milestone in sessionMilestones {
            if stats.totalSessions >= milestone && lastTotalSessions < milestone {
                lastTotalSessions = milestone
                triggerCelebration(.totalSessions(milestone))
            }
        }
    }
    
    func onDailyGoalAchieved() {
        triggerCelebration(.dailyGoal)
    }
    
    func onSessionCompleted() {
        todaySessionCount += 1
        if todaySessionCount == 1 {
            triggerCelebration(.firstOfDay)
        } else {
            triggerCelebration(.sessionCompleted)
        }
    }
    
    func resetDailyCount() {
        todaySessionCount = 0
    }
    
    func load() {
        lastStreakMilestone = UserDefaults.standard.integer(forKey: "last_streak_milestone")
        lastLevelMilestone = UserDefaults.standard.integer(forKey: "last_level_milestone")
        lastTotalHours = UserDefaults.standard.integer(forKey: "last_total_hours")
        lastTotalSessions = UserDefaults.standard.integer(forKey: "last_total_sessions")
    }
    
    func save() {
        UserDefaults.standard.set(lastStreakMilestone, forKey: "last_streak_milestone")
        UserDefaults.standard.set(lastLevelMilestone, forKey: "last_level_milestone")
        UserDefaults.standard.set(lastTotalHours, forKey: "last_total_hours")
        UserDefaults.standard.set(lastTotalSessions, forKey: "last_total_sessions")
    }
}

// MARK: - Celebration Overlay View

struct CelebrationOverlay: View {
    let milestone: MilestoneType
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 20) {
                Image(systemName: milestone.icon)
                    .font(.system(size: 64))
                    .foregroundColor(milestone.color)
                    .shadow(color: milestone.color.opacity(0.5), radius: 20)
                    .scaleEffect(isShowing ? 1 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isShowing)
                
                Text(milestone.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(milestone.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "2C2C2E"))
                    .shadow(color: milestone.color.opacity(0.3), radius: 30)
            )
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink]
        
        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: -20),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        for i in 0..<particles.count {
            withAnimation(.easeOut(duration: Double.random(in: 2...4))) {
                particles[i].position.y = UIScreen.main.bounds.height + 50
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}
