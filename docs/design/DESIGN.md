# PEEK: Photo Booth. UI/UX handoff

This is the design spec for updating the PEEK app UI. It is extracted from the PEEK lookbook (light and dark) and the "Light style" screens. `tokens.json` in this folder holds every colour, size and radius as data. `wordmark.png` is the PEEK wordmark.

## How to use this (for Claude Code)

1. Read this file and `tokens.json` before touching any view.
2. Find where the app defines colours, fonts and shared controls. Map the tokens here onto that, or add a theme file if none exists. Do not hard-code hex values in views.
3. Restyle screen by screen in the order under "Screens". Keep existing behaviour unless a section below says to change it.
4. Support light and dark mode from the same semantic tokens. Follow the system appearance.
5. Stop and ask before acting on anything under "Open decisions".
6. Do not ship the sample photos. They are placeholders.

## Principles

- **Light, quiet, native.** White surfaces, near-black text, grey hairlines. System font and standard iOS controls during capture.
- **One red.** Red marks the primary action on a screen and the shutter core. Nothing else is red.
- **Pick up and go.** The camera screen has the photo, the pose, four-shot progress and the shutter. Everything else is one tap away.
- **Never colour alone.** Every status has an icon, a number or a word as well as a colour.
- **The subject sees one thing at a time.** Pose reference, live framing, countdown, or the captured shot.

## Colour

All values are in `tokens.json` under `color`, each with a light and a dark value.

| Token | Light | Dark | Use |
|---|---|---|---|
| page | #F7F7F7 | #000000 | App background |
| surface | #FFFFFF | #1C1C1E | Screens and cards |
| fill | #F2F2F7 | #2C2C2E | Secondary buttons, chips, empty slots |
| ink | #1D1D1F | #F5F5F7 | Text and icons |
| inkSecondary | #6E6E73 | #AEAEB2 | Secondary text |
| separator | #E5E5EA | #38383A | Hairlines, card borders |
| strong / onStrong | #1D1D1F / #FFFFFF | #F5F5F7 / #1D1D1F | Selected segment, accepted slot, shutter ring |
| red / onRed | #D9291C / #FFFFFF | same | Primary action, shutter core |
| redText | #C4231A | #FF6B5E | Red as text |
| photoPaper | #FBF3E1 | same | Instant-photo border |

Pack accents: Street Style `#22D3EE`, Kids Poses `#C8F53A`, Animations `#FF69B4`. Use them only on the reference frame, the current-shot slot, the pack bar and pack chips. Text on an accent fill is `#1D1D1F` in both modes.

Dark mode uses neutral black and charcoal. No navy or blue tint.

## Type

System font (SF Pro) with Dynamic Type. Sizes below are the default size.

| Role | Size | Weight |
|---|---|---|
| Screen title | 22 | Bold |
| Pose cue, photographer | 24 | Bold |
| Pose cue, subject | 42 | Bold |
| Countdown numeral | 120 | Bold |
| Body | 16 | Regular |
| Button | 16 | Semibold |
| Rail button label | 13 | Semibold |
| Caption | 14 | Regular, inkSecondary |
| Chip | 12 | Bold, uppercase |

No serif and no italic lettering anywhere in the app.

## Shape and spacing

- Minimum touch target 44 × 44.
- Radii: cards and photos 20, small photos 12, buttons 14, primary button 16, chips 16, pills 22, slots 8.
- Spacing steps: 6, 10, 14, 18, 24.
- Light mode cards carry a soft shadow. Dark mode has none; use the separator border.
- Photos sit inset with rounded corners inside a screen. They do not run edge to edge, except the full-screen camera on a standard iPhone.

## Components

**Shutter.** 78 circle. 4 ring in `strong`, 4 gap, red core. Text label underneath for the timer ("Start · 3s"). Accessibility label "Start countdown".

**Shot slot.** 26 × 34, radius 8, four in a row (or a column in compact width). Three states:
- Accepted: `strong` fill with a check icon.
- Current: pack accent fill, the shot number, and a 2 ring in `strong`.
- Empty: `fill` background, the shot number in `inkSecondary`.

**Side rail (regular width, landscape).** 218 wide column (the handoff gave 150; the four slots with 44-point touch targets need 218, and at 150 or 170 the right side of the rail was outside the display) on the trailing edge. Top to bottom: the More menu, pose reference thumbnail (the pose name is on the cue line only), four slots, shutter, poses button. The flip button is directly left of the shutter. In review it shows Keep shot and Retake. On the finished screen it shows Save Strip, Share, Save Originals.

**Side bar (compact width).** 60 wide column on the trailing edge, below the outer camera: close, four slots stacked, shutter.

**Pose reference thumbnail.** 104 × 124, radius 14, 3 border in the pack accent. No pose name underneath: the name shows one time, on the cue line.

**Reference frame, subject display.** The complete reference image with no cut, as large as the display permits, at the far right. The background of the picture continues to the edges of the display (the line of pixels at each edge of the picture is drawn across the space beside it), so the display has no empty band and nothing is cut. A photo pose picture has no plain edge for this. It has a wide copy (`pose-<id>-wide`, 16:9, the person at the right) that covers the display with its right edge at the right. A photo with no wide copy shows complete, with black beside it, because a 3:4 photo that covers the display loses the head or the feet. The display is used to its edges. 5 border in the pack accent around the display, no "Pose reference" chip and no pose name on the picture (owner decisions, 2026-11-15).

**Cue line.** Pose name at 24 bold with a caption under it ("Shot 2 of 4"). Sits under the photo on the leading side, never across the hinge.

**Countdown.** Numeral at 120 bold with three pips beside it. Filled pips are the seconds left. Placed below the photo, clear of faces.

**Pose guide.** Small copy of the reference (46 × 55, accent border) in the top-leading corner of the live photo on the subject display. Shown during live framing only.

**Glam light.** Removed (owner decision, 2026-11-17). The booth has no fill light: the warm display hid the live picture during the countdown.

**Chip.** Fill background, 12 bold uppercase. Accent variant uses the pack accent fill. Over a photo, use `surface` as the chip background.

**Buttons.**
- Primary: red fill, white label, height 56 for the main call to action, 50 elsewhere.
- Secondary: `fill` background, ink label.
- Outline: `surface` with a separator border.
- Rail button: 122 wide, min height 54, icon above label.
- Disabled: `fill` background, `inkSecondary` label.

**Segmented choice.** Pill container in `fill`; selected segment in `strong` with `onStrong` text and a check icon. Used for Classic / Copycat and Strip / 2×2.

**Pack card.** A card in the pose library grid: the poses of the pack as a block of small pictures (two in each row), the name, a one-line description, and a 2 border in the pack accent. A tap selects the pack. The grid replaces the long list of pack rows (owner decision, 2026-11-15); the packs show together with little scroll.

**Instant strip.** `photoPaper` border, radius 4. Vertical (four stacked) and 2×2. Optional caption line with the wordmark and date.

**Status banner.** `surface` card over the photo with a warning icon and one sentence.

## Screens

Each entry gives the state, the primary action and the layout rule.

### 1. Home (removed)
- The app has no Home screen (owner decision, 2026-11-15). It opens on the viewfinder with the classic booth. The system asks for camera access at the first launch.
- There is no Classic / Copycat choice and no Start a Booth. The poses button of the booth changes the pack.
- A set that is not complete comes back at launch and continues at "ready" with no Resume step. A finished set that was saved to Photos does not come back.
- The booth has no close button. "New set" in the More menu starts again during a set, after a confirmation.
- The picture has no "Live" label, on the inner display and on the outer display.

### 2. Choose a pose (Copycat)
- State: pose selected, one shot accepted, next shot pending.
- Primary action: shutter (starts the countdown).
- Photographer: live photo on the leading side with the cue line under it; side rail with the one pose reference thumbnail. A sideways swipe on the photo, or the poses button, changes the pose. No leading panel: a second pose picture beside the photo conflicted with the rail thumbnail. The wide booth has this one layout with one screen and with two, and with each camera (owner decision, 2026-11-15).
- Tall display (a closed iPhone Duo, a standard iPhone): a viewfinder as in a camera app. The upright 3:4 picture has the full width. The pose picture, with no name, is in the bottom-leading corner of the picture. The black bar below has the four progress bars and the shutter row. The shutter row is in the center: the flip button, the shutter, and the poses button. The zoom choices are in the center of the bottom of the picture. The countdown numeral is large, on a card in the center of the picture; the bar then has Cancel only. There is no cue line.
- Subject: large reference in an accent frame. No "Pose reference" chip and no pose name: the people see the full picture (owner decisions, 2026-11-15).
- The reference must look different from the live camera: different image treatment and an accent frame. It has no label (owner decision, 2026-11-15).

### 3. Follow the cue (subject display)
Three states in order. The live crop does not change between the second and third.
1. Pose reference: reference image, with no pose name.
2. Live framing: live photo with the pose guide in its corner, with no pose name.
3. Countdown: live photo, numeral and pips below it. The pose guide and cue are removed.

### 4. Kids Poses and Animations
- Photographer sees the live photo and controls when the countdown starts.
- Subject sees an illustrated character and a short cue ("Freeze like a robot"). Accent is lime.
- Animations: the character demonstrates the move. With Reduce Motion on, show the still final pose instead. Label the two states "Animated" and "Still". A clip that the customer made or asked for plays with Reduce Motion on too: the record screen after a recording, and the replay in the pack editor (owner decision, 2026-11-17).

### 5. Review and retake
- State: a shot was just captured and its slot is selected.
- Primary action: **Keep shot**. Secondary: **Retake shot N**. Both have an icon and a word.
- Subject sees the captured shot and "Shot N".
- A retake brings back the same pose reference on both displays. Only the selected slot is replaced, and only once the new take is kept. Other accepted shots are untouched.

### 6. Finish the strip
- State: four shots accepted.
- Primary action: **Save Strip**. Then **Share** and **Save Originals**, all on the trailing rail.
- Photographer: Strip / 2×2 choice, vertical strip on the leading half, 2×2 on the trailing half.
- Subject: the finished strip.
- The exported image is the strip alone: paper border, four shots, wordmark and date. No device and no UI.

### 7. One screen only
Triggered when the outer display becomes unavailable mid-session.
- Pause the countdown. Show a banner: "Outer display unavailable. Countdown paused."
- Move the pose cue (with a small reference thumbnail) into the camera view. Keep the pose, the current slot and accepted shots.
- Primary action: **Resume** (regular width) or **Continue on one screen** (compact width). The countdown restarts only after that tap.
- If the outer display returns, let the photographer restore the subject view before shooting.

### Standard iPhone (single screen, portrait)
From the "Light style" screens.
- Camera: photo fills the top; black bar at the bottom with last-shot thumbnail, shutter (white ring, red core) and a Poses button; four progress bars above them; "Shot 2 of 4" and zoom chips over the photo.
- Customer packs (owner decision, 2026-11-15): the first card of the pose library is "New pack". It opens the pack editor: a pack name, and four poses, each with a name and a Record button. The record screen shows the live camera, a 3-2-1 countdown, a 5-second silent clip with a progress bar, then "Use this pose" (red) and "Record again". "Save pack" is the one red action of the editor, and it is available when the pack has a name and four clips. A customer pack is in the group "Mine". A long press on its card gives "Delete pack", with a confirmation. The clip size (720 x 960), its bit rate (1.5 Mbit/s), and the 3-second start allowance are design values.
- Pose tray: removed (owner decision, 2026-11-15). The poses button opens the pose library at once.
- Pose library: a grid of pack cards in the order of their groups (Classic, Kids, Street, Trends), with a filter All / Kids / Street / Trends. A tap on a card selects the pack. There is no Saved tab and no star; the choice of a pose for one shot is the sideways swipe on the photo (60 points or more), or the ‹ › buttons beside the pose picture, with a dot for each pose of the pack below it. A pose shows one time in a session: the change trades poses with the open shot that had the pose, and it skips the pose of an accepted shot (owner decisions, 2026-11-20).
- Strip builder: choose four, frame colour chips (Cream, White, Black), layout chips (2×2, Strip), Retake and Save Strip.

## Layout rules for iPhone Duo

From Apple's "Designing for iPhone Duo" guidance.
- Regular width layout for the inner display, compact width for the outer display. Use size classes; no fixed widths.
- Controls sit on the trailing side on the outer display and on the inner display in landscape.
- Keep controls and important text clear of the fold. Only the live photo may cross it.
- Keep control positions the same across poses of the device. Move only what is needed.
- The outer camera is in the top trailing corner and is always visible. Keep chips and the cue clear of it.
- Keep state identical across both displays.
- During capture the subject display shows no purchasing, navigation or camera settings.

## Accessibility

- Text contrast at least 4.5:1, 3:1 for text 24 and larger.
- Every icon-only button has an accessibility label.
- Every animation has a static equivalent. Sound is optional.
- Countdown numerals never cover faces.
- Shutter, Keep and Retake are identifiable without colour.

## Verify on a physical iPhone Duo

- Hinge geometry and the width of the folding region.
- Where the inner camera appears when active and what it pushes aside.
- Outer camera and Dynamic Island clearance.
- Outer display availability through capture and review, and the delay between displays.
- Matching live crop on both sides, after mirroring.
- Cue and countdown readability at portrait distance, indoors and in sunlight.
- Pause and resume across posture changes. A fold just before the timer expires cancels the pending shot.
- One shutter event produces one take in the correct slot.
- Thumb reach to the shutter on the trailing rail.

## Open decisions. Ask before building.

1. **Home screen.** Decided 2026-11-15: no Home. The app opens straight into the camera with the Classic pack.
2. **Red for all primary actions.** This spec uses red for Keep shot, Save Strip and Resume. The earlier rule was red only for Start a Booth. Confirm.
3. **Create together.** Friends adding one shot each by link appears in the Light style screens. It needs share links and conflicts with "No account". Not in scope until confirmed.
4. **Controls with no home.** Timer length, the outer display toggle, captions, pause, and Copycat's Silhouette and Replay are not in these designs. Defaults assumed: 3 seconds, outer display on.
   Owner decision, 2026-11-15: the booth has a pose match (a match meter on the photographer's side, an automatic shutter switch in the More menu, and the match of the shot in review). Its three limits are provisional until the owner sets them on the phone.
   Owner request, 2026-11-17: the clip of a customer pose plays over the camera picture. A tap on the pose picture opens the clip large; "Ghost" puts it over the live picture, partly transparent. Both start with a tap, so they play with Reduce Motion on. The owner set the ghost transparency (`PoseClipTuning.ghostOpacity`) to 40% on the phone (2026-11-17). The ghost also shows on the outer display, over the live picture, so the people in the photo line up with it; "Ghost" changes the outer display to the live picture.
   Owner request, 2026-11-17: the finished picture can show the match score in the center of its footer ("92% match"), with a switch that is off at the start. The score is the mean of the shots whose pose picture has a person; a shot with no person counts as 0. For a pack of the customer, "Share strip and pack" sends the picture and the pack file together, after a note that the files have pictures and video of people. The default, the mean rule, and the stamp size are design values that the owner must still confirm.
   Owner request, 2026-11-17, the duet: a switch "Duet video" in the More menu, off at the start of each run and only for a pack with clips. With it on, the booth records a silent clip of the people during each countdown, with the length of the countdown. A sign "Recording video" with an icon shows on the two displays for that time. The clips are in the temporary folder, in memory of the session only. A manual shot has no countdown, so it has no clip. "Save duet video" on the finished screen makes one upright video (1080 x 1920, H.264, silent) and saves it to Photos: for each pose with the two clips, the clip of the pose above the clip of the people, on the cream paper, with the wordmark and the pose number. The score of the shot shows there when the picture shows the match score. The sizes are design values. (The look of the video changed on 2026-11-21; see the next item.)
   Owner decisions, 2026-11-21, the duet video look: a split screen from edge to edge, for sharing on TikTok, Reels and Messages. The video has its own fixed colors, as the exported strip has, so it can be bolder than the quiet camera screens; red is allowed in the video and in a REC dot. The clip of the pose is the top half and the clip of the people is the bottom half (1080 x 960 each), with a white line of 8 between them. Each clip covers its half: an upright clip is cut from the bottom, so faces stay; a wide clip is cut at its sides. The story: an intro card (black, the pack name, a red "DUET" pill) for 1.0 s; for each pose a title card ("POSE 2") for 0.6 s, the two clips for the length of the countdown with the caption "POSE 2" at the bottom left of the top half, a white shutter flash for 0.15 s, and a freeze of 0.8 s that keeps the last picture of the pose above the photo of the shot; the finished strip for 1.5 s at the end. When the picture shows the match score, a red pill at the top right of the bottom half counts up from 0 in 0.6 s of the freeze, then pops. The caption is 92 pt bold white with a soft shadow, the pill text 64 pt, the white wordmark 56 tall at the bottom right, and the space to the edges 48. These are design values that the owner confirmed.
   Owner decision, 2026-11-17: a pose clip keeps the full wide camera picture (4:3) when the customer records it with a wide camera picture. The outer display shows such a clip from edge to edge, as it shows the live picture. A 3:4 view shows the middle part. A clip from an upright camera picture, and each clip made before this change, is upright 3:4 and shows complete on the outer display, with black beside it.
   Owner decision, 2026-11-21, the duet video sound: original sounds that the app makes (no file, no microphone, so no license and no permission), in a quiet mix so that music a customer adds later stays on top. A beep for each second of the countdown, counted back from the shot (880 Hz, 0.12 s); a double shutter click at the flash (two bursts of noise, 0.03 s, 0.05 s apart); a quick rising pop when the score pops (400 to 900 Hz, 0.09 s). AAC, one channel, 44.1 kHz, 96 kbit/s. The frequencies, lengths, and levels are design values for the owner to confirm by ear.
5. **Display sizes.** Mock frames are proportional stand-ins (inner 4:3, outer 3:4). Use real device metrics.

## Assets

- `wordmark.png`: PEEK wordmark, red on transparent. Tint white in dark mode.
- Sample photos and illustrations in the lookbook are placeholders. Do not ship them.

## Reference

- Apple, Designing for iPhone Duo: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
