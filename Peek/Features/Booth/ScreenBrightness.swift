import SwiftUI
import UIKit

/// Sets the display of its window to full brightness while `isBright` is true, and gives the old brightness back after.
struct ScreenBrightness: UIViewRepresentable {
    let isBright: Bool

    func makeUIView(context _: Context) -> BrightnessUIView {
        BrightnessUIView()
    }

    func updateUIView(_ view: BrightnessUIView, context _: Context) {
        view.isBright = isBright
    }

    static func dismantleUIView(_ view: BrightnessUIView, coordinator _: ()) {
        view.isBright = false
    }
}

final class BrightnessUIView: UIView {
    private var keeper = BrightnessKeeper()

    var isBright = false {
        didSet { apply() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        apply()
    }

    private func apply() {
        guard let screen = window?.windowScene?.screen else { return }
        if let value = keeper.update(isBright: isBright, current: screen.brightness) {
            screen.brightness = value
        }
    }
}
