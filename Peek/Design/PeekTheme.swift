import SwiftUI
import UIKit

/// The PEEK look, from the UI handoff (`docs/design/DESIGN.md` and `docs/design/tokens.json`).
///
/// Light, quiet, native: white surfaces, near-black text, grey hairlines, and one red.
/// Each semantic color has a light value and a dark value. The dark values are neutral: no navy and no blue tint.
enum PeekTheme {
    /// The app background behind screens and grouped content.
    static let page = dynamic(light: 0xF7F7F7, dark: 0x000000)
    /// The background of a screen or a card.
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x1C1C1E)
    /// Secondary buttons, chips, and empty slots.
    static let fill = dynamic(light: 0xF2F2F7, dark: 0x2C2C2E)
    /// Text and icons.
    static let ink = dynamic(light: 0x1D1D1F, dark: 0xF5F5F7)
    static let inkSecondary = dynamic(light: 0x6E6E73, dark: 0xAEAEB2)
    /// Hairlines and card borders.
    static let separator = dynamic(light: 0xE5E5EA, dark: 0x38383A)
    /// The selected segment, an accepted slot, and the shutter ring.
    static let strong = dynamic(light: 0x1D1D1F, dark: 0xF5F5F7)
    static let onStrong = dynamic(light: 0xFFFFFF, dark: 0x1D1D1F)
    /// The primary action and the shutter core. Nothing else is red.
    static let red = fixed(0xD9291C)
    static let onRed = fixed(0xFFFFFF)
    /// Red as text on the page or on a surface.
    static let redText = dynamic(light: 0xC4231A, dark: 0xFF6B5E)
    static let wordmark = dynamic(light: 0xBA011C, dark: 0xFFFFFF)
    /// The border of an instant photo. It is the same in the two modes.
    static let photoPaper = fixed(0xFBF3E1)
    /// The text on the paper of a strip and on a pack accent. It is the same in the two modes.
    static let paperInk = fixed(0x1D1D1F)
    /// The wordmark on the paper of a strip.
    static let paperWordmark = fixed(0xBA011C)
    /// The shade behind a white label on a photo.
    static let scrim = Color.black.opacity(0.6)

    // Pack accents. The handoff gives three; the editorial, kids, and trend groups use them.
    static let cyan = fixed(0x22D3EE)
    static let lime = fixed(0xC8F53A)
    static let pink = fixed(0xFF69B4)

    static let cardCorner: CGFloat = 20
    static let photoCorner: CGFloat = 20
    static let smallPhotoCorner: CGFloat = 12
    static let buttonCorner: CGFloat = 14
    static let primaryButtonCorner: CGFloat = 16
    static let chipCorner: CGFloat = 16
    static let slotCorner: CGFloat = 8
    /// The smallest spacing step.
    static let tightSpace: CGFloat = 6

    private static func fixed(_ hex: UInt32) -> Color {
        Color(uiColor(hex))
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? uiColor(dark) : uiColor(light) })
    }

    private nonisolated static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
