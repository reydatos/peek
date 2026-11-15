import SwiftUI

/// Arranges the booth. `docs/design/DESIGN.md`, "Components" and "Layout rules for iPhone Duo".
///
/// A wide display has the photo on the leading side and the side rail on the trailing side. The rail has the one
/// pose reference. So the controls stay clear of the fold; only the photo can cross it.
/// A finished set on a wide display adds the leading panel, with the layout and the frame color.
/// A tall display has the full-screen camera above the black camera bar. A finished set on a tall display has
/// the strip above the slots and the controls.
struct BoothLayout: View {
    let model: BoothSessionModel
    let actions: BoothActions

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            if model.cameraStatus == .running, isWide(proxy) {
                HStack(spacing: 0) {
                    if model.isComplete {
                        BoothLeadingPanel(model: model)
                            .frame(width: proxy.size.width / 4)
                    }
                    BoothStatusView(model: model, showsPoseArt: false)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    BoothSideRail(model: model, actions: actions)
                        .frame(width: PeekTheme.railWidth)
                }
                // With the glam light, the page is the warm light, so the content has the light-mode colors.
                .environment(\.colorScheme, model.showsInnerGlamLight ? .light : colorScheme)
            } else if model.cameraStatus == .running, !model.isComplete {
                // A tall display: a viewfinder at the full width, and the black camera bar below it.
                VStack(spacing: 0) {
                    BoothStatusView(model: model, isFullBleed: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .top) {
                            HStack {
                                Button(action: actions.close) {
                                    PeekIconLabel(text: .close, systemImage: "xmark")
                                }
                                Spacer()
                                BoothMoreMenu(model: model)
                            }
                            .padding(.horizontal)
                        }
                    BoothCameraBar(model: model, actions: actions)
                }
                .background(model.showsInnerGlamLight ? PeekTheme.glamLight : PeekTheme.cameraChrome)
                // The bar and the labels on the photo have a fixed space. Above this text size they do not fit.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
