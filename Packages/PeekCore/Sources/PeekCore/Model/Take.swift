import CoreGraphics
import Foundation

/// One captured still. PRD section 5: asset reference, crop, orientation, and request token.
public struct Take: Identifiable, Equatable, Sendable, Codable {
    public let id: UUID
    public let slotID: SlotID
    public let token: CaptureToken
    /// The name of the media file in app-managed storage.
    public let assetName: String
    /// The crop in normalized coordinates (0 to 1).
    public var crop: CGRect
    /// Degrees applied at capture to keep the photo level with the horizon.
    public var rotationAngle: Double

    public init(
        id: UUID = UUID(),
        slotID: SlotID,
        token: CaptureToken,
        assetName: String,
        crop: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
        rotationAngle: Double = 0
    ) {
        self.id = id
        self.slotID = slotID
        self.token = token
        self.assetName = assetName
        self.crop = crop
        self.rotationAngle = rotationAngle
    }
}
