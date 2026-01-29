//
//  Theme.swift
//  Karaoke Time
//
//  Green and black color scheme with modern styling
//

import SwiftUI

struct KaraokeTheme {
    // MARK: - Colors
    
    /// Neon green primary color
    static let primaryGreen = Color(hex: "#00FF88")
    
    /// Darker green for gradients and accents
    static let darkGreen = Color(hex: "#00994D")
    
    /// Accent green with glow effect
    static let glowGreen = Color(hex: "#00FF88").opacity(0.6)
    
    /// Near-black background
    static let background = Color(hex: "#0A0A0A")
    
    /// Slightly lighter for cards/surfaces
    static let surface = Color(hex: "#1A1A1A")
    
    /// Border/divider color
    static let border = Color(hex: "#2A2A2A")
    
    /// Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    
    /// Error/warning
    static let error = Color(hex: "#FF4444")
    
    // MARK: - Gradients
    
    static let primaryGradient = LinearGradient(
        colors: [primaryGreen, darkGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0D0D0D"), Color(hex: "#1A1A1A")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let glowGradient = RadialGradient(
        colors: [glowGreen, Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 100
    )
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Button Styles

struct KaraokeButtonStyle: ButtonStyle {
    var isActive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(isActive ? KaraokeTheme.background : KaraokeTheme.textPrimary)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isActive {
                        KaraokeTheme.primaryGradient
                    } else {
                        KaraokeTheme.surface
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? KaraokeTheme.primaryGreen : KaraokeTheme.border, lineWidth: 2)
            )
            .shadow(color: isActive ? KaraokeTheme.glowGreen : .clear, radius: 20)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct LargeCircleButtonStyle: ButtonStyle {
    var isActive: Bool = false
    var size: CGFloat = 120
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundColor(isActive ? KaraokeTheme.background : KaraokeTheme.primaryGreen)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isActive ? KaraokeTheme.primaryGradient : LinearGradient(colors: [KaraokeTheme.surface], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                Circle()
                    .stroke(KaraokeTheme.primaryGreen, lineWidth: 3)
            )
            .shadow(color: isActive ? KaraokeTheme.glowGreen : KaraokeTheme.primaryGreen.opacity(0.3), radius: isActive ? 30 : 10)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - View Modifiers

struct GlowingBorder: ViewModifier {
    var color: Color = KaraokeTheme.primaryGreen
    var isActive: Bool = true
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: 2)
            )
            .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 10)
    }
}

extension View {
    func glowingBorder(color: Color = KaraokeTheme.primaryGreen, isActive: Bool = true) -> some View {
        modifier(GlowingBorder(color: color, isActive: isActive))
    }
}
