# Bearforming — native iPhone fitness app

Open **Bearforming.xcodeproj**, select the **Bearforming** scheme and an iPhone simulator, then Run. Opening Package.swift builds only FitnessCore.

## Current upgrade
- Today: saved time, equipment, goal and readiness check-in. Planner offers up to six exercises by default (seven configurable), subject to time, equipment and readiness. Completed set timestamps drive the 48-hour recent-exercise exclusion, including saved active sets. Familiar logged exercises are preferred within each movement group. Reviewed completed Cycling entries within 48 hours prompt a fatigue check without guessing ride intensity or changing warmup/volume. Goals are captured, but goal-specific progression is not implemented.
- Workout: editable sets, complete/undo, previous performance, substitutions, absolute rest deadline, synchronous atomic saves. Valid text edits save immediately; invalid input stays visibly unsaved.
- Journey: lifting summaries and dated free-text weight, cycling, measurement and milestone records; edit/delete and review status.
- Import: choose conversations.json (up to 50 MB). Fitness-keyword messages become pending review records. Original text, raw timestamp, conversation link, message ID and role are retained. All branches may be extracted; records deduplicate by conversation/message identity. Assistant messages default to advice; user messages default to unclear. Review dates, units and completion manually. Imported free text does not drive load or workout-volume calculations.
- Coach: offline guided responses for today, logged progress and reviewed completed notes, with sources. Unsupported questions receive an explicit limitation. No connected AI model.

## Validation
Initial shell passed GitHub macOS CI and the owner reported it running. The first text-entry update had a compile error, corrected in this upgrade. Check Actions for current build/test results. Automated checks do not verify phone lifecycle or keyboard behavior.

## Device acceptance
Start a workout, edit values while the keyboard remains open, terminate, reopen and verify values and completion state. Repeat for undo, rest deadline and finish. Confirm old saved workouts survive upgrading. Import a small export twice, verify duplicates are skipped and records stay pending; approve only reviewed completed records and check Coach. Verify failed saves show an error.

## Remaining work
Progress photos, structured measurements/charts, goal-specific progression, open-ended AI coaching, normalized workout extraction with date/unit confidence, full data export/deletion, HealthKit, notifications, backup/cloud sync, signing, TestFlight and App Store preparation remain unfinished. This is a development build, not the January release.

No personal chat or health data is stored in this public repository. App data remains on the device. No analytics, API keys or external AI calls are included.
