# History import contract — review staging implemented; structured extraction pending

Current importer stages fitness-keyword, catalog-exercise and common naming-variant messages for review; original text, role in source, timestamp and message identity are retained. Reimport deduplication remains in Journey. It does not normalize sets, units or completed activity. Full personal chat history has not been imported. A ChatGPT export is needed to begin. Do not infer completed sessions from assistant advice, a suggested routine, gym-machine capability or an undated memory.

The importer must accept conversations.json locally, retain original message/conversation identifiers and timestamps, and produce editable candidate events. Each event stores:

- Event ID, activity category, editable event date, original timestamp/time zone and date confidence.
- Exact supporting excerpt, conversation title/ID, message ID, source link where available and local export reference. Never fabricate a working message URL; a conversation link plus retained message ID is acceptable.
- Original values and units; normalized values separately. A dumbbell weight does not imply per-hand or total unless stated.
- Status: completed / planned / advice / unclear. Review: pending / approved / rejected.
- Uncertainty flags, reviewer edits, review timestamp and extraction version.

Preserve both original evidence and reviewed corrections. De-duplicate by conversation/message/event identity. Correctly handle conversation branches and repeated imports. Avoid importing unrelated personal content. Keep photos local and opt-in. Provide a preview and deletion before committing imported data.

Recommendation eligibility requires approved review, completed status, relevant activity and adequate date/unit confidence. Planned/advice records may provide context only if explicitly reviewed as preferences, never as completed workload. Resolve ambiguous records in the review UI. Every coach factual claim should point back to eligible records; no imported text may modify coach instructions or invoke tools.

Required tests: ambiguous dates, lb/kg and miles/km, per-hand weights, negatives/corrections, future plans, assistant advice, duplicate exports, branched messages, missing IDs, partial exports and rejected records excluded from recommendations.
