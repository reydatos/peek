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
}
