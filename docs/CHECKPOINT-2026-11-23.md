# Bearforming checkpoint — November 23, 2026

Continued verified Dordisha/Bearforming draft PR #6 from e19fabf17971bea52b3776936441c7769d4d3bf3. Fresh Git and connected PR agree; working tree initially clean. Read current checkpoint/source/backlog, PR conversation, Library market direction and Daily-Xcode-Test-Plan-v1. Owner history/import refinements still apply. No native approval found; existing issue #2 and critical BF-T17 remain the owners, no new case/issue or separate lead alert.

## Bounded increment: explicit set quantities and confirmation

Occurrence review now accepts one manually added row per known set, optional reps/load and explicit lb/kg unit. Rows start blank, not 3x8/zero load. Empty/whitespace input remains unknown; invalid numeric text rejects save. Reps allow whole 1–999; load allows explicit 0–9999, decimal point or comma. Unknown units remain unknown; no automatic conversion or duration parsing. Units are retained per set. Partial known information can be saved without confirming it.

Explicit quantity confirmation requires valid, fully quantified nonempty set rows, a known nonfuture workout day (UTC day comparison), and completed occurrence status. Confirmation stores an exact snapshot of the occurrence. Changing day/movement/status/row identities/reps/load/unit/order invalidates it, including after persistence. It can be explicitly cleared/reconfirmed. Legacy occurrences decode with no sets/confirmation.

Confirmed review evidence still does not create Workout/LoggedSet, change previous performance, six-exercise recommendations, sequence or progression. Applying reviewed evidence to history with deduplication/correction/revocation rules is the next separate step. Original source text, provenance and other-day rows remain preserved; owner corrections remain manual, not semantic inference. Existing live logging, manual modes, cycling/recovery and prior synthetic composite regressions remain intact. No personal workout data used.

## Validation and native acceptance

Four new synthetic core tests cover explicit quantities/units/confirmation persistence and planning isolation; material-edit invalidation; unknown/invalid/explicit-zero gates; and date/status/duplicate/legacy behavior. Expected final core suite: 103. Local diff check passed. Scripts/check.sh blocked locally: Linux has no Swift/Xcode/simulator/device. Final hosted macOS core/unsigned simulator-SDK results and exact commit/tree/run linkage are recorded on PR #6 after execution. No advance pass claimed here.

Existing critical BF-T17 refinements — pending owner vetting, NOT RUN interactively:

1. Reuse the synthetic adjacent-day source; add known set rows only to the corrected completed occurrence. Blank reps/load/unit and unknown day remain unresolved and cannot be confirmed. Implausible duration text remains original evidence, not a duration value.
2. Enter 10 reps / 12.5 kg explicitly, known nonfuture day; confirm, save/reopen. Values, unit and confirmation persist; no change to adjacent-day row or source. Enter explicit 0 lb separately: distinguish from blank load.
3. Edit each confirmed field or add/remove a set; confirmation becomes invalid until explicitly reconfirmed. Planned/skipped/future-dated occurrences cannot be confirmed.
4. Invalid/negative/fractional reps, exponent notation, unsupported unit or malformed load block save; cancel/save failure preserve last durable values. Large text/VoiceOver controls remain a native review requirement.
5. Even confirmed review notes remain excluded from live history and progression until a future explicit apply operation is implemented and tested. No composite native pass is claimed.

Native approved cases verified: 0; native cases run: 0. BF-T01–20/R01–20 and refinements remain proposals. Overall acceptance requires >=95% of all approved cases passing plus all critical cases passing, with blocked/skipped cases disclosed and never counted as passes. Hosted unit/SDK checks are not simulator interaction/device acceptance. January 2027 conditional.

Next: explicit application of reviewed dated sets to history with source-identity deduplication, unit handling and correction/revocation semantics; approved BF-T17 native testing. No new costs, workflow, issue, merge/release, outreach or dashboard feed.
