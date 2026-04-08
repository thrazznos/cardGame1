---
name: conflict-from-worldbuilding
description: "Derive structural tensions, factions, dilemmas, enemy/event seeds, and boss hooks from world rules, institutions, resource pressures, and incompatible values."
argument-hint: "[optional focus, e.g. 'enemy families', 'hub tensions', 'boss lanes']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite, HonchoSearch, HonchoConclude
---

When this skill is invoked:

1. Read first:
   - `design/world/canon-foundation.md`
   - `design/world/factions-and-cultures.md`
   - `design/world/institutions-and-locations.md`
   - `design/world/conflict-seeds.md` if present
   - relevant system docs when the ask targets combat, hub, map, or reward flavor

2. Pull back matching Honcho facts if available, but do not let memory outrank files.

3. Treat conflict as structural, not decorative.
   Good sources include:
   - who controls a bottleneck
   - what must be maintained to avoid collapse
   - which two good things cannot both be preserved
   - what one faction needs that another faction cannot safely grant
   - what belief system breaks if a hidden truth becomes public

4. Build each conflict seed with this structure:
   - seed name
   - core tension
   - stakeholders and what each side wants
   - what makes compromise hard
   - escalation ladder (small pressure -> local conflict -> institutional crisis -> boss/event scale)
   - gameplay surfaces: enemy family, boss lane, event seed, relic flavor, card family, hub investment flavor

5. Prioritize conflicts that feed the actual game loop.
   For Dungeon Steward, prefer combat-facing and event-facing seeds over broad history dumps.

6. Offer 2-4 possible conflict directions when the same world rule can produce different gameplay outcomes.

7. Default write target:
   - `design/world/conflict-seeds.md`

8. Ask before writing.

9. After approval/write, offer a Honcho sync of only the durable structural facts.
