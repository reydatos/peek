# PEEK agent contract

PEEK: Photo Booth is a pure iOS app (SwiftUI) for iPhone and iPhone Duo. The global contract in `~/.claude/AGENTS.md` applies. This file adds repo specifics and wins on conflict.

## Commands

All commands run from the repo root. Each one was run and verified on 2026-11-11 with Xcode 27.2.

| Task | Command |
|---|---|
| Generate the Xcode project | `xcodegen generate` |
| Fast engine tests (host, no simulator) | `swift test --package-path Packages/PeekCore` |
| All tests, Duo simulator | `xcodebuild test -scheme Peek -destination 'platform=iOS Simulator,name=PEEK Duo 27.1' -derivedDataPath DerivedData` |
| All tests, iOS 27.0 | `xcodebuild test -scheme Peek -destination 'platform=iOS Simulator,name=PEEK 17 27.0' -derivedDataPath DerivedData` |
| Format | `swiftformat .` |
| Lint | `swiftformat --lint .` |

Create the simulators one time:

```sh
xcrun simctl create "PEEK Duo 27.1" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo com.apple.CoreSimulator.SimRuntime.iOS-27-1
xcrun simctl create "PEEK 17 27.0" com.apple.CoreSimulator.SimDeviceType.iPhone-17 com.apple.CoreSimulator.SimRuntime.iOS-27-0
```

Verify the test COUNT. The tests use Swift Testing, so the XCTest line `Executed 0 tests` is normal. Look for `Test run with N tests` for both `PeekCoreTests` and `PeekTests`.

## Structure

| Path | Purpose |
|---|---|
| `project.yml` | XcodeGen spec. `Peek.xcodeproj` is generated and gitignored. |
| `Config/Shared.xcconfig` | Build settings. The Info.plist is generated from `INFOPLIST_KEY_*`. |
| `Packages/PeekCore` | Pure Swift. Session reducer, data records, templates, `DraftStore` protocol and `FileDraftStore`. No AVFoundation or UIKit. |
| `Peek/Features` | SwiftUI by feature: `Home` (first screen: booth entry, draft, pack tiles), `Booth` (inner display), `Poses` (pose packs and picker), `Finish` (strip and 2x2 renderer, save, share), `Outer` (outer display accessory). The app opens on Home. The camera starts in the booth, after an explicit action. |
| `Peek/Capture` | `CaptureService` actor, preview layer view (inner), `FrameSource` frame feed view (outer), rotation. |
| `Peek/Resources/Localizable.xcstrings` | Manual keys. Use generated symbols: `Text(.poseIdeas)`. |
| `PeekTests` | App tests with `FakeCapture`. |

## Rules

- Deployment target is iOS 27.0. Gate every iPhone Duo API (`CameraCaptureAccessory`, `onHingeChange`, direction coordinator) with `#available(iOS 27.1, *)`. Run the iOS 27.0 test command after any change to these.
- Look up every Duo symbol on sosumi.ai before use. These APIs are newer than most model training data.
- Drafts: `BoothSessionModel` stores the bytes of a take first, then the record, in one serial chain (`persistTask`). The model default is no store, so tests stay isolated; `BoothView` passes the `FileDraftStore`.
- `BoothReducer` is the one authority for session state. It is pure: no timers, no I/O. Add a state rule there with a test, not in a view.
- Review is a state of `BoothView`. Do not move it to a sheet or a navigation push. The system shows the outer accessory only while the registering view is onscreen and the capture session runs.
- The outer display is an enhancement. Every flow must complete on the inner display alone.
- The outer display draws frames from `FrameSource` (`AVCaptureVideoDataOutput`). Do not put a second `AVCaptureVideoPreviewLayer` there. On a physical Duo that layer showed no picture.
- Keep purchase prompts, links, and account requests off the outer (subject) display.
- The look follows the UI handoff in `docs/design` (`DESIGN.md`, `tokens.json`): light and dark from the same semantic tokens, the system font, and one red. Colors and corners live in `PeekTheme`; do not put a hex value or `Color.white` in a view. Each state has one red main action (`PeekPrimaryButtonStyle`). The exported strip has fixed colors.
- The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Mark types that must leave the main actor `nonisolated`.

## Dangers

- Never commit a `.plist`, `.env`, or `Peek.xcodeproj`. `.gitignore` blocks them.
- Signing: put `DEVELOPMENT_TEAM = <10-character Team ID>` in `Config/Local.xcconfig` (gitignored), then run `xcodegen generate`. Do not set the team in Xcode; `xcodegen generate` removes it.
- The simulator has no camera. Camera, accessory, and rotation behavior are verified only on a physical iPhone Duo.
- `xcodebuild` and `simctl` do not work inside the Claude Code sandbox.
