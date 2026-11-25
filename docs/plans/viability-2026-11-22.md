# PEEK viability plan (design review, 2026-11-22)

## What this means

PEEK has a real hook. People copy a pose picture, the app scores the match, and the duet video gives them something to post. The booth is specified in detail and well built: 210 tests on `main` 7ef41fb. PEEK is not yet a viable App Store product, because everything around the booth is missing:

- a first run that teaches the app
- a business model in the code
- downloadable content
- history
- a hook for standard iPhones
- a share loop that leads back to the app

The owner decided each gap below on 2026-11-21 and 2026-11-22. With these decisions, the design rating goes from 3/10 to 8/10. The two remaining open items are owner decisions. Nothing in this file is built yet.

## Decisions (owner, 2026-11-22)

| # | Area | Decision |
|---|---|---|
| 1 | Memories entry | **1A.** A 44 pt round thumbnail of the last saved strip opens the Memories sheet. It is on the leading side of the black camera bar (tall booth) and at the bottom of the side rail (wide booth). With no saves, it is hidden and the bar keeps its current layout. |
| 2 | Business model | **Superseded 2026-11-24 (twice):** Street Style is the free pack, and All Packs at $19.99 a year is the one product; no single packs and no bundles (see "Owner decisions after the reviews"). Original **2A.** The Classic pack is free. Every other pack is a one-time unlock. An all-access subscription ("All Packs") includes every pack and every future pack. The owner sets the prices and any trial in App Store Connect. |
| 3 | Locked packs | **3A.** A locked pack card shows a chip with a lock icon and the word "LOCKED" (never color alone). A tap opens the unlock sheet, so the user sees the poses before paying. |
| 4 | Settings | **4A.** The last item of the More menu opens a Settings sheet: Purchases (Restore Purchases, Manage subscription, "All Packs" state), Replay tips, Privacy, Terms, About. |
| 5 | Purchase states | **5A.** The state table below. |
| 6 | Memories storage | **6A.** "Save Strip" and "Save duet video" also keep a small copy in the app container. Memories lists only saved items. Photos access stays add-only. The rule "nothing goes to Photos before Save" stays. |
| 7 | Memories states | **7A.** The state table below. |
| 8 | First-run coach | **8A.** The rules below. |
| 9 | Share loop | **9A + 9B in 1.0.** Every share of a strip, duet, or pack adds one line of message text with a link. The link opens a small web page for the strip or pack with an App Store button, through universal links. Choosing a domain and a host is open (see Unresolved). |
| 10 | New content | **10A.** Packs come as Apple-hosted downloadable assets (Background Assets; look up every symbol on sosumi.ai before use). A "New" badge on the Poses button shows a new pack. Download states are below. |
| 11 | Looks | **11A.** A row of 4-5 looks on the finished screen (Natural, B&W, Film, Flash), applied to the strip and the duet. Some looks are free; the others come with packs or All Packs. The owner sets which looks are free. |
| 12 | Unlock copy | **12A.** The unlock sheet shows lines from the pack itself: the pose names, and "Included in All Packs". It shows "Video guide for every pose" only for a pack that has clips. It never lists app features that free packs also have. |
| 13 | Tokens | **13A.** The token map below. Existing tokens win over the mockup sizes, and nothing new goes in `PeekTheme`. |
| 14 | Wide display and accessibility | **14A.** The table below. |
| 15 | App Store category | **15A.** Photo & Video, age rating 4+, not the Kids category. Ask to Buy covers children. No parent gate. |
| 16 | Custom packs | **Superseded 2026-11-24: unlimited and free (T10 dropped).** Original **16A.** Anyone can make and share one custom pack for free. More custom packs come with All Packs. The "New pack" card shows a pack-limit state (lock chip plus "1 free pack used"). A tap opens the All Packs sheet. |
| 17 | Languages | **17A.** English at launch. Strings stay in the catalog. Languages are added later from App Store data (see TODOS.md). |
| 18 | Duet failure | **18A.** "Couldn't make your duet." with a warning icon and Try again. The shots and clips stay, and Save Strip still works. This replaces the generic `SaveStatus.failed` label for the duet. |

## State tables

### Unlock sheet (5A)

| State | User sees |
|---|---|
| Prices loading | The poses and the lines are visible. The buttons show their labels with a small spinner and are disabled. |
| Prices failed | "Can't load prices. Check your connection." and Try again (secondary). |
| Cancelled | The sheet stays open. Nothing changes. |
| Ask to Buy waiting | The red button changes to grey "Waiting for a parent", with a clock icon. The lock stays on the card. |
| Approved later | The lock on the pack card changes to a check. The next time the library opens, the pack shows as unlocked. |
| Failed | A banner: "Purchase didn't go through." and Try again. |
| Success | A check appears on the button (static with Reduce Motion on). The sheet closes, the pack is selected, and its first pose loads. |
| Restore, nothing found | "No purchases to restore on this Apple Account." |
| Restore, found | "Restored." The packs unlock where the user is. |
| Subscribed | No card shows a lock, and the sheet does not open. Settings shows "All Packs". |

### Memories (7A)

| State | User sees |
|---|---|
| No saves | The camera-bar thumbnail is hidden. The sheet shows a strip outline, the line "Your saved strips and duets show up here.", and a red "Start a set" button, which closes the sheet. |
| Loading | Grey placeholders in the grid. No spinner. |
| Tap an item | A full-screen viewer shows the strip, or plays the duet with sound. Share is the red action. Delete asks for a confirmation. |
| Missing file | A broken-photo icon, "Can't open this one", and Delete. |
| Delete | Removes the app copy only. The sheet says that the copy in Photos stays. |

### First-run coach (8A)

- **Order:** The system camera prompt comes first. The coach starts only when the live picture shows.
- **Denied:** No coach. The existing "Open Settings" status shows (`BoothStatusView`). The coach runs after the user allows access.
- **Steps:**
  1. "Copy the pose": the spotlight is on the pose picture and its arrows.
  2. "Tap to start": the spotlight is on the shutter.
  3. "Make a duet": the spotlight is on the Duet chip. This step is only for a pack with clips. Other packs get "Pick a pack" on the Poses button instead.
- **Duo:** When the outer display is on, step 1 adds "Your friends see the pose on the outside."
- **Skip:** Ends the coach for good. Settings > Replay tips runs it again.
- **Fold and rotate:** The coach pauses and moves its spotlight to the new position. The card never covers the item it points at.
- **Accessibility:** VoiceOver reads the card, then Next. With Reduce Motion on, the spotlight does not pulse. The coach never shows on the outer display.

### Pack downloads (10A)

| State | Pack card shows |
|---|---|
| Not downloaded | A cloud icon on the card |
| Downloading | A progress ring on the card. The card cannot be selected. |
| Failed | "Couldn't download" and Try again |
| Offline | "Connect to download" |
| New | A "New" badge on the card and a dot on the Poses button until the user opens the library |

### Duet video (18A)

- **Making:** No change: a bar with "Making your duet".
- **Failed or timeout (30 s):** "Couldn't make your duet.", a warning icon, and Try again. Save Strip stays available.

## Token map (13A)

| Component | Tokens |
|---|---|
| Coach card | `surface`, radius 20. Title 22 bold, body 16. Next is the primary red button, height 50. Skip is a text button in `inkSecondary`. |
| Lock chip | The Chip component: `fill`, 12 bold uppercase "LOCKED", and a `lock.fill` icon. Over a photo, it uses `surface`. |
| Unlock sheet | `page` background. Pose pictures at radius 12 with a 2 border in the pack accent. Title 22 bold, lines 16 with a check. Unlock is the primary red button, height 56, radius 16. All Packs is a secondary button in `fill`, height 50. Restore, Terms, and Privacy are captions. |
| Last-strip thumbnail | A 44 × 44 circle with a 2 ring in `onStrong`, in the camera bar or at the bottom of the rail. |
| Memories | `page` background. Cards in `surface`, radius 20, with a shadow in light mode and a `separator` border in dark mode. Title 22 bold. The tabs use the Segmented choice. Dates are captions, and the match label uses the Chip. No red except the empty-state action. |
| Look chips | The same chip row as the frame colors, with a small preview swatch and a name. |

The one-red rule holds on every screen.

## Wide display and accessibility (14A)

| Screen | Tall (iPhone, Duo closed) | Wide (Duo open) |
|---|---|---|
| Unlock sheet | Bottom sheet at a medium height, which grows to large. It scrolls. | Centered form sheet, with the poses in one row |
| Memories | 2 columns | Adaptive grid, about 4 columns, minimum card width 160 |
| Coach | Card in the middle of the picture | Card beside the rail, with the spotlight on the rail item |
| Look chips | A row that scrolls sideways | Wraps in the leading panel |

These rules apply to all new screens:

- **Text size:** Dynamic Type works up to AX5 in the sheets, because they scroll. The camera bar keeps its stop at xxxLarge.
- **Touch targets:** 44 × 44 for every control.
- **VoiceOver:** The lock chip reads "Locked". The thumbnail reads "Memories, last strip". Each purchase state is announced.
- **Outer display:** None of these screens show on the outer display.
- **Contrast:** At least 4.5:1 for body text and 3:1 for text of 24 pt and larger. No state is shown by color alone.

## Approved mockups (layout guides only; the tokens and copy rules above win)

| Screen | Mockup path | Direction | Notes |
|---|---|---|---|
| First-run coach | /Users/jonchu/.gstack/projects/reydatos-peek/designs/first-run-20261121/variant-C-2.png | Spotlight ring on the pose picture, compact card | Step 3 (Duet) is not drawn |
| Unlock sheet | /Users/jonchu/.gstack/projects/reydatos-peek/designs/pack-unlock-20261121/variant-C-2.png | Bottom sheet, four poses, one red button | The benefit list is replaced by 12A. The title must be 22 pt. The prices are placeholders. |
| Memories | /Users/jonchu/.gstack/projects/reydatos-peek/designs/memories-20261121/variant-B-2.png | Two columns, strips and duets mixed | The thumbnail entry point (1A) is not drawn |

The image tool's tallest size is 2:3, so no mockup has the full height of an iPhone screen. A refresh after the decisions failed twice with API timeouts, so these mockups predate 12A and 13A.

## Launch requirements outside the design scope

- `PrivacyInfo.xcprivacy`: the app uses `UserDefaults`, which is a required-reason API. App Store Connect blocks the upload without the manifest.
- An App Store privacy label that matches 6A (on-device copies only) and the camera clips.
- App Store screenshots and a preview video. The duet video is the natural preview.

## NOT in scope

- **Kids category and parent gate:** decision 15A.
- **Localization at launch:** decision 17A, with a TODO.
- **App Clip:** the landing page (9B) covers sharing with people who do not have the app.
- **Push notifications:** the "New" badge (10A) is the signal to come back. Notifications need a separate owner decision later.
- **"Create together" (friends add shots by link):** still an open decision in `DESIGN.md`, and it conflicts with "No account".

## What already exists (reuse it)

- **Design system:** `DESIGN.md` and `tokens.json`, through `PeekTheme`, the one-red rule, and `PeekPrimaryButtonStyle`, `PeekSecondaryButtonStyle`, and `PeekRailButtonStyle`.
- **Pose library:** the pack card grid (`PackCard`, `PoseLibraryView`), the Chip, the Segmented choice.
- **Saving and sharing:** `ShareLink` in `FinishedControls` and `ChallengeShare`, `SaveStatus` and `SaveStatusLabel`, and the `PhotoSaving` seam.
- **Duet:** the duet preview as a state of the booth (`DuetPreviewView`).
- **Camera access:** `BoothStatusView`, with its denied state and Open Settings link.
- **Paid flag:** `PosePack.isFree`. It exists but no code reads it yet; the paywall uses it.

## Implementation tasks

The effort estimates use the default ratios: features about 30x, tests about 50x, scaffolding about 100x.

- [x] **T1 (P1, human: ~3d / CC: ~3h)**: Purchases: StoreKit products for each pack plus All Packs. Gate on `PosePack.isFree`, add the unlock sheet with every 5A state, and add Ask to Buy. **Built 2026-11-24** (branch `feat/store-t1`): `PosePack.productID` replaces `isFree`; `StoreProducts` is the one product table (product → packs, with an empty bundle table until the owner names the bundles); `Entitlements` behind a `StoreClient` seam; the unlock sheet; the D5 gates; `Config/Products.storekit` for tests and Xcode runs. The lock and check chip of T2 is in the same change, because the 5A "Approved later" state needs it.
  - Surfaced by: Pass 1, issue 2 (2A); Pass 2, issue 5 (5A); Pass 4, issue 12 (12A)
  - Files: `Peek/Features/Poses/PosePack.swift`, `PoseLibraryView.swift`, `PackCard.swift`, a new `Peek/Features/Store/`
  - Verify: StoreKit configuration file tests for each state; render pictures of the sheet, light and dark, tall and wide, at AX5
- [ ] **T2 (P1, human: ~4h / CC: ~20min)**: Lock chip on pack cards. A tap opens the unlock sheet (3A).
  - Files: `PackCard.swift`, `StageChips.swift`
  - Verify: a test that a locked pack opens the sheet and an unlocked pack is selected
- [ ] **T3 (P1, human: ~1d / CC: ~1h)**: Settings sheet from the More menu: Restore Purchases, Manage subscription, Replay tips, Privacy, Terms, About (4A).
  - Files: `BoothMoreMenu.swift`, a new `Peek/Features/Settings/`
  - Verify: a render picture; a test that Restore Purchases calls the store
- [ ] **T4 (P1, human: ~1d / CC: ~1h)**: First-run coach with the 8A rules.
  - Files: `BoothView.swift`, a new `Peek/Features/Booth/CoachOverlay.swift`
  - Verify: tests for the order, the denied state, and Skip; render pictures for steps 1-3, tall and wide, AX5
- [ ] **T5 (P1, human: ~2h / CC: ~10min)**: `PrivacyInfo.xcprivacy` with the required-reason entries.
  - Files: `Peek/Resources/PrivacyInfo.xcprivacy`, `project.yml`
  - Verify: an archive passes the App Store Connect validation
- [ ] **T6 (P2, human: ~2d / CC: ~2h)**: Memories: app copies on Save (6A), the sheet with the 7A states, and the thumbnail entry (1A).
  - Files: `BoothSessionModel.swift`, `BoothCameraBar.swift`, `BoothSideRail.swift`, a new `Peek/Features/Memories/`, a store in `PeekCore`
  - Verify: store tests; a test that Close on an unsaved duet still deletes it; render pictures
- [ ] **T7 (P2, human: ~2d / CC: ~2h)**: Downloadable packs through Apple-hosted Background Assets, with the download states and the "New" badge (10A).
  - Files: `PoseCatalog.swift`, `PoseLibrary.swift`, `PackCard.swift`
  - Verify: look up the API on sosumi first; a test for each download state
- [ ] **T8 (P2, human: ~1d / CC: ~1h)**: Share message with a link (9A), and the landing page with universal links (9B). The host is decided (`peek.therevolv.com`, 2026-11-23); see "Owner decisions after the reviews".
  - Files: `FinishedControls.swift`, `ChallengeShare.swift`, `DuetPreviewView.swift`, `PackShareView.swift`, an associated-domains entitlement
  - Verify: the link opens the App Store from Messages; a universal link opens the app
- [ ] **T9 (P2, human: ~1.5d / CC: ~1.5h)**: Strip looks (Natural, B&W, Film, Flash) on the strip and the duet (11A).
  - Files: `StripRenderer.swift`, `FramePicker.swift`, `DuetVideo.swift`
  - Verify: snapshot tests for each look; the duet render time stays under the 30 s timeout
- [x] ~~**T10 (P2, human: ~3h / CC: ~15min)**: Custom pack limit: 1 free, more with All Packs (16A).~~ **Dropped 2026-11-24:** making custom packs is unlimited and free.
  - Files: `NewPackCard.swift`, `UserPacks.swift`
  - Verify: a test that the second pack opens the All Packs sheet
- [ ] **T11 (P2, human: ~2h / CC: ~10min)**: Duet failure message and Try again (18A).
  - Files: `BoothSessionModel.swift`, `SaveStatusLabel.swift`, `Localizable.xcstrings`
  - Verify: a test with a failed and a timed-out duet video
- [ ] **T12 (P2, human: ~2h / CC: ~10min)**: Add the new components, the token map (13A), and the rules for wide displays and accessibility (14A) to `docs/design/DESIGN.md`.
  - Files: `docs/design/DESIGN.md`
  - Verify: review

## Design Review Completion Summary

```
  +====================================================================+
  |         DESIGN PLAN REVIEW — COMPLETION SUMMARY                    |
  +====================================================================+
  | System Audit         | DESIGN.md present; UI scope: whole app      |
  | Step 0               | 4/10; full viability review (all 7 passes)  |
  | Pass 1  (Info Arch)  | 5/10 → 8/10 after fixes                     |
  | Pass 2  (States)     | 3/10 → 8/10 after fixes                     |
  | Pass 3  (Journey)    | 3/10 → 8/10 after fixes                     |
  | Pass 4  (AI Slop)    | 7/10 → 9/10 after fixes                     |
  | Pass 5  (Design Sys) | 6/10 → 9/10 after fixes                     |
  | Pass 6  (Responsive) | 5/10 → 8/10 after fixes                     |
  | Pass 7  (Decisions)  | 4 resolved, 2 deferred (owner)              |
  +--------------------------------------------------------------------+
  | NOT in scope         | written (5 items)                           |
  | What already exists  | written                                     |
  | TODOS.md updates     | 1 item added (9B moved into 1.0)            |
  | Approved Mockups     | 9 generated, 3 approved                     |
  | Decisions made       | 19 added to plan                            |
  | Decisions deferred   | 2 (listed below)                            |
  | Overall design score | 3/10 → 8/10                                 |
  +====================================================================+
```

Every rated pass is now 8/10 or higher. The two open items below are owner decisions, not design gaps.

### Unresolved decisions

- **Resolved 2026-11-24:** $1.99 per PEEK Pack, 3 for $4.99, All Packs $19.99 a year, one free photo pack (see "Owner decisions after the reviews"). Store details decided the same day: Street Style is free, fixed themed bundles, no trial, unlimited free custom packs (T10 dropped). Still open: which looks are free, and the bundle names and contents. Earlier text: the prices and any trial or introductory offer for each pack and for All Packs, and which looks (11A) are free. If these are deferred, the store cannot go live.
- **Resolved 2026-11-23:** `peek.therevolv.com` on a new Vercel project (see "Owner decisions after the reviews"). Earlier text: the domain and host for the static site (D2 = A), and how a web page fits the "pure iOS" rule in `AGENTS.md`. This blocks T1 and T3 (guideline 3.1.2 needs Terms and Privacy links in the subscription flow), the App Store Connect privacy policy URL, and T8. (This bullet was corrected by the eng review: it first said only T8 was affected.)

## Eng review (2026-11-22, /plan-eng-review of this file)

Target: `docs/plans/viability-2026-11-22.md` on `docs/viability-plan` (PR #71), base `main` 7ef41fb.

### Scope record

feature answers: D2 = A (9B is a static app page plus one page per pack, with universal links, and no user photos uploaded; this replaces "a small web page for the strip"); structure: D3 = B, smaller arrangement; accepted scope: T1-T12 with D2 applied to T8 and the D3 arrangement below; pending remedies: R1, R2, R3 (Decision ledger). Scope Challenge result: scope accepted as-is (D2 narrows how T8 works, not what is built).

**D3 arrangement (smaller):**
- **Packs:** Downloaded packs use `PackFile` (`Packages/PeekCore/Sources/PeekCore/Packs/PackFile.swift`). Its manifest gets optional fields: accent, category, product ID, and localized names. Old files still decode. `PoseCatalog.packs` adds a third source: built-in, then downloaded, then the customer's packs.
- **Entitlements:** One `@Observable` `Entitlements` store wraps StoreKit 2 and answers `isUnlocked(pack)`. `PosePack.isFree` becomes `productID: String?`, where `nil` means free. Each product ID lives in one place: on the built-in `PosePack`, or in the pack manifest.
- **Memories:** A `MemoryStore` protocol plus `FileMemoryStore` in `PeekCore/Persistence`, on the `FileDraftStore` pattern. The record repurposes `ExportRecord`, which no app code uses; it adds date, pack name, kind, and file names.
- **Looks:** A `Look` enum in `PeekCore/Template` beside `FrameColor`. One app-side function applies a look to an image. `StripRenderer` calls it for each photo, and `DuetVideo` calls it for each frame.
- **Downloads:** A new `ManagedDownloaderExtension` target in `project.yml`, with an App Group and the `BAAppGroupID`, `BAHasManagedAssetPacks`, and `BAUsesAppleHosting` keys. The app uses `AssetPackManager`, verified on sosumi.ai on 2026-11-22.

Counts [estimated]: about 20 changed files, about 7 new types, plus 1 extension target.

### Scope Challenge findings

1. [CRITICAL] (confidence: 9/10) plan line 22 ("opens a small web page for the strip or pack"): a page for each strip means uploading photos of people. **Resolved by D2 = A.**
2. [INFORMATIONAL] (9/10) `PackFile.swift:3-7` ("A pose pack as one file... A file is not trusted: `init(data:)` checks each size"): downloaded packs reuse this checked format. **Applied by D3 = B.**
3. [INFORMATIONAL] (8/10) `ExportRecord.swift:3` ("an export stores its selected takes, layout version, format, and outcome"): no app caller uses it, so it can be the Memories record. **Applied by D3 = B.**
4. [INFORMATIONAL] (9/10) T7 does not name the downloader extension target, the App Group, or the BA* Info.plist keys. sosumi lists `ManagedDownloaderExtension`, `BAAppGroupID`, and `BAUsesAppleHosting`. These are required mechanics of 10A, so they are added to T7 with no question.
5. [INFORMATIONAL] (8/10) The 5A "Approved later" state needs a `Transaction.updates` listener that starts at launch (`PeekApp.swift`). Without it, an Ask to Buy approval arrives while nothing listens. This is a required mechanic of 5A, so it is added to T1.
6. [INFORMATIONAL] (7/10) T5: if Memories sorts or displays file dates through `FileManager` attributes, the manifest also needs the file timestamp reason. Otherwise it needs only `UserDefaults` (`SavedPoseStore.swift`). This is a required mechanic of T5.

### Reality rows

- REALITY: premise-table pass. 6 premises checked, unverified=0: `isFree` is never read; there is no StoreKit; the camera-denied state exists; Save Strip is the only red button; `UserDefaults` is used; Background Assets exists. Peek/Features/Poses/PosePack.swift:31
- REALITY: already-done pass. `git log origin/main` has no StoreKit, Memories, coach, or asset-pack commit (head 7ef41fb, `git log --oneline -15`).
- REALITY: surface-check pass. `AssetPackManager`, `ManagedDownloaderExtension`, and `BAUsesAppleHosting` are verified on sosumi.ai/documentation/backgroundassets (recorded at docs/plans/viability-2026-11-22.md:245). StoreKit 2 `Transaction.updates` and `.pending` must be re-checked on sosumi before T1. docs/plans/viability-2026-11-22.md:245
- REALITY: binding-decisions pass. The 18 owner decisions in this file, D2, and D3 outrank the defaults. The "pure iOS" rule (`AGENTS.md:3`) stays open under Unresolved; D2 keeps the web part static.
- REALITY: numbers finding. The effort numbers are [estimated] from the default ratios. The 30 s duet timeout is at Peek/Features/Finish/DuetVideo.swift:72. The 6.9 s duet render time is [re-measure before gate] on the Duo; it came from a simulator run of commit e30c991. Peek/Features/Finish/DuetVideo.swift:72
- REALITY: deferred-asks pass. There is no linked issue. Every item of the owner's request maps to T1-T12 or NOT in scope. docs/plans/viability-2026-11-22.md:157
- REALITY: pr-count finding. There is no `.gstack/ship-policy.json` at 7ef41fb, so the default is one PR per wave. The waves give 4 PRs (see Build waves). 7ef41fb

### 1. Architecture

```
            +-------------------+       Transaction.updates (launch)
 StoreKit --| Entitlements      |<----- Ask to Buy approval, renewals, refunds
            | isUnlocked(pack)  |
            +---------+---------+
                      | read by
     +----------------+----------------+-------------------+
     v                v                v                   v
 PoseCatalog      PackCard /       NewPackCard         Settings
 (built-in +      UnlockSheet      (16A limit)         (restore, state)
  downloaded +    (5A states)
  customer)
     ^
     | PackFile(data:) validates
 AssetPackManager <-- ManagedDownloaderExtension (App Group) <-- App Store Connect packs

 Save Strip / Save duet --> PhotoSaving (Photos, add-only)
                       \--> MemoryStore (app container copy + thumbnail) --> Memories sheet
```

**Design twice (new boundary: `Entitlements`):**
- **Shape A:** an `Entitlements` store. Callers ask `isUnlocked(pack)`, and the store hides StoreKit, the listener, and the offline cache.
- **Shape B:** each `PosePack` carries an `isUnlocked` value that `PoseCatalog` computes and pushes into views.

**Pick: A.** One small interface hides all of StoreKit. With B, the unlock value is copied into every pack value and goes stale after a purchase.

**Red flags:**
- **Hand-synced list:** product IDs appear in the StoreKit configuration file, in code, and in App Store Connect. Fix: a test that every paid `PosePack.productID` exists in the `.storekit` configuration file.
- **Two ways to do one task:** `isFree` and `productID` would both answer the same question. Fix: remove `isFree` in the same change.

No other flags.

**Failure per new path:**
- **Entitlements:** offline launch. StoreKit 2 keeps verified entitlements on the device, so owned packs stay unlocked, and the 5A "Prices failed" state covers the sheet.
- **Downloads:** a pack fails to download partway. The 10A "Failed" state covers it, and `PackFile` rejects damaged bytes.
- **Memories:** the disk is full on Save. Pending as R1.
- **Expiry:** All Packs ends during a set. Pending as R2.

**Open decisions found in this section:**
- R1: how long Memories keeps app copies (storage)
- R2: an All Packs expiry while a set uses a paid pack
- R3: custom packs above the free one after All Packs ends

### 2. Code quality

- [INFORMATIONAL] (8/10) `SaveStatus.swift:7` (`case failed`): 18A needs a duet-specific failure. Add a separate duet status; do not overload `SaveStatus`, which also drives the Save Strip label. This is a required mechanic of 18A.
- No shared-code extraction is proposed beyond D3. `Look` has two callers (`StripRenderer`, `DuetVideo`), both proposed for 11A; one function serves both.

Dispositions: both items are carried as required mechanics. There are no new questions.

### 3. Tests

The framework is Swift Testing (`AGENTS.md`, "Verify the test COUNT"). There are 151 app tests and 59 engine tests on `main`.

```
CODE PATHS                                         USER FLOWS
[+] Entitlements (T1)                              [+] Buy a pack
  ├── [GAP] purchase success -> unlocked             ├── [GAP] [→E2E] tap locked card -> sheet -> buy -> pack selected
  ├── [GAP] .pending (Ask to Buy) -> waiting         ├── [GAP] Ask to Buy -> approve later -> lock to check
  ├── [GAP] userCancelled -> unchanged               ├── [GAP] restore none / found
  ├── [GAP] verification failed -> locked            └── [GAP] subscribed -> no sheet
  ├── [GAP] updates listener applies late approval
  └── [GAP] productID table matches .storekit file
[+] PackFile manifest v2 (D3)                      [+] Download a pack
  ├── [★★★ TESTED] v1 checks (PackFileTests)          ├── [GAP] not downloaded -> downloading -> ready
  ├── [GAP] v1 file still decodes (REGRESSION)       └── [GAP] failed / offline
  └── [GAP] v2 optional fields round-trip
[+] MemoryStore (T6)                               [+] Memories
  ├── [GAP] save strip -> record + file + thumb      ├── [GAP] empty -> Start a set
  ├── [GAP] save duet -> record + video              ├── [GAP] delete keeps Photos copy
  ├── [GAP] missing file -> broken state             └── [GAP] thumbnail hidden with no saves
  └── [★★ TESTED] Close on unsaved duet deletes (DuetTests) - must stay green (REGRESSION)
[+] Coach (T4)                                     [+] Look (T9)
  ├── [GAP] denied -> no coach                       ├── [GAP] each look renders strip (snapshot)
  ├── [GAP] skip -> never again                      └── [GAP] duet with look under timeout
  └── [GAP] step 3 only for a pack with clips
[+] Duet failure (T11): [GAP] timeout -> "Couldn't make your duet" + Try again keeps clips
COVERAGE: 2/27 paths tested (7%) | all gaps are proposed code with no tests yet
```

**Required proof (carried forward from approved behavior; not new scope):**
- **StoreKit:** `StoreKitTest` (`SKTestSession`) tests for each 5A state.
  - Value: protects=5A purchase states; fails_when=a state maps to the wrong UI; why_new=no store code exists; seam=none; no_claim=real App Store billing (local StoreKit test session)
- **PackFile v1 regression (CRITICAL, contract from D3: "old files still decode"):** a v1 fixture decodes after the manifest change.
  - Value: protects=packs shared before v2 still open; fails_when=v2 decoding requires a new field; why_new=PackFileTests only cover the v1 writer; seam=none; no_claim=none beyond protects
- **MemoryStore:** tests on the `FileDraftStore` test pattern.
- **Close on an unsaved duet still deletes it (REGRESSION):** the existing `DuetTests` stay green. Extend them with "Save then Close keeps the Memories copy".
- **Coach:** reducer-style tests for the 8A rules.
- **Looks:** snapshot tests for each look.
- **Duet with a look:** a render time check on the Duo against the 30 s timeout (manual, device only).

**Tests to retire:** none. `isFree` has no tests.

### 4. Performance

- [INFORMATIONAL] (7/10) `DuetVideo` renders every frame. Measured on 2026-11-21 in the simulator: 6.9 s for a 26 s video. A look adds one Core Image pass on each 1080 × 1920 frame, about 780 frames. The cost on the Duo is unknown. The timeout is 30 s (`DuetVideo.timeout`). Mechanic: create one `CIContext` for each render, not one per frame, and re-measure on the Duo before the gate.
- [INFORMATIONAL] (7/10) A Memories grid that decodes full strips and videos is slow. Mechanic of 7A: write a small thumbnail at save time, and have the grid load only thumbnails.
- Downloads run in the system extension, off the main thread. No other paths run in loops.

## Decision ledger

### R1: Memories storage bound
Finding: Section 1, INFORMATIONAL, confidence 7/10, `DuetVideo.swift` (a 1080 × 1920 H.264 video for each duet), reviewer: Claude (in-host)
Plan baseline: 6A, an app copy on each Save; no bound stated
Runtime evidence: the size of a duet file on the Duo is unknown [re-measure]; there is no app container copy today
Comparison grid:
| Choice | Current | A | B | C |
|---|---|---|---|---|
| R1 bound | none, pending | no limit; Settings shows the size and a "Clear Memories" action | duet copies stored smaller than the Photos copy (owner sets the size); strips full size | keep the newest N items (owner sets N) |
| 6A (app copy on Save) | approved | unchanged | unchanged | unchanged |
| R2, R3 | pending | pending | pending | pending |
Question D4:
D4 — How should Memories bound its storage?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), task T6.
ELI10: Decision 6A keeps a copy of every saved strip and duet inside PEEK. Strips are small, but each duet is a full-HD video, so a busy user could fill tens of GB without knowing. Today nothing limits it.
Stakes if we pick wrong: Unbounded copies grow PEEK's storage, the phone warns, and people delete the app; a hard cap silently loses memories.
Recommendation: A because the user stays in control with no silent loss, and Settings can show the size.
Note: options differ in kind, not coverage — no completeness score.
Pros / cons:
A) No limit + Clear in Settings (recommended)
  ✅ Nothing is ever deleted behind the user's back; Memories is complete
  ✅ Settings shows "Memories: 2.1 GB" and a Clear Memories action (human: ~3h / CC: ~15min)
  ❌ Heavy duet users can still grow storage until they notice
B) Smaller duet copies
  ✅ Each duet copy takes far less space; the full copy stays in Photos
  ✅ No deletion; strips stay full size
  ❌ Re-encoding on Save adds time; you must set the size (a design value)
C) Keep newest N items
  ✅ Storage has a hard ceiling no matter how much people shoot
  ✅ Simple rule, easy to test
  ❌ Older memories vanish silently; you must set N
Net: user control and completeness vs. a guaranteed storage ceiling.
Header: D4 Storage
Options:
A) No limit + Clear in Settings (recommended)
No cap; Settings shows Memories size and a Clear Memories action with confirmation (human: ~3h / CC: ~15min).
B) Smaller duet copies
Store a smaller re-encoded duet copy in the app; size is an owner design value; strips full size (human: ~4h / CC: ~20min).
C) Keep newest N items
Delete the oldest app copies beyond N (owner sets N); Photos copies stay (human: ~2h / CC: ~10min).

State: approved
Actual answer: A) No limit + Clear in Settings (D4, 2026-11-22)
Accepted scope: No cap on Memories app copies. Settings shows the total size of Memories and a "Clear Memories" action, with a confirmation that says the copies in Photos stay. This is added to T3 (Settings) and T6 (MemoryStore needs `totalSize()` and `removeAll()`), with tests.
History: none

### R2: All Packs ends while a set uses a paid pack
Finding: Section 1, INFORMATIONAL, confidence 7/10, `BoothSessionModel` draft restore (a set that is not complete comes back at launch, per `DESIGN.md` "Home (removed)"), reviewer: Claude (in-host)
Plan baseline: 2A, all-access subscription; no rule for expiry or refund during a set
Runtime evidence: the draft restores its pack at launch today; no entitlement check exists
Comparison grid:
| Choice | Current | A | B | C |
|---|---|---|---|---|
| R2 expiry during a set | unspecified, pending | the set finishes with its pack; the pack locks at the next pack choice or New set | the pack locks now; the booth switches to Classic and keeps the accepted shots | the pack locks now; the booth blocks shooting until the user subscribes again |
| R1 | approved (D4 = A) | unchanged | unchanged | unchanged |
| R3 | pending | pending | pending | pending |
Question D5:
D5 — What happens when All Packs ends during a set?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), tasks T1 and T6.
ELI10: A subscriber starts a set with a paid pack. Then the subscription ends, or Apple refunds it, while the set is open or saved as a draft. PEEK brings unfinished sets back at launch. Without a rule, the engineer guesses: the set might crash on a locked pack, or keep it forever.
Stakes if we pick wrong: Locking mid-set loses a party's photos in progress; never re-checking gives paid packs away after a refund.
Recommendation: A because the people already in front of the camera finish their strip, and the lock applies at the next natural choice point.
Note: options differ in kind, not coverage — no completeness score.
Pros / cons:
A) Finish the set, then lock (recommended)
  ✅ No one loses a set in progress; the strip and the duet can still be saved
  ✅ One clear rule: entitlements are checked when a pack is chosen or a New set starts
  ❌ A refunded user can finish one last set with the pack
B) Lock now, switch to Classic
  ✅ The entitlement holds at once, with no free use after expiry
  ✅ Accepted shots stay; only the remaining poses change
  ❌ The strip mixes two packs, and the change mid-set surprises people
C) Lock now, block shooting
  ✅ The strictest guard on paid content
  ✅ Clear prompt to subscribe again
  ❌ A party in front of the camera is stuck until someone pays
Net: never interrupting a set vs. enforcing the lock immediately.
Header: D5 Expiry
Options:
A) Finish the set, then lock (recommended)
The open set or draft keeps its pack until it is finished or a New set starts; the lock applies at the next pack choice (human: ~3h / CC: ~15min).
B) Lock now, switch to Classic
On expiry, the remaining shots use the Classic pack; accepted shots stay (human: ~4h / CC: ~20min).
C) Lock now, block shooting
On expiry, the booth shows the unlock sheet and no new shot until the user subscribes (human: ~3h / CC: ~15min).

State: approved
Actual answer: A) Finish the set, then lock (D5, 2026-11-22)
Accepted scope: Entitlements are checked when a pack is chosen and when a New set starts. An open set or a restored draft keeps its pack until the set is finished or a New set starts. The strip and the duet of that set can still be saved. This is added to T1, with a test: a draft restored on an expired pack finishes, and the next pack choice shows the lock.
History: none

### R3: Custom packs above the free one after All Packs ends
Finding: Section 1, INFORMATIONAL, confidence 7/10, `UserPacks.swift` / `NewPackCard.swift` (16A: one free custom pack, more with All Packs), reviewer: Claude (in-host)
Plan baseline: 16A, one free custom pack and more with All Packs; no rule for the packs above one after the subscription ends
Runtime evidence: customer packs today have no limit and no entitlement check
Comparison grid:
| Choice | Current | A | B | C |
|---|---|---|---|---|
| R3 extra custom packs after expiry | unspecified, pending | all existing packs stay usable and shareable; only a new pack above one needs All Packs | the oldest pack stays usable; the others show the lock until the user subscribes again (never deleted) | the user picks which one pack stays usable; the others show the lock (never deleted) |
| 16A (1 free, more with All Packs) | approved | unchanged | unchanged | unchanged |
| R1, R2 | approved (D4 = A, D5 = A) | unchanged | unchanged | unchanged |
Question D6:
D6 — What happens to extra custom packs when All Packs ends?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), task T10.
ELI10: Decision 16A gives one custom pack free and more with All Packs. A subscriber records three packs, then cancels. The packs hold their own recorded videos of friends. Should those packs keep working?
Stakes if we pick wrong: Locking people's own recordings feels like holding them hostage; leaving everything open weakens the reason to stay subscribed.
Recommendation: A because the packs are the user's own recordings; the subscription buys making more, not keeping what they made.
Note: options differ in kind, not coverage — no completeness score.
Pros / cons:
A) Keep existing packs usable (recommended)
  ✅ No one loses access to their own recorded videos; no hostage feeling or angry reviews
  ✅ Simplest rule: the limit applies only when a new pack is made
  ❌ A user can subscribe for one month, make many packs, and cancel
B) Oldest stays, others locked
  ✅ The limit holds after expiry, which protects the subscription's value
  ✅ Nothing is deleted; subscribing again unlocks everything
  ❌ The user cannot choose which pack stays, and locked own content frustrates people
C) User picks which stays
  ✅ The limit holds, and the user keeps the pack they care about most
  ✅ Nothing is deleted
  ❌ One more screen and state to build and test (human: ~1d / CC: ~1h)
Net: respecting people's own recordings vs. keeping the custom-pack limit strict.
Header: D6 Own packs
Options:
A) Keep existing packs usable (recommended)
All custom packs stay usable and shareable after expiry; only making a new pack beyond one needs All Packs (human: ~1h / CC: ~5min).
B) Oldest stays, others locked
After expiry, the oldest custom pack stays usable; the others show the lock until resubscribe; none deleted (human: ~3h / CC: ~15min).
C) User picks which stays
After expiry, a sheet lets the user pick one pack to keep usable; the others show the lock; none deleted (human: ~1d / CC: ~1h).

State: approved
Actual answer: A) Keep existing packs usable (D6, 2026-11-22)
Accepted scope: After All Packs ends, every existing custom pack stays usable and shareable. The limit of one free pack applies only when a new pack is made. This is added to T10, with a test: with an expired subscription and 3 packs, all 3 open, and "New pack" shows the limit state.
History: none

### Outside voice (Claude Plan subagent, native fallback; Codex unavailable: binary missing)

The reviewer's full report arrived inside the 5-minute limit. It had 11 findings and ended with VERDICT: FINDINGS. These dispositions need no question:
- **#4 (High), factual correction:** App Store Connect needs a privacy policy URL, and guideline 3.1.2 needs Terms and Privacy links in the subscription flow. So the open domain decision blocks T1, T3, and submission, not only T8. The Unresolved list is updated.
- **#6 (Medium), required output:** the build waves and PR split are written under "Build waves" below. T12 (DESIGN.md) moves first, and T1 (Entitlements, `productID`) comes before T2, T3, and T10.
- **#8 (Medium), required mechanic of D5:** if a restored draft names a pack that is no longer on disk, the draft restores to the Classic pack and keeps its accepted shots, and it never crashes. A test is added to T1.
- **#9 (Low), mechanic of the Section 1 red-flag fix:** one checked-in table lists every product ID, built-in and downloaded. A test matches it against the `.storekit` configuration file.
- **#11 (Low), factual:** the terminal report is rewritten when this review completes.

Verified claims: `PackFile.swift:99` (`guard entry.stillBytes > 0, entry.clipBytes > 0`) and `PackImport.swift:33` (`func confirm(_ file: PackFile) async`, which adds the pack to `UserPacks`).

### R4: Is T7 (downloadable packs) in 1.0?
Finding: Outside voice #3, High, confidence 8/10, `PoseLibrary.swift:23-55` (10 packs with `isFree: false` already in the app), reviewer: Claude Plan subagent
Plan baseline: 10A (Apple-hosted downloads) is approved as an owner decision; T7 is P2 in 1.0
Runtime evidence: the 10 paid packs are in the asset catalog today; no extension target exists
Comparison grid:
| Choice | Current | A Include | B Defer | C Cut | D Hold |
|---|---|---|---|---|---|
| T7 in 1.0 | included (10A) | in 1.0, with a small bundled pack catalog for "Not downloaded" cards (finding #2) and the `PackFile` v2 clip rule (finding #5) | moves to 1.1; 1.0 sells the 10 built-in packs; 10A stays the plan for new packs | removed; new packs ship in app updates | stop and discuss; T7 stays included |
| Findings #2, #5 | pending | resolved inside A | not needed until 1.1 | not needed | pending |
Question D7:
D7 — Should downloadable packs (T7) ship in 1.0?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), task T7.
ELI10: You chose Apple-hosted downloads so that new packs don't need an app update (10A). The reviewer points out that 1.0 already has 10 paid packs built in, so the store can launch without downloads. T7 is the biggest new system: an extension, an App Group, a pack catalog so cards show before download, and a format change for packs without clips.
Stakes if we pick wrong: Including it delays launch and adds the riskiest code; cutting it leaves no way to drop new packs without a release.
Recommendation: B because the 10 built-in packs already give the store something to sell, and downloads matter only once there is a second wave of packs.
Note: options differ in kind, not coverage — no completeness score.
Pros / cons:
A) Include in 1.0
  ✅ New packs can drop on day one without an app update
  ✅ The All Packs subscription has a visible "new content" story at launch
  ❌ Adds the extension, App Group, catalog and format change to 1.0 (human: ~1 wk / CC: ~1 day)
B) Defer to 1.1 (recommended)
  ✅ 1.0 ships sooner, with the riskiest system out of the launch
  ✅ 10A stays the plan; built-in packs move to downloads later if needed
  ❌ The first new pack after launch waits for 1.1 or an app update
C) Cut
  ✅ No download system to build or maintain at all
  ✅ Simplest app: every pack ships in the binary
  ❌ Each new pack needs an App Review cycle, which weakens All Packs
D) Hold
  ✅ Keeps T7 in 1.0 while we discuss the trade-off
  ✅ No scope change until you decide
  ❌ Leaves findings #2 and #5 open, and the waves cannot be final
Net: launch speed and risk vs. new content from day one.
Header: D7 Downloads
Options:
A) Include
T7 stays in 1.0; adds a bundled pack catalog (names, accents, product IDs, preview stills) and a PackFile v2 rule for clip-less packs.
B) Defer (recommended)
T7 moves to 1.1; 1.0 sells the 10 built-in packs; 10A stays the plan for new packs.
C) Cut
No downloads; every new pack ships in an app update.
D) Hold
Stop and discuss; T7 stays included and findings #2 and #5 stay open.

State: approved
Actual answer: A) Include (D7, 2026-11-22)
Accepted scope: T7 stays in 1.0. Two additions:
- **Bundled pack catalog:** a JSON file in the app bundle lists each downloadable pack with its ID, localized names, accent, category, product ID, and 4 preview stills. It feeds the "Not downloaded" card, the unlock sheet before a download, and the "New" badge. It is also the one product-ID table from finding #9.
- **`PackFile` v2 clip rule (finding #5):** a pose may have `clipBytes == 0` only when the manifest marks the pack as clip-less. Every other size check stays as it is.
Tests: a clip-less v2 pack decodes, and a v1 or v2 file with a damaged size still throws `.damaged`. Findings #2 and #5 are resolved here.
History: none

### R5: Do received packs count against the free custom-pack limit?
Finding: Outside voice #1, High, confidence 8/10, `PackImport.swift:33` (`func confirm(_ file: PackFile) async`, which adds the pack to `UserPacks`), reviewer: Claude Plan subagent
Plan baseline: 16A, one free custom pack and more with All Packs; D6 = A; received packs are not mentioned
Runtime evidence: imported packs and made packs share one `UserPacks` store, with no origin flag
Comparison grid:
| Choice | Current | A Apply | B Keep | C Investigate | D Defer |
|---|---|---|---|---|---|
| R5 received packs vs limit | unspecified (imports would count by default) | received packs never count; only packs made on this phone count; `UserPack` gets an origin flag (made / received) | imports count like made packs | look at the self-AirDrop workaround first (bounded: one test), then decide | leave unspecified |
| 16A, D6 | approved | unchanged | unchanged | unchanged | unchanged |
Question D8:
D8 — Do packs you receive from friends count against the free custom-pack limit?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), task T10.
ELI10: Friends challenge each other by sending a .peekpack file. Today, received packs land in the same list as packs you made. If they count toward the one free pack, anyone who has made a pack can't accept a friend's challenge, which breaks the main growth loop. If they don't count, someone could export their own pack, delete it, make another, and import the first one back.
Stakes if we pick wrong: Counting imports blocks challenges; not counting allows a small workaround that needs effort.
Recommendation: A because challenges are PEEK's growth loop, and the workaround takes effort and only lets someone keep their own old recordings.
Note: options differ in kind, not coverage — no completeness score.
Pros / cons:
A) Apply: received packs are free
  ✅ Anyone can always accept a friend's challenge, so the share loop never hits a paywall
  ✅ The limit stays clear: it counts only packs you make (human: ~2h / CC: ~10min)
  ❌ A determined user can re-import their own exported pack to keep more than one
B) Keep: imports count
  ✅ The limit is airtight: every pack on the phone counts
  ✅ No origin flag to add or test
  ❌ Accepting a challenge after making one pack opens the All Packs sheet, which kills sharing
C) Investigate first
  ✅ Measures how easy the workaround really is before choosing
  ✅ Nothing changes until we know
  ❌ T10 can't finish, and the loop stays undefined until the next answer
D) Defer
  ✅ No work now
  ✅ Keeps today's code untouched
  ❌ The engineer picks a behavior by accident, most likely "imports count"
Net: an open share loop vs. an airtight custom-pack limit.
Header: D8 Imports
Options:
A) Apply: received packs free
Only packs made on this phone count toward the free limit; UserPack gets a made/received origin flag, with tests (human: ~2h / CC: ~10min).
B) Keep: imports count
Every pack on the phone, made or received, counts toward the one free pack.
C) Investigate first
Bound: one test of the self-AirDrop workaround, then ask again; nothing changes now.
D) Defer
Leave it unspecified for now; the engineer's default applies.

State: approved
Actual answer: A) Apply: received packs free (D8, 2026-11-22; the label was sent with a "(recommended)" suffix, and the option is the same)
Accepted scope: `UserPack` gets an origin flag (made or received). A pack with no flag, made before this change, decodes as "made". Only packs made on this phone count toward the one free pack. A received pack never opens the All Packs sheet. This is added to T10. Tests: (1) with 1 pack made, importing a friend's pack succeeds; (2) with 1 pack made, "New pack" shows the limit; (3) an old `UserPack` with no flag decodes as "made".
History: none

### R6: Where Memories copies live, and iCloud backup
Finding: Outside voice #7, Medium, confidence 7/10. The plan has no location (T6 says only "app container"). Reviewer: Claude Plan subagent.
Plan baseline: 6A (an app copy on Save), D4 = A (no cap). No location or backup rule.
Runtime evidence: `FileDraftStore` exists, but its folder was not checked [unknown]. No Memories store exists. Apple guidance (sosumi.ai, "Optimizing Your App's Data for iCloud Backup", read on 2026-11-22):
- Exclude large data that the user can get back on a restored device (the example is downloaded HD movies), with `isExcludedFromBackup`.
- Do not exclude data that is hard to re-create.
- Put purgeable data, such as thumbnails, in `Library/Caches`.
- Set the flag again on each save, because file operations can reset it.
Comparison grid:
| Choice | Current | A Apply | B Keep | C Investigate | D Defer |
|---|---|---|---|---|---|
| R6 location and backup | unspecified | Application Support, excluded from iCloud backup (the copy in Photos is the backed-up one) | Application Support, included in iCloud backup | measure duet file sizes on the Duo first, then decide | leave unspecified |
| Thumbnails | unspecified | `Library/Caches` (purgeable, per Apple) | `Library/Caches` | pending | pending |
| 6A, D4 | approved | unchanged | unchanged | unchanged | unchanged |
Question D10:
D10 — Should Memories copies go into the phone's iCloud backup?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), task T6.
ELI10: Every saved strip and duet already goes to Photos, and iCloud Photos backs it up. PEEK's own Memories copy is a second copy. If that copy also goes into the iCloud backup, each duet counts twice against the user's iCloud storage, with no cap (D4). If it is left out, a new phone restored from backup gets an empty Memories list, while every photo stays in Photos.
Stakes if we pick wrong: Including it can quietly fill people's iCloud. Excluding it means Memories starts empty after a phone restore.
Recommendation: A because Apple's guidance (sosumi) says to exclude large data the user can get back. Every Memories copy is also in Photos, so it survives a restore. Thumbnails go in Caches, as Apple advises.
Note: options differ in kind, not coverage. No completeness score.
Pros / cons:
A) Apply: exclude from backup
  ✅ No double iCloud storage. The backed-up copy is the one in Photos.
  ✅ Application Support with isExcludedFromBackup is one line to set and test.
  ❌ After a restore to a new phone, Memories is empty, though Photos still has everything.
B) Keep in backup
  ✅ Memories comes back complete after a phone restore.
  ✅ No special file flag to maintain.
  ❌ Each duet is stored twice in iCloud with no cap, and heavy users fill their quota.
C) Investigate first
  ✅ Real duet sizes on the Duo show how much this matters.
  ✅ Nothing changes until there is data.
  ❌ T6 cannot finish its storage code until the answer.
D) Defer
  ✅ No decision now.
  ✅ The current code stays as it is.
  ❌ The engineer picks a folder by accident, probably Documents, which is backed up.
Net: Memories surviving a phone restore vs. not doubling people's iCloud storage.
Header: D10 Backup
Options:
A) Apply: exclude from backup
Store Memories copies in Application Support, excluded from iCloud backup, with a test that checks the flag (human: ~1h / CC: ~5min).
B) Keep in backup
Store them in Application Support and include them in iCloud backup.
C) Investigate first
Measure duet file sizes on the Duo first, then ask again. Nothing changes now.
D) Defer
Leave it unspecified for now. The engineer's default applies.

State: approved
Actual answer: A) Apply: exclude from backup (D10, 2026-11-22)
Accepted scope:
- Memories copies go in an Application Support folder marked `isExcludedFromBackup = true`. The flag is set on the folder and set again after each save.
- Thumbnails go in `Library/Caches`. They are purgeable, and the grid makes them again when they are missing.
- Added to T6. Tests: (1) the flag is true after a save; (2) a missing thumbnail is made again.
- The privacy label and the copy in Settings say that the copies stay on the phone.
History: D9 was sent on 2026-11-22. The user replied "Which one is prefer sosumi", which picked no option. The sosumi evidence above was added, and the question is asked again as D10 with the same options.

### R7: A new MemoryRecord, or reuse ExportRecord
Finding: Outside voice #10, Low, confidence 7/10. `ExportRecord.swift:3-15` has required `takeIDs`, `layout`, `layoutVersion`, `format`, and `outcome` fields for "PRD section 5". Reviewer: Claude Plan subagent.
Plan baseline: D3 = B, which repurposes `ExportRecord` as the Memories record.
Runtime evidence: no app code uses `ExportRecord`. Only `.build` artifacts name it.
Comparison grid:
| Choice | Current | A Apply | B Keep | C Investigate | D Defer |
|---|---|---|---|---|---|
| R7 Memories record type | D3: repurpose `ExportRecord` | a new `MemoryRecord` (id, date, kind, pack name, match, file names); delete the unused `ExportRecord` in the same change | repurpose `ExportRecord` (add fields, drop the unused ones) | check the PRD for a planned use of `ExportRecord` first | leave D3 as it is |
| Rest of D3 (PackFile, Entitlements, Look) | approved | unchanged | unchanged | unchanged | unchanged |
Question D11:
D11 — Should Memories use a new MemoryRecord type?
Project/branch/task: eng review of the PEEK viability plan (docs/viability-plan, PR #71), task T6.
ELI10: The smaller arrangement (D3) reused an unused type, `ExportRecord`, for Memories. The reviewer notes that it was made for a different job (a record of an export, with takes and an outcome). Reusing it keeps a misleading name and fields that Memories doesn't need. A new `MemoryRecord` says what it is. The old type is deleted, so there is still only one.
Stakes if we pick wrong: A misleading type confuses the next contributor. Keeping both types would be two ways to do one thing.
Recommendation: A because the name should match the meaning, and deleting the unused type keeps one record type.
Note: options differ in kind, not coverage. No completeness score.
Pros / cons:
A) Apply: new MemoryRecord
  ✅ The type name and fields match what Memories stores (date, kind, pack, match, files).
  ✅ The unused ExportRecord is deleted in the same change, so there is no second record type.
  ❌ About 20 more lines than reusing the old struct (human: ~30min / CC: ~5min).
B) Keep: repurpose ExportRecord
  ✅ No new type. Follows D3 exactly.
  ✅ The old struct already conforms to Codable, Identifiable, and Sendable.
  ❌ The name says "export" but means "memory", and the fields need breaking changes anyway.
C) Investigate first
  ✅ Confirms the PRD has no planned use for ExportRecord before it is deleted.
  ✅ Nothing changes until then.
  ❌ Delays T6's model for a Low finding.
D) Defer
  ✅ No change to D3.
  ✅ Nothing to decide now.
  ❌ The misleading name stays the default.
Net: a clear name vs. strict reuse of an existing struct.
Header: D11 Record
Options:
A) Apply: new MemoryRecord
Add MemoryRecord in PeekCore/Model; delete the unused ExportRecord in the same change (human: ~30min / CC: ~5min).
B) Keep: repurpose ExportRecord
Follow D3: change ExportRecord's fields for Memories.
C) Investigate first
Check the PRD for a planned ExportRecord use, then ask again. Nothing changes now.
D) Defer
Leave D3 as it is.

State: approved
Actual answer: A) Apply: new MemoryRecord (D11, 2026-11-22)
Accepted scope: Add `MemoryRecord` in `PeekCore/Model` (id, date, kind strip or duet, pack name, match, file names). Delete the unused `ExportRecord` in the same change. This replaces the `ExportRecord` part of D3. Added to T6, with a Codable round-trip test.
History: none

Approval readiness: PASS. Checked: D2 (scope), D3 (structure), R1/D4, R2/D5, R3/D6, R4/D7, R5/D8, R6/D10 (D9 was asked again), R7/D11. Each accepted remedy cites its own answer. The regression contracts are carried forward: PackFile v1 still decodes (D3), Close on an unsaved duet still deletes it (6A), and old UserPacks decode as "made" (D8).

### Eng amendments to the implementation tasks

These amendments apply to the tasks above. Each one cites its decision.
- **T1:** One `Entitlements` store. `PosePack.isFree` becomes `productID`, from one checked-in product-ID table. A `Transaction.updates` listener starts at launch. Rules:
  - Checks run when a pack is chosen and when a New set starts (D5).
  - A draft whose pack is missing restores to Classic (outside voice #8).
  - StoreKit tests cover each 5A state.
  - Blocked by the domain and host decision: Terms and Privacy URLs (guideline 3.1.2).
- **T3:** Shows the Memories size and a "Clear Memories" action (D4). It needs hosted Terms and Privacy URLs.
- **T6:**
  - The record is `MemoryRecord`, and `ExportRecord` is deleted (D11). `MemoryStore` and `FileMemoryStore` follow the `FileDraftStore` pattern, with `totalSize()` and `removeAll()`.
  - Copies go in Application Support, excluded from backup. Thumbnails go in `Library/Caches` (D10).
- **T7:**
  - Add the `ManagedDownloaderExtension` target, the App Group, and the BA* keys in `project.yml`.
  - Add a bundled pack catalog JSON and the `PackFile` v2 manifest. Optional fields; v1 still decodes; clip-less packs only when the manifest says so (D7).
  - Use the local mock server for tests.
- **T8:** A static app page plus one page per pack, with universal links and no uploads (D2). Blocked by the domain and host decision.
- **T9:** A `Look` enum in `PeekCore/Template`. One apply function and one `CIContext` per render. Re-measure the duet render time on the Duo against the 30 s timeout.
- **T10:** `UserPack` gets an origin flag. Received packs never count toward the limit (D8). Existing packs stay usable after expiry (D6).
- **T11:** A separate duet status. `SaveStatus` is not overloaded.
- **T12:** Moves first, to Wave 0.

### Build waves (one PR per wave, the default; no `.gstack/ship-policy.json`)

| Step | Modules touched | Depends on |
|------|----------------|------------|
| W0: T12 DESIGN.md, T5 privacy manifest | docs/design, project config | — |
| W1: T1 Entitlements + unlock sheet | Peek/Features/Store (new), Poses, App | W0 |
| W2a: T2 lock chip, T10 custom limit | Peek/Features/Poses, PeekCore/Packs | W1 |
| W2b: T6 Memories | PeekCore/Persistence + Model, Booth, Memories (new) | W1 |
| W2c: T9 looks, then T11 duet failure | PeekCore/Template, Finish, Booth | W1 |
| W3a: T3 Settings | Settings (new), Booth (More menu) | W1, W2b (Memories size) |
| W3b: T4 coach | Booth | W0 |
| W3c: T7 downloads | Poses, PeekCore/Packs, extension target, project.yml | W1, W2a (PackFile) |
| W3d: T8 share links + static site | Finish, Poses, web (new) | domain decision |

- **Parallel lanes:**
  - Lane A: W2a, then W3c (shared Poses/Packs)
  - Lane B: W2b, then W3a
  - Lane C: W2c
  - Lane D: W3b (it can start after W0)
- **Execution order:** W0, then W1. Then launch A, B, C, and D together. W3d waits for the domain.
- **Conflict flags:**
  - W2b, W2c, and W3b all touch Booth: `BoothSessionModel`, the camera bar, and `BoothView`. Merge them one at a time.
  - W2a and W3c share PeekCore/Packs.
- **PR count:** 4 waves give 4 PRs by default. Wave 2 and Wave 3 are large. Splitting them by lane gives 9 PRs and costs one CI and review cycle each [estimated].

### Failure modes

| Path | Realistic failure | Test / handling | User sees |
|---|---|---|---|
| Purchase | Ask to Buy approved while the app is closed | `Transaction.updates` at launch; StoreKit test | The lock turns into a check |
| Entitlements | Offline launch | StoreKit's cached verified entitlements; test | Owned packs stay unlocked |
| Draft restore | The draft's pack is locked or missing | D5 rule and the outside-voice #8 fallback; tests | The set finishes, or the draft moves to Classic |
| Download | Download fails partway | 10A failed state; `PackFile` rejects damaged bytes; test | "Couldn't download" and Try again |
| Memories save | Disk full | The save error shows through the existing save label; test | Save failed, with the strip still on screen |
| Duet + look | The render goes past 30 s on the Duo | 18A message; device check | "Couldn't make your duet" and Try again |
| Share link | The domain is not set up yet | T8 is blocked, and 9A's message link still works | An App Store link in the message |

Critical gaps (no test, no handling, and silent): 0.

### NOT in scope (eng additions)

- Per-strip web pages with uploads: replaced by D2 = A.
- Moving the 10 built-in paid packs to downloads: they stay in the app for 1.0. T7 is only for new packs.

### What already exists (eng)

- `PackFile` (checked, untrusted-safe format) is reused for downloaded packs.
- The `FileDraftStore` pattern is reused for `FileMemoryStore`.
- `BoothStatusView` (camera denied) is reused by the coach.
- `PhotoSaving` stays the Photos path.
- StoreKit 2 and Background Assets are the platform layers. No new third-party dependency.

### TODOS.md (eng)

No new TODO proposals. Every finding was decided in this review or is in the tasks.

### Eng review completion summary

- Step 0: Scope Challenge — scope accepted as-is (D2 narrowed T8's mechanism; D3 chose the smaller arrangement)
- Reality rows: 7/7 tier-1 rows emitted, 0 unverified premises
- Architecture Review: 5 issues found (2 red flags, R1-R3)
- Code Quality Review: 1 issue found
- Test Review: diagram produced, 25 gaps identified (all in proposed code)
- Performance Review: 2 issues found
- NOT in scope: written
- What already exists: written
- TODOS.md updates: 0 items proposed to user
- Failure modes: 0 critical gaps flagged
- Unresolved decisions: 2 in this review (owner: prices; domain and host, which now block T1, T3, T8, and submission)
- Outside voice: Codex unavailable (binary missing); native Claude Plan subagent completed with 11 findings, all dispositioned
- Parallelization: 4 lanes, 4 parallel / 2 sequential waves (W0, W1)
- Lake Score: 0/1 (D2 = A scored 9/10; the 10/10 option did not exist)

## Owner decisions after the reviews (2026-11-23 and 2026-11-24)

These came after the design and eng reviews. They outrank earlier text in this file.

**The website (resolves the domain and host decision)**
- Address: `peek.therevolv.com`, on a new, separately named Vercel project with one DNS record. It does not use a path on www.therevolv.com, because that host already serves the Revolv app's `apple-app-site-association` file; PEEK gets its own.
- The landing page is a short "dare" page: the hook "Can you copy this pose?", a duet with a score, the make-your-own-pack loop, sample sessions, and an email waitlist. The share page is a dare page, with the first name and score in the link, no photos, and no upload. Prototype: https://claude.ai/artifact/5RuLiAxc8ppug5P7prPmHn
- Waitlist: a Vercel function in that project emails the owner each signup. There is no database. The website Privacy page says that the site collects an email only for the waitlist; the app still collects nothing.
- Still open (owner): the email service (a new dependency), the address that gets signups, who manages the therevolv.com DNS, and where the site code lives. A separate repo is recommended, so this repo stays pure iOS.

**Shipped in PR #72 (merged 2026-11-24)**
- Duet and Match prints: the pose above the shot, with poses drawn whole and a cyan line.
- Score fun: a score pill on each shot, a "Best copy" crown, and verdicts (90 Basically twins, 75 Certified copycat, 50 Close enough, 25 Creative interpretation, else Did you even look?).
- Photo lines: black on cream and white paper, white on black paper.
- The crop follows the people: the eye line in the upper third, and with no person the upper part of the shot.
- A shot framed too close has no score instead of 0%, and the meter says "Step back so your arms show".
- Confirmed on a physical Duo: plush and illustrated poses give no body, so those packs have no score.

**Business model and prices (2026-11-24, after pricing research)**
- The app is free. Making a pack and sharing it with friends stays free; this is the viral loop. A pack from a friend is free (D8).
- **PEEK Pack** (a pack designed by PEEK, 4 poses): **$1.99** each, or a **3-pack bundle for $4.99**.
- **All Packs:** **yearly only, $19.99**, and it unlocks every PEEK Pack. There is no monthly plan.
- **Free at launch:** **one free photo pack**, so the match score, the verdicts, and the duet work in the first minute. This replaces 2A ("the Classic pack is free"). Plush and illustrated poses give no score, so Classic is not the free pack.
- **Creator packs:** featured creators first. PEEK signs a few creators and sells their packs as featured PEEK Packs, with a revenue split by contract, through the same in-app purchase. An open marketplace for packs made by anyone is version 2. It needs accounts, uploads, moderation (guideline 1.2: filter, report, block, contact), an age limit on content (1.2.1), payouts, and an 18+ creator rule, and it would end the no-upload privacy promise.
- Apple's commission is 15% under the Small Business Program: about $1.69 kept per $1.99 pack, $4.24 per bundle, and $16.99 per year of All Packs.
- Research notes: impulse extras in consumer photo apps cost about $0.99–$2.99; $5 and higher prices in this category are for event photo booth businesses. Yearly plans keep the most subscribers. Plan to A/B test $1.99 against $2.99 per pack after launch.

**Store details (2026-11-24)**
- The free pack is **Street Style**: full-body poses that scored 98–99% in the Duo tests.
- The 3-for-$4.99 bundles are **fixed themed bundles**, one store product each (for example Seoul + Hong Kong, or a kids bundle). There is no "any 3" choice, so no unlock credits.
- All Packs has **no free trial**. The free Street Style pack is the trial.
- Making custom packs is **unlimited and free**. This supersedes 16A, and **T10 (the custom pack limit) is dropped**.

**Classic and the opening pack (2026-11-24)**
- Classic is a paid pack ($1.99). The app opens on Street Style, and Street Style replaces Classic as the fallback for a pack that is gone. This replaces "a draft whose pack is missing restores to Classic" (outside voice #8).

**One product: All Packs (2026-11-24, later the same day)**
- Owner's words: "buy app with unlock everything per year charge".
- The app sells one product: All Packs, $19.99 a year (`com.a8media.peek.allpacks.yearly`). It unlocks every paid pack. The app stays a free download, and Street Style stays free.
- This supersedes the $1.99 PEEK Pack, the 3-for-$4.99 themed bundles, and "Classic is a paid pack ($1.99)": Classic is now inside All Packs.
- Why: one product in App Store Connect in place of 11, and one for each later bundle.

**Still open (owner)**
- Which looks (11A) are free.
- How featured creator packs are paid for, now that no single pack is sold.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Outside Review | Codex via `/plan-design-review` and `/plan-eng-review` | Independent 2nd opinion | 2 | unavailable | Codex CLI not runnable (binary missing); native fallbacks ran |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | issues_open | 25 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | issues_open | score: 3/10 → 8/10, 19 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **OUTSIDE COVERAGE:**
  - **Design phase:** Codex unavailable. A native Claude subagent completed.
  - **Plan-review phase:** Codex unavailable (to repair, run `npm install -g @openai/codex`). A native Claude Plan subagent finished inside the 5-minute limit with 11 findings and VERDICT: FINDINGS. All 11 have a disposition: 5 recorded without a question, and D7-D11 answered.
  - Native fallbacks do not count as outside coverage.
- **VERDICT:** No review is CLEAR. The eng review has issues open. Prices and store details are decided (2026-11-24); T10 is dropped. Which looks are free and the bundle contents are open, but they do not block the start of T1. The host is decided (2026-11-23); its setup details are open (see "Owner decisions after the reviews"). The other 10 tasks can start with W0 and W1.

**UNRESOLVED DECISIONS:**
- Which looks (11A) are free, and how featured creator packs are paid for with All Packs as the one product (owner)
- Site setup for `peek.therevolv.com`: the email service for the waitlist function, the address that gets signups, who manages the therevolv.com DNS, and where the site code lives (a separate repo is recommended, so this app repo stays pure iOS) (owner)
