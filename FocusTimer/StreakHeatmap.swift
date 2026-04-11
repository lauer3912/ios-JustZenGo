//
//  StreakHeatmap.swift
//  FocusTimer
//

import SwiftUI

// MARK: - Streak Heatmap View

struct StreakHeatmapView: View {
    @StateObject private var dataManager = FocusDataManager.shared
    @State private var sessionsByDate: [Date: Int] = [:]
    
    private let calendar = Calendar.current
    private let columns = 53 // Weeks in a year
    private let rows = 7 // Days in a week
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Focus Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "8E8E93"))
                    
                    ForEach(0..<5) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(intensityColor(level: level))
                            .frame(width: cellSize, height: cellSize)
                    }
                    
                    Text("More")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
            
            // Heatmap grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: cellSpacing) {
                    // Day labels
                    VStack(spacing: cellSpacing) {
                        ForEach(["", "Mon", "", "Wed", "", "Fri", ""], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "8E8E93"))
                                .frame(width: 20, height: cellSize)
                        }
                    }
                    
                    // Weeks
                    ForEach(weeksInYear, id: \.self) { weekStart in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { dayOffset in
                                let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
                                let sessions = getSessions(for: date)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(colorForSessions(sessions))
                                    .frame(width: cellSize, height: cellSize)
                                    .overlay(
                                        Circle()
                                            .stroke(sessions > 0 ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            
            // Stats summary
            HStack(spacing: 24) {
                StatBox(title: "Current Streak", value: "\(dataManager.statistics.currentStreak)", color: .orange)
                StatBox(title: "Longest Streak", value: "\(dataManager.statistics.longestStreak)", color: Color(hex: "FFD60A"))
                StatBox(title: "Total Sessions", value: "\(dataManager.statistics.totalSessions)", color: Color(hex: "4ECB71"))
                StatBox(title: "This Week", value: "\(dataManager.statistics.weekSessions)", color: Color(hex: "5AC8FA"))
            }
        }
        .padding()
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
        .onAppear {
            loadSessionsByDate()
        }
    }
    
    private var weeksInYear: [Date] {
        var weeks: [Date] = []
        let today = Date()
        
        for weekOffset in stride(from: -52, to: 1, by: 1) {
            if let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], for: calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today)!)) {
                weeks.append(weekStart)
            }
        }
        return weeks.reversed()
    }
    
    private func loadSessionsByDate() {
        var grouped: [Date: Int] = [:]
        for session in dataManager.sessions where session.type == .work && session.completed {
            let startOfDay = calendar.startOfDay(for: session.startTime)
            grouped[startOfDay, default: 0] += 1
        }
        sessionsByDate = grouped
    }
    
    private func getSessions(for date: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: date)
        return sessionsByDate[startOfDay] ?? 0
    }
    
    private func colorForSessions(_ sessions: Int) -> Color {
        switch sessions {
        case 0: return Color(hex: "3A3A3C")
        case 1: return Color(hex: "0E4429")
        case 2...3: return Color(hex: "006D32")
        case 4...6: return Color(hex: "26A641")
        case 7...9: return Color(hex: "39D353")
        default: return Color(hex: "58D398")
        }
    }
    
    private func intensityColor(level: Int) -> Color {
        switch level {
        case 0: return Color(hex: "3A3A3C")
        case 1: return Color(hex: "0E4429")
        case 2: return Color(hex: "006D32")
        case 3: return Color(hex: "26A641")
        case 4: return Color(hex: "39D353")
        default: return Color(hex: "3A3A3C")
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8E8E93"))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Social Sharing Card

struct SocialSharingCard: View {
    let stats: FocusStatistics
    let level: Int
    let streak: Int
    let achievements: Int
    
    @State private var renderedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF9500")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    Text("FocusTimer")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("My Focus Report")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.vertical, 24)
            }
            .frame(height: 140)
            
            // Stats
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    ShareStatItem(value: "\(stats.totalHours)", label: "Hours Focused", icon: "clock.fill", color: .orange)
                    ShareStatItem(value: "\(stats.totalSessions)", label: "Sessions", icon: "checkmark.circle.fill", color: .green)
                }
                
                HStack(spacing: 24) {
                    ShareStatItem(value: "\(streak)", label: "Day Streak", icon: "flame.fill", color: .red)
                    ShareStatItem(value: "Lv.\(level)", label: "Current Level", icon: "star.fill", color: .yellow)
                    ShareStatItem(value: "\(achievements)", label: "Achievements", icon: "trophy.fill", color: .purple)
                }
            }
            .padding(20)
            .background(Color(hex: "1C1C1E"))
        }
        .frame(width: 320)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 20)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    var statsTotalHours: Int {
        stats.totalMinutes / 60
    }
}

struct ShareStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
