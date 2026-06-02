import SwiftUI

enum CodeReloadColors {
    static let background = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let surfaceElevated = Color(uiColor: .tertiarySystemBackground)
    static let border = Color(uiColor: .separator)
    static let accent = Color.accentColor
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textMuted = Color(uiColor: .tertiaryLabel)
    static let textDisabled = Color(uiColor: .quaternaryLabel)
}

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

extension View {
    /// CodeReload is dark-only; lock SwiftUI and system chrome to dark appearance.
    func codereloadDarkTheme() -> some View {
        self.preferredColorScheme(.dark)
    }
}
