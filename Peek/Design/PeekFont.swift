import CoreText
import SwiftUI
import UIKit

/// The PEEK typeface is Inter Tight. Instrument Serif stays in the bundle; no screen uses it now.
///
/// Each font starts at the system size of its text style and scales with Dynamic Type.
enum PeekFont {
    static let serifName = "InstrumentSerif-Regular"
    static let sansName = "Inter Tight"

    static func sans(_ style: Font.TextStyle) -> Font {
        let font = Font.custom(sansName, size: baseSize(style), relativeTo: style)
        return style == .headline ? font.weight(.semibold) : font
    }

    /// Registers the bundled font files. The Info.plist is generated, so there is no `UIAppFonts` list.
    static func register(bundle: Bundle = .main) {
        for url in bundle.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [] {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// The system point size of a text style at the default Dynamic Type size.
    private static func baseSize(_ style: Font.TextStyle) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: uiStyle(style), compatibleWith: traits)
            .pointSize
    }

    private static func uiStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
