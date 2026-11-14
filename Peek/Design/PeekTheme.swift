import SwiftUI

/// The PEEK look, from the UX lookbook: midnight navy, warm ivory, the red wordmark, cyan for live, lime for kids.
///
/// The colors are the vector fills of the lookbook. The corner sizes are design values.
enum PeekTheme {
    static let ink = Color(red: 16 / 255, green: 27 / 255, blue: 56 / 255)
    /// The fill of the primary camera action, and the light text color.
    static let cream = Color(red: 249 / 255, green: 239 / 255, blue: 220 / 255)
    /// The fill of a secondary control, and the soft text color.
    static let mist = Color(red: 221 / 255, green: 229 / 255, blue: 240 / 255)
    static let line = Color(red: 82 / 255, green: 96 / 255, blue: 121 / 255)
    static let panel = Color(red: 34 / 255, green: 48 / 255, blue: 76 / 255)
    /// The red of the wordmark and of the booth entry.
    static let accent = Color(red: 197 / 255, green: 18 / 255, blue: 43 / 255)
    /// The live frame and the selected slot.
    static let live = Color(red: 35 / 255, green: 213 / 255, blue: 234 / 255)
    static let lime = Color(red: 201 / 255, green: 243 / 255, blue: 56 / 255)
    static let pink = Color(red: 255 / 255, green: 112 / 255, blue: 176 / 255)
    /// The corner of a card or a button.
    static let corner: CGFloat = 16
    /// The corner of a chip, a slot, or a picture.
    static let smallCorner: CGFloat = 6
}
