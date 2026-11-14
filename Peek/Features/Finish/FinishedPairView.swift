import PeekCore
import SwiftUI

/// The finished set on a wide display: the vertical strip on the leading half and the 2x2 on the trailing half.
/// A tap selects the layout. The selected one has a check and a border, so the color is not the only sign.
struct FinishedPairView: View {
    @Bindable var model: BoothSessionModel
    /// The picture of the layout that is not selected.
    @State private var other: UIImage?

    var body: some View {
        HStack {
            choice(.verticalStrip, label: .layoutStrip)
            choice(.grid2x2, label: .layoutGrid)
        }
        .task(id: PreviewKey(layout: model.layout, frame: model.frame)) {
            other = nil
            let layout: PeekCore.Layout = model.layout == .verticalStrip ? .grid2x2 : .verticalStrip
            other = await StripRenderer.renderInBackground(model.finishedShots, layout: layout, style: .paper(model.frame))
        }
    }

    private func choice(_ layout: PeekCore.Layout, label: LocalizedStringResource) -> some View {
        let isSelected = model.layout == layout
        return Button { model.layout = layout } label: {
            ZStack {
                if let picture = isSelected ? model.strip : other {
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFit()
                        .overlay {
                            Rectangle()
                                .strokeBorder(isSelected ? PeekTheme.strong : Color.clear, lineWidth: 3)
                        }
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(PeekTheme.onStrong, PeekTheme.strong)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private struct PreviewKey: Hashable {
        let layout: PeekCore.Layout
        let frame: FrameColor
    }
}
