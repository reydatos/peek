import Observation
import PeekCore
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    /// The pack file of PEEK. `project.yml` declares this type for the app.
    static let peekPack = UTType(exportedAs: "com.a8media.peek.pack")
}

/// The pack file that the customer opened. The customer confirms before the app adds the pack.
@Observable
final class PackImport {
    /// The pack that waits for the answer of the customer.
    private(set) var pending: PackFile?
    /// True when a file was not usable, or storage refused the pack.
    var isFailed = false
    private let userPacks: UserPacks

    init(userPacks: UserPacks) {
        self.userPacks = userPacks
    }

    func open(_ url: URL) async {
        if let file = await userPacks.readPackFile(at: url) {
            pending = file
        } else {
            isFailed = true
        }
    }

    /// Adds the pack. The caller gives the file: the alert clears `pending` when it closes, before this runs.
    func confirm(_ file: PackFile) async {
        pending = nil
        if await userPacks.add(file) == nil {
            isFailed = true
        }
    }

    func cancel() {
        pending = nil
    }
}

/// The question "Add this pack?" and the message for a file that is not usable.
/// These are on the side of the photographer only.
struct PackImportAlerts: ViewModifier {
    @Environment(PackImport.self) private var packImport: PackImport?

    func body(content: Content) -> some View {
        content
            .alert(
                Text(.addPackTitle),
                isPresented: Binding(get: { packImport?.pending != nil }, set: {
                    if !$0 {
                        packImport?.cancel()
                    }
                }),
                presenting: packImport?.pending
            ) { file in
                Button { Task { await packImport?.confirm(file) } } label: { Text(.addPack) }
                Button(role: .cancel) { packImport?.cancel() } label: { Text(.cancel) }
            } message: { file in
                Text(.addPackMessage(file.name))
            }
            .alert(
                Text(.importFailedTitle),
                isPresented: Binding(get: { packImport?.isFailed ?? false }, set: { packImport?.isFailed = $0 })
            ) {
                Button(role: .cancel) {} label: { Text(.ok) }
            } message: {
                Text(.importFailedMessage)
            }
    }
}
