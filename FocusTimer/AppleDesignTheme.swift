//
//  AppleDesignTheme.swift
//  FocusTimer
//
//  Apple Design System implementation based on Human Interface Guidelines
//

import SwiftUI

// MARK: - Apple Design Tokens

enum AppleDesign {
    // MARK: - Colors
    
    enum Colors {
        // Backgrounds
        static let background = Color(hex: "#1D1D1F")
        static let backgroundSecondary = Color(hex: "#2C2C2E")
        static let backgroundElevated = Color(hex: "#3A3A3C")
        static let backgroundTertiary = Color(hex: "#48484A")
        
        // Light backgrounds
        static let backgroundLight = Color(hex: "#F5F5F7")
        static let backgroundWhite = Color(hex: "#FFFFFF")
        
        // Text
        static let textPrimary = Color(hex: "#F5F5F7")
        static let textSecondary = Color(hex: "#98989D")
        static let textTertiary = Color(hex: "#636366")
        static let textOnLight = Color(hex: "#1D1D1F")
        
        // Semantic - Focus Timer specific
        static let focusRed = Color(hex: "#FF453A")
        static let focusOrange = Color(hex: "#FF9F0A")
        static let focusYellow = Color(hex: "#FFD60A")
        static let focusGreen = Color(hex: "#30D158")
        static let focusMint = Color(hex: "#63E6BE")
        static let focusTeal = Color(hex: "#40C8E0")
        static let focusCyan = Color(hex: "#64D2FF")
        static let focusBlue = Color(hex: "#0A84FF")
        static let focusIndigo = Color(hex: "#5E5CE6")
        static let focusPurple = Color(hex: "#BF5AF2")
        static let focusPink = Color(hex: "#FF375F")
        
        // System colors
        static let systemGray = Color(hex: "#8E8E93")
        static let systemGray2 = Color(hex: "#636366")
        static let systemGray3 = Color(hex: "#48484A")
        static let systemGray4 = Color(hex: "#3A3A3C")
        static let systemGray5 = Color(hex: "#2C2C2E")
        static let systemGray6 = Color(hex: "#1C1C1E")
        
        // Gradients
        static let gradientFocus = LinearGradient(
            colors: [focusPink, focusPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gradientSuccess = LinearGradient(
            colors: [focusGreen, focusMint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gradientCalm = LinearGradient(
            colors: [focusBlue, focusCyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gradientEnergy = LinearGradient(
            colors: [focusOrange, focusYellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    
    enum Typography {
        // SF Pro Display - Large titles
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        
        // Headlines
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let headlineMedium = Font.system(size: 17, weight: .medium, design: .default)
        
        // Body
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 17, weight: .medium, design: .default)
        
        // Callout
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let calloutMedium = Font.system(size: 16, weight: .medium, design: .default)
        
        // Subheadline
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let subheadlineMedium = Font.system(size: 15, weight: .medium, design: .default)
        
        // Footnote
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let footnoteMedium = Font.system(size: 13, weight: .medium, design: .default)
        
        // Caption
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption1Medium = Font.system(size: 12, weight: .medium, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Monospaced for timer
        static let timerLarge = Font.system(size: 64, weight: .bold, design: .monospaced)
        static let timerMedium = Font.system(size: 48, weight: .medium, design: .monospaced)
        static let timerSmall = Font.system(size: 32, weight: .medium, design: .monospaced)
        static let timerCaption = Font.system(size: 14, weight: .medium, design: .monospaced)
    }
    
    // MARK: - Spacing (8pt grid)
    
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
        static let giant: CGFloat = 80
    }
    
    // MARK: - Border Radius
    
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let xxlarge: CGFloat = 24
        
        // Apple uses fully rounded for pills
        static let pill: CGFloat = 980
        static let circle: CGFloat = 9999
        
        // Timer specific
        static let timer: CGFloat = 140
        static let button: CGFloat = 14
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static let small = ShadowStyle(
            color: Color.black.opacity(0.04),
            radius: 4,
            x: 0,
            y: 1
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.06),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 8
        )
        
        static let card = ShadowStyle(
            color: Color.black.opacity(0.12),
            radius: 20,
            x: 0,
            y: 10
        )
        
        static let elevated = ShadowStyle(
            color: Color.black.opacity(0.16),
            radius: 32,
            x: 0,
            y: 16
        )
    }
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let snappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - Apple SF Symbols

enum AppleSymbols {
    // Focus Timer
    static let timer = "timer"
    static let timerCircle = "timer.circle.fill"
    static let playFill = "play.fill"
    static let pauseFill = "pause.fill"
    static let stopFill = "stop.fill"
    static let forwardFill = "forward.fill"
    static let backwardFill = "backward.fill"
    static let arrowCounterclockwise = "arrow.counterclockwise"
    
    // Navigation
    static let houseFill = "house.fill"
    static let chartBarFill = "chart.bar.fill"
    static let gearshapeFill = "gearshape.fill"
    static let listBullet = "list.bullet"
    static let personFill = "person.fill"
    
    // Achievements
    static let trophyFill = "trophy.fill"
    static let starFill = "star.fill"
    static let sparkles = "sparkles"
    static let crownFill = "crown.fill"
    
    // Status
    static let checkmarkCircleFill = "checkmark.circle.fill"
    static let xmarkCircleFill = "xmark.circle.fill"
    static let flameFill = "flame.fill"
    static let boltFill = "bolt.fill"
    static let target = "target"
    
    // Social
    static let heartFill = "heart.fill"
    static let bubbleLeftFill = "bubble.left.fill"
    static let squareAndArrowUp = "square.and.arrow.up"
    
    // Sound
    static let speakerWave3Fill = "speaker.wave.3.fill"
    static let speakerSlashFill = "speaker.slash.fill"
    
    // Mode icons
    static let brainHeadProfile = "brain.head.profile"
    static let moonFill = "moon.fill"
    static let sunMaxFill = "sun.max.fill"
    static let leafFill = "leaf.fill"
    static let figureWalk = "figure.walk"
    static let infinity = "infinity"
    
    // Coins
    static let bitcoinsignCircleFill = "bitcoinsign.circle.fill"
    
    // Misc
    static let folderFill = "folder.fill"
    static let calendarBadgeClock = "calendar.badge.clock"
    static let tagFill = "tag.fill"
    static let bellFill = "bell.fill"
    static let listClipboard = "list.clipboard"
    static let chartLineUptrendXYAxis = "chart.line.uptrend.xyaxis"
}

// MARK: - Apple Style Modifiers

struct AppleCardStyle: ViewModifier {
    var padding: CGFloat = AppleDesign.Spacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppleDesign.Colors.backgroundSecondary)
            .cornerRadius(AppleDesign.Radius.xlarge)
    }
}

struct ApplePillStyle: ViewModifier {
    var color: Color = AppleDesign.Colors.focusBlue
    
    func body(content: Content) -> some View {
        content
            .font(AppleDesign.Typography.caption1Medium)
            .foregroundColor(color)
            .padding(.horizontal, AppleDesign.Spacing.sm)
            .padding(.vertical, AppleDesign.Spacing.xxs)
            .background(color.opacity(0.2))
            .cornerRadius(AppleDesign.Radius.pill)
    }
}

struct AppleButtonStyle: ViewModifier {
    var size: ButtonSize = .medium
    var style: ButtonStyle = .primary
    
    enum ButtonSize {
        case small, medium, large
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return AppleDesign.Spacing.md
            case .medium: return AppleDesign.Spacing.lg
            case .large: return AppleDesign.Spacing.xl
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return AppleDesign.Spacing.xs
            case .medium: return AppleDesign.Spacing.sm
            case .large: return AppleDesign.Spacing.md
            }
        }
        
        var font: Font {
            switch self {
            case .small: return AppleDesign.Typography.footnoteMedium
            case .medium: return AppleDesign.Typography.subheadlineMedium
            case .large: return AppleDesign.Typography.headline
            }
        }
    }
    
    enum ButtonStyle {
        case primary, secondary, tertiary, destructive
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return AppleDesign.Colors.focusBlue
            case .tertiary: return AppleDesign.Colors.textPrimary
            case .destructive: return AppleDesign.Colors.focusRed
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppleDesign.Colors.focusBlue
            case .secondary: return AppleDesign.Colors.backgroundSecondary
            case .tertiary: return AppleDesign.Colors.backgroundElevated
            case .destructive: return AppleDesign.Colors.focusRed.opacity(0.15)
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(size.font)
            .foregroundColor(style.foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(style.backgroundColor)
            .cornerRadius(AppleDesign.Radius.button)
    }
}

struct AppleCircleButtonStyle: ViewModifier {
    var size: CGFloat = 60
    var backgroundColor: Color = AppleDesign.Colors.backgroundSecondary
    
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

struct ApplePrimaryCircleButtonStyle: ViewModifier {
    var size: CGFloat = 88
    var gradient: LinearGradient = AppleDesign.Colors.gradientFocus
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size * 0.4, weight: .medium))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(gradient)
            .clipShape(Circle())
            .shadow(color: AppleDesign.Colors.focusPurple.opacity(0.4), radius: 16, x: 0, y: 8)
    }
}

// MARK: - View Extensions

extension View {
    func appleCard(padding: CGFloat = AppleDesign.Spacing.lg) -> some View {
        modifier(AppleCardStyle(padding: padding))
    }
    
    func applePill(color: Color = AppleDesign.Colors.focusBlue) -> some View {
        modifier(ApplePillStyle(color: color))
    }
    
    func appleButton(size: AppleButtonStyle.ButtonSize = .medium, style: AppleButtonStyle.ButtonStyle = .primary) -> some View {
        modifier(AppleButtonStyle(size: size, style: style))
    }
    
    func appleCircleButton(size: CGFloat = 60, backgroundColor: Color = AppleDesign.Colors.backgroundSecondary) -> some View {
        modifier(AppleCircleButtonStyle(size: size, backgroundColor: backgroundColor))
    }
    
    func applePrimaryCircleButton(size: CGFloat = 88, gradient: LinearGradient = AppleDesign.Colors.gradientFocus) -> some View {
        modifier(ApplePrimaryCircleButtonStyle(size: size, gradient: gradient))
    }
    
    func appleShadow(_ style: AppleDesign.ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}

// MARK: - Focus Mode Colors

extension FocusModeType {
    var appleColor: Color {
        switch self {
        case .deepWork:
            return AppleDesign.Colors.focusRed
        case .creativeFlow:
            return AppleDesign.Colors.focusPurple
        case .easyDay:
            return AppleDesign.Colors.focusGreen
        case .miniSprint:
            return AppleDesign.Colors.focusOrange
        }
    }
    
    var appleGradient: LinearGradient {
        switch self {
        case .deepWork:
            return LinearGradient(colors: [AppleDesign.Colors.focusRed, AppleDesign.Colors.focusOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .creativeFlow:
            return LinearGradient(colors: [AppleDesign.Colors.focusPurple, AppleDesign.Colors.focusPink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .easyDay:
            return LinearGradient(colors: [AppleDesign.Colors.focusGreen, AppleDesign.Colors.focusMint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .miniSprint:
            return LinearGradient(colors: [AppleDesign.Colors.focusOrange, AppleDesign.Colors.focusYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
