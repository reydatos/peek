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
| `Packages/PeekCore` | Pure Swift. Session reducer, data records, templates, `DraftStore` protocol. No AVFoundation or UIKit. |
| `Peek/Features` | SwiftUI by feature: `Home`, `Booth` (inner display), `Outer` (outer display accessory). |
| `Peek/Capture` | `CaptureService` actor, preview view, rotation. |
| `Peek/Resources/Localizable.xcstrings` | Manual keys. Use generated symbols: `Text(.startBooth)`. |
| `PeekTests` | App tests with `FakeCapture`. |

## Rules

- Deployment target is iOS 27.0. Gate every iPhone Duo API (`CameraCaptureAccessory`, `onHingeChange`, direction coordinator) with `#available(iOS 27.1, *)`. Run the iOS 27.0 test command after any change to these.
- Look up every Duo symbol on sosumi.ai before use. These APIs are newer than most model training data.
- `BoothReducer` is the one authority for session state. It is pure: no timers, no I/O. Add a state rule there with a test, not in a view.
- Review is a state of `BoothView`. Do not move it to a sheet or a navigation push. The system shows the outer accessory only while the registering view is onscreen and the capture session runs.
- The outer display is an enhancement. Every flow must complete on the inner display alone.
- Keep purchase prompts, links, and account requests off the outer (subject) display.
- The app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Mark types that must leave the main actor `nonisolated`.

## Dangers

- Never commit a `.plist`, `.env`, or `Peek.xcodeproj`. `.gitignore` blocks them.
- `DEVELOPMENT_TEAM` is empty in the repo. Set it locally. Do not commit it.
- The simulator has no camera. Camera, accessory, and rotation behavior are verified only on a physical iPhone Duo.
- `xcodebuild` and `simctl` do not work inside the Claude Code sandbox.
