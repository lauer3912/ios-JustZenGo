//
//  IntelligenceDashboard.swift
//  JustZen
//

import SwiftUI

struct IntelligenceDashboardView: View {
    @StateObject private var intelligence = FocusIntelligence.shared
    @StateObject private var health = HealthIntegration.shared
    @StateObject private var coach = AICoach.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1C1C1E")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Focus Score Card
                        focusScoreCard
                        
                        // AI Coach Card
                        coachCard
                        
                        // Health Correlation
                        if health.isAuthorized {
                            healthCard
                        }
                        
                        // Insights List
                        insightsList
                        
                        // Peak Hours Visualization
                        peakHoursCard
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Focus Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .accessibilityIdentifier("done_intelligence")
                }
            }
            .onAppear {
                intelligence.analyze()
                health.fetchTodayData()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Focus Score Card
    
    private var focusScoreCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Focus Score")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    coach.checkIn()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Color(hex: "8E8E93"))
                }
            }
            
            HStack(spacing: 24) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(Color(hex: "3A3A3C"), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: Double(intelligence.focusScore) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(intelligence.focusScore)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Text("/ 100")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ScoreRow(label: "Completion", value: "\(Int(intelligence.completionRate * 100))%")
                    ScoreRow(label: "Avg Session", value: "\(intelligence.averageSessionLength / 60) min")
                    ScoreRow(label: "Peak Hours", value: "\(intelligence.peakHours.count)")
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    private var scoreColor: Color {
        switch intelligence.focusScore {
        case 80...100: return Color(hex: "4ECB71")
        case 60..<80: return Color(hex: "5AC8FA")
        case 40..<60: return Color(hex: "FFD60A")
        default: return Color(hex: "FF6B6B")
        }
    }
    
    // MARK: - AI Coach Card
    
    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Color(hex: "AF52DE"))
                Text("AI Coach")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let lastMessage = coach.messages.last {
                Text(lastMessage.text)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .italic()
            } else {
                Text("Tap refresh to get a personalized tip!")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Button(action: {
                _ = coach.checkIn()
            }) {
                Text("Get Advice")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "AF52DE"))
                    .cornerRadius(20)
            }
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    // MARK: - Health Card
    
    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Health Correlation")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 24) {
                HealthMetric(icon: "figure.walk", value: "\(health.todaySteps)", label: "Steps", color: .green)
                HealthMetric(icon: "bed.double.fill", value: String(format: "%.1f", health.todaySleepHours), label: "Hours Sleep", color: .blue)
            }
            
            if let tip = health.getHealthTip() {
                Text(tip)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    // MARK: - Insights List
    
    private var insightsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if intelligence.insights.isEmpty {
                Text("Complete more sessions to generate insights")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding()
            } else {
                ForEach(intelligence.insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    // MARK: - Peak Hours Card
    
    private var peakHoursCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Peak Hours")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if intelligence.peakHours.isEmpty {
                Text("Not enough data yet. Keep focusing!")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8E8E93"))
            } else {
                HStack(spacing: 12) {
                    ForEach(intelligence.peakHours, id: \.self) { hour in
                        VStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Color(hex: "FF9500"))
                            Text(formatHour(hour))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "3A3A3C"))
                        .cornerRadius(12)
                    }
                }
                
                Text("Schedule your most important tasks during these times for maximum productivity.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(hex: "2C2C2E"))
        .cornerRadius(16)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

// MARK: - Supporting Views

struct ScoreRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8E8E93"))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

struct HealthMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "8E8E93"))
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightRow: View {
    let insight: FocusInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.2))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(insight.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var iconColor: Color {
        switch insight.type {
        case .positive: return Color(hex: "4ECB71")
        case .negative: return Color(hex: "FF6B6B")
        case .neutral: return Color(hex: "5AC8FA")
        case .tip: return Color(hex: "FFD60A")
        }
    }
}
