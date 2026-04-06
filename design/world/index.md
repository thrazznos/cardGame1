# Dungeon Steward World Index

## Document Status
- Status: Working Draft
- Last Updated: 2026-04-06
- Scope: thin-slice world framework for combat flavor, hub flavor, enemies, relics, events, and naming
- Authority Rule: files under `design/world/` are the source of truth for world canon in this repo
- Supporting Sources: `design/gdd/game-concept.md`, `design/art-bible.md`, `tools/imagegen/prompts/dungeon_steward_character_faction_prompt_pack.md`

## Why This Stack Exists
Dungeon Steward already had a strong world vibe in the game concept, art bible, prompt packs, and card/art language, but not a compact file-backed canon stack. These docs establish a small, useful world framework that can directly feed:
- enemy families
- boss identities
- relic and event flavor
- card naming
- hub investment flavor
- future map/hub/narrative content

The goal is not to build a giant lore bible before the game is fun. The goal is to make the existing world legible, reusable, and audit-friendly.

## Source-of-Truth Policy
1. Files in `design/world/` are canonical project records.
2. Honcho is the memory and retrieval layer for distilled approved world facts.
3. If Honcho and files disagree, files win.
4. Open questions and unresolved alternatives must remain in files, not Honcho.
5. Lore contradictions should be treated as bugs and reviewed with `lore-audit`.

## Canon Tiers
- Core Canon: highly stable statements the rest of the setting should assume.
- Working Canon: currently approved guidance that may still tighten or split later.
- Flavor: examples, suggested motifs, and tone-supporting details that can vary without breaking the setting.
- Open Question: unresolved territory that should not be silently treated as fact.

## World Documents
| File | Purpose | Tier Bias |
| --- | --- | --- |
| `design/world/canon-foundation.md` | Core premise, truth vs belief split, canon tiers, world rules, tone guardrails | Core / Working |
| `design/world/factions-and-cultures.md` | Compact definitions for the setting's active social groups and how they justify themselves | Working |
| `design/world/institutions-and-locations.md` | Practical world structures: charter-house, gates, works, tunnels, thresholds, and play-facing spaces | Working |
| `design/world/conflict-seeds.md` | Structural tensions that can feed cards, events, enemies, relics, and bosses | Working |
| `design/world/naming-lexicon.md` | Naming lanes, vocabulary banks, and readability guardrails | Working / Flavor |
| `design/world/open-questions.md` | Unresolved world questions and expansion hooks | Open Question |

## How To Use This Stack
- Use `world-canon-foundation` when the project needs clearer truth/belief boundaries.
- Use `culture-from-ecology` when a faction or institution feels aesthetic-only and needs material grounding.
- Use `myth-rashomon-lens` when different groups should interpret the same world truth differently.
- Use `conflict-from-worldbuilding` when the setting needs enemy, boss, event, relic, or hub flavor hooks.
- Use `naming-lexicon-builder` before naming passes on cards, factions, places, relics, or bosses.
- Use `lore-audit` when docs drift, contradict, or stop feeding gameplay.
- Use `honcho-world-sync` only after approved file-backed canon exists.

## Current Thin-Slice Priorities
1. Preserve the world lane already implied by the art bible and prompt packs.
2. Turn that lane into reusable gameplay flavor rather than generic fantasy dressing.
3. Keep the stack compact enough to support combat-first development.
4. Explicitly separate truth, belief, tone guidance, and open questions.

## Known Gaps
- The world still needs sharper answers about what the charter-house legally is.
- The dungeon's material/economic role is established only in broad strokes.
- Faction tensions are outlined but not yet tied to authored event/reward content.
- Naming policy exists, but most current card names still lean mechanical rather than fully world-integrated.
