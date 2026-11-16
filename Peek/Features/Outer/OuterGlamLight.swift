import PeekCore
import SwiftUI

/// The outer display as a fill light: the warm light color on the whole display, with the countdown numeral.
/// The numeral is in the column at the right, which the hinge cover does not hide.
struct OuterGlamLight: View {
    let model: BoothSessionModel

    var body: some View {
        GeometryReader { proxy in
            let column = StripPlacement.outerColumn(in: proxy.size, avoiding: proxy.occlusions)
            PeekTheme.glamLight
            if case let .countdown(remaining) = model.state.phase {
                CountdownView(remaining: remaining, total: model.countdown.seconds, isLarge: true)
                    .frame(width: column.width, height: column.height)
                    .position(x: column.midX, y: column.midY)
            }
        }
        // The light color is the same in light mode and in dark mode, so the numeral has the light-mode color.
        .environment(\.colorScheme, .light)
        // The light covers the display to its edges, as the picture below it does.
        .ignoresSafeArea()
    }
}
