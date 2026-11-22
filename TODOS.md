# TODOS

## Add languages from App Store data (decision 17A, 2026-11-22)

- **What:** Review downloads by country 30 days after the 1.0 launch. Then translate the strings, the pack names, and the App Store screenshots for the top non-English markets.
- **Why:** 1.0 ships in English only. Gen Z audiences are global, and local pack names and screenshots sell better.
- **Pros:** The translation work goes where the users are, and the launch has no delay.
- **Cons:** Early users outside English markets get English only.
- **Context:** All 212 strings are in `Peek/Resources/Localizable.xcstrings`, with generated symbols. The 30-day check is a review date, not a design value. See `docs/plans/viability-2026-11-22.md`.
- **Depends on:** The 1.0 launch and App Store Connect analytics.
