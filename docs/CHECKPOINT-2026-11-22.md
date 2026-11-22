# Bearforming checkpoint — November 22, 2026

Continued Dordisha/Bearforming draft PR #6 from 5b8c4c70d7bbffbbc1aa62d220799a264dc4043b. Workspace cleanup removed the checkout; restored from the verified GitHub branch, not the older Library source archive. Read current PR/conversation, checkpoint/backlog/source/parser, Library market direction and Daily-Xcode-Test-Plan-v1. Owner November 20 refinements still apply; no native approval found. Issue #2 remains structured-import owner. No duplicate issue or separate lead alert.

## Bounded increment: manual date-scoped occurrence review

Journey review for Lifting/Imported conversation now offers optional lifting occurrence rows. Each stores its own stable identity, explicit Gregorian YYYY-MM-DD workout day (blank unresolved), movement and unclear/planned/completed/skipped status. Rows are manually authored from evidence, not generated from the transcript or message date. The editor supports correction/removal of one row without altering adjacent days or original message text, timestamp, role or reply links. Original evidence remains available in the existing Source section; copy directs reviewers to prefer owner corrections over assistant recaps. Automatic semantic reconciliation is not implemented.

Date/movement/status/unique-identity validation is all-or-nothing. Invalid calendar days, incomplete dates, empty movements or unsupported statuses cannot save. Unknown workout day remains blank rather than becoming today's date or message date. Rows are optional Codable data so old entries still decode; reimport keeps existing reviewed edits. Save/cancel uses the existing atomic save-before-publish record editor.

This is occurrence review only: sets, reps, load and duration are explicitly unresolved. Even a reviewed completed occurrence is not converted into LoggedSet or Workout, and cannot change numeric progression, previous performance, Today explanations or recommendations. Planned/skipped occurrence rows likewise remain separate from performed structured workout history. Quantified-set confirmation remains the next increment; no default 3x8/zero-load data is fabricated. Existing six-movement workouts, partial-finish/skip behavior, manual modes, cycling and recovery retained.

## Regression and acceptance

Four new synthetic core tests cover independent adjacent-day correction and source preservation; date/status/movement/duplicate validation; reviewed-unquantified isolation plus disk persistence/reimport; and legacy/removal behavior. Existing November 20/21 composite transcript tests are reused unchanged. Expected suite: 99 tests. Local diff check passed; Scripts/check.sh blocked by missing Swift/Xcode on Linux. Actual final-tree hosted macOS unit/SDK results and source/run linkage recorded on PR #6 after execution; no advance pass claimed here.

Existing critical BF-T17 refinement, pending owner vetting — NOT RUN natively:

1. Open the existing synthetic adjacent-day transcript. Manually enter separate movement/day rows for its two planned days. Review original owner correction, change only the applicable second-day row to completed and remove the unsupported second-day movement. First-day rows and original source must remain unchanged after save/reopen.
2. Leave unknown day blank and all amounts unresolved, including the implausible duration text. Mark occurrence completed and record reviewed. Expect no completed lifting sets, previous performance, progression or new Today evidence.
3. Enter invalid dates (non-leap February 29, April 31), blank movement or malformed date. Save disabled; previous durable record intact. Cancel edits, reopen, remove an occurrence, and reimport: no loss of original source or unintended adjacent-day changes.
4. Inject save failure and retry; legacy entry upgrade; inspect controls under large text/VoiceOver. Last durable record retained on failure, no false success. These remain proposed refinements of BF-T17, not another case or issue.

Approved native cases verified: 0; native cases executed: 0. Local macOS/Xcode/simulator/device unavailable. Hosted unit tests and unsigned simulator SDK compilation are not simulator/device acceptance. Overall acceptance requires >=95% of all approved cases passing and every critical case passing, with blocked/skipped cases disclosed and never counted as passes. January 2027 conditional.

Next: explicit quantified-set confirmation with known dates/units and unresolved-value gates, then approved native BF-T17. No personal workout content copied, new costs/workflows/issues, merge/release, outreach or dashboard feed.
