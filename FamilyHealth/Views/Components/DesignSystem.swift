import SwiftUI

// MARK: - FamilyHealth Design System
// Premium design tokens following ShipSwift (SW) guidelines.

/// Central color palette with HSL-tuned values for a health-care premium feel.
enum FHColors {
    // Primary — calming teal-blue
    static let primary = Color(hue: 0.55, saturation: 0.72, brightness: 0.62)        // #2D7DD2 shade
    static let primaryLight = Color(hue: 0.55, saturation: 0.50, brightness: 0.88)
    static let primaryDark = Color(hue: 0.57, saturation: 0.80, brightness: 0.42)

    // Accent — warm coral for CTAs
    static let accent = Color(hue: 0.02, saturation: 0.68, brightness: 0.95)          // Coral-ish
    static let accentLight = Color(hue: 0.02, saturation: 0.40, brightness: 0.98)

    // Semantic
    static let success = Color(hue: 0.40, saturation: 0.58, brightness: 0.62)
    static let warning = Color(hue: 0.10, saturation: 0.72, brightness: 0.92)
    static let danger  = Color(hue: 0.98, saturation: 0.65, brightness: 0.88)
    static let info    = Color(hue: 0.58, saturation: 0.55, brightness: 0.75)

    // Neutral
    static let cardBackground  = Color(.systemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let subtleGray = Color(.systemGray5)

    // Category colors (for stats cards)
    static let reportBlue   = Color(hue: 0.58, saturation: 0.65, brightness: 0.72)
    static let caseOrange   = Color(hue: 0.08, saturation: 0.70, brightness: 0.90)
    static let familyGreen  = Color(hue: 0.40, saturation: 0.55, brightness: 0.65)
    static let calendarPurp = Color(hue: 0.77, saturation: 0.50, brightness: 0.68)
    static let aiPurple     = Color(hue: 0.73, saturation: 0.55, brightness: 0.72)
}

/// Gradient presets
enum FHGradients {
    /// Primary hero gradient (top header bars, splash areas)
    static let primaryHero = LinearGradient(
        colors: [
            Color(hue: 0.57, saturation: 0.72, brightness: 0.58),
            Color(hue: 0.52, saturation: 0.62, brightness: 0.72)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Warm accent gradient (CTA buttons)
    static let accentButton = LinearGradient(
        colors: [
            Color(hue: 0.55, saturation: 0.70, brightness: 0.65),
            Color(hue: 0.60, saturation: 0.55, brightness: 0.78)
        ],
        startPoint: .leading, endPoint: .trailing
    )

    /// Onboarding bg — adapts to light/dark mode
    static let onboardingBg = LinearGradient(
        colors: [
            Color(.systemBackground),
            Color(.secondarySystemBackground)
        ],
        startPoint: .top, endPoint: .bottom
    )

    /// Chat user bubble
    static let userBubble = LinearGradient(
        colors: [
            Color(hue: 0.57, saturation: 0.68, brightness: 0.60),
            Color(hue: 0.53, saturation: 0.58, brightness: 0.72)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Settings profile header pill
    static let profileAvatar = LinearGradient(
        colors: [
            Color(hue: 0.55, saturation: 0.60, brightness: 0.65),
            Color(hue: 0.73, saturation: 0.45, brightness: 0.75)
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

/// Corner radius presets
enum FHRadius {
    static let small: CGFloat  = 8
    static let medium: CGFloat = 12
    static let large: CGFloat  = 16
    static let xl: CGFloat     = 20
    static let pill: CGFloat   = 100
}

/// Spacing presets
enum FHSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

/// Shadow presets
struct FHShadow: ViewModifier {
    enum Level { case light, medium, heavy }
    let level: Level

    func body(content: Content) -> some View {
        switch level {
        case .light:
            content.shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        case .medium:
            content.shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        case .heavy:
            content.shadow(color: .black.opacity(0.14), radius: 20, y: 8)
        }
    }
}

extension View {
    func fhShadow(_ level: FHShadow.Level = .light) -> some View {
        modifier(FHShadow(level: level))
    }
}

/// Animation presets
enum FHAnimation {
    static let springBounce = Animation.spring(response: 0.35, dampingFraction: 0.6)
    static let springSmooth = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let easeOutQuick = Animation.easeOut(duration: 0.25)
    static let gentlePulse  = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}

/// Staggered entrance animation modifier
struct FHStaggeredEntrance: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .onAppear {
                withAnimation(FHAnimation.springSmooth.delay(Double(index) * 0.08)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func fhStaggerEntrance(index: Int) -> some View {
        modifier(FHStaggeredEntrance(index: index))
    }
}

/// Press-scale button style
struct FHPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func fhPressStyle() -> some View {
        buttonStyle(FHPressButtonStyle())
    }
}

/// Glow-pulse overlay (for icons / hero elements)
struct FHGlowPulse: ViewModifier {
    let color: Color
    @State private var isGlowing = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(color.opacity(0.15))
                    .scaleEffect(isGlowing ? 1.35 : 0.9)
                    .opacity(isGlowing ? 0 : 0.5)
            )
            .onAppear {
                withAnimation(FHAnimation.gentlePulse) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func fhGlowPulse(color: Color = FHColors.primary) -> some View {
        modifier(FHGlowPulse(color: color))
    }
}
