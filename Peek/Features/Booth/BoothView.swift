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
    @Environment(\.scenePhase) private var scenePhase

    init(packID: String) {
        _model = State(initialValue: BoothSessionModel(
            capture: CaptureService(),
            packID: packID
        ))
    }

    var body: some View {
        @Bindable var model = model
        BoothLayout(model: model)
            .background(PeekTheme.ink)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { posePicker = PosePickerRequest() } label: {
                        Label(.poseIdeas, systemImage: "figure.wave")
                    }
                }
                if model.isOuterDisplayAvailable {
                    ToolbarItemGroup {
                        Toggle(isOn: $model.isOuterDisplayEnabled) {
                            Label(.showOnOuterDisplay, systemImage: "rectangle.on.rectangle")
                        }
                        Toggle(isOn: $model.isOuterPreviewMirrored) {
                            Label(.mirrorOuterPreview, systemImage: "arrow.left.and.right")
                        }
                    }
                }
            }
            .sheet(item: $posePicker) { _ in
                // The warning shows on the sheet, so the photographer decides before the sheet closes.
                PoseIdeasView { pack in
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
            .navigationTitle(Text(.boothTitle))
            .navigationBarTitleDisplayMode(.inline)
            .task { await model.startCamera() }
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
    }
}
