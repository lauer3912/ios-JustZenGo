//
//  StatisticsView.swift
//  JustZen
//

import SwiftUI

struct StatisticsView: View {
    @StateObject private var dataManager = FocusDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Today's Progress
                        TodayProgressCard()
                        
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "This Week",
                                value: "\(dataManager.statistics.weekSessions)",
                                subtitle: "sessions",
                                icon: "calendar",
                                color: Color(hex: "4ECB71")
                            )
                            
                            StatCard(
                                title: "This Week",
                                value: "\(dataManager.statistics.weekMinutes)",
                                subtitle: "minutes",
                                icon: "clock.fill",
                                color: Color(hex: "5AC8FA")
                            )
                            
                            StatCard(
                                title: "Total Sessions",
                                value: "\(dataManager.statistics.totalSessions)",
                                subtitle: "all time",
                                icon: "star.fill",
                                color: Color(hex: "FF9500")
                            )
                            
                            StatCard(
                                title: "Total Time",
                                value: "\(dataManager.statistics.totalMinutes)",
                                subtitle: "minutes",
                                icon: "hourglass",
                                color: Color(hex: "AF52DE")
                            )
                        }
                        
                        // Streak Card
                        StreakCard(
                            currentStreak: dataManager.statistics.currentStreak,
                            longestStreak: dataManager.statistics.longestStreak
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .accessibilityIdentifier("done_statistics")
                }
            }
            .toolbarBackground(Color(hex: "1C1C1E"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Components

struct TodayProgressCard: View {
    @StateObject private var dataManager = FocusDataManager.shared
    
    var progress: Double {
        min(Double(dataManager.statistics.todaySessions) / Double(dataManager.settings.dailyGoal), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(dataManager.statistics.todaySessions)/\(dataManager.settings.dailyGoal)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(hex: "FF6B6B"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "3A3A3C"))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF9500")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                }
            }
            .frame(height: 12)
            
            HStack {
                Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "target")
                    .foregroundColor(progress >= 1.0 ? Color(hex: "4ECB71") : Color(hex: "8E8E93"))
                
                Text(progress >= 1.0 ? "Daily goal achieved!" : "\(Int(progress * 100))% of daily goal")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "8E8E93"))
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "636366"))
            }
        }
        .padding(16)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(12)
    }
}

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                Text("\(currentStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Current Streak")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color(hex: "3A3A3C"))
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "FFD700"))
                
                Text("\(longestStreak)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Best Streak")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
}

#Preview {
    StatisticsView()
}
