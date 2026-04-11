//
//  SocialSharing.swift
//  FocusTimer
//

import SwiftUI
import UIKit

// MARK: - Social Sharing Card Generator

struct SocialSharingCardGenerator {
    
    static func generateCard(
        stats: FocusStatistics,
        level: Int,
        streak: Int,
        achievements: Int,
        theme: AppTheme = .default
    ) -> UIImage? {
        
        let width: CGFloat = 400
        let height: CGFloat = 500
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background
            UIColor(Color(hex: theme.backgroundColor)).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            // Gradient header
            let gradientColors = [
                UIColor(Color(hex: "FF6B6B")).cgColor,
                UIColor(Color(hex: "FF9500")).cgColor
            ]
            
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: gradientColors as CFArray,
                locations: [0, 1]
            ) {
                ctx.saveGState()
                ctx.addRect(CGRect(x: 0, y: 0, width: width, height: 150))
                ctx.clip()
                ctx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: width, y: 150),
                    options: []
                )
                ctx.restoreGState()
            }
            
            // Title
            let titleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let title = "FocusTimer"
            title.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttrs)
            
            // Main title
            let mainTitleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            let mainTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: mainTitleFont,
                .foregroundColor: UIColor.white
            ]
            let mainTitle = "My Focus Report"
            mainTitle.draw(at: CGPoint(x: 20, y: 45), withAttributes: mainTitleAttrs)
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let dateStr = dateFormatter.string(from: Date())
            let dateFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            dateStr.draw(at: CGPoint(x: 20, y: 80), withAttributes: dateAttrs)
            
            // Stats section
            let statsY: CGFloat = 180
            
            // Hours
            drawStat(
                context: ctx,
                value: "\(stats.totalMinutes / 60)",
                label: "Hours Focused",
                icon: "clock.fill",
                iconColor: UIColor.orange,
                x: 30,
                y: statsY,
                width: 110,
                theme: theme
            )
            
            // Sessions
            drawStat(
                context: ctx,
                value: "\(stats.totalSessions)",
                label: "Sessions",
                icon: "checkmark.circle.fill",
                iconColor: UIColor(Color(hex: "4ECB71")),
                x: 150,
                y: statsY,
                width: 110,
                theme: theme
            )
            
            // Streak
            drawStat(
                context: ctx,
                value: "\(streak)",
                label: "Day Streak",
                icon: "flame.fill",
                iconColor: UIColor.red,
                x: 270,
                y: statsY,
                width: 110,
                theme: theme
            )
            
            // Second row
            let stats2Y: CGFloat = 280
            
            // Level
            drawStat(
                context: ctx,
                value: "Lv.\(level)",
                label: "Current Level",
                icon: "star.fill",
                iconColor: UIColor.yellow,
                x: 30,
                y: stats2Y,
                width: 110,
                theme: theme
            )
            
            // Achievements
            drawStat(
                context: ctx,
                value: "\(achievements)",
                label: "Achievements",
                icon: "trophy.fill",
                iconColor: UIColor.purple,
                x: 150,
                y: stats2Y,
                width: 110,
                theme: theme
            )
            
            // Today
            drawStat(
                context: ctx,
                value: "\(stats.todaySessions)",
                label: "Today",
                icon: "sun.max.fill",
                iconColor: UIColor(Color(hex: "5AC8FA")),
                x: 270,
                y: stats2Y,
                width: 110,
                theme: theme
            )
            
            // Quote
            let quoteFont = UIFont.italicSystemFont(ofSize: 14)
            let quoteAttrs: [NSAttributedString.Key: Any] = [
                .font: quoteFont,
                .foregroundColor: UIColor(Color(hex: theme.secondaryTextColor))
            ]
            let quotes = [
                "Focus is the key to productivity.",
                "Small daily improvements lead to stunning results.",
                "Consistency beats intensity every time.",
                "The secret of getting ahead is getting started."
            ]
            let quote = quotes[stats.totalSessions % quotes.count]
            quote.draw(at: CGPoint(x: 20, y: 400), withAttributes: quoteAttrs)
            
            // App branding
            let brandFont = UIFont.systemFont(ofSize: 10, weight: .medium)
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: brandFont,
                .foregroundColor: UIColor(Color(hex: theme.secondaryTextColor))
            ]
            let brand = "Made with FocusTimer"
            brand.draw(at: CGPoint(x: width - 120, y: height - 30), withAttributes: brandAttrs)
        }
    }
    
    private static func drawStat(
        context: CGContext,
        value: String,
        label: String,
        icon: String,
        iconColor: UIColor,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        theme: AppTheme
    ) {
        // Card background
        let cardRect = CGRect(x: x, y: y, width: width, height: 80)
        let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
        UIColor(Color(hex: theme.cardColor)).setFill()
        cardPath.fill()
        
        // Icon
        if let iconImage = UIImage(systemName: icon)?.withTintColor(iconColor, renderingMode: .alwaysOriginal) {
            iconImage.draw(in: CGRect(x: x + 12, y: y + 12, width: 24, height: 24))
        }
        
        // Value
        let valueFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: UIColor.white
        ]
        value.draw(at: CGPoint(x: x + 12, y: y + 40), withAttributes: valueAttrs)
        
        // Label
        let labelFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor(Color(hex: theme.secondaryTextColor))
        ]
        label.draw(at: CGPoint(x: x + 12, y: y + 65), withAttributes: labelAttrs)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let items: [Any] = [image, text]
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
