import SwiftUI

/// The actions for a finished strip. Lookbook page 06: Save Strip is the main action; Share and Save Originals follow.
struct FinishedControls: View {
    let model: BoothSessionModel
    @State private var isConfirmingNewSet = false

    var body: some View {
        VStack(alignment: .leading) {
            statusText
            LayoutPicker(model: model)
            Button { Task { await model.saveStrip() } } label: { Text(.saveStrip) }
                .buttonStyle(PeekPrimaryButtonStyle())
            if let strip = model.strip {
                ShareLink(
                    item: Image(uiImage: strip),
                    preview: SharePreview(Text(.yourStrip), image: Image(uiImage: strip))
                ) {
                    Text(.shareStrip)
                }
                .buttonStyle(PeekSecondaryButtonStyle())
            }
            Button { Task { await model.saveShots() } } label: { Text(.saveShots) }
                .buttonStyle(PeekSecondaryButtonStyle())
            // A new set discards the shots, so the photographer confirms first.
            Button { isConfirmingNewSet = true } label: {
                Label(.newSet, systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
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
