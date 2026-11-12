import Foundation

/// Identifies one capture request. A callback that carries an old token is stale.
public struct CaptureToken: Hashable, Sendable, Codable {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
