import AVFoundation
import SwiftUI

/// A live view that draws frames from `FrameSource`. The outer display uses it.
struct FramePreviewView: UIViewRepresentable {
    let capture: any CaptureProviding
    let deviceID: String?
    let isMirrored: Bool

    func makeUIView(context _: Context) -> FrameUIView {
        FrameUIView(capture: capture)
    }

    func updateUIView(_ view: FrameUIView, context _: Context) {
        view.observeRotation(deviceID: deviceID)
        view.setMirrored(isMirrored)
    }

    static func dismantleUIView(_ view: FrameUIView, coordinator _: ()) {
        view.detach()
    }
}
