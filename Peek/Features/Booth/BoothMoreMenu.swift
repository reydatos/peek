import PeekCore
import SwiftUI

/// The controls that have no place on the rail: the countdown length, the automatic shutter, and the outer display.
struct BoothMoreMenu: View {
    @Bindable var model: BoothSessionModel
    @State private var isConfirmingNewSet = false

    var body: some View {
        Menu {
            // The heading says what "Manual, 3 s, 5 s" set. A Picker here hides its label, and on iOS 27 the
            // menu also drops the heading of a section that holds a Picker. So each choice is a checkmark item.
            Section {
                countdownChoice(.manual) { Text(.countdownManual) }
                countdownChoice(.three) { Text(.countdownThree) }
                countdownChoice(.five) { Text(.countdownFive) }
            } header: {
                Text(.countdownLabel)
            }
            // The pose picture needs a person in it. A robot or an animal gives no body shape to match.
            Toggle(isOn: Binding(get: { model.match.isAutoShutterOn }, set: { model.match.isAutoShutterOn = $0 })) {
                Label(.autoShutter, systemImage: "figure.wave.circle")
            }
            // The photographer can always set it to off.
            .disabled(!model.match.canMatch && !model.match.isAutoShutterOn)
            // The duet needs the clip of a pose, so only a pack with clips has it.
            Toggle(isOn: Binding(get: { model.isDuetOn }, set: { model.isDuetOn = $0 })) {
                Label(.duetVideo, systemImage: "rectangle.split.1x2")
                // A gray switch with no reason is a dead end. This line says what the duet needs.
                if !model.hasPoseClips {
                    Text(.duetNeedsPack)
                }
            }
            .disabled(!model.hasPoseClips && !model.isDuetOn)
            if model.isOnOneScreen {
                // This item has no availability condition: the system can report the outer display
                // as not available while the booth does not ask for it.
                Button { model.restoreOuterDisplay() } label: {
                    Label(.useOuterDisplay, systemImage: "rectangle.on.rectangle")
                }
            }
            if model.isOuterDisplayAvailable, !model.isSelfie {
                Toggle(isOn: $model.isOuterDisplayEnabled) {
                    Label(.showOnOuterDisplay, systemImage: "rectangle.on.rectangle")
                }
                Toggle(isOn: $model.isOuterPreviewMirrored) {
                    Label(.mirrorOuterPreview, systemImage: "arrow.left.and.right")
                }
            }
            // The booth has no close button, so a set that has shots starts again from here.
            if model.hasShots, !model.isComplete {
                Button(role: .destructive) { isConfirmingNewSet = true } label: {
                    Label(.newSet, systemImage: "plus")
                }
            }
        } label: {
            PeekIconLabel(text: .more, systemImage: "ellipsis")
        }
        // A new set discards the shots, so the photographer confirms first.
        .confirmationDialog(Text(.discardShotsTitle), isPresented: $isConfirmingNewSet, titleVisibility: .visible) {
            Button(role: .destructive) { model.startNewSet() } label: { Text(.discardShots) }
            Button(role: .cancel) {} label: { Text(.cancel) }
        } message: {
            Text(.discardShotsMessage)
        }
    }

    /// One countdown choice. A tap selects it; a tap on the selected choice keeps it, so one choice is always on.
    private func countdownChoice(_ length: CountdownLength, label: () -> Text) -> some View {
        Toggle(isOn: Binding(
            get: { model.countdown == length },
            set: {
                if $0 {
                    model.countdown = length
                }
            }
        )) {
            label()
        }
    }
}
