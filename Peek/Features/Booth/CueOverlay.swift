import PeekCore
import SwiftUI

/// One short cue per state. Review and finished states show the shot with no overlay.
struct CueOverlay: View {
    let phase: BoothPhase
    let isSubjectFacing: Bool
    var prompt: LocalizedStringResource = .samplePrompt

    var body: some View {
        switch phase {
        case .ready:
            CueBadge(text: prompt, systemImage: "figure.wave", isSubjectFacing: isSubjectFacing)
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

#Preview("Ready") {
    CueOverlay(phase: .ready, isSubjectFacing: true)
}

#Preview("Countdown") {
    CueOverlay(phase: .countdown(remaining: 3), isSubjectFacing: true)
}

#Preview("Capturing") {
    CueOverlay(phase: .capturePending(CaptureToken()), isSubjectFacing: true)
}

#Preview("Paused") {
    CueOverlay(phase: .paused(resumeTo: .countdown, reason: .outerDisplayLost), isSubjectFacing: true)
}
