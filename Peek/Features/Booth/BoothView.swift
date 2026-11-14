import PeekCore
import SwiftUI

/// The capture interface on the inner display.
///
/// Review is a state of this view, not a push or a sheet. The system shows the outer accessory
/// only while this view is onscreen and the capture session runs.
struct BoothView: View {
    @State private var model: BoothSessionModel
    @State private var posePicker: PosePickerRequest?
    @State private var packToConfirm: PosePack?
    /// The pose tray is an overlay of this view, not a sheet. So the booth and its outer display stay onscreen.
    @State private var isTrayOpen = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    private let resumesDraft: Bool

    init(request: BoothRequest) {
        resumesDraft = request.resumesDraft
        _model = State(initialValue: BoothSessionModel(
            capture: CaptureService(),
            packID: request.packID,
            drafts: BoothDraftStore.shared
        ))
    }

    var body: some View {
        BoothLayout(model: model, actions: BoothActions(
            close: { dismiss() },
            showPoses: { isTrayOpen.toggle() }
        ))
        .overlay(alignment: .bottomTrailing) {
            // The tray changes the poses of the open shots. The reducer accepts this only while the booth waits.
            if isTrayOpen, model.state.phase == .ready {
                PoseTray(
                    model: model,
                    onMoreIdeas: { posePicker = PosePickerRequest() },
                    onClose: { isTrayOpen = false }
                )
                // On a wide display the tray stays on the trailing side, clear of the fold.
                .frame(maxWidth: PeekTheme.trayWidth)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: isTrayOpen)
        .background(PeekTheme.page)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $posePicker) { _ in
            // The warning shows on the sheet, so the photographer decides before the sheet closes.
            PoseLibraryView { pack in
                if model.hasShots {
                    packToConfirm = pack
                } else {
                    load(pack)
                }
            }
            .confirmationDialog(
                Text(.discardShotsTitle),
                isPresented: Binding(
                    get: { packToConfirm != nil },
                    set: {
                        if !$0 {
                            packToConfirm = nil
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: packToConfirm
            ) { pack in
                Button(role: .destructive) { load(pack) } label: { Text(.discardShots) }
                Button(role: .cancel) {} label: { Text(.cancel) }
            } message: { _ in
                Text(.discardShotsMessage)
            }
        }
        .modifier(OuterDisplayAccessory(model: model))
        .task {
            if resumesDraft {
                await model.restoreDraft()
            } else {
                await model.discardStoredDraft()
            }
            await model.startCamera()
        }
        .onDisappear { model.stopCamera() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                model.send(.pause(.interruption))
            }
        }
    }

    private func load(_ pack: PosePack) {
        model.loadPack(pack.id)
        packToConfirm = nil
        posePicker = nil
        isTrayOpen = false
    }
}
