# Bearforming checkpoint — November 14, 2026

Continued existing Dordisha/Bearforming draft PR #6 at 60c8c0e, verified with fresh Git fetch and connected PR metadata. Read November 13 checkpoint, roadmap, source, recent owner instructions and unchanged Library Daily-Xcode-Test-Plan-v1. No newer owner approval or structured personal workout/cycling records retrieved. Existing six-exercise defaults are retained; no replacement app or invented activity.

## Bounded increment: opt-in rolling Upper/Lower

Today offers an optional sequence starting with the user's explicit Upper or Lower choice. Enabling/resetting/disabling asks before replacing preview edits and clears the one-workout override; usual profile focus/history stay unchanged. The next slot persists across missed days and relaunch. Planning uses sequence focus unless a one-workout override is selected. Add/substitute continues using the effective planning focus.

At start, a matching workout records its sequence slot. At finish, it advances exactly once only if all remaining exercises have nonempty sets, every set has a completion timestamp within start/finish, all exercises are recognized and compatible with the slot, and at least one is a primary upper/lower movement (core is neutral). Empty/partial/future/unknown/opposite/core-only work does not advance. A different-focus override does not consume a slot; returning to sequence resumes that slot. Sequence settings cannot change during an active workout. Optional fields preserve legacy decoding. These are explicit product rules, not a clinical recovery assessment; edited shorter workouts can qualify if every remaining set meets them.

The independent history advisory is hidden while sequence mode is on to avoid contradictory next-focus recommendations; existing saved-draft recovery/cycling notices remain. Six-exercise target, time/equipment/readiness gates, exact completed-exercise recovery exclusion, reviewed cycling provenance and no automatic warmup/effort/weight inference remain unchanged. No cardio mode yet.

## Validation

Six new core tests cover six-exercise generation/advancement/idempotency, partial/empty/invalid dates, different-focus overrides, unknown/opposite/core-only edits, persistence/missed days/active roundtrip, and configuration guards/legacy fallback. Expected total 64. Local Scripts/check.sh blocked: Swift/Xcode/simulator/device unavailable. git diff --check passes. Final hosted core-test/SDK-build results and exact SHA recorded in PR #6. Build success is not simulator interaction acceptance.

## Native scenarios — awaiting approval, NOT RUN

BF-T01–20 and R01–20 remain proposed; no approval found. Concrete R07–R10/R18 refinements for review:
1. Edit a draft, choose sequence start Lower, Cancel: identical draft and settings. Confirm: Lower sequence and new eligible draft, usual profile unchanged.
2. Relaunch after a missed day: same edited preview, IDs and Lower slot; no catch-up workouts.
3. Start, log all remaining sets, relaunch/resume, finish: exactly one history item and Upper next. Repeat finish: no duplicate or extra advancement.
4. Finish with one undone set, no completed sets, unknown/opposite exercise or only core: keep same slot.
5. Override Upper while Lower next: finish override; Lower remains next. Clear override and verify sequence plan resumes.
6. Disable sequence with confirmation; usual focus restored. Upgrade legacy saved active/draft/history and inject save failure: preserve last durable state and show failure, never claim advancement saved.
7. Pain/unwell still blocks start; reviewed recent cycling remains a qualitative notice and does not advance sequence or mark warmup complete.

Acceptance requires >=95% of all approved cases plus every critical case passing; blocked/skipped cases disclosed and incomplete runs cannot pass. No native acceptance percentage. Next: cardio mode and native sequence/lifecycle acceptance after approval. January 2027 remains conditional. No new costs, workflow, issue, merge/release, outreach or dashboard feed.
