---
name: naming-lexicon-builder
description: "Define naming lanes, title patterns, vocabulary banks, and readability guardrails for cards, factions, places, relics, bosses, and institutions."
argument-hint: "[optional domain, e.g. 'cards', 'places', 'titles', 'enemy names']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite, HonchoSearch, HonchoConclude
---

When this skill is invoked:

1. Read before naming anything:
   - `design/world/canon-foundation.md`
   - `design/world/factions-and-cultures.md`
   - `design/world/institutions-and-locations.md`
   - `design/world/conflict-seeds.md`
   - `design/world/naming-lexicon.md` if present
   - `design/art-bible.md`
   - current card/relic/enemy names from data files when relevant

2. Search Honcho for stable terms if available, especially institutions, faction labels, or previously approved naming rules.

3. Split naming work into lanes:
   - plain readability lane (for commons, tutorial cards, short utility labels)
   - world-flavor lane (for advanced cards, relics, encounters, factions)
   - prestige lane (for elites, bosses, rare relics, formal institutions)

4. Build the lexicon with these sections:
   - naming goals
   - word banks per faction/material lane
   - title conventions
   - place-name patterns
   - card naming policy
   - enemy/boss naming policy
   - forbidden lanes / anti-patterns
   - approved examples

5. Always test names against readability:
   - can a player parse this in combat at a glance?
   - is the noun/verb concrete?
   - is the flavor doing useful world work instead of ornamental clutter?
   - does it fit the established tone rather than generic fantasy sludge?

6. For Dungeon Steward specifically:
   - keep starter/common combat cards short and legible
   - let higher-rarity, event, relic, and boss content carry more world-specific flavor
   - prefer concrete administrative, courtly, maintenance, and frontier words over vague mystic mush

7. Default write target:
   - `design/world/naming-lexicon.md`

8. Ask before writing.

9. After approval/write, sync only the stable naming rules and exemplars to Honcho.
