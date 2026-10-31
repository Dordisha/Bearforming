# Personal Fitness App — January 2027

Owner: Dorian Dishani. Original native iPhone implementation. Fitbod is the experience reference; Liftosaur is a technical learning reference only. No Fitbod private code or algorithm was recovered. No Liftosaur code is included.

## Product contract

Today: suggest a workout using confirmed goals, equipment, time, recent completed training and today's feedback; explain why and allow changes.
Workout: previous performance; log and undo sets, reps and weights; substitute exercises; rest timing; dependable restoration.
Journey: lifting, cycling, weight, measurements, photos and personal milestones.
Coach: everyday conversation grounded in reviewed records, clearly separating known facts from uncertain inferences.

## Delivery gates

November 2026: confirm scope/design; implement and device-test logger; import/review initial history when the export is supplied.
December 2026: progress views, explainable workout suggestions, grounded coach; TestFlight testing on Dorian's iPhone.
January 2027: beta fixes, reliability/privacy verification, release preparation. Decide personal TestFlight versus public App Store before committing a launch date. Public release depends on App Review.

First acceptance gate: start, log, terminate, reopen, restore accurately. Currently pending compilation and device validation.

## Next implementation work

1. Compile the supplied source in Xcode; run persistence tests and device checklist; fix numeric-field commit and lifecycle issues if observed.
2. Editable equipment, time, goals, readiness and unit preferences. Keep planning distinct from completed training.
3. Chat export import with provenance and explicit per-record review; export/delete controls and data migration/recovery.
4. Journey entries for cycling, body metrics, photos and milestones, preserving original units and dates.
5. Rule-based suggestions from confirmed records, with readable reasons and user overrides; then conversational coaching through a secure backend.
6. Accessibility, app icons, privacy policy, signing, TestFlight, release QA.

## Research provenance supplied by owner

Node.js, Codex CLI, REA and Hopper were installed on Dorian's Mac and REA connected to Codex. This environment has not independently verified that setup.
Fitbod web automation was blocked; official documentation supplied feature descriptions.
Liftosaur REA inspection reached home via onboarding and Basic Beginner Routine. Active logging was not successfully demonstrated. Set completion, timers, history and progression findings came from public source; deployed behavior/version equivalence remains unverified.

## Decisions deferred

Final name/design, exact launch date, personal beta versus public launch, monetization, coaching provider and budget, cloud backup/sync and HealthKit. Default initial build is offline and personal; no account required.
