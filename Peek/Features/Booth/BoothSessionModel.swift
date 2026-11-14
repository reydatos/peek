import Foundation
import Observation
import PeekCore
import UIKit

/// The one model that drives both displays. The outer accessory reads the same instance.
@Observable
final class BoothSessionModel {
    private(set) var state: BoothState
    private(set) var packID: String
    private(set) var cameraStatus: CameraStatus = .idle
    private(set) var deviceID: String?
    private(set) var isOuterDisplayAvailable = false
    var isOuterDisplayEnabled = true
    /// PRD open decision: default mirroring. Off until hardware tests decide.
    var isOuterPreviewMirrored = false

    /// The layout of the finished picture. A change draws the picture again.
    var layout: PeekCore.Layout = .verticalStrip {
        didSet {
            guard layout != oldValue else { return }
            strip = nil
            saveStatus = .idle
            updateStrip()
            persist()
        }
    }

    /// The finished strip. It exists only while the session is complete.
    private(set) var strip: UIImage?
    private(set) var saveStatus: SaveStatus = .idle

    private(set) var countdownTask: Task<Void, Never>?
    private(set) var captureTask: Task<Void, Never>?
    /// The last storage operation. Each operation waits for the one before it.
    private(set) var persistTask: Task<Void, Never>?

    let capture: any CaptureProviding
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
    private let reducer = BoothReducer()
    private let sleep: @Sendable (Duration) async throws -> Void

    init(
        capture: any CaptureProviding,
        packID: String = PoseLibrary.classicID,
        cueIDs: [String]? = nil,
        saver: any PhotoSaving = PhotoLibrarySaver(),
        drafts: (any DraftStore)? = nil,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.capture = capture
        self.saver = saver
        self.drafts = drafts
        self.sleep = sleep
        self.packID = packID
        state = BoothState(cueIDs: cueIDs ?? PoseLibrary.cueIDs(forPack: packID))
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
        self.packID = packID
        state = BoothState(cueIDs: PoseLibrary.cueIDs(forPack: packID), countdown: state.countdown)
        if cameraStatus == .running {
            send(.finishSetup)
        }
    }

    /// True when a pack change discards work: an accepted shot, or a shot in review.
    var hasShots: Bool {
        if case .review = state.phase {
            return true
        }
        return state.slots.contains { $0.acceptedTake != nil }
    }

    var pack: PosePack? {
        PoseLibrary.packs.first { $0.id == packID }
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
        PoseLibrary.cue(for: state.currentSlot.cueID)
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
        isOuterDisplayAvailable && isOuterDisplayEnabled
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
            cameraStatus = .running
            send(.finishSetup)
        } catch let error as CaptureError {
            cameraStatus = CameraStatus(error)
        } catch {
            cameraStatus = .failed
        }
    }

    func stopCamera() {
        send(.pause(.interruption))
        cameraStatus = .idle
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
        if state.slots != slots || !takesToDelete.isEmpty {
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
        let slots = record.slots.map { slot in
            Slot(
                id: slot.id,
                cueID: slot.cueID,
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
        packID = record.templateID
        var restored = record
        restored.slots = slots
        state = BoothState(restoring: restored)
        // The layout changes last: its observer stores the session, and the state is now the draft.
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
        guard drafts != nil else { return }
        let takes = state.slots.flatMap { [$0.acceptedTake, $0.previousTake] }.compactMap(\.self)
        guard hasDraft || !takes.isEmpty else {
            takesToDelete.removeAll()
            return
        }
        hasDraft = true
        let media = takes.filter { !stored.contains($0.id) }.compactMap { take in
            originals[take.id].map { (take, $0) }
        }
        stored.formUnion(media.map(\.0.id))
        let deletes = takesToDelete.filter { stored.contains($0.id) }
        stored.subtract(deletes.map(\.id))
        takesToDelete.removeAll()
        let record = SessionRecord(
            id: draftID,
            templateID: packID,
            templateVersion: 1,
            countdown: state.countdown,
            layout: layout,
            slots: state.slots
        )
        enqueue { [weak self] drafts in
            do {
                for (take, data) in media {
                    try await drafts.writeMedia(data, for: take)
                }
                try await drafts.commit(record)
                for take in deletes {
                    try await drafts.deleteMedia(for: take)
                }
            } catch {
                // The record in storage is still the last good one. The next change writes the bytes again.
                self?.stored.subtract(media.map(\.0.id))
            }
        }
    }

    private func deleteDraft() {
        let id = draftID
        draftID = UUID()
        hasDraft = false
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
            if strip == nil {
                strip = StripRenderer.render(state.slots.compactMap { image(for: $0) }, layout: layout)
            }
        } else if strip != nil {
            strip = nil
            saveStatus = .idle
        }
    }

    /// Saves the strip to Photos. The system asks for add-only access the first time.
    func saveStrip() async {
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
