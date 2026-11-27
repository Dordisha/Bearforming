# Bearforming checkpoint — November 3, 2026

Canonical repository: Dordisha/Bearforming. Base: main at 774863d.
Working branch: openai/history-aware-planning-2026-11-03. No merge or release.
The October 31 Library source zip is an older 0.1.0 package; continue the GitHub source, not a replacement app.

## Delivered source increment

Existing fuller sessions and editable preview are retained. Suggestions now prefer exercises with past completed sets within each existing movement group, preserving the catalog's group sequence. Recovery exclusion uses actual completed-set timestamps (including active saved sets), not the workout opening date. Future and uncompleted sets do not count. The existing 48-hour heuristic is retained; it is not proof of physiological recovery.

Only reviewed, completed, explicitly categorized Cycling entries dated within the preceding 48 hours produce a fatigue-check message. Free-text distance/intensity is not interpreted. No automatic cycling volume deduction or warmup completion is inferred. No private chat history, personal weights, or alleged recent rides were seeded into this public repository. On-device records are needed for actual personalization; historical conversation summaries are not normalized workout records.

Six deterministic unit tests added; storage schema, persisted preview, logger, import review and offline coach unchanged. README and stale session-planning status reconciled.

## Final-version validation

- Source checks: git diff --check PASS; bash syntax for Scripts/check.sh PASS; both asset JSON files parsed successfully.
- Unit suite: 17 test methods discovered by source inventory (11 existing, 6 new). Executed 0; all 17 blocked locally because Swift is absent. Scripts/check.sh exited 1 with `Swift is required; run on a Mac with Xcode.` This is an infrastructure blocker, not a product test failure or success.
- iOS build/simulator/device: BLOCKED. Host is Linux, no xcodebuild or device access. No new CI run dispatched. Existing workflow only triggers main pushes or pull requests; this isolated branch is not a release candidate.
- Acceptance: NOT RUN, awaiting approval. Retrieved Daily-Xcode-Test-Plan-v1.md (Library libfile_8f598855fc988191b5155a1265f8fe2a); BF-T01–20 are proposed, not approved. No approval found in current context or existing issue comments. No acceptance percentage claimed.
- Acceptance rule: at least 95% of all approved cases, all critical cases passing; disclose every blocked/skipped case. Incomplete suites cannot pass. Source checks never substitute for simulator evidence.

## Concrete proposed refinements for owner review (not executed)

Keep BF-T01–20 as the existing manifest. For BF-T03, default ready/Gym/40-minute fixture produces six exercises within budget; prior completed pulldown more than 48 hours ago moves it ahead of row within Pull slots, with no copied load. For BF-T04, exclude sets completed 47h59m59s ago, include at exactly 48h, ignore future/uncompleted sets, and account for recent sets in an older active workout. For BF-T15/17, only a reviewed completed Cycling note dated within 48h shows the fatigue prompt; planned/advice/pending/future/older entries do not; warmup and set count stay unchanged. Verify saved manual preview is preserved until Reset suggestion.

## Next priorities and release outlook

1. Compile and run all 17 unit tests on Swift/macOS, then fix any failures; obtain approval for existing native scenario manifest before running acceptance.
2. Validate editable preview and logger persistence on simulator/device (BF-01/BF-02); fuller sessions are source-implemented, not newly device-accepted.
3. Normalize reviewed history with explicit dates, units and completion; add related-movement recovery only after behavior is specified. January 2027 remains a target dependent on native acceptance, beta, privacy/export and signing.

Existing progress issues #1/#2/#5 are sufficient. No new change-request issue, dashboard feed, production publishing, paid service, or outreach. No new costs incurred.
