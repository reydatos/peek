import Foundation

/// The group of a pose pack. The pose library shows the packs in the order of these groups, and its filter
/// shows one group. The groups are a design value: they follow the kind of the poses and of their pictures.
enum PackCategory: Int, CaseIterable, Comparable {
    /// The classic booth: it is first, and it shows only with all packs.
    case classic
    /// Cartoon and animal poses for children and families.
    case kids
    /// Photo poses in a city street.
    case street
    /// Photo poses that follow a trend.
    case trends

    static func < (lhs: PackCategory, rhs: PackCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// The choice of the filter in the pose library.
enum PackFilter: Hashable {
    case all
    case only(PackCategory)

    func shows(_ pack: PosePack) -> Bool {
        switch self {
        case .all: true
        case let .only(category): pack.category == category
        }
    }
}
