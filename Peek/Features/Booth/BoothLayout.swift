import SwiftUI

/// Arranges the booth. `docs/design/DESIGN.md`, "Components" and "Layout rules for iPhone Duo".
///
/// A wide display has the pose reference on the leading side, the photo in the center, and the side rail on the
/// trailing side. So the controls stay clear of the fold; only the photo can cross it.
/// A tall display has the photo above the slots and the controls.
struct BoothLayout: View {
    let model: BoothSessionModel
    let actions: BoothActions

    var body: some View {
        GeometryReader { proxy in
            if model.cameraStatus == .running, isWide(proxy) {
                HStack(spacing: 0) {
                    BoothLeadingPanel(model: model)
                        .frame(width: proxy.size.width / 4)
                    BoothStatusView(model: model, showsPoseArt: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    BoothSideRail(model: model, actions: actions)
                        .frame(width: PeekTheme.railWidth)
                }
            } else {
                BoothStatusView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top) {
                        HStack {
                            Button(action: actions.close) {
                                PeekIconLabel(text: .close, systemImage: "xmark")
                            }
                            Spacer()
                            if model.cameraStatus == .running {
                                Button(action: actions.showPoses) {
                                    PeekIconLabel(text: .poses, systemImage: "square.grid.2x2")
                                }
                                BoothMoreMenu(model: model)
                            }
                        }
                        .padding(.horizontal)
                    }
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
