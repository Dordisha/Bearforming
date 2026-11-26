# Bearforming checkpoint — November 26, 2026

Verified Dordisha/Bearforming draft PR #6 at 349122eb53b69341c21503570ebaaaf253791e02. Local checkout was clean but one commit behind; fetched and switched to verified remote before editing. Read current checkpoint, roadmap, source, PR conversation and current Library market direction/test proposals. No owner native approval found. Issue #2 remains structured import owner.

## Bounded increment: explicit catalog identity review

Each lifting occurrence can now be explicitly matched to an existing catalog exercise or left Not matched / unsure. No fuzzy matching or automatic inference. Source movement wording and original message are retained. Changing source movement clears its match and quantity confirmation; changing/clearing the catalog match invalidates confirmation, while unchanged choices preserve it. Unsupported match requests reject without mutation; unavailable persisted matches cannot be quantity-confirmed. Legacy records without the optional field remain readable. Unmatched occurrence notes remain savable/reviewable and cannot affect progression.

Three synthetic regressions cover explicit matching, persistence/source/history isolation, correction/clear/invalid requests, and absent-field compatibility. Existing composite import and six-movement partial-history regressions retained; no personal workout data copied. Expected suite 110. No Workout/LoggedSet promotion yet: applying confirmed history still requires unit handling, date precision, deduplication and correction/revocation semantics. Six-exercise defaults, manual choices, cycling/recovery and edited drafts preserved.

## Validation and native acceptance

Local diff check passed. Scripts/check.sh blocked locally: Linux lacks Swift/macOS/Xcode/simulator/device. Final saved-source hosted regression and unsigned SDK results will be recorded on PR #6 with commit/tree/run evidence; prior 107/107 result is historical, not today's verification.

Refine existing critical BF-T17, pending owner vetting, NOT RUN: use the synthetic adjacent-day source; leave an ambiguous movement unmatched, then explicitly select the catalog equivalent only when supported. Save/reopen: source wording, original message, day and selected match persist without influencing Today. Confirm quantities, change catalog choice and verify confirmation clears. Edit source movement and verify both match and confirmation clear, including after restoring original wording. Cancel preserves last durable record; clear match keeps source notes. Check VoiceOver and large text picker usability. Retain earlier unknown-quantity and partial-finish cases; no new native case or issue.

Native approved cases verified: 0; executed: 0. BF-T01–20/R01–20 remain awaiting owner approval. Interactive simulator/device access unavailable. Acceptance requires >=95% of all approved cases and all critical cases passing; disclose blocked/skipped without counting them as passes. Hosted unit tests/SDK compilation are not native acceptance. January 2027 conditional.

Next: apply explicitly reviewed history with unit/date precision, source deduplication and correction/revocation safeguards; approved native acceptance. No new costs, workflows, issues, production merge/release, outreach or dashboard feed.
