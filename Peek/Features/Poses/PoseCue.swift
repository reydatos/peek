import SwiftUI

/// One pose prompt. The reference picture is the asset named `assetName`, when the app has one.
struct PoseCue: Identifiable {
    let id: String
    let name: LocalizedStringResource
    /// The SF Symbol that stands in until a reference picture exists.
    let symbol: String

    var assetName: String {
        "pose-\(id)"
    }

    /// A wide copy of the reference picture, for the outer display. A photo pose picture has one, because a 3:4
    /// photo can not cover a wide display with the person complete. The person is at the right of the wide picture.
    var wideAssetName: String {
        "pose-\(id)-wide"
    }

    /// The picture of the start of a move. With `assetName` as the end, the two pictures show the move.
    var startAssetName: String {
        "pose-\(id)-start"
    }
}
