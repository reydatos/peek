import PeekCore
import SwiftUI

/// The capture interface on the inner display.
///
/// Review is a state of this view, not a push or a sheet. The system shows the outer accessory
/// only while this view is onscreen and the capture session runs.
struct BoothView: View {
    @State private var model: BoothSessionModel
    @Environment(\.scenePhase) private var scenePhase

    init(packID: String) {
        _model = State(initialValue: BoothSessionModel(
            capture: CaptureService(),
            cueIDs: PoseLibrary.cueIDs(forPack: packID)
        ))
    }

    var body: some View {
        @Bindable var model = model
        BoothLayout(model: model)
            .toolbar {
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
}
