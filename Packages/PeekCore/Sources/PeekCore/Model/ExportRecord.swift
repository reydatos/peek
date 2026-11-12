import Foundation

/// PRD section 5: an export stores its selected takes, layout version, format, and outcome.
public struct ExportRecord: Identifiable, Equatable, Sendable, Codable {
    public enum Outcome: String, Sendable, Codable {
        case succeeded
        case failed
    }

    public let id: UUID
    public let takeIDs: [UUID]
    public let layout: Layout
    public let layoutVersion: Int
    public let format: String
    public var outcome: Outcome

    public init(id: UUID = UUID(), takeIDs: [UUID], layout: Layout, layoutVersion: Int, format: String, outcome: Outcome) {
        self.id = id
        self.takeIDs = takeIDs
        self.layout = layout
        self.layoutVersion = layoutVersion
        self.format = format
        self.outcome = outcome
    }
}
