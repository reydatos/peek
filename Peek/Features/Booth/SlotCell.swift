import SwiftUI

/// One position in the slot rail: the accepted shot, or the slot number.
struct SlotCell: View {
    let number: Int
    let image: UIImage?
    let isCurrent: Bool

    var body: some View {
        (image == nil ? Color.clear : PeekTheme.panel)
            .aspectRatio(4 / 3, contentMode: .fit)
            .containerRelativeFrame(.vertical, count: 10, spacing: 0)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(number, format: .number)
                        .font(.title)
                        .fontDesign(.serif)
                        .foregroundStyle(isCurrent ? PeekTheme.cream : PeekTheme.mist)
                }
            }
            .clipShape(.rect(cornerRadius: PeekTheme.corner))
            .overlay {
                RoundedRectangle(cornerRadius: PeekTheme.corner)
                    .strokeBorder(isCurrent ? PeekTheme.accent : PeekTheme.line, lineWidth: isCurrent ? 2 : 1)
            }
    }
}
