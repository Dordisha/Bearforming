# Bearforming checkpoint — November 21, 2026

Continued Dordisha/Bearforming draft PR #6 at 11817464d911cdd3ac4bf2d0cacdf2b1d747b4f6, verified by fresh Git fetch and connected PR. Read current source/parser/tests, November 20 checkpoint/backlog, issue #2 and PR comments, Library market direction and Daily-Xcode-Test-Plan-v1. Latest owner instructions make BF-T17 the existing critical structured-import acceptance owner; no equivalent approved case or new approval found. No duplicate issue or separate lead alert.

## Bounded prerequisite: retain owner corrections for review

Inspection found keyword-only staging could silently drop a later owner correction such as “Correction: ... only the first movement” when it contains no exercise name. The parser now retains user-authored correction/completion followups with recognized prefixes only when their actual parent ancestry contains fitness content. Unrelated branches, orphan followups and assistant-only keyword-free recaps are not pulled in. Ancestry traversal handles cycles safely. This is conservative candidate retrieval, not semantic interpretation; ambiguous or unrelated retained candidates still require review.

Imported entries now preserve optional original author role and immediate parent message identity, alongside unchanged original text/timestamp/source identity. The review screen distinguishes message date from workout date, instructs review per workout day and prioritizing direct owner corrections over assistant recaps, and states that unknown quantities remain unresolved. Existing records decode without these optional fields. Deduplicated previously saved entries are not overwritten or automatically enriched.

The synthetic composite transcript covers two adjacent workout dates in one plan message, an assistant recap claiming completion/amounts, a later direct owner correction narrowing only the second day with completed but unquantified work, and an implausible duration unit. All original messages remain separate pending review, with reply identities retained. No workout dates, sessions, sets, reps, load or duration are extracted or guessed. Note approval alone does not create quantified lifting history or progression. Automatic date-scoped structured session creation and explicit lifting-quantity confirmation UI remain outstanding; this increment fixes lost evidence before that work. No personal content copied into fixtures.

Existing six-exercise planning, history-based recommendations, manual modes, Full body, recovery, cardio and November 20 partial-history behavior preserved.

## Validation and acceptance

Four new core regressions cover composite evidence preservation, review/progression isolation, serialization/reimport; unrelated branches/assistant/orphan exclusion; cycle/fallback identity; and legacy decoding. Expected final suite 95. Local diff check passed; Scripts/check.sh blocked because Swift/Xcode are absent on Linux. Hosted macOS final-tree unit/SDK results and exact source linkage are recorded in PR #6 after execution. No advance pass or native result claimed.

BF-T17 refinement only — critical, awaiting owner vetting, NOT RUN interactively:

Use the synthetic transcript in ImportCorrectionTests. Import, review source roles/reply identities and reopen. Retain both original workout-day statements; do not treat message timestamps as session dates. The owner correction narrows only day two; an assistant recap cannot supply completion or numerical amounts. A confirmed but unquantified occurrence stays nonnumeric; “20 fortnights” remains original text with duration unresolved. Pending entries and unquantified lifting notes must not affect Today or numeric progression. Reimport preserves reviewed edits and original evidence. Future date-scoped structured confirmation must demonstrate this behavior before native BF-T17 can pass. This refines the existing case, not a new case/issue. November 20 partial-history proposal remains pending too.

Approved native scenarios verified: 0; native scenarios executed: 0. Local macOS/Xcode/simulator/device unavailable. Hosted unit tests and unsigned simulator SDK build are not simulator/device acceptance. Overall acceptance requires >=95% of all approved cases passing, every critical case passing, and blocked/skipped cases disclosed and not counted as passes.

Next: explicit date-scoped lifting occurrence review with unresolved quantities and owner-correction precedence, then approved native BF-T17 execution. January 2027 remains conditional. No new costs, workflows, issue, merge/release, outreach or dashboard feed.
