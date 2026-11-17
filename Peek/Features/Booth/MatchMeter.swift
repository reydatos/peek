import SwiftUI

/// How near the people are to the pose: a word, an icon, and a bar. It does not use color alone.
/// It is on the side of the photographer only.
struct MatchMeter: View {
    let score: Double?

    private var level: MatchLevel {
        MatchLevel(score: score)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PeekTheme.tightSpace) {
            HStack(spacing: PeekTheme.tightSpace) {
                Label(label, systemImage: symbol)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                #if DEBUG
                    // The owner reads the score here to set the limits. A release build does not show it.
                    Spacer(minLength: 0)
                    Text(score ?? 0, format: .number.precision(.fractionLength(2)))
                        .font(.caption2)
                        .monospacedDigit()
                        .accessibilityHidden(true)
                #endif
            }
            ProgressView(value: min(max(score ?? 0, 0), 1))
                .tint(PeekTheme.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text((score ?? 0).formatted(.percent.precision(.fractionLength(0)))))
    }

    private var label: LocalizedStringResource {
        switch level {
        case .none: .matchNoPerson
        case .different: .matchDifferent
        case .near: .matchNear
        case .matched: .matchDone
        }
    }

    private var symbol: String {
        switch level {
        case .none: "person.slash"
        case .different: "exclamationmark.triangle"
        case .near: "figure.arms.open"
        case .matched: "checkmark.circle.fill"
        }
    }
}
