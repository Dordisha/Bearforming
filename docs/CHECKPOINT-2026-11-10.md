# Bearforming checkpoint — November 10, 2026

Recovered canonical source from Dordisha/Bearforming after scratch maintenance. Continued existing draft PR #6 at fa353ad; main remains 774863d. Read current master plan (version 12), Daily-Xcode-Test-Plan-v1, PR discussion, exercise-priority issue comments, November 9 checkpoint and roadmap. No owner approval of the proposed native list found. Prior candidate: 38/38 unit tests and simulator SDK compilation passed.

## BF-02: numeric edits preserve durable values

Clearing a logger field previously saved zero immediately, silently replacing the prior reps or weight. Blank or malformed text now fails validation and leaves the last saved value intact. Explicit zero remains valid; zero reps still cannot complete a set. Zero displays as 0 so a blank field is visibly distinct from a saved zero. Extracted numeric validation into FitnessCore; decimal keyboard/localized separator and partial trailing decimal supported. Negative, nonfinite, exponent, multiple decimal and over-limit values are rejected. No storage schema change. Existing fuller six-exercise planning, completed-history preference, reviewed cycling gates, import staging and persistence remain intact. No personal records or activity invented.

Four new unit tests cover invalid edits retaining prior weight, explicit zero/bounds/partial decimal, whole reps, localized decimals and serialization. Final source contains 42 XCTest methods. Final exact SHA, hosted macOS results and CI merge/source-tree equivalence are recorded in PR #6 and issue #1 after execution. Local Swift/Xcode/simulator unavailable; hosted workflow executes unit tests and unsigned simulator SDK compilation only.

## Native acceptance: awaiting approval, NOT RUN

BF-T01–20 remain proposed/unapproved. Concrete BF-T06/07 refinement for review: enter 60.5 lb and 8 reps, clear either field, verify Not saved and that relaunch restores 60.5/8. Enter explicit 0 lb and verify it persists. Enter negative/alphabetic/over-limit text, verify error and prior value retained. Repeat decimal input in a comma-decimal locale and with keyboard focused on termination. No simulator UI/device scenarios executed. Unit tests do not establish UI behavior.

Acceptance requires >=95% of all approved cases and every critical gate passing, with blocked/skipped cases disclosed and incomplete runs not passing. January 2027 remains conditional on native QA, beta, privacy/export and signing. Next: approved native logger/import acceptance and reviewed structured personal history. No merge/release, new issues, outreach, dashboard feeds or new costs.
