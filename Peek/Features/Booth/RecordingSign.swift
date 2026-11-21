import SwiftUI

/// The sign that the booth records video of the people: a word, a red dot that pulses, and the seconds since the
/// start. The word and the icon say it, not the color alone. It shows on the display of the photographer and on the
/// display that faces the people. The red dot is the one red beside the main action (owner decision, 2026-11-21).
struct RecordingSign: View {
    /// The time at which the recording started.
    let start: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Label {
            HStack(spacing: PeekTheme.tightSpace) {
                Text(.recordingVideo)
                TimelineView(.periodic(from: start, by: 1)) { context in
                    Text(Duration.seconds(max(0, context.date.timeIntervalSince(start))), format: .time(pattern: .minuteSecond))
                        .monospacedDigit()
                }
            }
        } icon: {
            Image(systemName: "record.circle.fill")
                .foregroundStyle(PeekTheme.red)
                // With Reduce Motion on, the dot stays still.
                .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
        }
        .font(.subheadline)
        .bold()
        .padding(.horizontal)
        .padding(.vertical, PeekTheme.tightSpace)
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.chipCorner))
    }
}
