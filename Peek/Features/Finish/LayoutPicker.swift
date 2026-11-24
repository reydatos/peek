import PeekCore
import SwiftUI

/// The choice of the finished picture: the vertical strip and the 2x2 layout (PRD FR-01), and the two duet
/// prints, Duet (the poses above the shots) and Match (one pose above one shot).
/// Where four labels do not fit in one row, as in the narrow leading panel of the wide booth or at a large text
/// size, the choice has two rows: the prints, then the duet prints.
struct LayoutPicker: View {
    @Bindable var model: BoothSessionModel

    private static let prints: [(PeekCore.Layout, LocalizedStringResource)] = [
        (.verticalStrip, .layoutStrip),
        (.grid2x2, .layoutGrid),
    ]
    private static let duets: [(PeekCore.Layout, LocalizedStringResource)] = [
        (.duetRow, .layoutDuet),
        (.duetSingle, .layoutMatch),
    ]

    var body: some View {
        // The labels have one line each, so the ideal width of a row is the width of its full labels.
        ViewThatFits(in: .horizontal) {
            PeekSegmentedChoice(selection: $model.layout, options: (Self.prints + Self.duets).map { ($0.0, $0.1) })
            VStack(spacing: PeekTheme.tightSpace) {
                PeekSegmentedChoice(selection: $model.layout, options: Self.prints.map { ($0.0, $0.1) })
                PeekSegmentedChoice(selection: $model.layout, options: Self.duets.map { ($0.0, $0.1) })
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(.layoutLabel))
    }
}
