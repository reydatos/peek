import SwiftUI

/// The result of a save to Photos. Each state has an icon or a sentence.
struct SaveStatusLabel: View {
    let status: SaveStatus

    var body: some View {
        Group {
            switch status {
            case .idle: EmptyView()
            case .saving: ProgressView()
            case .saved: Label(.savedToPhotos, systemImage: "checkmark.circle")
            case .denied: Text(.photosDenied)
            case .failed: Text(.saveFailed)
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
    }
}
