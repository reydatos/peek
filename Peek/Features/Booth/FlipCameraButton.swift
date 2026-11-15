import SwiftUI

/// Changes between the rear camera and the front camera, as the flip button of a camera app does.
/// It shows while the booth waits for a shot, on the camera bar of a tall display and on the side rail.
struct FlipCameraButton: View {
    let model: BoothSessionModel

    var body: some View {
        Button { Task { await model.flipCamera() } } label: {
            PeekIconLabel(text: .flipCamera, systemImage: "arrow.triangle.2.circlepath.camera")
        }
    }
}
