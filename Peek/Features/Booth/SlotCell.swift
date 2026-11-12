import SwiftUI

/// One position in the slot rail: the accepted shot, or the slot number.
struct SlotCell: View {
    let number: Int
    let image: UIImage?
    let isCurrent: Bool

    var body: some View {
        Color.secondary.opacity(0.2)
            .aspectRatio(3 / 4, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(number, format: .number)
                        .font(.headline)
                }
            }
            .clipShape(.rect(cornerRadius: 8))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.tint, lineWidth: 3)
                }
            }
    }
}
