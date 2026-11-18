import AVFoundation
import SwiftUI
import UIKit

/// The player of one pose clip. The clip plays again and again, with no sound.
///
/// It is made off the main thread: the main thread makes no media call that can wait (the lesson of the
/// scene-update watchdog stop of 2026-11-15).
final nonisolated class ClipLoop: @unchecked Sendable {
    let player: AVQueuePlayer
    private let looper: AVPlayerLooper

    init(url: URL) {
        player = AVQueuePlayer()
        // The clip has no sound track. The player stays silent, and it does not keep the display on.
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.allowsExternalPlayback = false
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
    }
}

/// The clip that shows the move of a customer pose. It covers its frame, with no controls.
/// The caller puts the still picture below it, so the frame is never empty while the clip loads.
struct PoseClipView: UIViewRepresentable {
    let url: URL
    /// True shows the complete clip inside the frame. False, the standard, covers the frame.
    var showsAll = false

    func makeUIView(context _: Context) -> ClipUIView {
        ClipUIView()
    }

    func updateUIView(_ view: ClipUIView, context _: Context) {
        view.showsAll = showsAll
        view.show(url)
    }

    static func dismantleUIView(_ view: ClipUIView, coordinator _: ()) {
        view.stop()
    }
}

/// A recorded pose: its last frame, and above it the clip. The frame is never empty while the clip loads.
struct PoseClipPicture: View {
    /// The JPEG bytes of the last frame of the clip.
    let still: Data
    /// Nil shows the last frame only.
    let clipURL: URL?

    var body: some View {
        Color.clear
            .overlay {
                if let image = UIImage(data: still) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .overlay {
                if let clipURL {
                    PoseClipView(url: clipURL)
                }
            }
    }
}

/// A view with a player layer. One player has one layer: a second layer of the same player shows no picture.
final class ClipUIView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var showsAll = false {
        didSet { playerLayer?.videoGravity = showsAll ? .resizeAspect : .resizeAspectFill }
    }

    private var url: URL?
    private var loop: ClipLoop?
    private var activeObserver: (any NSObjectProtocol)?

    private var playerLayer: AVPlayerLayer? {
        layer as? AVPlayerLayer
    }

    func show(_ url: URL) {
        guard self.url != url else { return }
        stop()
        self.url = url
        playerLayer?.videoGravity = showsAll ? .resizeAspect : .resizeAspectFill
        isUserInteractionEnabled = false
        Task {
            let loop = await Task.detached { ClipLoop(url: url) }.value
            // The view can have a different clip, or no clip, when the player is ready.
            guard self.url == url else { return }
            self.loop = loop
            playerLayer?.player = loop.player
            playIfVisible()
        }
        // The system stops a video player when the app goes to the background. The clip starts again after that.
        activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.playIfVisible() }
        }
    }

    func stop() {
        loop?.player.pause()
        playerLayer?.player = nil
        loop = nil
        url = nil
        if let activeObserver {
            NotificationCenter.default.removeObserver(activeObserver)
        }
        activeObserver = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        playIfVisible()
    }

    /// The clip plays only while the view is on a display.
    private func playIfVisible() {
        if window == nil {
            loop?.player.pause()
        } else {
            loop?.player.play()
        }
    }
}

/// The shape of pose clips: the width of the level picture divided by its height.
/// A clip from a wide camera picture is 4:3. A clip from an upright camera picture is 3:4.
enum ClipShape {
    private static var known: [URL: CGFloat] = [:]

    /// Nil when the file is not a video that the system can read.
    static func aspect(of url: URL) async -> CGFloat? {
        if let aspect = known[url] {
            return aspect
        }
        let aspect = await Task.detached { () -> CGFloat? in
            guard
                let track = try? await AVURLAsset(url: url).loadTracks(withMediaType: .video).first,
                let (size, transform) = try? await track.load(.naturalSize, .preferredTransform)
            else { return nil }
            let shown = CGRect(origin: .zero, size: size).applying(transform)
            return shown.height > 0 ? abs(shown.width) / abs(shown.height) : nil
        }.value
        known[url] = aspect
        return aspect
    }
}
