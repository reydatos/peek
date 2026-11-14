import PeekCore
import SwiftUI

/// The pose tray. It opens over the camera, so the booth stays on the screen.
///
/// The photographer chooses poses for the open shots: each tap gives the pose the number of its shot.
/// Apply gives the poses to the slots. More ideas opens the pose library.
struct PoseTray: View {
    let model: BoothSessionModel
    let onMoreIdeas: () -> Void
    let onClose: () -> Void
    @Environment(SavedPoses.self) private var saved
    @State private var showsSaved = false
    @State private var selection: PoseSelection
    @ScaledMetric(relativeTo: .body) private var thumbnailHeight = 110

    init(model: BoothSessionModel, onMoreIdeas: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.model = model
        self.onMoreIdeas = onMoreIdeas
        self.onClose = onClose
        _selection = State(initialValue: PoseSelection(openSlots: model.openSlotNumbers))
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                PeekSegmentedChoice(selection: $showsSaved, options: [(false, .forYou), (true, .saved)])
                Button(action: onClose) {
                    PeekIconLabel(text: .close, systemImage: "xmark")
                }
            }
            let cues = showsSaved ? saved.cues : model.packCues
            if cues.isEmpty {
                Text(.noSavedPoses)
                    .font(.subheadline)
                    .foregroundStyle(PeekTheme.inkSecondary)
                    .frame(maxWidth: .infinity, minHeight: thumbnailHeight)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top) {
                        ForEach(cues) { cue in
                            thumbnail(cue)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            HStack {
                Button(action: onMoreIdeas) {
                    Label(.moreIdeas, systemImage: "square.grid.2x2")
                }
                .buttonStyle(PeekSecondaryButtonStyle())
                Button {
                    model.send(.assignCues(selection.ids))
                    onClose()
                } label: {
                    Label(.apply, systemImage: "checkmark")
                }
                .buttonStyle(PeekPrimaryButtonStyle())
                .disabled(selection.ids.isEmpty)
            }
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        .overlay {
            RoundedRectangle(cornerRadius: PeekTheme.cardCorner)
                .strokeBorder(PeekTheme.separator)
        }
        .shadow(color: PeekTheme.scrim.opacity(0.2), radius: 20, y: 8)
    }

    private func thumbnail(_ cue: PoseCue) -> some View {
        let number = selection.slotNumber(for: cue.id)
        return Button { selection.toggle(cue.id) } label: {
            VStack {
                PoseArt(cue: cue)
                    .frame(height: thumbnailHeight)
                    .overlay(alignment: .topLeading) {
                        if let number {
                            // The number of the shot that gets this pose.
                            Text(number, format: .number)
                                .font(.caption)
                                .bold()
                                .foregroundStyle(PeekTheme.onRed)
                                .padding(PeekTheme.tightSpace)
                                .background(PeekTheme.red, in: .circle)
                                .padding(PeekTheme.tightSpace / 2)
                        }
                    }
                Text(cue.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: thumbnailHeight * 3 / 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(cue.name))
        .accessibilityValue(number.map { Text(.shotNumber($0)) } ?? Text(verbatim: ""))
        .accessibilityAddTraits(number == nil ? [] : .isSelected)
        .overlay(alignment: .topTrailing) {
            SaveStarButton(cue: cue)
        }
    }
}
