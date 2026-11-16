import Observation

/// All pose packs: the built-in packs of `PoseLibrary`, and the packs that the customer made.
/// The booth and the pose library read the packs and the poses from here.
@Observable
final class PoseCatalog {
    /// The packs of the customer. The default is none, so tests and previews stay isolated.
    var userPacks: [PosePack]

    init(userPacks: [PosePack] = []) {
        self.userPacks = userPacks
    }

    /// A customer pack with no pose is not in the catalog: a session needs one pose or more.
    var packs: [PosePack] {
        PoseLibrary.packs + userPacks.filter { !$0.cues.isEmpty }
    }

    /// The classic pack. It stands in for a pack that the catalog does not have.
    var classicPack: PosePack {
        PoseLibrary.packs[0]
    }

    /// The packs in the order of the pose library: by group, and inside a group in the order of `packs`.
    func packs(for filter: PackFilter) -> [PosePack] {
        packs.enumerated()
            .filter { filter.shows($0.element) }
            .sorted { ($0.element.category, $0.offset) < ($1.element.category, $1.offset) }
            .map(\.element)
    }

    func pack(id: String) -> PosePack? {
        packs.first { $0.id == id }
    }

    /// The pack with the ID, or the classic pack when the catalog has no such pack: a customer can remove a pack
    /// that a stored session still names.
    func packOrClassic(id: String) -> PosePack {
        pack(id: id) ?? classicPack
    }

    func cue(for id: String) -> PoseCue? {
        packs.lazy.flatMap(\.cues).first { $0.id == id }
    }
}
