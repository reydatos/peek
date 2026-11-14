import PeekCore
import SwiftUI

/// The zoom choices over the photo. They show only when the camera gives more than one factor.
/// The selected factor has the strong fill and the selected trait.
struct ZoomChips: View {
    let model: BoothSessionModel

    var body: some View {
        if model.zoomFactors.count > 1, model.state.phase == .ready {
            HStack(spacing: PeekTheme.tightSpace) {
                ForEach(model.zoomFactors, id: \.self) { factor in
                    let isSelected = factor == model.zoom
                    Button { Task { await model.setZoom(factor) } } label: {
                        Text(.zoomFactor(factor.formatted(.number.precision(.fractionLength(0 ... 1)))))
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, PeekTheme.tightSpace * 2)
                            .frame(minWidth: PeekTheme.touchTarget, minHeight: PeekTheme.touchTarget)
                            .foregroundStyle(isSelected ? PeekTheme.onStrong : PeekTheme.ink)
                            .background(isSelected ? PeekTheme.strong : PeekTheme.surface, in: .capsule)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(.zoom))
        }
    }
}
