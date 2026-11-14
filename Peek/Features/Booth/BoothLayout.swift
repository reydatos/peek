import SwiftUI

/// Arranges the booth. Lookbook pages 02, 05, and 07A.
///
/// A wide display has the slot rail at one side, the live crop in the center, and the controls at the other side.
/// So the controls stay clear of the fold. A tall display has the live crop above the rail and the controls.
struct BoothLayout: View {
    let model: BoothSessionModel

    var body: some View {
        GeometryReader { proxy in
            if model.cameraStatus == .running, isWide(proxy) {
                HStack(spacing: 0) {
                    BoothRail(model: model)
                        .frame(width: proxy.size.width / 6)
                    BoothStatusView(model: model)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    BoothControls(model: model, usesShutter: true)
                        .padding()
                        .frame(width: proxy.size.width / 4)
                }
            } else {
                BoothStatusView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .bottom) {
                        if model.cameraStatus == .running {
                            VStack {
                                SlotRail(model: model, axis: .horizontal)
                                BoothControls(model: model)
                            }
                            .padding()
                        }
                    }
            }
        }
    }

    /// True on an open iPhone Duo (the fold is vertical) and on other displays that are wider than tall.
    private func isWide(_ proxy: GeometryProxy) -> Bool {
        if #available(iOS 27.1, *), proxy.reservedRegions(kind: .division).contains(where: { $0.frame.height > $0.frame.width }) {
            return true
        }
        return proxy.size.width > proxy.size.height
    }
}
