@testable import Peek
import SwiftUI
import Testing
import UIKit

struct PeekThemeTests {
    /// SwiftUI resolves a color on a render thread during an animation.
    /// A color provider that is bound to the main actor stops the app there.
    @Test func dynamicColorsResolveOffTheMainActor() async {
        let colors = [
            PeekTheme.page, PeekTheme.surface, PeekTheme.fill, PeekTheme.ink, PeekTheme.inkSecondary,
            PeekTheme.separator, PeekTheme.strong, PeekTheme.onStrong, PeekTheme.redText, PeekTheme.wordmark,
        ].map { UIColor($0) }

        let differ = await Task.detached {
            let light = UITraitCollection(userInterfaceStyle: .light)
            let dark = UITraitCollection(userInterfaceStyle: .dark)
            return colors.map { $0.resolvedColor(with: light) != $0.resolvedColor(with: dark) }
        }.value

        #expect(differ == Array(repeating: true, count: colors.count))
    }
}
