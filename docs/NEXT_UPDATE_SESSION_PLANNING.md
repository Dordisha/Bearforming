# Next update: full-session planning

Status: scoped, not implemented. Owner requests sessions longer than the current three-exercise cap. Personal history evidence stays out of this public repository; imported records still require review before recommendation use.

## Behavior
- Replace fixed 2/3-exercise cap with editable session size and an estimated time budget. Initial product defaults: short 20–30 minute sessions 3–4 movements; standard 40–60 minute sessions 5–6; extended sessions up to 7 when time and feedback permit. These are configurable product defaults, not personalized medical prescriptions or inferred historical averages.
- Count warmup/cardio separately from resistance/core exercises. Ask whether cycling or another warmup is already completed; do not double count its duration.
- Offer Full body, Upper, Lower, Push and Pull focus. Provide primary lifts, accessories and optional core/finishers, with add/remove/reorder/substitute before starting.
- Calculate estimated duration from sets, reps, rest and transitions, including separate warmup allowance. Warn when edits exceed available time; never silently add volume to fill time.
- Returning after a break or low-energy feedback reduces sets and optional accessories. Current pain/unwell gate remains.
- Expand equipment-tagged exercise catalog and movement/muscle metadata. Recovery filtering must consider related movements, not just identical names. Explain exclusions without presenting fixed recovery rules as certainty.
- Show eligible previous logged performance for the same exercise and weight convention. Never treat undated memories, machine differences or assistant prescriptions as personal records. Do not auto-increase loads based solely on an old history reference.

## Acceptance
1. A standard gym session can offer 5–6 distinct movements when catalog, time and feedback allow.
2. A short or reduced session stays within its estimated budget; warmup is shown separately.
3. Chosen focus and equipment are respected; substitutions remain appropriate.
4. Preview edits and started sessions survive relaunch with identical exercise IDs/order/sets.
5. Pending/advice/planned imports cannot influence workload or load selection.
6. Tests cover session budgets, equipment, recent training, restart/low-energy paths and insufficient catalog choices. CI tests and simulator compilation must pass; owner verifies the preview/logger on device.

## Sequencing
First catalog + planner tests, then editable preview, then logging/persistence integration and device acceptance. Structured reviewed-history extraction and advanced progression remain separate follow-on work.
