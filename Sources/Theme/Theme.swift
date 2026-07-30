import SwiftUI

/// Mirrors the Tailwind palette used across the web app (slate-950 background,
/// emerald-500 accents, red-500/600 for danger/security flows, cyan for freeze).
enum KTheme {
    static let bgBase = Color(red: 0.01, green: 0.03, blue: 0.07)          // slate-950
    static let bgCard = Color(red: 0.06, green: 0.09, blue: 0.16)          // slate-900
    static let bgCardMuted = Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.5)
    static let border = Color.white.opacity(0.06)
    static let textPrimary = Color.white
    static let textMuted = Color(red: 0.45, green: 0.5, blue: 0.58)        // slate-500
    static let emerald = Color(red: 0.06, green: 0.72, blue: 0.51)         // emerald-500
    static let emeraldDark = Color(red: 0.02, green: 0.59, blue: 0.41)
    static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)          // red-500
    static let dangerDark = Color(red: 0.86, green: 0.15, blue: 0.15)      // red-600
    static let cyan = Color(red: 0.02, green: 0.71, blue: 0.83)           // cyan-500

    static let cardRadius: CGFloat = 32
    static let pillRadius: CGFloat = 999
}

struct KBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KTheme.bgBase.ignoresSafeArea())
    }
}

extension View {
    func kBackground() -> some View { modifier(KBackground()) }
}
