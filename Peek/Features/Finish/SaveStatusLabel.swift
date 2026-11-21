import SwiftUI

/// The result of a save to Photos. Each state has an icon or a sentence.
struct SaveStatusLabel: View {
    let status: SaveStatus
    /// The part of the duet video that is made. With it, the label shows a bar with words instead of the spinner.
    var duetProgress: Double?

    var body: some View {
        Group {
            switch status {
            case .idle: EmptyView()
            case .saving:
                if let duetProgress {
                    ProgressView(value: duetProgress) {
                        Text(.makingDuet)
                    }
                    .tint(PeekTheme.strong)
                } else {
                    ProgressView()
                }
            case .saved: Label(.savedToPhotos, systemImage: "checkmark.circle")
            case .denied: Text(.photosDenied)
            case .failed: Text(.saveFailed)
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
    }
}
