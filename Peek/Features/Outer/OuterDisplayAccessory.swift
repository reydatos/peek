import SwiftUI

/// Registers the outer-display content on the capture interface.
///
/// `CameraCaptureAccessory` needs iOS 27.1. On iOS 27.0 this modifier does nothing and the
/// booth runs on one screen. The system decides when the accessory shows.
struct OuterDisplayAccessory: ViewModifier {
    @Bindable var model: BoothSessionModel

    /// The outer display is off with the front camera: the people in the photo then face the inner display.
    private var isEnabled: Binding<Bool> {
        Binding(
            get: { model.isOuterDisplayEnabled && !model.isSelfie },
            set: {
                if !model.isSelfie {
                    model.isOuterDisplayEnabled = $0
                }
            }
        )
    }

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.sceneAccessory {
                CameraCaptureAccessory(isEnabled: isEnabled) {
                    OuterCueView(model: model)
                }
                .onAvailabilityChange { isAvailable in
                    model.setOuterDisplayAvailable(isAvailable)
                }
            }
        } else {
            content
        }
    }
}
