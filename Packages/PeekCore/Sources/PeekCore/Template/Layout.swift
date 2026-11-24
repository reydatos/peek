/// The layouts of the finished picture: the two launch layouts from PRD FR-01, and two duet prints that put
/// the pose pictures above the shots. The raw values are stored in drafts, so do not change them.
public enum Layout: String, Sendable, Codable, CaseIterable {
    case verticalStrip
    case grid2x2
    /// The poses in a row at the top, the shots in a row below them.
    case duetRow
    /// One pose above the shot of that pose.
    case duetSingle

    /// True for a layout that draws the pose pictures.
    public var showsPoses: Bool {
        self == .duetRow || self == .duetSingle
    }
}
