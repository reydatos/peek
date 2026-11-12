import PeekCore
import SwiftUI

/// One short cue per state. Review and finished states show the shot with no overlay.
struct CueOverlay: View {
    let phase: BoothPhase
    let isSubjectFacing: Bool

    var body: some View {
        switch phase {
        case .ready:
            CueBadge(text: .samplePrompt, systemImage: "figure.wave", isSubjectFacing: isSubjectFacing)
        case let .countdown(remaining):
            CountdownView(remaining: remaining, isSubjectFacing: isSubjectFacing)
        case .capturePending:
            CueBadge(text: .capturing, systemImage: "camera.shutter.button", isSubjectFacing: isSubjectFacing)
        case .paused:
            CueBadge(text: .paused, systemImage: "pause.circle", isSubjectFacing: isSubjectFacing)
        case .setup, .review, .complete:
            EmptyView()
        }
    }
}
