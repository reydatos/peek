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
| 2 | Business model | **2A.** The Classic pack is free. Every other pack is a one-time unlock. An all-access subscription ("All Packs") includes every pack and every future pack. The owner sets the prices and any trial in App Store Connect. |
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
| 16 | Custom packs | **16A.** Anyone can make and share one custom pack for free. More custom packs come with All Packs. The "New pack" card shows a pack-limit state (lock chip plus "1 free pack used"). A tap opens the All Packs sheet. |
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

- [ ] **T1 (P1, human: ~3d / CC: ~3h)**: Purchases: StoreKit products for each pack plus All Packs. Gate on `PosePack.isFree`, add the unlock sheet with every 5A state, and add Ask to Buy.
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
- [ ] **T8 (P2, human: ~1d / CC: ~1h)**: Share message with a link (9A), and the landing page with universal links (9B). This task waits on the domain and host decision.
  - Files: `FinishedControls.swift`, `ChallengeShare.swift`, `DuetPreviewView.swift`, `PackShareView.swift`, an associated-domains entitlement
  - Verify: the link opens the App Store from Messages; a universal link opens the app
- [ ] **T9 (P2, human: ~1.5d / CC: ~1.5h)**: Strip looks (Natural, B&W, Film, Flash) on the strip and the duet (11A).
  - Files: `StripRenderer.swift`, `FramePicker.swift`, `DuetVideo.swift`
  - Verify: snapshot tests for each look; the duet render time stays under the 30 s timeout
- [ ] **T10 (P2, human: ~3h / CC: ~15min)**: Custom pack limit: 1 free, more with All Packs (16A).
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

- The prices and any trial or introductory offer for each pack and for All Packs, and which looks (11A) are free. If these are deferred, the store cannot go live.
- The domain and host for the 9B landing page, and how a web page fits the "pure iOS" rule in `AGENTS.md`. If these are deferred, T8 ships the message link only.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Outside Review | Codex via `/plan-design-review` outside voices | Independent 2nd opinion | 1 | unavailable | Codex CLI not runnable (binary missing) |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | — | — |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | issues_open | score: 3/10 → 8/10, 19 decisions |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **OUTSIDE COVERAGE:** Codex design phase: unavailable (`codex` is on PATH, but its binary is missing; to repair, run `npm install -g @openai/codex`). A native Claude subagent completed an independent completeness review. Two of its claims were wrong when checked against the code (the camera-denied state and the red button on the finished screen exist). Its other findings went into Passes 1-7.
- **VERDICT:** No review is CLEAR. Design review issues open: 2 owner decisions. Eng review required.

**UNRESOLVED DECISIONS:**
- Prices, trial or introductory offer, and which looks are free (owner)
- Domain and host for the 9B landing page, and how it fits the "pure iOS" rule (owner)
