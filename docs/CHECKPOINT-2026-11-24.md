# Bearforming checkpoint — November 24, 2026

Continued Dordisha/Bearforming draft PR #6 from bf3ed96762995c21ae6c58d2172588b9d37955f6, matching fresh remote and clean checkout. Read November 23 checkpoint, roadmap, current source, PR and issue #2 conversations, current Library market-direction and Daily-Xcode-Test-Plan-v1. No new owner acceptance approval found.

## Bounded correction

Inspection found that snapshot comparison alone allowed edited quantities to regain old confirmation when their original values were restored. LiftingOccurrence now clears the stored confirmation on material changes to identity, day, movement, status or set rows (including nested quantity/unit/identity edits). Reverting those fields cannot silently reapprove them; explicit confirmation is required again. Identical binding writes preserve confirmation, and decoding saved unchanged confirmations remains compatible.

Two synthetic regression tests cover edit/revert across persistence for all fields and no-op binding writes. Existing 103 tests are retained, including adjacent-day correction, unknown quantities and partial six-movement history; expected total 105. No personal workout data used. Review notes remain separate from Workout/LoggedSet and progression. Existing six-exercise planning, manual modes, cycling/recovery, original evidence and authored plans are unchanged.

## Validation and acceptance

Local diff check passed. Scripts/check.sh is blocked locally (Swift required; Linux has no macOS/Xcode/simulator/device). Final hosted macOS regression and unsigned simulator SDK compilation results will be recorded on existing PR #6 with commit/tree linkage. No native pass is implied.

Refine existing critical BF-T17, pending owner vetting, NOT RUN interactively: confirm a synthetic completed occurrence with known date, 10 reps and 12.5 kg; change reps to 11, save/reopen, restore 10 and save/reopen. Confirmation must remain off until explicitly selected. Repeat for date, movement, status and set add/remove/unit edits. Merely opening/saving an unchanged review must retain confirmation. Cancel must preserve the last durable entry. This extends the existing case, not a new case or issue.

Approved native cases verified: 0; native cases executed: 0. BF-T01–20/R01–20 remain proposals awaiting approval. Interactive simulator/device access is unavailable. Overall acceptance is unestablished and requires >=95% of all approved cases plus every critical case passing, with blocked/skipped cases disclosed and not counted as passes.

Next: explicitly apply confirmed review sets to history with source-identity deduplication, unit handling and correction/revocation semantics; owner-approved native acceptance. Issue #2 remains structured-import owner. January 2027 conditional. No new costs, workflows, issues, production merge/release, outreach or dashboard feeds.
