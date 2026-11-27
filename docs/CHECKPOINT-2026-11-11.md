# Bearforming checkpoint — November 11, 2026

Continued Dordisha/Bearforming draft PR #6 from 754ada4, not the older local checkout. Retrieved current source, November 10 checkpoint, roadmap, GitHub issue/PR context, Library market direction and Daily-Xcode-Test-Plan-v1. Recent owner direction requests an explainable Today suggestion with manual choices; market report/mockups remain proposals. No approved native scenario list found. No structured new personal workout records were available in these retrieved records; no private activity was seeded or inferred.

## Bounded increment: truthful saved-workout summary

Today now leads with the saved draft's exercise count, planned set count and estimated duration, plus Start/Resume. It no longer displays an explanation generated for a different hypothetical workout. Legacy drafts are labeled saved drafts without invented focus or generation rationale. Empty drafts show zero exercise time. Existing Add/Remove/Substitute/Reset controls remain available. Warmup toggle explicitly says strength warmup rather than conflating it with cycling.

Read-only summary flags exact exercises with actual completed sets within 48 hours (including active sets), excluding future/uncompleted evidence. Reviewed completed recent cycling prompts an energy/leg-fatigue check without inventing intensity or marking warmup complete. Draft IDs/order/sets are never mutated by the summary. Existing six-exercise planner, recovery filters, logger validation and storage schema remain unchanged. Rolling Upper/Lower queue, today-only overrides, muscle tagging and cardio mode remain backlog, not implemented by this increment.

## Validation

Five new unit cases cover edited persisted counts/duration, empty/missing drafts, completion boundaries and active/history overlap, cycling provenance, and pain/budget warnings. Existing 42 cases retained (47 total). Local Scripts/check.sh is BLOCKED: Swift absent; Linux has no Xcode/simulator/device. Existing hosted workflow will run the final pushed candidate; exact commit/result is recorded in PR #6 after execution. Hosted unit/SDK compilation is not simulator UI acceptance.

## Native scenarios: awaiting approval, NOT RUN

BF-T01–20 remain proposed; market R01–20 also proposed. Concrete R12/BF-T05 refinement for review: generate normal six-exercise draft (18 sets), remove one exercise, verify five exercises/15 sets and recalculated estimate; reorder/substitute, terminate/relaunch, verify identical draft and summary. Remove all: zero exercises/sets/minutes and Start disabled. Add a reviewed recent completed cycling note: show unknown-intensity context, preserve draft and warmup. Planned/unapproved/future cycling must not trigger the message. Add recent completed matching exercise evidence: warn without rewriting the draft. Start then reopen Today: Resume leads and no draft counts are represented as the active session. Pain/unwell blocks new starts even for a saved draft. Native execution requires approval and a simulator/device.

Acceptance requires >=95% of all approved cases, every critical case passing, and blocked/skipped/incomplete cases disclosed (incomplete run cannot pass). No acceptance percentage claimed. Next: rolling-plan model with explicit completion semantics, reviewed actual history, and approved native acceptance. January 2027 remains the target subject to implementation and release gates. No new cost, workflow, issue, merge, release, outreach or dashboard activity.
