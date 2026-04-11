//
//  FocusIntelligence.swift
//  FocusTimer
//

import Foundation
import Combine

// MARK: - Focus Insight

struct FocusInsight: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: InsightType
    let icon: String
    let date: Date
    
    enum InsightType: String, Codable {
        case positive = "positive"
        case negative = "negative"
        case neutral = "neutral"
        case tip = "tip"
    }
}

// MARK: - Insight Categories

enum InsightCategory: String {
    case pattern = "pattern"
    case wellness = "wellness"
    case achievement = "achievement"
    case reflection = "reflection"
    
    var icon: String {
        switch self {
        case .pattern: return "chart.line.uptrend.xyaxis"
        case .wellness: return "heart.fill"
        case .achievement: return "trophy.fill"
        case .reflection: return "lightbulb.fill"
        }
    }
}

enum InsightImportance {
    case low
    case medium
    case high
}

// MARK: - Focus Intelligence Engine

class FocusIntelligence: ObservableObject {
    static let shared = FocusIntelligence()
    
    @Published var insights: [FocusInsight] = []
    @Published var peakHours: [Int] = [] // 0-23 hour values
    @Published var bestDays: [Int] = [] // weekday values
    @Published var averageSessionLength: Int = 0
    @Published var completionRate: Double = 0.0
    @Published var focusScore: Int = 0 // 0-100
    
    private let dataManager = FocusDataManager.shared
    
    func analyze() {
        analyzePeakHours()
        analyzeBestDays()
        analyzeCompletionRate()
        calculateFocusScore()
        generateInsights()
    }
    
    private func analyzePeakHours() {
        let sessions = dataManager.sessions.filter { $0.type == .work && $0.completed }
        var hourCounts: [Int: Int] = [:]
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            hourCounts[hour, default: 0] += 1
        }
        
        // Get top 3 peak hours
        let sorted = hourCounts.sorted { $0.value > $1.value }
        peakHours = Array(sorted.prefix(3).map { $0.key })
    }
    
    private func analyzeBestDays() {
        let sessions = dataManager.sessions.filter { $0.type == .work && $0.completed }
        var dayCounts: [Int: Int] = [:]
        
        for session in sessions {
            let weekday = Calendar.current.component(.weekday, from: session.startTime)
            dayCounts[weekday, default: 0] += 1
        }
        
        let sorted = dayCounts.sorted { $0.value > $1.value }
        bestDays = Array(sorted.prefix(3).map { $0.key })
    }
    
    private func analyzeCompletionRate() {
        let allSessions = dataManager.sessions.filter { $0.type == .work }
        let completed = allSessions.filter { $0.completed }.count
        averageSessionLength = allSessions.isEmpty ? 0 : allSessions.reduce(0) { $0 + $1.duration } / allSessions.count
        completionRate = allSessions.isEmpty ? 0 : Double(completed) / Double(allSessions.count)
    }
    
    private func calculateFocusScore() {
        // Composite score from multiple factors
        var score = 50
        
        // Completion rate (up to +25)
        score += Int(completionRate * 25)
        
        // Streak bonus (up to +15)
        let streak = dataManager.statistics.currentStreak
        score += min(streak, 15)
        
        // Daily goal achievement (up to +10)
        if dataManager.statistics.todaySessions >= dataManager.settings.dailyGoal {
            score += 10
        }
        
        focusScore = min(max(score, 0), 100)
    }
    
    func addInsight(text: String, category: InsightCategory = .wellness, importance: InsightImportance = .medium) {
        let type: FocusInsight.InsightType
        switch category {
        case .pattern: type = .positive
        case .wellness: type = .tip
        case .achievement: type = .positive
        case .reflection: type = .neutral
        }
        
        insights.append(FocusInsight(
            id: UUID(),
            title: category.rawValue.capitalized,
            description: text,
            type: type,
            icon: category.icon,
            date: Date()
        ))
        save()
    }
    
    private func generateInsights() {
        insights.removeAll()
        
        // Peak hours insight
        if !peakHours.isEmpty {
            let hourStr = peakHours.map { formatHour($0) }.joined(separator: ", ")
            insights.append(FocusInsight(
                id: UUID(),
                title: "Peak Focus Hours",
                description: "You're most focused at \(hourStr). Schedule important tasks during these times.",
                type: .positive,
                icon: "clock.fill",
                date: Date()
            ))
        }
        
        // Best days insight
        if !bestDays.isEmpty {
            let dayStr = bestDays.map { formatWeekday($0) }.joined(separator: ", ")
            insights.append(FocusInsight(
                id: UUID(),
                title: "Best Focus Days",
                description: "Your most productive days are \(dayStr).",
                type: .tip,
                icon: "calendar",
                date: Date()
            ))
        }
        
        // Completion rate insight
        if completionRate < 0.8 && completionRate > 0 {
            insights.append(FocusInsight(
                id: UUID(),
                title: "Session Completion",
                description: "You complete \(Int(completionRate * 100))% of sessions. Try shorter sessions to improve.",
                type: .negative,
                icon: "exclamationmark.circle.fill",
                date: Date()
            ))
        } else if completionRate >= 0.9 {
            insights.append(FocusInsight(
                id: UUID(),
                title: "Excellent Completion!",
                description: "You finish \(Int(completionRate * 100))% of your sessions. Keep it up!",
                type: .positive,
                icon: "checkmark.seal.fill",
                date: Date()
            ))
        }
        
        // Focus score insight
        if focusScore >= 80 {
            insights.append(FocusInsight(
                id: UUID(),
                title: "Focus Champion",
                description: "Your focus score is \(focusScore)! You're in the top performers.",
                type: .positive,
                icon: "star.fill",
                date: Date()
            ))
        }
        
        // Average session length
        if averageSessionLength > 0 {
            let avgMin = averageSessionLength / 60
            if avgMin > 45 {
                insights.append(FocusInsight(
                    id: UUID(),
                    title: "Long Sessions",
                    description: "Average session: \(avgMin) min. You prefer deep work sessions.",
                    type: .neutral,
                    icon: "brain.head.profile",
                    date: Date()
                ))
            }
        }
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
    
    private func formatWeekday(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        var components = DateComponents()
        components.weekday = weekday
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "Day \(weekday)"
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(insights) {
            UserDefaults.standard.set(encoded, forKey: "focus_insights")
        }
        if let encoded = try? JSONEncoder().encode(peakHours) {
            UserDefaults.standard.set(encoded, forKey: "peak_hours")
        }
        if let encoded = try? JSONEncoder().encode(bestDays) {
            UserDefaults.standard.set(encoded, forKey: "best_days")
        }
        UserDefaults.standard.set(focusScore, forKey: "focus_score")
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: "focus_insights"),
           let decoded = try? JSONDecoder().decode([FocusInsight].self, from: data) {
            insights = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "peak_hours"),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            peakHours = decoded
        }
        if let data = UserDefaults.standard.data(forKey: "best_days"),
           let decoded = try? JSONDecoder().decode([Int].self, from: data) {
            bestDays = decoded
        }
        focusScore = UserDefaults.standard.integer(forKey: "focus_score")
    }
}
