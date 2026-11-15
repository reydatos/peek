import SwiftUI

/// The leading panel of a wide booth with a finished set: the layout choice and the frame color.
/// Before the set is finished, the wide booth has no leading panel. The side rail has the pose reference.
struct BoothLeadingPanel: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(.yourStrip)
                .font(.title2)
                .bold()
            LayoutPicker(model: model)
            FramePicker(model: model)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(PeekTheme.ink)
        .padding()
        // The panel is narrow. Above this text size, its labels do not fit.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}
