import SwiftUI

/// A status message over the photo: a warning icon and one sentence on a surface card.
struct PeekBanner<Action: View>: View {
    let text: LocalizedStringResource
    var systemImage = "exclamationmark.triangle"
    @ViewBuilder var action: Action

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
                Text(text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            action
        }
        .font(.subheadline)
        .foregroundStyle(PeekTheme.ink)
        .padding()
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.thumbnailCorner))
        .overlay {
            RoundedRectangle(cornerRadius: PeekTheme.thumbnailCorner)
                .strokeBorder(PeekTheme.separator)
        }
    }
}

extension PeekBanner where Action == EmptyView {
    init(text: LocalizedStringResource, systemImage: String = "exclamationmark.triangle") {
        self.init(text: text, systemImage: systemImage) { EmptyView() }
    }
}
