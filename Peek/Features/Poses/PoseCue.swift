import SwiftUI
import UIKit

/// Where the pictures of a pose come from.
enum PoseMedia {
    /// The asset catalog of the app, by the names that come from the pose ID.
    case catalog
    /// Files of a customer pose: the still picture, and a short clip that shows the move.
    case files(still: URL, clip: URL?)
}

/// One pose prompt. A built-in pose has its pictures in the asset catalog. A customer pose has files.
struct PoseCue: Identifiable {
    let id: String
    let name: PoseName
    /// The SF Symbol that stands in until a reference picture exists.
    let symbol: String
    let media: PoseMedia

    /// A built-in pose.
    init(id: String, name: LocalizedStringResource, symbol: String) {
        self.id = id
        self.name = .builtIn(name)
        self.symbol = symbol
        media = .catalog
    }

    /// A customer pose. The ID must be unique in all packs, because a session stores a pose by its ID.
    init(id: String, name: String, symbol: String = "figure.stand", still: URL, clip: URL? = nil) {
        self.id = id
        self.name = .custom(name)
        self.symbol = symbol
        media = .files(still: still, clip: clip)
    }

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

    /// The reference picture. Nil when the pose has none, and the symbol then stands in.
    var picture: UIImage? {
        switch media {
        case .catalog: UIImage(named: assetName)
        case let .files(still, _): Self.picture(at: still)
        }
    }

    /// The pictures of customer poses that the app has read. A view asks for its picture each time it draws,
    /// and a read of the file each time is slow.
    private static let pictures = NSCache<NSURL, UIImage>()

    private static func picture(at url: URL) -> UIImage? {
        if let picture = pictures.object(forKey: url as NSURL) {
            return picture
        }
        guard let picture = UIImage(contentsOfFile: url.path) else { return nil }
        pictures.setObject(picture, forKey: url as NSURL)
        return picture
    }

    /// The picture of the start of a move. Only a built-in pose has one; a customer pose shows its move as a clip.
    var startPicture: UIImage? {
        switch media {
        case .catalog: UIImage(named: startAssetName)
        case .files: nil
        }
    }

    /// The wide copy of the reference picture. Only a built-in photo pose has one.
    var widePicture: UIImage? {
        switch media {
        case .catalog: UIImage(named: wideAssetName)
        case .files: nil
        }
    }

    /// The clip that shows the move of a customer pose.
    var clipURL: URL? {
        switch media {
        case .catalog: nil
        case let .files(_, clip): clip
        }
    }

    /// True when the pose can show its move: a built-in pose with a start picture, or a customer pose with a clip.
    var hasMove: Bool {
        clipURL != nil || startPicture != nil
    }
}
