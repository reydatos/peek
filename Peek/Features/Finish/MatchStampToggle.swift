import SwiftUI

/// The switch that puts the match score on the finished picture. It shows after the app has the score,
/// so each picture with the switch on has its stamp.
struct MatchStampToggle: View {
    @Bindable var model: BoothSessionModel

    var body: some View {
        if let percent = model.matchPercent {
            Toggle(isOn: $model.showsMatchStamp) {
                VStack(alignment: .leading) {
                    Text(.matchStampToggle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(BoothSessionModel.stampText(percent: percent))
                        .font(.footnote)
                        .foregroundStyle(PeekTheme.inkSecondary)
                }
            }
            .tint(PeekTheme.strong)
        }
    }
}
