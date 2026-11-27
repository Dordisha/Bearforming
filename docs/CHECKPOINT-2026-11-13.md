# Bearforming checkpoint — November 13, 2026

Continued Dordisha/Bearforming draft PR #6 from a74e4d5, verified by fresh fetch and connected GitHub metadata. Read latest checkpoint, roadmap, source, owner conversation and unchanged Library Daily-Xcode-Test-Plan-v1. Library source archive predates the delivery branch; no replacement app created. No newly verified personal workout records available or imported.

## Bounded increment: next-workout focus override

Choose Full body, Upper, Lower, Push or Pull for the next workout without changing the usual profile focus. The evidence-based advisory offers an explicit action to use its suggestion. A confirmation dialog discloses that applying a focus replaces preview edits; cancellation leaves the draft intact. The optional override and draft persist across reopening (including another day), and starting consumes the override atomically with the draft. Reset/time/equipment changes use the override until it is consumed or explicitly returned to usual focus. Active workouts reject override changes. Legacy state decodes without the new optional field. No automatic program advancement or cardio mode is claimed.

The six-exercise default, time/equipment/readiness constraints, completed-set recovery exclusions and reviewed cycling notices remain. No inferred personal activity, fatigue percentage, ride intensity, warmup credit or numeric training loads. Add/substitute choices use the effective planning focus. Existing usual preferences remain editable.

## Regression checks

Six new unit cases cover six-movement Lower without changing usual Upper, persistence/edit preservation, consumption and active protection, reset/return to usual, legacy/invalid mode, and pain/equipment boundaries. Expected suite: 58 tests. Local Scripts/check.sh blocked: no Swift/Xcode/simulator/device. git diff --check passes. Exact final hosted core-test/SDK-build result is recorded in PR #6 after execution; source checks never constitute simulator interaction acceptance.

## Native acceptance proposals — awaiting approval, NOT RUN

No approval found in current owner instructions, PR discussion or retrieved Library plan. BF-T01–20 and market R01–20 remain proposed. Concrete R08/R11/R18 refinements:
1. Save usual Upper and edit a draft. Choose Lower for this workout, then Cancel: verify exact unchanged exercise IDs/order/sets and usual focus.
2. Confirm Lower: verify actual eligible lower-body draft and usual Upper retained; remove one exercise, terminate/relaunch and verify identical edited draft plus Lower planning focus.
3. Change time/equipment then reset: override remains Lower with valid options/budget. Choose Use usual focus and confirm: usual Upper applies.
4. Start overridden workout: active exercises match preview; reopen Today and Resume unchanged. Finish and reopen: next preview uses usual Upper; repeated finish never duplicates history.
5. Upgrade legacy persisted state; verify existing history, active workout and edited draft survive. Inject write failure when applying override: visible error and previous durable state retained.
6. Pain/unwell still prevents starting; reviewed cycling prompts remain evidence-based with no automatic volume/warmup change.

All proposed outcomes NOT RUN. Acceptance requires >=95% of all approved cases, every critical case passing, and disclosed blocked/skipped cases; incomplete runs cannot pass. Next: rolling-plan progression with explicit partial/completion semantics, cardio mode and approved native acceptance. January 2027 remains conditional. No new costs, issue, workflow, production merge/release, outreach or dashboard feed.
