# Bearforming checkpoint — November 6, 2026

Canonical source: Dordisha/Bearforming, draft PR #6 / openai/session-lifecycle-2026-11-04, continued from 34c03d6. Main remains 774863d. Read latest Library master plan and Daily-Xcode-Test-Plan-v1; no new Bearforming approval or scope changes found in current context or issue/PR comments. Previous checkpoint and roadmap recovered from existing source.

## Increment: stable editable session previews (BF-01/BF-02)

When no draft was saved, Today regenerated a TrainingPlan for each preview read. Each generation created new exercise UUIDs, so Remove/Substitute could not find the displayed row; a recomputation could also disrupt row identity. Today now displays only its saved draft. On appearing it prepares a draft only when absent. Check-in/preferences and Reset explicitly regenerate and persist it. Empty or edited drafts survive reopening; the existing start/finish lifecycle consumes/retires them. If the initial save fails, no unsaved generated workout is offered for starting. No schema changes, new activities, copied historical loads or altered cycling/recovery rules.

Four new unit regressions: first Remove with reload, first Substitute and repeated preparation, intentional empty preview versus Reset, and preferences/next-session recovery. Total 30 unit methods. Existing six-exercise default retained when time/equipment/readiness allow.

## Validation

Local diff, shell syntax and asset JSON checks performed; hosted macOS unit/build CI requested on final source. Exact SHA and final results are recorded in PR #6 and issue #1 after completion. This checkpoint does not assert an unobserved pass. November 5 baseline: 26/26 unit tests and unsigned simulator SDK build passed.

Native BF-T01–20 remain NOT RUN awaiting owner approval. Local Linux lacks macOS/Xcode/simulator; hosted macOS can run unit tests and compile the simulator target, but no interactive simulator or device acceptance is established. Acceptance requires >=95% of all approved cases plus every critical case passing, with blocked/skipped cases disclosed; no acceptance score claimed.

Proposed BF-T05 refinement, NOT RUN: clean install -> Today -> immediately Remove first row (six becomes five); Reset -> immediately Substitute first row; confirm only selected row changes and preserved set IDs/order survive relaunch. Remove all rows and reopen: empty draft remains, Start disabled until Add/Reset. Change equipment/focus and verify fresh eligible draft. Inject initial save failure: error visible, no unsaved session starts; reopen/retry after storage recovers. These concrete UI cases await owner review.

## Next and release

Vetted native preview/logger/history acceptance remains the next gate, followed by structured reviewed-history normalization. Actual personalization needs on-device completed/reviewed records; no private workout or cycling data invented. January 2027 remains conditional on native acceptance, beta, privacy/export and signing. Existing PR and issues reused; no new cost, merge, release, outreach or dashboard feed.
