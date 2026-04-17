//
//  ReportGenerator.swift
//  FocusTimer
//

import Foundation
import PDFKit
import UIKit

// MARK: - Focus Report Generator

class ReportGenerator {
    static let shared = ReportGenerator()
    
    private let dataManager = FocusDataManager.shared
    private let intelligence = FocusIntelligence.shared
    
    // MARK: - Generate Weekly Report
    
    func generateWeeklyReport() -> Data? {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin
            
            // Header
            yPosition = drawHeader(context: context, title: "Weekly Focus Report", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            
            // Date Range
            let (startDate, endDate) = getWeekDateRange()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateRange = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            drawText(dateRange, at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 12), color: .gray)
            yPosition += 40
            
            // Summary Stats
            let weekStats = getWeekStats(from: startDate, to: endDate)
            yPosition = drawSectionTitle("Summary", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Total Sessions", value: "\(weekStats.sessions)", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Total Focus Time", value: formatMinutes(weekStats.minutes), yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Daily Average", value: "\(weekStats.sessions / 7) sessions", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Longest Streak This Week", value: "\(weekStats.longestStreak) days", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            
            yPosition += 20
            
            // Peak Hours
            yPosition = drawSectionTitle("Your Peak Hours", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            let peakHours = intelligence.peakHours
            if !peakHours.isEmpty {
                let hoursText = peakHours.map { formatHour($0) }.joined(separator: ", ")
                drawText("You focus best at: \(hoursText)", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 14), color: .black)
                yPosition += 25
            } else {
                drawText("Not enough data yet", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 14), color: .gray)
                yPosition += 25
            }
            
            yPosition += 20
            
            // Best Days
            yPosition = drawSectionTitle("Your Best Days", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            let bestDays = intelligence.bestDays
            if !bestDays.isEmpty {
                let daysText = bestDays.map { formatWeekday($0) }.joined(separator: ", ")
                drawText("Most productive: \(daysText)", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 14), color: .black)
                yPosition += 25
            } else {
                drawText("Not enough data yet", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 14), color: .gray)
                yPosition += 25
            }
            
            yPosition += 20
            
            // Daily Breakdown
            yPosition = drawSectionTitle("Daily Breakdown", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            
            let calendar = Calendar.current
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                let dayStats = getDayStats(for: date)
                
                let dayFormatter = DateFormatter()
                dayFormatter.dateFormat = "EEEE"
                let dayName = dayFormatter.string(from: date)
                let dayDate = dateFormatter.string(from: date)
                
                yPosition = drawDayRow(dayName: dayName, date: dayDate, sessions: dayStats.sessions, minutes: dayStats.minutes, yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            }
            
            // Footer
            drawFooter(context: context, pageHeight: pageHeight, margin: margin)
        }
        
        return data
    }
    
    // MARK: - Generate Monthly Report
    
    func generateMonthlyReport() -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        let data = renderer.pdfData { context in
            context.beginPage()
            var yPosition: CGFloat = margin
            
            let (startDate, endDate) = getMonthDateRange()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            yPosition = drawHeader(context: context, title: "Monthly Focus Report", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            drawText("Month of \(dateFormatter.string(from: startDate))", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 12), color: .gray)
            yPosition += 40
            
            // Monthly Stats
            let monthStats = getMonthStats(from: startDate, to: endDate)
            yPosition = drawSectionTitle("Monthly Summary", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Total Sessions", value: "\(monthStats.sessions)", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Total Focus Time", value: formatHours(monthStats.minutes), yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Daily Average", value: "\(monthStats.sessions / 30) sessions", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Average Session Length", value: "\(monthStats.minutes / max(monthStats.sessions, 1)) min", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Current Streak", value: "\(dataManager.statistics.currentStreak) days", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition = drawStatRow("Longest Streak", value: "\(dataManager.statistics.longestStreak) days", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            
            yPosition += 20
            
            // Mode Breakdown
            yPosition = drawSectionTitle("Focus Mode Breakdown", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            let modeBreakdown = getModeBreakdown(from: startDate, to: endDate)
            for (mode, count) in modeBreakdown.prefix(6) {
                yPosition = drawStatRow(mode, value: "\(count) sessions", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            }
            
            yPosition += 20
            
            // Achievements This Month
            yPosition = drawSectionTitle("Achievements Unlocked", yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            let recentBadges = AchievementManager.shared.badges.filter { badge in
                guard let date = badge.unlockedDate else { return false }
                return date >= startDate && date <= endDate
            }
            
            if recentBadges.isEmpty {
                drawText("No achievements this month", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 14), color: .gray)
            } else {
                for badge in recentBadges.prefix(10) {
                    drawText("🏆 \(badge.name) - \(badge.description)", at: CGPoint(x: margin, y: yPosition), font: .systemFont(ofSize: 12), color: .black)
                    yPosition += 20
                }
            }
            
            drawFooter(context: context, pageHeight: pageHeight, margin: margin)
        }
        
        return data
    }
    
    // MARK: - CSV Export
    
    func generateCSVExport() -> String {
        var csv = "Date,Day,Start Time,End Time,Duration (min),Type,Mode,Label,Completed\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        for session in dataManager.sessions {
            let date = dateFormatter.string(from: session.startTime)
            let day = dayFormatter.string(from: session.startTime)
            let startTime = timeFormatter.string(from: session.startTime)
            let endTime = session.endTime != nil ? timeFormatter.string(from: session.endTime!) : "N/A"
            let duration = session.duration / 60
            let type = session.type.rawValue
            let completed = session.completed ? "Yes" : "No"
            
            csv += "\(date),\(day),\(startTime),\(endTime),\(duration),\(type),\(completed)\n"
        }
        
        return csv
    }
    
    // MARK: - Helper Methods
    
    private func drawHeader(context: UIGraphicsPDFRendererContext, title: String, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attrs)
        return yPosition + 50
    }
    
    private func drawSectionTitle(_ title: String, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        ]
        (title as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attrs)
        
        // Underline
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPosition + 22))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition + 22))
        UIColor.lightGray.setStroke()
        path.stroke()
        
        return yPosition + 35
    }
    
    private func drawStatRow(_ label: String, value: String, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let labelFont = UIFont.systemFont(ofSize: 14)
        let valueFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.gray]
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.black]
        
        (label as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: labelAttrs)
        (value as NSString).draw(at: CGPoint(x: pageWidth - margin - 150, y: yPosition), withAttributes: valueAttrs)
        
        return yPosition + 25
    }
    
    private func drawDayRow(dayName: String, date: String, sessions: Int, minutes: Int, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 13)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        
        ("\(dayName) (\(date))" as NSString).draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attrs)
        ("\(sessions) sessions, \(minutes) min" as NSString).draw(at: CGPoint(x: pageWidth - margin - 150, y: yPosition), withAttributes: attrs)
        
        return yPosition + 22
    }
    
    private func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        (text as NSString).draw(at: point, withAttributes: attrs)
    }
    
    private func drawFooter(context: UIGraphicsPDFRendererContext, pageHeight: CGFloat, margin: CGFloat) {
        let footerFont = UIFont.systemFont(ofSize: 10)
        let attrs: [NSAttributedString.Key: Any] = [.font: footerFont, .foregroundColor: UIColor.lightGray]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let footerText = "Generated by FocusTimer on \(dateFormatter.string(from: Date()))"
        (footerText as NSString).draw(at: CGPoint(x: margin, y: pageHeight - margin), withAttributes: attrs)
    }
    
    private func getWeekDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return (today, today)
        }
        return (startOfWeek, endOfWeek)
    }
    
    private func getMonthDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return (today, today)
        }
        return (startOfMonth, endOfMonth)
    }
    
    private func getWeekStats(from startDate: Date, to endDate: Date) -> (sessions: Int, minutes: Int, longestStreak: Int) {
        let sessions = dataManager.sessions.filter { $0.startTime >= startDate && $0.startTime <= endDate && $0.completed }
        let totalSessions = sessions.count
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration / 60 }
        return (totalSessions, totalMinutes, dataManager.statistics.currentStreak)
    }
    
    private func getDayStats(for date: Date) -> (sessions: Int, minutes: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let sessions = dataManager.sessions.filter { $0.startTime >= startOfDay && $0.startTime < endOfDay && $0.completed }
        return (sessions.count, sessions.reduce(0) { $0 + $1.duration / 60 })
    }
    
    private func getMonthStats(from startDate: Date, to endDate: Date) -> (sessions: Int, minutes: Int) {
        let sessions = dataManager.sessions.filter { $0.startTime >= startDate && $0.startTime <= endDate && $0.completed }
        return (sessions.count, sessions.reduce(0) { $0 + $1.duration / 60 })
    }
    
    private func getModeBreakdown(from startDate: Date, to endDate: Date) -> [(String, Int)] {
        let sessions = dataManager.sessions.filter { $0.startTime >= startDate && $0.startTime <= endDate && $0.completed }
        var modeCounts: [String: Int] = [:]
        for session in sessions {
            modeCounts[session.type.rawValue, default: 0] += 1
        }
        return modeCounts.sorted { $0.value > $1.value }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) min"
    }
    
    private func formatHours(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return "\(hours)h \(mins)m"
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
}
