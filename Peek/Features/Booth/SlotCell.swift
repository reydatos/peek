import SwiftUI

/// One position in the slot rail: the slot number, over the accepted shot when there is one.
/// The current slot is cyan. The number states the position, so the color is not the only sign.
struct SlotCell: View {
    let number: Int
    let image: UIImage?
    let isCurrent: Bool

    var body: some View {
        (isCurrent ? PeekTheme.live : PeekTheme.panel)
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(.rect(cornerRadius: PeekTheme.smallCorner))
            .overlay(alignment: image == nil ? .center : .topLeading) {
                Text(number, format: .number)
                    .font(PeekFont.sans(image == nil ? .title3 : .caption))
                    .bold()
                    .padding(image == nil ? .zero : PeekTheme.smallCorner)
                    .foregroundStyle(image == nil && !isCurrent ? Color.white : PeekTheme.ink)
                    .background(image == nil ? Color.clear : isCurrent ? PeekTheme.live : Color.white, in: .rect(cornerRadius: PeekTheme.smallCorner))
            }
            .overlay {
                if isCurrent, image != nil {
                    RoundedRectangle(cornerRadius: PeekTheme.smallCorner)
                        .strokeBorder(PeekTheme.live, lineWidth: 2)
                }
            }
    }
}
