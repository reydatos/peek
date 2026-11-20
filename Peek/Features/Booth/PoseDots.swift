import SwiftUI

/// A dot for each pose of the pack. The dot of the current pose is solid. The dots are on a surface, so they show
/// over the camera picture too. VoiceOver reads the pose name on the picture, so the dots are hidden from it.
struct PoseDots: View {
    let count: Int
    /// Nil when the current pose is not in the pack.
    let current: Int?
    @ScaledMetric(relativeTo: .caption) private var size = 6

    var body: some View {
        HStack(spacing: size) {
            ForEach(0 ..< count, id: \.self) { index in
                Circle()
                    .fill(index == current ? PeekTheme.ink : PeekTheme.inkSecondary)
                    .frame(width: size, height: size)
            }
        }
        .padding(.horizontal, size)
        .padding(.vertical, size / 2)
        .background(PeekTheme.surface, in: .capsule)
        .accessibilityHidden(true)
    }
}
