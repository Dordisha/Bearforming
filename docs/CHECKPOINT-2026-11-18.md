# Bearforming checkpoint — November 18, 2026

Continued Dordisha/Bearforming draft PR #6 from 7ce49cc705940f192f700d0fbd8444c9044ca06e after fresh Git fetch and connected PR verification. Read November 17 checkpoint, roadmap, current source/workflow, existing issues #1/#2/#5 and comments, owner context, Library market-direction report and Daily-Xcode-Test-Plan-v1. No later Bearforming scenario approval found. Unrelated property-search context was excluded; GitHub is authoritative for this Swift app. No new personal workout records were imported or inferred. Recommendations still depend on actual completed on-device sets and reviewed completed cycling evidence.

## Bounded increment: durable cardio pause/resume

Today Cardio/Cycling timers now support Pause and Resume, with persisted pause state and accumulated excluded seconds. Relaunch restores running or paused state. Display and proposed saved duration subtract explicit pauses, including when stopping while paused. Time away from the app while running still counts: this is unpaused clock time, not measured movement or verified exercise. Original wall-clock, paused and unpaused totals remain in the pending Journey evidence; completion, effort and approval remain unknown until explicit review. Whole-minute flooring and short/long-duration unknown limits apply to unpaused time.

Duplicate pause/resume actions are idempotent. Clock rollback before the latest transition and nonfinite dates reject transitions/stop without losing the timer; a visible timing notice explains recovery/discard. Legacy timers decode as running without a recorded pause. Paused cardio still blocks concurrent strength/cardio starts. Existing save-before-publish persistence retains the last durable state on write failure. Strength draft, session focus, next Upper/Lower slot, rest deadline and history are preserved. Six-exercise normal target, manual Upper/Lower/Push/Pull, full-body and existing recovery/time constraints are unchanged. A first-class Rest/recovery action is still outstanding.

## Regression evidence

Six new core unit tests cover multiple pauses and strength isolation; disk round trip and stop while paused; duplicate transitions and running relaunch; backward/nonfinite clocks; legacy running timers; and concurrent-start/discard/sub-minute behavior. Expected suite: 82 tests. Local git diff --check passed. Local Scripts/check.sh is BLOCKED because Linux has no Swift/Xcode/simulator/device. The existing hosted macOS workflow will run the final saved tree; its actual unit counts, SDK build result and exact commit/run linkage are recorded on PR #6. This checkpoint does not predeclare a pass. No workflow or paid-runner change.

## Native acceptance proposal — awaiting approval, NOT RUN

BF-T01–20 and R01–20 remain proposed, with zero verified approved cases. The following concrete refinements for R16/R18 and BF-T12/BF-T13 require review before native execution:

| Case | Critical | Steps | Expected result |
|---|---|---|---|
| Pause and relaunch | Yes | Start Cycling, run 125 seconds, pause, terminate/relaunch after 5 minutes | Same timer identity/category; paused at 2:05; draft/slot/rest unchanged |
| Resume and stop | Yes | Resume that timer, run 55 seconds, stop; cancel review and reopen Journey | One pending record with 3 minutes, unknown effort/unclear completion, wall/paused/unpaused evidence retained |
| Stop while paused | Yes | Run 125 seconds, pause, advance clock one day and stop | Proposed duration 2 minutes; long paused time excluded; record still requires review |
| Repeated actions and old state | Yes | Upgrade a pre-pause timer; repeat pause/resume taps; try concurrent strength start; discard with cancel then confirm | No reset/double-count/concurrent workout; old timer retained; confirmed discard creates no record |
| Failed persistence and clock rollback | Yes | Inject pause/resume/stop save failures, relaunch and retry; move clock before latest transition | Last durable timer preserved, visible error/clock notice, no false success or duplicate record |
| Readability and background | No | Run/background/reopen; pause/background/reopen; inspect largest text and VoiceOver | Only running time increases; paused display stable; controls reachable and duration announced |

Approved acceptance cases run: 0; native simulator/device results: none. Acceptance remains awaiting owner approval and a native test environment. Overall acceptance needs at least 95% of all approved cases passing and every critical case passing; blocked/skipped cases must be disclosed and cannot count as passes. Unit tests and simulator SDK compilation do not meet native acceptance.

Next priority: explicit Rest/recovery action that preserves the strength queue/draft, then approved native strength/cardio acceptance and structured review of actual history. January 2027 remains conditional on device QA and release gates. No new issue, costs, production merge/release, outreach or dashboard feed.
