import Foundation
import Observation
import PeekCore
import SwiftUI
import UIKit

/// The one model that drives both displays. The outer accessory reads the same instance.
@Observable
final class BoothSessionModel {
    private(set) var state: BoothState
    private(set) var packID: String
    private(set) var cameraStatus: CameraStatus = .idle
    private(set) var deviceID: String?
    /// The camera in use. The front camera makes a group selfie: the people in the photo read the inner display.
    private(set) var cameraFacing: CameraFacing = .rear
    private var isSwitchingCamera = false
    /// The zoom factors of the camera in use. With one value or none, the booth shows no zoom control.
    private(set) var zoomFactors: [Double] = []
    private(set) var zoom = 1.0
    private(set) var isOuterDisplayAvailable = false
    /// True after the photographer continued on one screen. The outer display then waits for an explicit action.
    private(set) var isOnOneScreen = false
    var isOuterDisplayEnabled = true
    /// PRD open decision: default mirroring. Off until hardware tests decide.
    var isOuterPreviewMirrored = false

    /// The layout of the finished picture. A change draws the picture again.
    var layout: PeekCore.Layout = .verticalStrip {
        didSet {
            if layout != oldValue {
                redrawStrip()
            }
        }
    }

    /// The paper color of the finished picture. A change draws the picture again.
    var frame: FrameColor = .cream {
        didSet {
            if frame != oldValue {
                redrawStrip()
            }
        }
    }

    private func redrawStrip() {
        stripTask?.cancel()
        stripTask = nil
        strip = nil
        saveStatus = .idle
        updateStrip()
        persist()
    }

    /// The finished strip. It exists only while the session is complete.
    private(set) var strip: UIImage?
    /// The draw of the strip. It runs off the main actor.
    private(set) var stripTask: Task<Void, Never>?
    private(set) var saveStatus: SaveStatus = .idle
    /// True when storage does not hold the shots of this session. They do not come back after the app closes.
    private(set) var isDraftUnsaved = false

    private(set) var countdownTask: Task<Void, Never>?
    private(set) var captureTask: Task<Void, Never>?
    /// The last storage operation. Each operation waits for the one before it.
    private(set) var persistTask: Task<Void, Never>?

    let capture: any CaptureProviding
    /// The one preview view of the inner display. The layouts of the booth share it.
    let preview = PreviewHolder()
    private let saver: any PhotoSaving
    private var images: [Take.ID: UIImage] = [:]
    /// The camera's bytes for each take, so a save keeps the full quality.
    private var originals: [Take.ID: Data] = [:]
    private let drafts: (any DraftStore)?
    private var draftID = UUID()
    /// True when storage holds a record for this session.
    private var hasDraft = false
    private var didRestore = false
    /// The takes that have their bytes in storage.
    private var stored: Set<Take.ID> = []
    private var takesToDelete: [Take] = []
    /// The built-in packs and the packs of the customer.
    let catalog: PoseCatalog
    /// The pose match: the live score, the automatic shutter, and the score of the shot in review.
    let match: PoseMatch
    private let reducer = BoothReducer()
    private let sleep: @Sendable (Duration) async throws -> Void

    init(
        capture: any CaptureProviding,
        packID: String = PoseLibrary.classicID,
        cueIDs: [String]? = nil,
        catalog: PoseCatalog = PoseCatalog(),
        saver: any PhotoSaving = PhotoLibrarySaver(),
        drafts: (any DraftStore)? = nil,
        analyzePose: @escaping @Sendable (UIImage) async -> PoseSignature? = { _ in nil },
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.capture = capture
        self.saver = saver
        self.drafts = drafts
        self.sleep = sleep
        self.catalog = catalog
        // A pack that the catalog does not have gives the classic booth.
        let pack = catalog.packOrClassic(id: packID)
        self.packID = pack.id
        state = BoothState(cueIDs: cueIDs ?? pack.cues.map(\.id))
        // The default finds no body shape, so tests stay isolated. The app passes the Vision analyzer.
        match = PoseMatch(capture: capture, analyze: analyzePose)
        // The automatic shutter sends the same event as the shutter button. The reducer accepts it in `ready` only.
        match.onHold = { [weak self] in self?.send(.start) }
    }

    /// Gives the state of the booth to the pose match.
    private func updateMatch() {
        var reviewImage: UIImage?
        if case let .review(take) = state.phase {
            reviewImage = images[take.id]
        }
        match.update(cue: currentCue, phase: state.phase, isCameraRunning: cameraStatus == .running, reviewImage: reviewImage)
    }

    /// Starts a new four-shot session with the poses of a pack. The shots of the old session are discarded.
    func loadPack(_ packID: String) {
        countdownTask?.cancel()
        captureTask?.cancel()
        images.removeAll()
        originals.removeAll()
        strip = nil
        saveStatus = .idle
        deleteDraft()
        isOnOneScreen = false
        let pack = catalog.packOrClassic(id: packID)
        self.packID = pack.id
        state = BoothState(cueIDs: pack.cues.map(\.id), countdown: state.countdown)
        if cameraStatus == .running {
            send(.finishSetup)
        }
        updateMatch()
    }

    /// True when a pack change discards work: an accepted shot, or a shot in review.
    var hasShots: Bool {
        if case .review = state.phase {
            return true
        }
        return state.slots.contains { $0.acceptedTake != nil }
    }

    var pack: PosePack? {
        catalog.pack(id: packID)
    }

    var packCues: [PoseCue] {
        pack?.cues ?? []
    }

    /// Changes the pose of the current shot. The reducer accepts this in `ready` only.
    func swapPose(to cueID: String) {
        send(.swapCue(cueID))
    }

    /// Changes the pose of the current shot to the next or the previous pose of the pack. It wraps at the ends.
    func stepPose(by offset: Int) {
        let ids = packCues.map(\.id)
        guard !ids.isEmpty else { return }
        let index = ids.firstIndex(of: state.currentSlot.cueID) ?? 0
        swapPose(to: ids[((index + offset) % ids.count + ids.count) % ids.count])
    }

    /// The pose of the current slot. Nil when the cue ID is not in the library.
    var currentCue: PoseCue? {
        catalog.cue(for: state.currentSlot.cueID)
    }

    // MARK: The clip over the camera picture

    /// How the clip of the current pose shows over the camera picture. This is a state of the screen, not of
    /// the session, so the reducer and the draft do not have it.
    private(set) var clipLook = ClipLook.corner

    /// True when the photographer can play the clip of the pose: the booth waits for a shot, and the pose has a clip.
    var canPlayClip: Bool {
        state.phase == .ready && currentCue?.clipURL != nil
    }

    /// The look that the screen shows now. Out of live framing, the clip does not show.
    var shownClipLook: ClipLook {
        canPlayClip ? clipLook : .corner
    }

    /// A tap on the pose picture: it opens the large clip, or closes the large clip or the ghost.
    func togglePoseClip() {
        guard canPlayClip else { return }
        clipLook = clipLook == .corner ? .large : .corner
    }

    func setClipLook(_ look: ClipLook) {
        guard canPlayClip || look == .corner else { return }
        clipLook = look
        // The ghost is over the live picture. The people in the photo must see that picture on the outer display,
        // not the pose reference.
        if look == .ghost, isOuterDisplayPresenting, state.subjectView != .live {
            send(.showSubject(.live))
        }
    }

    #if DEBUG
        /// The ghost transparency that the owner tries on the phone. The release build has the fixed value.
        var ghostOpacity = PoseClipTuning.ghostOpacity
    #else
        let ghostOpacity = PoseClipTuning.ghostOpacity
    #endif

    /// The numbers of the slots that have no accepted shot, in slot order.
    var openSlotNumbers: [Int] {
        state.slots.filter { $0.acceptedTake == nil }.map { $0.id.index + 1 }
    }

    /// The accepted shots in slot order, for a picture of the finished set.
    var finishedShots: [UIImage] {
        state.slots.compactMap { image(for: $0) }
    }

    /// The accepted shot of a slot, for the slot rail.
    func image(for slot: Slot) -> UIImage? {
        slot.acceptedTake.flatMap { images[$0.id] }
    }

    var countdown: CountdownLength {
        get { state.countdown }
        set {
            state.countdown = newValue
            persist()
        }
    }

    /// True when the system shows the accessory on the outer display.
    var isOuterDisplayPresenting: Bool {
        isOuterDisplayAvailable && isOuterDisplayWanted
    }

    /// True when the booth asks the system for the outer display.
    var isOuterDisplayWanted: Bool {
        isOuterDisplayEnabled && !isSelfie && !isOnOneScreen
    }

    /// True when the outer display came back after the photographer continued on one screen.
    /// The photographer then decides when the people in the photo get their view back.
    var canRestoreOuterDisplay: Bool {
        isOnOneScreen && isOuterDisplayAvailable && isOuterDisplayEnabled && !isSelfie
    }

    func restoreOuterDisplay() {
        isOnOneScreen = false
    }

    /// Continues a paused session. After the loss of the outer display, the session continues on one screen.
    func resume() {
        if case .paused(_, .outerDisplayLost) = state.phase, !isOuterDisplayAvailable {
            isOnOneScreen = true
        }
        send(.resume)
    }

    /// The accent of the pack: the reference frame and the current slot.
    var accent: Color {
        pack?.accent ?? PeekTheme.strong
    }

    /// The color of a label on the accent. A pack color is the same in light and in dark, so its label is dark.
    /// The classic booth, a customer pack, and a set with no pack have the strong color as accent, so their label
    /// is its opposite.
    var onAccent: Color {
        guard let pack, pack.category != .classic, pack.category != .mine else { return PeekTheme.onStrong }
        return PeekTheme.paperInk
    }

    var isSelfie: Bool {
        cameraFacing == .front
    }

    /// Changes between the rear camera and the front camera. The booth accepts this only while it waits for a shot.
    /// The accepted shots stay. When the change fails, the booth keeps the camera it has.
    func flipCamera() async {
        guard cameraStatus == .running, state.phase == .ready, !isSwitchingCamera else { return }
        isSwitchingCamera = true
        defer { isSwitchingCamera = false }
        let next = cameraFacing.opposite
        guard let id = try? await capture.selectCamera(next) else { return }
        // The facing changes first, so the outer display closes with no "outer display lost" pause.
        cameraFacing = next
        deviceID = id
        await loadZoom()
    }

    /// Reads the zoom factors of the camera in use, and sets the camera to 1.
    /// So the model and the camera agree after the booth opens again and after a flip.
    private func loadZoom() async {
        zoomFactors = await capture.zoomFactors()
        if zoomFactors.count > 1 {
            try? await capture.setZoom(1)
        }
        zoom = 1
    }

    /// Changes the zoom. The booth accepts this only while it waits for a shot.
    /// When the change fails, the booth keeps the zoom it has.
    func setZoom(_ factor: Double) async {
        guard cameraStatus == .running, state.phase == .ready, zoomFactors.contains(factor) else { return }
        guard await (try? capture.setZoom(factor)) != nil else { return }
        zoom = factor
    }

    /// The still to show in place of the live frame: the take in review, or the strip when complete.
    var stillImage: UIImage? {
        switch state.phase {
        case let .review(take): images[take.id]
        case .complete: strip
        default: nil
        }
    }

    func startCamera() async {
        guard cameraStatus == .idle else { return }
        cameraStatus = .starting
        do {
            deviceID = try await capture.start()
            await loadZoom()
            cameraStatus = .running
            send(.finishSetup)
        } catch let error as CaptureError {
            cameraStatus = CameraStatus(error)
        } catch {
            cameraStatus = .failed
        }
    }

    /// Continues a set that waits at "ready" after the app came back or after a draft came back.
    /// The shutter is then available with no extra step. A countdown does not start again by itself:
    /// a pause in a countdown waits for the photographer.
    func continueIfWaiting() {
        guard case let .paused(resumeTo: .ready, reason: reason) = state.phase,
              reason == .interruption || reason == .recovered
        else { return }
        send(.resume)
    }

    /// Starts the camera again after it did not start: no permission, no camera, or a fault.
    func retryCamera() async {
        switch cameraStatus {
        case .denied, .unavailable, .failed:
            cameraStatus = .idle
            await startCamera()
        case .idle, .starting, .running:
            break
        }
    }

    func stopCamera() {
        send(.pause(.interruption))
        cameraStatus = .idle
        updateMatch()
        Task { [capture] in await capture.stop() }
    }

    func setOuterDisplayAvailable(_ isAvailable: Bool) {
        let wasPresenting = isOuterDisplayPresenting
        isOuterDisplayAvailable = isAvailable
        if wasPresenting, !isOuterDisplayPresenting {
            send(.outerDisplayLost)
        }
    }

    func send(_ event: BoothEvent) {
        let slots = state.slots
        for effect in reducer.reduce(&state, event) {
            run(effect)
        }
        updateStrip()
        updateMatch()
        // The large clip covers the picture, so it closes when the shot starts. The ghost stays on for the next pose.
        if clipLook == .large, state.phase != .ready {
            clipLook = .corner
        }
        // While the draft is not stored, each event stores it again.
        if state.slots != slots || !takesToDelete.isEmpty || isDraftUnsaved {
            persist()
        }
    }

    // MARK: Drafts

    /// Brings back the draft from storage. Call this before the camera starts.
    /// The reducer then shows the finished picture, or waits for an explicit resume.
    func restoreDraft() async {
        guard let drafts, !didRestore, state.phase == .setup else { return }
        didRestore = true
        guard let record = try? await drafts.loadDraft(), !record.slots.isEmpty else { return }
        var loaded: [Take.ID: Data] = [:]
        for take in record.slots.flatMap({ [$0.acceptedTake, $0.previousTake] }).compactMap(\.self) {
            if let data = try? await drafts.media(for: take), UIImage(data: data) != nil {
                loaded[take.id] = data
            }
        }
        // A customer can remove a pack or a pose that the draft still names. Such a slot gets the classic pose
        // of its position, so each slot has a pose that the catalog knows.
        let classicIDs = catalog.classicPack.cues.map(\.id)
        let slots = record.slots.enumerated().map { index, slot in
            Slot(
                id: slot.id,
                cueID: catalog.cue(for: slot.cueID) == nil ? classicIDs[index % classicIDs.count] : slot.cueID,
                acceptedTake: slot.acceptedTake.flatMap { loaded[$0.id] == nil ? nil : $0 },
                previousTake: slot.previousTake.flatMap { loaded[$0.id] == nil ? nil : $0 }
            )
        }
        guard state.phase == .setup, slots.contains(where: { $0.acceptedTake != nil }) else { return }
        originals = loaded
        images = loaded.compactMapValues(UIImage.init(data:))
        stored = Set(loaded.keys)
        draftID = record.id
        hasDraft = true
        packID = catalog.packOrClassic(id: record.templateID).id
        var restored = record
        restored.slots = slots
        state = BoothState(restoring: restored)
        // The layout and the frame change last: an observer stores the session, and the state is now the draft.
        frame = record.frame
        layout = record.layout
    }

    /// Removes the draft in storage. Call this before the camera starts, when the photographer starts a new booth.
    func discardStoredDraft() async {
        guard let drafts, !didRestore, state.phase == .setup else { return }
        didRestore = true
        if let record = try? await drafts.loadDraft() {
            try? await drafts.deleteDraft(record.id)
        }
    }

    /// Stores the session: the bytes of each new take first, then the record, then the deletes.
    private func persist() {
        // The operation holds the model, so the write completes after the booth view goes away.
        enqueue { drafts in await self.store(in: drafts) }
    }

    /// One storage operation. It reads the session when it runs, not when it was queued.
    /// Thus an operation that follows a failed one writes the bytes that the failed one did not.
    private func store(in drafts: any DraftStore) async {
        let takes = state.slots.flatMap { [$0.acceptedTake, $0.previousTake] }.compactMap(\.self)
        guard hasDraft || !takes.isEmpty else {
            takesToDelete.removeAll()
            return
        }
        hasDraft = true
        let id = draftID
        let media = takes.filter { !stored.contains($0.id) }.compactMap { take in
            originals[take.id].map { (take, $0) }
        }
        let deletes = takesToDelete.filter { stored.contains($0.id) }
        stored.subtract(deletes.map(\.id))
        takesToDelete.removeAll()
        let record = SessionRecord(
            id: id,
            templateID: packID,
            templateVersion: 1,
            countdown: state.countdown,
            layout: layout,
            frame: frame,
            slots: state.slots
        )
        do {
            for (take, data) in media {
                try await drafts.writeMedia(data, for: take)
            }
            try await drafts.commit(record)
        } catch {
            // The record in storage is still the last good one. The next event stores the session again.
            if draftID == id {
                isDraftUnsaved = true
            }
            return
        }
        // A new session can start during the writes. Its status is not the status of this record.
        if draftID == id {
            stored.formUnion(media.map(\.0.id))
            isDraftUnsaved = false
        }
        for take in deletes {
            // A media file that stays is not a fault: `loadDraft` removes the files that the record does not use.
            try? await drafts.deleteMedia(for: take)
        }
    }

    private func deleteDraft() {
        let id = draftID
        draftID = UUID()
        hasDraft = false
        isDraftUnsaved = false
        stored.removeAll()
        takesToDelete.removeAll()
        enqueue { drafts in try? await drafts.deleteDraft(id) }
    }

    /// Runs the storage operations one at a time, in order.
    private func enqueue(_ operation: @escaping (any DraftStore) async -> Void) {
        guard let drafts else { return }
        persistTask = Task { [persistTask] in
            await persistTask?.value
            await operation(drafts)
        }
    }

    var isComplete: Bool {
        state.phase == .complete
    }

    /// Makes the strip when the last shot is accepted. Drops it when a retake reopens the session.
    private func updateStrip() {
        if isComplete {
            guard strip == nil, stripTask == nil else { return }
            let shots = state.slots.compactMap { image(for: $0) }
            stripTask = Task { [layout, frame] in
                let picture = await StripRenderer.renderInBackground(shots, layout: layout, style: .paper(frame))
                // A retake, a new layout, or a new set cancels this draw.
                guard !Task.isCancelled else { return }
                strip = picture
                stripTask = nil
            }
        } else {
            stripTask?.cancel()
            stripTask = nil
            if strip != nil {
                strip = nil
                saveStatus = .idle
            }
        }
    }

    /// Saves the strip to Photos. The system asks for add-only access the first time.
    func saveStrip() async {
        await stripTask?.value
        await save([strip?.jpegData(compressionQuality: 1)].compactMap(\.self))
    }

    /// Saves each accepted shot to Photos, with the camera's bytes.
    func saveShots() async {
        await save(state.slots.compactMap { $0.acceptedTake.flatMap { originals[$0.id] } })
    }

    private func save(_ photos: [Data]) async {
        guard !photos.isEmpty, saveStatus != .saving else { return }
        saveStatus = .saving
        do {
            try await saver.save(photos)
            saveStatus = .saved
            // The app opens on the viewfinder. A finished set that is in Photos does not come back at the next launch.
            if isComplete {
                deleteDraft()
            }
        } catch PhotoSaveError.denied {
            saveStatus = .denied
        } catch {
            saveStatus = .failed
        }
    }

    /// Starts a new set with the same pack. The shots of the old set are discarded.
    func startNewSet() {
        loadPack(packID)
    }

    private func run(_ effect: BoothEffect) {
        switch effect {
        case let .startCountdown(seconds):
            countdownTask?.cancel()
            countdownTask = Task { [sleep] in
                for _ in 0 ..< seconds {
                    do { try await sleep(.seconds(1)) } catch { return }
                    guard !Task.isCancelled else { return }
                    send(.tick)
                }
            }

        case .stopCountdown:
            countdownTask?.cancel()
            countdownTask = nil

        case let .capture(token, slotID):
            captureTask = Task {
                do {
                    let photo = try await capture.capturePhoto()
                    guard let image = UIImage(data: photo.data) else { throw CaptureError.captureFailed }
                    let take = Take(
                        slotID: slotID,
                        token: token,
                        assetName: token.rawValue.uuidString,
                        rotationAngle: photo.rotationAngle
                    )
                    images[take.id] = image
                    originals[take.id] = photo.data
                    send(.captureSucceeded(token, take))
                } catch {
                    send(.captureFailed(token, CaptureFailure(message: String(describing: error))))
                }
            }

        case let .discardTake(take):
            images[take.id] = nil
            originals[take.id] = nil
            takesToDelete.append(take)
        }
    }
}
