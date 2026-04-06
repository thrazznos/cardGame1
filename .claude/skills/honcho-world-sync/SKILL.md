---
name: honcho-world-sync
description: "Sync approved, file-backed world canon into Honcho as compact durable facts. Uses files as the source of truth and falls back gracefully when Honcho is unavailable."
argument-hint: "[optional file or domain, e.g. 'canon-foundation', 'factions', 'naming']"
user-invocable: true
allowed-tools: Read, Glob, Grep, HonchoSearch, HonchoConclude, AskUserQuestion
---

When this skill is invoked:

1. Read the relevant approved files first:
   - `design/world/index.md`
   - target world file(s) under `design/world/`
   - any upstream file needed to resolve ambiguity

2. Source-of-truth rules:
   - files win over memory
   - only approved, durable facts may be synced
   - unresolved options, brainstorms, and open questions must stay out of Honcho
   - if a canon statement changes, replace or remove the stale Honcho fact

3. Distill facts aggressively.
   Good sync candidates are:
   - one fact per conclusion
   - short and explicit
   - tagged as truth or belief when necessary
   - useful across future sessions

4. Bad sync candidates include:
   - whole paragraphs copied from docs
   - stylistic prose without factual content
   - contradictory alternatives
   - temporary tasks or pending decisions
   - speculation not yet accepted in files

5. Preferred sync shapes:
   - `Truth: [stable world fact]`
   - `Belief: [faction] believes [claim]`
   - `Rule: [setting/system constraint]`
   - `Naming: [lexicon rule or approved lane]`
   - `Conflict: [stable structural tension]`

6. Example good fact statements:
   - `Truth: Dungeon Steward's frontier is governed through charters, inspections, warrants, and recognized lines of authority.`
   - `Truth: Cards in Dungeon Steward are framed as favors, warrants, procedures, prepared techniques, and named allies as much as raw attacks.`
   - `Belief: Badger wardens are widely seen as the hard line between civic order and tunnel collapse.`
   - `Naming: Dungeon Steward favors concrete administrative, courtly, maintenance, and frontier vocabulary over vague mystical wording.`
   - `Conflict: The frontier depends on goblin maintenance labor that other factions often undervalue or distrust.`

7. Before syncing, present the candidate fact list for review.
   Ask which should be added, replaced, or omitted.

8. If Honcho is unavailable:
   - do not fail the workflow
   - treat `Honcho session could not be initialized.` as a normal degraded-mode case
   - do not retry in a tight loop or pretend the sync succeeded
   - return a clean candidate fact list in chat
   - explicitly note that the sync is pending because Honcho could not be reached
   - keep files as the only authoritative layer until a later successful Honcho session

9. After syncing, summarize:
   - facts added
   - facts replaced
   - facts withheld because they were not durable enough
