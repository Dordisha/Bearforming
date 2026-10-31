# Bearforming — first native iPhone code

Native iPhone app targeting iOS 17+. January 2027 is the release target, not a verified launch commitment. Approved app name: Bearforming.

## Status
Implementation has started. Source has not been compiled or run: the authoring environment has neither Swift nor Xcode. No signed build, simulator validation, TestFlight upload or device verification has occurred. Source is published in Dordisha/Bearforming. Persistence tests are provided but have not been executed. This is not an installable iPhone build.

Implemented in source: editable starter workouts, sets/reps/weights in pounds, set completion and undo, previous logged performance, adding exercises/sets, substitution before completed sets, a 90-second rest timer, completed workout summaries, and atomic local saves after mutations. Rest uses an absolute deadline so it can resume after relaunch; it does not send background notifications. App reports save errors and blocks edits after unreadable/unsupported data is encountered. Draft numeric text is committed through SwiftUI numeric fields; verify keyboard/focus behavior during device testing.

Today uses explicitly selected starter templates. No personalized recommendation engine exists. Journey has lifting summaries only. Coach is a clearly labeled placeholder. Chat history, cycling, body weight, measurements, photos, awards, cloud sync, export/deletion controls and HealthKit are not implemented. No personal history is seeded, and there are no API keys, analytics, network calls or copied third-party code. The approved Bearforming mascot is bundled and displayed on Today. Start/Resume opens the Workout tab.

## Open on a Mac

Requires Xcode with iOS 17+ SDK. Open Bearforming.xcodeproj directly. XcodeGen is optional for regeneration; with it installed, run:

```sh
swift test
xcodegen generate
open Bearforming.xcodeproj
```

Select an iPhone simulator and Run. For a physical iPhone, set your own signing team and a unique bundle identifier in Xcode. Signing credentials are not included. A directly openable Xcode project and shared scheme are included. project.yml can regenerate it with XcodeGen.

## Required first milestone verification

1. Start a workout; enter reps and weight; complete a set. Verify the rest countdown and saved values.
2. Dismiss the numeric keyboard, terminate the app from the app switcher, relaunch, and verify identical session ID, exercise order, values and completion state.
3. Repeat while the numeric field is still focused. Verify the final typed value was persisted. Fix field handling if needed before milestone acceptance.
4. Reopen before and after the rest deadline. Confirm remaining time reflects wall clock time and does not restart at 90 seconds.
5. Undo a set, relaunch and verify it remains undone. Substitute an unstarted exercise, relaunch and verify its name.
6. Finish a session, relaunch, confirm it appears exactly once in Journey; start the same exercise and verify previous performance.
7. Inject unreadable JSON in a simulator container. Confirm the app blocks edits and does not overwrite the file. Restore it and Retry.
8. Run the XCTest persistence suite; simulate storage-write failure and confirm the UI reports failure without claiming a save.

Only mark the first milestone complete after these pass on an iPhone. Atomic file replacement reduces partial writes; it does not constitute backup, storage-failure recovery, migration support or cross-device sync.

See docs/PROJECT_BRIEF.md and docs/HISTORY_IMPORT.md for scope and the review gate.
