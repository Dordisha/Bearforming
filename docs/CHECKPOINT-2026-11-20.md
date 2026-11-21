# Bearforming checkpoint — November 20, 2026

Continued Dordisha/Bearforming draft PR #6 from ff972b5f4f5c188210579ecaf677e80d4265c40b after fresh Git/connected-PR verification. Read November 19 checkpoint, roadmap, source, PR conversation, Library market direction and Daily-Xcode-Test-Plan-v1, plus recent owner context. The November 20 instruction explicitly keeps the new history acceptance candidate pending owner vetting. Equivalent coverage exists in proposed R03/R09/R11/R12 and BF-T11/BF-T17, but no approved equivalent was found. No new issue or private workout fixture.

## Bounded increment: separate completed activity from the retained plan

Workout now supports Skip remaining sets / Restore remaining sets per exercise. Skipping retains exercise identity/order, all authored reps/weights/sets and any already completed sets. Pending skipped sets cannot be completed or edited until restored; existing completed-set undo remains available. Add-set/substitution controls are disabled while skipped. Optional persisted metadata preserves compatibility with older records.

Journey's completed-work display now lists only movements with completed, nonfuture sets. A separate Saved plan disclosure retains every authored movement and set count, with completed counts and explicit remaining-skipped labels. A zero-completed-set finish shows No completed sets logged, rather than a list resembling performed activity. Finish still archives the plan once and consumes the session draft; a later session gets its own suggestion, as before. This does not delete unperformed movements from the archived authored plan.

Today already uses completed timestamps for recent overlap and next-focus evidence. Synthetic regression now exercises a six-movement partial finish/save/reopen with four upper movements partially completed, one lower movement left planned and another lower movement skipped. Only four completed sets/movements qualify; the two unperformed lower movements do not alter the upper-work-derived Lower advisory. The partial session retains its current sequence slot. Pending import staging cannot alter Today cycling context; review and completed status are both required. No free-text lifting import is converted into structured completed sets in this increment.

Six-exercise normal planning, manual Upper/Lower/Cardio/Push/Pull, Full body, recovery selection, cardio timers and existing history behavior retained. No personal workout data imported, seeded publicly, or inferred from intention.

## Regression and native acceptance

Four new core tests: six-movement partial lifecycle/disk round trip/Today evidence/plan preservation; pending-import review/completion gating; skip/restore completed-data preservation; and legacy/planned/future evidence exclusion. Expected suite 91. Final local diff check passed; local Scripts/check.sh blocked because Swift/Xcode are absent on Linux. Hosted macOS final-source core/SDK results and exact commit/tree/run linkage are recorded in PR #6 after execution. These are regression checks, not interactive native acceptance.

### November 20 native history candidate — NOT RUN, awaiting owner vetting

This refines the equivalent proposed cases above, not an additional issue or claimed pass. Synthetic data only:

1. Start a six-movement draft: Dumbbell bench press, Seated row, Lat pulldown, Dumbbell shoulder press, Leg press, Leg curl; three planned sets each. Record one completed set for each of the first four. Leave Leg press planned; mark Leg curl remaining sets skipped.
2. Finish, save, terminate and reopen. Expect exactly one archived workout, four completed movements/four completed sets in the activity display, and all six original movement IDs/order/sets in Saved plan. Planned/skipped lower work must not count as completed activity. Partial finish does not advance the sequence.
3. Inspect Today next-focus explanation with the sequence off: completed upper work supports Lower; unperformed lower movements do not imply mixed completed work. Inspect a draft containing only the two unperformed movements: no recent-completed-overlap claim. Do not regenerate or shrink the archived six-movement plan.
4. Stage a synthetic pending Cycling candidate dated within 48 hours. Expect no cycling explanation before review and completed-status confirmation; then expect qualitative cycling context only, never inferred effort or warmup credit.
5. Critical data guard: skip/restore after a completed set, repeat finish, relaunch, and inject save failure. Completed data and authored plan remain intact; no duplicate history, false success or unsaved state presented as durable.

All data integrity and evidence-gating expectations are proposed critical gates. Also inspect skipped labels/controls with large text and VoiceOver. Native cases executed: 0; BF-T01–20/R01–20 and these refinements await approval. Local macOS/Xcode/simulator/device unavailable; SDK compilation is not simulator interaction. Overall acceptance requires >=95% of all approved cases passing, every critical case passing, and blocked/skipped cases disclosed and not counted as passes.

Next: reviewed structured lifting-history confirmation with explicit dates/units/completed sets, and approved native end-to-end history/logger acceptance. January 2027 conditional. No new costs, workflow, issue, merge/release, outreach or dashboard feed.
