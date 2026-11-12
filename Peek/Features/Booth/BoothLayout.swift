import SwiftUI

/// Puts the picture and the controls in two panes on a wide display, or in a stack on a tall one.
struct BoothLayout: View {
    let model: BoothSessionModel

    var body: some View {
        GeometryReader { proxy in
            if model.cameraStatus == .running, let split = BoothSplit(proxy: proxy) {
                HStack(spacing: 0) {
                    BoothStatusView(model: model)
                        .frame(width: split.leading)
                    BoothSidePane(model: model)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.leading, split.gap)
                }
            } else {
                BoothStatusView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .bottom) {
                        if model.cameraStatus == .running {
                            BoothControls(model: model)
                        }
                    }
            }
        }
    }
}
