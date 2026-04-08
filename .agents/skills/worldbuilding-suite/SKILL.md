---
name: worldbuilding-suite
description: "Orchestrate a Hermes-native worldbuilding workflow backed by text files and Honcho: read context first, route to the right specialized skill, keep truth vs belief explicit, and never write canon without approval."
argument-hint: "[worldbuilding task or domain, e.g. 'factions', 'canon', 'naming', 'audit']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite, HonchoSearch, HonchoContext, HonchoConclude
---

When this skill is invoked:

1. Read the current project context before proposing anything:
   - `design/gdd/game-concept.md`
   - `design/art-bible.md`
   - `design/world/index.md` if it exists
   - the world docs under `design/world/`
   - task-relevant flavor sources (prompt packs, card names, enemy docs, hub/map docs) when relevant

2. Search Honcho for the relevant domain if Honcho is available:
   - query for factions, institutions, terms, places, or conflicts related to the user's ask
   - treat Honcho as a recall layer, not the source of truth
   - if Honcho is unavailable or returns nothing useful, continue file-only without blocking

3. Present a short diagnosis before doing world design:
   - what is already established in files
   - what Honcho seems to know
   - what is still thin, contradictory, or missing
   - what should remain provisional

4. Route into the focused skill that best fits the task:
   - `world-canon-foundation` for truth/belief split, canon tiers, and world rules
   - `culture-from-ecology` for factions, institutions, labor, material life, and social order
   - `myth-rashomon-lens` for multiple in-world interpretations of the same truth
   - `conflict-from-worldbuilding` for structural tensions, enemy/event/relic seeds, and escalation paths
   - `naming-lexicon-builder` for terms, titles, place names, faction lexicons, and card naming policy
   - `lore-audit` for contradictions, canon drift, truth-vs-belief confusion, or missing bridges
   - `honcho-world-sync` only after file-backed canon has been approved or written

5. Follow the project collaboration pattern every time:
   - Question -> Options -> Decision -> Draft -> Approval
   - summarize findings first
   - recommend one path
   - draft in chat before writing
   - ask before writing or patching files

6. Respect the source-of-truth rules:
   - files in `design/world/` are canonical project records
   - Honcho stores distilled, durable facts derived from approved files
   - if Honcho and files disagree, files win and the mismatch becomes an audit issue
   - do not store brainstorm options, contradictions, or unresolved ideas in Honcho

7. Keep the workflow thin-slice and gameplay-serving:
   - worldbuilding exists to improve enemy families, bosses, hub flavor, relics, event seeds, and card language
   - prefer compact, useful docs over sprawling lore bibles
   - for Dungeon Steward, bias toward combat-first and readability-first world support

8. After any approved world doc write, explicitly offer to run `honcho-world-sync`.
