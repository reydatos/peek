/// One prompt in a sequence. PRD FR-05: stable ID, version, short instruction, descriptive text.
public struct Cue: Identifiable, Equatable, Sendable, Codable {
    public let id: String
    public let version: Int
    public let instruction: String
    public let descriptiveText: String

    public init(id: String, version: Int, instruction: String, descriptiveText: String) {
        self.id = id
        self.version = version
        self.instruction = instruction
        self.descriptiveText = descriptiveText
    }
}
