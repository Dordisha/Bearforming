# Bearforming checkpoint — November 19, 2026

Continued Dordisha/Bearforming draft PR #6 from 121f72ea948d98afd179fd77805fd9459ee49eee. Fresh Git fetch and connected PR match; local checkout clean before edits. Read previous checkpoint, roadmap/current source, PR conversation, Library market direction and Daily-Xcode-Test-Plan-v1, and recent owner context. No newer owner direction, approved native scenario IDs or verified personal activity records found. Existing issue tracking remains #1/#2/#5; no new issue.

## Increment: explicit Rest/recovery choice

Today now provides Choose rest/recovery and Return to training. The dated choice survives relaunch and remains selected until explicitly cleared; it is not a calendar-day auto-reset or evidence of recovered muscles/completed rest. Selecting and clearing it preserve the edited strength draft, next Upper/Lower slot, focus override, rest deadline, history and Journey evidence. No workout, calorie, fatigue or warmup credit is created. Normal six-exercise planning, manual strength modes, Full body, cardio pause/resume and existing history/readiness rules remain intact.

While selected, the start/recommendation card is replaced by the recovery notice; strength and cardio timer starts are guarded in core and UI. Actual activity can still be manually logged separately. An active strength or running/paused cardio session prevents choosing recovery; it is never silently stopped. Returning does not start a session, regenerate the saved draft, advance the sequence or bypass pain/unwell. Explicit subsequent preference/draft edits retain their existing behavior. Save-before-publish persistence remains unchanged.

## Validation

Five new core tests cover disk relaunch/full-state preservation, duplicate choices, both start guards and explicit return, active-session protection, manual logging/pain isolation, and legacy/invalid-date behavior. Expected final suite: 87 tests. Local diff check passed; Scripts/check.sh blocked by missing Swift/Xcode on Linux. Hosted macOS final-tree regression results and exact run/commit linkage are recorded in PR #6 after execution. No advance pass claimed here; SDK build is not simulator UI acceptance.

## Native acceptance — awaiting approval, NOT RUN

No approved case manifest found. BF-T01–20 and R01–20 remain proposals. Concrete R17/R18 refinements for review:

1. Critical: edit/reorder a six-exercise draft, configure Lower next and a Push override, choose recovery, terminate/relaunch. Same draft IDs/order/sets, slot/override and existing rest deadline; dated recovery choice restored; no new history entry.
2. Critical: while recovery selected, try strength/cardio starts, reopen next day, then Return to training. No automatic expiry/start/advancement; original draft remains. Existing pain/unwell still blocks starts.
3. Critical: start strength or running/paused cardio, attempt recovery. Action disabled; active session and timer untouched.
4. Critical: inject failed save for choose/return, then relaunch/retry. Visible error and last durable choice retained; no false success or lost draft. Upgrade old state: no recovery choice silently selected.
5. Noncritical: manually log actual cycling while recovery selected, use largest text/VoiceOver. Record saves through existing review path without clearing recovery; notice/date and controls accessible.

Native acceptance executed: 0. Local macOS/Xcode/simulator/device unavailable; hosted core/SDK checks are separate. Acceptance requires >=95% of all approved cases passing and all critical cases passing; blocked/skipped cases disclosed and never counted as passes. January 2027 remains conditional.

Next: reviewed structured history normalization and recommendation evidence, plus approved native end-to-end logger/strength/cardio/recovery acceptance. No personal records invented or seeded publicly, new costs, workflow changes, production merge/release, outreach or dashboard feed.
