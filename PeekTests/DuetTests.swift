import AVFoundation
import Foundation
@testable import Peek
import PeekCore
import Testing

@MainActor
struct DuetTests {
    private let capture = FakeCapture()

    /// A booth at "ready" with a pack of the customer. Each pose has a clip.
    private func booth(isDuetOn: Bool = true) async -> BoothSessionModel {
        let still = URL(filePath: "/nowhere/still.jpg")
        let clip = URL(filePath: "/nowhere/clip.mov")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: clip),
            PoseCue(id: "user-1-b", name: "Two", still: still, clip: clip),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: FakeSaver(), sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = isDuetOn
        return model
    }

    private func shoot(_ model: BoothSessionModel) async {
        model.send(.start)
        await model.countdownTask?.value
        await model.captureTask?.value
        // The clip goes to its shot after the recording ends.
        for _ in 0 ..< 5 {
            await Task.yield()
        }
    }

    private func exists(_ url: URL?) -> Bool {
        url.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    @Test func theBoothRecordsTheCountdownOfEachShot() async {
        let model = await booth()
        #expect(model.hasPoseClips)
        await shoot(model)
        model.send(.accept)
        let clip = model.attemptClip(for: model.state.slots[0])
        #expect(exists(clip))
        // The clip has the length of the countdown, so it ends at the shot.
        #expect(await capture.clipDurations == [Double(model.countdown.seconds)])
        #expect(!model.isRecordingAttempt)
        model.startNewSet()
        #expect(!exists(clip))
    }

    @Test func theBoothRecordsNothingWithTheSwitchOff() async {
        let model = await booth(isDuetOn: false)
        await shoot(model)
        model.send(.accept)
        #expect(model.attemptClip(for: model.state.slots[0]) == nil)
        #expect(await capture.clipCount == 0)
    }

    @Test func aBuiltInPackHasNoDuet() async {
        let model = BoothSessionModel(capture: capture, saver: FakeSaver(), sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = true
        #expect(!model.hasPoseClips)
        await shoot(model)
        #expect(await capture.clipCount == 0)
    }

    @Test func aRecordingFaultDoesNotStopTheShot() async {
        let model = await booth()
        await capture.failClips(true)
        await shoot(model)
        guard case .review = model.state.phase else {
            Issue.record("the shot did not reach review")
            return
        }
        model.send(.accept)
        #expect(model.attemptClip(for: model.state.slots[0]) == nil)
        #expect(!model.isRecordingAttempt)
    }

    @Test func aCancelOfTheCountdownRemovesTheClip() async {
        // The countdown waits, so the cancel comes before the shot.
        let still = URL(filePath: "/nowhere/still.jpg")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: URL(filePath: "/nowhere/clip.mov")),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: FakeSaver(), sleep: { _ in
            try await Task.sleep(for: .seconds(600))
        })
        await model.startCamera()
        model.isDuetOn = true
        model.send(.start)
        #expect(model.isRecordingAttempt)
        let task = model.attemptTask
        let url = await task?.value
        #expect(exists(url))
        model.send(.cancel)
        #expect(!model.isRecordingAttempt)
        for _ in 0 ..< 5 {
            await Task.yield()
        }
        #expect(!exists(url))
    }

    @Test func aRetakeRemovesTheClipOfTheOldShot() async {
        let model = await booth()
        await shoot(model)
        model.send(.accept)
        let first = model.attemptClip(for: model.state.slots[0])
        #expect(exists(first))
        model.send(.retake(model.state.slots[0].id))
        await shoot(model)
        model.send(.accept)
        let second = model.attemptClip(for: model.state.slots[0])
        #expect(exists(second))
        #expect(second != first)
    }

    @Test func aFinishedSetHasADuetOnlyForThePosesWithTheTwoClips() async {
        let model = await booth()
        await shoot(model)
        model.send(.accept)
        #expect(model.duetSegments.isEmpty, "the set is not finished")
        // The second shot has no clip of the people.
        model.isDuetOn = false
        await shoot(model)
        model.send(.accept)
        #expect(model.isComplete)
        #expect(model.duetSegments.count == 1)
        #expect(model.duetSegments[0].title.contains("1"))
    }

    @Test func aDuetThatTheAppCanNotMakeGivesAFaultAndSavesNothing() async {
        let saver = FakeSaver()
        let still = URL(filePath: "/nowhere/still.jpg")
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: still, clip: URL(filePath: "/nowhere/clip.mov")),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: saver, sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = true
        await shoot(model)
        model.send(.accept)
        #expect(model.duetSegments.count == 1)
        // The clips of this test are not video.
        await model.makeDuet()
        #expect(model.saveStatus == .failed)
        #expect(model.duetPreview == nil)
        #expect(model.duetProgress == nil)
        #expect(await saver.savedVideos.isEmpty)
    }

    /// A real clip of one gray value, 480 x 640, written with a writer that waits for the encoder.
    private static func realClip(seconds: Double = 0.5) async throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 480, AVVideoHeightKey: 640,
        ])
        input.expectsMediaDataInRealTime = false
        writer.add(input)
        #expect(writer.startWriting())
        writer.startSession(atSourceTime: CMTime(seconds: 100, preferredTimescale: 600))
        for index in 0 ..< Int(seconds * 30) {
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(1))
            }
            #expect(try input.append(ClipRecorderTests().frame(width: 480, height: 640, at: Double(index) / 30, fill: 0x80)))
        }
        input.markAsFinished()
        writer.endSession(atSourceTime: CMTime(seconds: 100 + seconds, preferredTimescale: 600))
        await writer.finishWriting()
        try #require(writer.status == .completed)
        return url
    }

    /// A finished set of one pose whose clips are real video.
    private func finishedSet(saver: any PhotoSaving) async throws -> BoothSessionModel {
        let clip = try await Self.realClip()
        await capture.setClipSource(clip)
        let catalog = PoseCatalog(userPacks: [PosePack(id: "user-1", name: "Friday night", cues: [
            PoseCue(id: "user-1-a", name: "One", still: URL(filePath: "/nowhere/still.jpg"), clip: clip),
        ])])
        let model = BoothSessionModel(capture: capture, packID: "user-1", catalog: catalog, saver: saver, sleep: { _ in })
        await model.startCamera()
        model.isDuetOn = true
        await shoot(model)
        model.send(.accept)
        try #require(model.isComplete)
        return model
    }

    @Test func aMadeDuetShowsInThePreviewAndGoesToPhotosOnlyOnSave() async throws {
        let saver = FakeSaver()
        let model = try await finishedSet(saver: saver)

        await model.makeDuet()
        let url = try #require(model.duetPreview)
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(model.saveStatus == .idle)
        #expect(model.duetProgress == nil)
        #expect(await saver.savedVideos.isEmpty, "nothing goes to Photos before Save")

        // Save keeps the preview, so the customer can still share the video.
        await model.saveDuetPreview()
        #expect(model.saveStatus == .saved)
        #expect(await saver.savedVideos.count == 1)
        #expect(model.duetPreview == url)

        // Close removes the video.
        model.closeDuetPreview()
        #expect(model.duetPreview == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(model.saveStatus == .idle)
    }

    @Test func thePreviewDoesNotCloseWhileTheVideoGoesToPhotos() async throws {
        // A saver that waits in the middle of the save until the test lets it go, then reads the video.
        actor GatedSaver: PhotoSaving {
            private var gate: CheckedContinuation<Void, Never>?
            private(set) var isWaiting = false
            private(set) var bytes = 0

            func save(_: [Data]) throws {}

            func saveVideo(at url: URL) async throws {
                isWaiting = true
                await withCheckedContinuation { gate = $0 }
                bytes = try Data(contentsOf: url).count
            }

            func open() {
                gate?.resume()
                gate = nil
            }
        }
        let saver = GatedSaver()
        let model = try await finishedSet(saver: saver)
        await model.makeDuet()
        let url = try #require(model.duetPreview)
        let save = Task { await model.saveDuetPreview() }
        while await !saver.isWaiting {
            await Task.yield()
        }

        model.closeDuetPreview()
        #expect(model.duetPreview == url, "the preview stays while the save reads the video")
        #expect(FileManager.default.fileExists(atPath: url.path))

        await saver.open()
        await save.value
        #expect(model.saveStatus == .saved)
        #expect(await saver.bytes > 0)
    }

    @Test func aNewSetClosesThePreviewAndRemovesItsVideo() async throws {
        let model = try await finishedSet(saver: FakeSaver())
        await model.makeDuet()
        let url = try #require(model.duetPreview)
        model.startNewSet()
        #expect(model.duetPreview == nil)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test func theProgressGatePassesWholePercentsThatGrowAndEndsAtOne() {
        final nonisolated class Sent: @unchecked Sendable {
            private let lock = NSLock()
            private var all: [Double] = []
            func add(_ value: Double) {
                lock.withLock { all.append(value) }
            }

            var list: [Double] {
                lock.withLock { all }
            }
        }
        let sent = Sent()
        let gate = DuetProgressGate { sent.add($0) }
        for value in [0.0, 0.001, 0.004, 0.011, 0.5, 0.49, 0.999, 1.0, 1.0] {
            gate.report(value)
        }
        #expect(sent.list == [0, 0.01, 0.5, 0.99, 1])
    }

    @Test func theDuetChipShowsOnlyForAPackWithClipsWhileTheBoothWaits() async {
        let model = await booth(isDuetOn: false)
        #expect(model.showsDuetChip)
        // The chip and the switch in the More menu are one setting.
        model.toggleDuet()
        #expect(model.isDuetOn)
        model.toggleDuet()
        #expect(!model.isDuetOn)

        model.send(.start)
        #expect(!model.showsDuetChip, "no chip during the countdown")

        let builtIn = BoothSessionModel(capture: FakeCapture(), sleep: { _ in })
        await builtIn.startCamera()
        #expect(!builtIn.hasPoseClips)
        #expect(!builtIn.showsDuetChip)
        builtIn.toggleDuet()
        #expect(!builtIn.isDuetOn, "a pack with no clips has no duet")
    }

    @Test func theRecordingSignHasAStartOnlyWhileTheBoothRecords() async {
        let model = await booth()
        #expect(model.attemptStart == nil)
        await shoot(model)
        model.send(.accept)
        #expect(model.attemptStart == nil)
        #expect(!model.isRecordingAttempt)
    }
}
