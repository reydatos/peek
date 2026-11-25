import PeekCore
import SwiftUI

/// The capture interface on the inner display.
///
/// Review is a state of this view, not a push or a sheet. The system shows the outer accessory
/// only while this view is onscreen and the capture session runs.
struct BoothView: View {
    @State private var model: BoothSessionModel
    @State private var posePicker: PosePickerRequest?
    @State private var packToConfirm: PosePack?
    /// A locked pack that the photographer chose. The unlock sheet shows over the pose library.
    @State private var packToUnlock: PosePack?
    /// The pack that the unlock sheet unlocked. It is chosen when the sheet has closed.
    @State private var unlockedPack: PosePack?
    @Environment(Entitlements.self) private var entitlements: Entitlements?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(UserPacks.self) private var userPacks
    @State private var isEditingPack = false

    private let resumesDraft: Bool

    init(request: BoothRequest, catalog: PoseCatalog) {
        resumesDraft = request.resumesDraft
        _model = State(initialValue: BoothSessionModel(
            capture: CaptureService(),
            packID: request.packID,
            catalog: catalog,
            drafts: BoothDraftStore.shared,
            analyzePose: { await PoseAnalyzer.signature(of: $0) }
        ))
    }

    var body: some View {
        BoothLayout(model: model, actions: BoothActions(
            // The poses button opens the pack cards at once. The booth has no pose tray (owner decision, 2026-11-15).
            showPoses: { posePicker = PosePickerRequest() }
        ))
        .background(PeekTheme.page)
        // The duet preview is a state of the booth, so the outer display stays.
        .overlay {
            if let url = model.duetPreview {
                DuetPreviewView(model: model, url: url)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // The automatic shutter starts no shot while the pose library, the pack editor, or the unlock sheet
        // covers the booth.
        .onChange(of: posePicker != nil || model.unlockRequest != nil, initial: true) { _, isCovered in
            model.match.isBlocked = isCovered
        }
        .sheet(item: $posePicker) { _ in
            // The warning shows on the sheet, so the photographer decides before the sheet closes.
            PoseLibraryView(packWithShotsID: model.hasShots ? model.packID : nil) { pack in
                choose(pack)
            } onNewPack: {
                isEditingPack = true
            } onDelete: { pack in
                // The dialog of the library told the photographer that the shots of this pack go away.
                // The booth leaves a pack before the pack goes away, so each slot keeps a pose that exists.
                if model.packID == pack.id {
                    model.loadPack(PoseLibrary.freeID)
                }
                Task { await userPacks.delete(packID: pack.id) }
            }
            .sheet(item: $packToUnlock, onDismiss: {
                // After a purchase the pack goes the usual way: a set with shots still asks first.
                if let pack = unlockedPack {
                    unlockedPack = nil
                    choose(pack)
                }
            }) { pack in
                if let entitlements {
                    UnlockSheet(pack: pack, entitlements: entitlements) {
                        unlockedPack = pack
                        packToUnlock = nil
                    }
                }
            }
            .sheet(isPresented: $isEditingPack) {
                PackEditorView(model: model) { draft in
                    guard await userPacks.save(draft) != nil else { return false }
                    isEditingPack = false
                    return true
                } onCancel: {
                    isEditingPack = false
                }
            }
            .confirmationDialog(
                Text(.discardShotsTitle),
                isPresented: Binding(
                    get: { packToConfirm != nil },
                    set: {
                        if !$0 {
                            packToConfirm = nil
                        }
                    }
                ),
                titleVisibility: .visible,
                presenting: packToConfirm
            ) { pack in
                Button(role: .destructive) { load(pack) } label: { Text(.discardShots) }
                Button(role: .cancel) {} label: { Text(.cancel) }
            } message: { _ in
                Text(.discardShotsMessage)
            }
        }
        // New set with a pack that is locked now (D5). Buying it starts the new set; Close keeps the set.
        .sheet(item: $model.unlockRequest) { pack in
            if let entitlements {
                UnlockSheet(pack: pack, entitlements: entitlements) {
                    model.unlockRequest = nil
                    model.loadPack(pack.id)
                }
            }
        }
        .modifier(OuterDisplayAccessory(model: model))
        .task {
            model.isUnlocked = { [entitlements] pack in entitlements?.isUnlocked(pack) ?? true }
            if resumesDraft {
                await model.restoreDraft()
            } else {
                await model.discardStoredDraft()
            }
            await model.startCamera()
            // The app opens on the viewfinder, so a set that came back from storage continues with no extra step.
            model.continueIfWaiting()
        }
        .onDisappear { model.stopCamera() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // The booth is the first screen, so it has no other way to start the camera again.
                Task {
                    await model.retryCamera()
                    model.continueIfWaiting()
                }
            } else {
                model.send(.pause(.interruption))
            }
        }
    }

    /// A locked pack opens the unlock sheet; a set with shots asks before it discards them (3A, D5).
    private func choose(_ pack: PosePack) {
        switch PackChoice(isUnlocked: entitlements?.isUnlocked(pack) ?? true, hasShots: model.hasShots) {
        case .unlock: packToUnlock = pack
        case .confirmDiscard: packToConfirm = pack
        case .load: load(pack)
        }
    }

    private func load(_ pack: PosePack) {
        model.loadPack(pack.id)
        packToConfirm = nil
        posePicker = nil
    }
}
