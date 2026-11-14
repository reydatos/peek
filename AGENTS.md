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
| `Packages/PeekCore` | Pure Swift. Session reducer, data records (`SessionRecord` with layout and frame color), templates, `DraftStore` protocol and `FileDraftStore`. No AVFoundation or UIKit. |
| `docs/design` | The UI handoff: `DESIGN.md` (screens, components, rules) and `tokens.json` (colors, sizes, corners). |
| `Peek/Design` | `PeekTheme` (tokens) and the shared controls: primary, secondary, and rail buttons, chip, banner, segmented choice, icon label. |
| `Peek/Features` | SwiftUI by feature. The app opens on Home. The camera starts in the booth, after an explicit action. |
| `Peek/Features/Home` | First screen: Classic / Copycat choice, pack selection, Start a Booth, Resume Draft. |
| `Peek/Features/Booth` | Inner display. `BoothLayout` selects the wide booth (leading panel, photo, side rail) or the tall booth (full-screen camera, black camera bar). `BoothSessionModel` drives the two displays. |
| `Peek/Features/Poses` | Pose packs, the pose tray (an overlay of `BoothView`), the pose library (Discover and Saved), and `SavedPoses`. |
| `Peek/Features/Finish` | Strip and 2x2 renderer, frame color, save, share. |
| `Peek/Features/Outer` | Outer display accessory: pose reference, live frame, countdown, shot, strip. |
| `Peek/Capture` | `CaptureService` actor (camera, flip, zoom), preview layer view (inner), `FrameSource` frame feed view (outer), rotation. `CaptureProviding` is the seam for tests. |
| `Peek/Resources/Localizable.xcstrings` | Manual keys. Use generated symbols: `Text(.poseIdeas)`. |
| `PeekTests` | App tests with `FakeCapture`, `FakeSaver`, and `FlakyDraftStore`. |

## Rules

- Deployment target is iOS 27.0. Gate every iPhone Duo API (`CameraCaptureAccessory`, `onHingeChange`, direction coordinator) with `#available(iOS 27.1, *)`. Run the iOS 27.0 test command after any change to these.
- Look up every Duo symbol on sosumi.ai before use. These APIs are newer than most model training data.
- Drafts: `BoothSessionModel` stores the bytes of a take first, then the record, in one serial chain (`persistTask`). The model default is no store, so tests stay isolated; `BoothView` passes the `FileDraftStore`.
- `BoothReducer` is the one authority for session state. It is pure: no timers, no I/O. Add a state rule there with a test, not in a view.
- Review is a state of `BoothView`. Do not move it to a sheet or a navigation push. The system shows the outer accessory only while the registering view is onscreen and the capture session runs.
- The outer display is an enhancement. Every flow must complete on the inner display alone.
- The outer display draws frames from `FrameSource` (`AVCaptureVideoDataOutput`). Do not put a second `AVCaptureVideoPreviewLayer` there. On a physical Duo that layer showed no picture.
- Keep purchase prompts, links, and account requests off the outer (subject) display.
- The pose tray is an overlay of `BoothView`, not a sheet. The pose library is a sheet on the photographer's side.
- A new `SessionRecord` field must decode a draft that does not have it, with a default and a test.
- `SavedPoses` and `BoothSessionModel` have no store by default, so tests stay isolated. The app passes the stores.
- The look follows the UI handoff in `docs/design` (`DESIGN.md`, `tokens.json`): light and dark from the same semantic tokens, the system font, and one red. Colors and corners live in `PeekTheme`; do not put a hex value or `Color.white` in a view. Each state has one red main action (`PeekPrimaryButtonStyle`). The exported strip has fixed colors.
- The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Mark types that must leave the main actor `nonisolated`.

## Dangers

- Never commit a `.plist`, `.env`, or `Peek.xcodeproj`. `.gitignore` blocks them.
- Signing: put `DEVELOPMENT_TEAM = <10-character Team ID>` in `Config/Local.xcconfig` (gitignored), then run `xcodegen generate`. Do not set the team in Xcode; `xcodegen generate` removes it.
- The simulator has no camera. Camera, zoom, accessory, and rotation behavior are verified only on a physical iPhone Duo.
- Tests do not show the look. For a UI change, render the screens to pictures and examine them: light and dark, wide and tall, with and without the outer display, and one accessibility text size.
- The side rail, the leading panel, and the tall camera screen stop at the xxxLarge text size. Their space is fixed.
- `xcodebuild` and `simctl` do not work inside the Claude Code sandbox.
