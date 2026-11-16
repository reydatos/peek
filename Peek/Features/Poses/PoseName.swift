import SwiftUI

/// The name of a pose or a pack. A built-in name is in the string catalog. A customer writes their own name,
/// and the app shows that text as it is.
enum PoseName {
    case builtIn(LocalizedStringResource)
    case custom(String)

    var text: Text {
        switch self {
        case let .builtIn(resource): Text(resource)
        case let .custom(string): Text(verbatim: string)
        }
    }
}
