import SwiftUI

/// The actions for a finished strip. Lookbook page 06: Save Strip is the main action; Share and Save Originals follow.
struct FinishedControls: View {
    let model: BoothSessionModel
    @State private var isConfirmingNewSet = false

    var body: some View {
        VStack(alignment: .leading) {
            SaveStatusLabel(status: model.saveStatus)
            LayoutPicker(model: model)
            FramePicker(model: model)
            MatchStampToggle(model: model)
            Button { Task { await model.saveStrip() } } label: {
                Label(.saveStrip, systemImage: "square.and.arrow.down")
            }
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
            ChallengeShareButton(model: model, style: PeekSecondaryButtonStyle())
            if !model.duetSegments.isEmpty {
                Button { Task { await model.saveDuet() } } label: {
                    Label(.saveDuet, systemImage: "rectangle.split.1x2")
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
}
