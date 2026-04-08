---
name: culture-from-ecology
description: "Derive factions, institutions, and social logic from environment, labor, logistics, and material life so cultures feel grounded rather than decorative."
argument-hint: "[culture, faction, or domain, e.g. 'badger wardens', 'frontier labor', 'charter-house society']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite, HonchoSearch, HonchoConclude
---

When this skill is invoked:

1. Read these first:
   - `design/gdd/game-concept.md`
   - `design/art-bible.md`
   - `design/world/canon-foundation.md` if present
   - `design/world/factions-and-cultures.md` if present
   - `design/world/institutions-and-locations.md` if present
   - relevant system docs if the culture strongly touches hub, map, reward, or combat loops

2. If Honcho is available, search for the target faction/culture and pull back only compact existing facts.

3. Use `ecology` broadly. For compact strategy games, ecology includes:
   - physical environment
   - labor and maintenance reality
   - resource flows
   - logistics bottlenecks
   - institutional authority
   - what must be repaired, guarded, fed, or inspected

4. Build the culture through these layers:
   - environment/material base: what physical conditions shape them?
   - subsistence/labor base: what work keeps them alive or relevant?
   - power structure: who has authority and how is it justified?
   - values/worldview: what story makes their structure feel natural?
   - contradictions: what they say vs. what material reality forces?
   - player-facing hooks: what enemy, ally, event, relic, or card flavor does this produce?

5. Ask the user targeted questions such as:
   - what does this faction maintain, extract, regulate, or protect?
   - what resource or bottleneck makes them necessary?
   - what do they admire in themselves?
   - what do they fear becoming?
   - how do they explain their privilege, burden, or usefulness?

6. Default outputs live in:
   - `design/world/factions-and-cultures.md`
   - `design/world/institutions-and-locations.md`

7. Draft with short, useful sections per faction or institution:
   - role
   - material language
   - power base
   - values
   - blind spots
   - gameplay hooks

8. Ask before writing either file.

9. After approval/write, offer to sync the stable faction facts into Honcho.
