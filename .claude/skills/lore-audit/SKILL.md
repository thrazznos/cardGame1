---
name: lore-audit
description: "Audit file-backed world canon and Honcho memory for contradictions, canon drift, truth-vs-belief confusion, and missing bridges into gameplay-facing flavor."
argument-hint: "[optional focus, e.g. 'factions', 'naming', 'honcho drift']"
user-invocable: true
allowed-tools: Read, Glob, Grep, HonchoSearch, HonchoContext
---

When this skill is invoked:

1. Read the full world stack first:
   - `design/world/index.md`
   - all files under `design/world/`
   - relevant upstream docs such as `design/gdd/game-concept.md` and `design/art-bible.md`
   - task-relevant card, relic, enemy, or prompt sources if naming/flavor drift is suspected

2. Query Honcho if available for world facts matching the audit scope.
   If Honcho is unavailable, run a file-only audit and note the missing memory pass.

3. Evaluate against these checks:
   - file-vs-file contradiction
   - file-vs-Honcho drift
   - truth stated as belief, or belief stated as truth
   - tone drift away from the established world lane
   - naming drift into the wrong genre or register
   - gameplay disconnect: lore exists but does not feed enemies, relics, events, cards, or hub flavor
   - missing bridge docs: a faction or institution is named but functionally undefined

4. Output the audit in this format:

   ## Lore Audit: [scope]

   ### Canon Drift
   - [issue]

   ### Truth vs Belief Confusion
   - [issue]

   ### Naming / Tone Drift
   - [issue]

   ### Gameplay Bridge Gaps
   - [issue]

   ### Honcho Sync Issues
   - [issue or `none checked`]

   ### Recommended Fixes
   - [prioritized list]

5. This skill is read-only.
   Do not silently fix docs. Recommend patches and let the user approve the follow-up write.
