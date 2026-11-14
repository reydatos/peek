import PeekCore
import SwiftUI

/// The state labels on the photographer's picture: live with the shot number, or the shot in review.
struct StageChips: View {
    let model: BoothSessionModel

    var body: some View {
        let number = model.state.currentSlotID.index + 1
        HStack {
            switch model.state.phase {
            case .ready, .countdown, .capturePending, .paused:
                PeekChip(text: .live, isLive: true)
                PeekChip(text: .shotOf(number, model.state.slots.count))
            case .review:
                PeekChip(text: .shotReview(number))
            case .setup, .complete:
                EmptyView()
            }
        }
    }
}
