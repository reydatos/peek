import SwiftUI

/// The actions for a finished strip: save, share, save the shots, or start again.
struct FinishedControls: View {
    let model: BoothSessionModel
    @State private var isConfirmingNewSet = false

    var body: some View {
        VStack {
            statusText
            LayoutPicker(model: model)
            Button { Task { await model.saveStrip() } } label: {
                Label(.saveStrip, systemImage: "square.and.arrow.down")
            }
            .buttonStyle(PeekPrimaryButtonStyle())
            HStack {
                if let strip = model.strip {
                    ShareLink(
                        item: Image(uiImage: strip),
                        preview: SharePreview(Text(.yourStrip), image: Image(uiImage: strip))
                    ) {
                        Label(.shareStrip, systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PeekGhostButtonStyle())
                }
                Button { Task { await model.saveShots() } } label: {
                    Label(.saveShots, systemImage: "photo.on.rectangle")
                }
                .buttonStyle(PeekGhostButtonStyle())
            }
            // A new set discards the shots, so the photographer confirms first.
            Button { isConfirmingNewSet = true } label: {
                Label(.newSet, systemImage: "plus")
            }
            .buttonStyle(PeekGhostButtonStyle())
            .confirmationDialog(Text(.discardShotsTitle), isPresented: $isConfirmingNewSet, titleVisibility: .visible) {
                Button(role: .destructive) { model.startNewSet() } label: { Text(.discardShots) }
                Button(role: .cancel) {} label: { Text(.cancel) }
            } message: {
                Text(.discardShotsMessage)
            }
        }
        .disabled(model.saveStatus == .saving)
    }

    @ViewBuilder private var statusText: some View {
        switch model.saveStatus {
        case .idle: EmptyView()
        case .saving: ProgressView()
        case .saved: Label(.savedToPhotos, systemImage: "checkmark.circle")
        case .denied: Text(.photosDenied)
        case .failed: Text(.saveFailed)
        }
    }
}
