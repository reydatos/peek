import PeekCore
import SwiftUI

/// The status messages of the booth. Each one has an icon and one sentence.
struct BoothBanners: View {
    let model: BoothSessionModel

    var body: some View {
        if case .paused(_, .outerDisplayLost) = model.state.phase {
            PeekBanner(text: .outerDisplayUnavailable)
        }
        if model.canRestoreOuterDisplay {
            PeekBanner(text: .outerDisplayAvailable, systemImage: "rectangle.on.rectangle") {
                Button { model.restoreOuterDisplay() } label: { Text(.useOuterDisplay) }
                    .buttonStyle(.bordered)
            }
        }
        if case .paused(_, .recovered) = model.state.phase {
            PeekBanner(text: .draftRestored, systemImage: "arrow.counterclockwise")
        }
        if model.state.lastFailure != nil, model.state.phase == .ready {
            PeekBanner(text: .captureFailed)
        }
        if model.isDraftUnsaved {
            PeekBanner(text: .draftNotSaved)
        }
    }
}
