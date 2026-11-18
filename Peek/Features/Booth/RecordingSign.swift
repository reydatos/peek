import SwiftUI

/// The sign that the booth records video of the people: a word and an icon, not the color alone.
/// It shows on the display of the photographer and on the display that faces the people.
struct RecordingSign: View {
    var body: some View {
        Label {
            Text(.recordingVideo)
        } icon: {
            Image(systemName: "record.circle.fill")
                .foregroundStyle(PeekTheme.red)
        }
        .font(.caption)
        .bold()
        .padding(.horizontal)
        .padding(.vertical, PeekTheme.tightSpace)
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.chipCorner))
    }
}
