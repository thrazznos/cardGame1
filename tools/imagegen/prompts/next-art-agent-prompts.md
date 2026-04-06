# Next Art Agent Prompts — Immediate Prototype Integration Targets

Purpose:
- Give the art agent one obvious file containing the next highest-leverage generated assets for Dungeon Steward.
- Focus on assets that are likely to integrate cleanly into the current native combat prototype and near-term reward/checkpoint flow.

Read first:
- `design/art-bible.md`
- `docs/plans/2026-04-05-art-generation-backlog.md`
- `tools/imagegen/prompts/dungeon_steward_character_faction_prompt_pack.md`

Current repo state:
- There are prompt packs and planning docs already.
- There are generated concept outputs under `tools/imagegen/output/`.
- There is now a first repo-local prototype gameplay-art pack under `assets/generated/` covering shared card-art lanes, gem art, placeholder art, and basic icons.
- Review of the current outputs shows useful material, but also clear failure modes that the next prompt pass must avoid.

## Observed Failure Modes From Current Outputs

1. **Wrong portrait composition**
- Some outputs are wide scene illustrations or full-body sprites that do not crop cleanly into a HUD portrait panel.
- For combat HUD use, the art agent should prefer **bust / head-and-shoulders / chest-up compositions** with the face and silhouette doing most of the work.

2. **Wrong character identity for current targets**
- Some placeholder sprites are readable but not thematically aligned with the actual Dungeon Steward cast.
- The next pass should prioritize the real faction/character lanes from the prompt pack, not generic placeholder figures.

3. **Wrong semantics for tiny UI button icons**
- Current prototype outputs included icons that do not mean what the button means in play.
- Example failure: an urn-like icon is not a valid “Pass” icon; an up/home-like icon is not a valid “Restart” icon.
- If semantic clarity is weak, **do not generate the icon**. Prefer text-only buttons over misleading icons.

## Priority Order — Immediate Gameplay-Art Pack For This Iteration

Context shift:
- `src/ui/combat_hud/assets/` already has live swap points for the player portrait, enemy portrait, banner crest, and reward seal.
- The next highest-leverage pack is not “more random portraits”; it is a compact set that covers the current starter deck, current reward pool, and the gem-stack prototype with the fewest new assets.

### 1) Small card-art set — 6 reusable art lanes
Generate these as portrait-safe 512x512 sources with quiet backgrounds and one dominant read.

1. `card_strike_cat_duelist_md.png`
- Usage: `strike`, `strike_plus`, `strike_precise`
- Why now: covers the whole base attack lane and the most-seen starter/reward family with one asset.

2. `card_defend_badger_bulwark_md.png`
- Usage: `defend`, `defend_plus`, `defend_hold`
- Why now: covers the whole base defense lane and gives the badger faction a gameplay-facing role immediately.

3. `card_scheme_seep_goblin_md.png`
- Usage: `scheme_flow`
- Why now: base utility currently has no visual identity; one clean goblin utility portrait establishes the third core lane.

4. `card_ember_jab_ruby_md.png`
- Usage: `gem_produce_ruby`, `gem_hybrid_ruby_strike`, `gem_consume_top_ruby`, `gem_offset_consume_ruby`
- Why now: Ruby production/consumption is already in the starter deck and in the current gem reward pool.

5. `card_ward_polish_sapphire_md.png`
- Usage: `gem_produce_sapphire`, `gem_hybrid_sapphire_guard`, `gem_hybrid_sapphire_burst`, `gem_consume_top_sapphire`, `gem_offset_consume_sapphire`
- Why now: Sapphire is the other baseline gem and appears in current deck/reward content right now.

6. `card_vault_focus_seal_md.png`
- Usage: `gem_focus`, `gem_hybrid_focus_guard`
- Why now: FOCUS is the prototype’s first advanced gem gate and needs its own visual lane instead of reading like another generic utility card.

Art direction for all six:
- portrait plate or emblem-plus-prop composition
- one face or object + one prop + one mechanic cue
- readable at card scale
- no wide scenes
- no tiny symbol soup

### 2) One generic fallback card art
- `card_placeholder_steward_warrant_md.png`
- Usage: default art for any current or newly added card without assigned family art.
- Why now: the card catalog will grow faster than bespoke illustration; one in-world fallback prevents a half-finished mix of art cards and blank cards.

### 3) Gem art masters
Generate isolated object renders first, then derive tiny icons from them.

1. `obj_gem_ruby_token_md.png`
- Usage: gem stack top window, card inline gem markers, reward/tooltip callouts
- Why now: Ruby is a baseline gem and is already produced/consumed by starter cards.

2. `obj_gem_sapphire_token_md.png`
- Usage: same as above for Sapphire
- Why now: Sapphire is the other baseline gem and the gem-stack-machine spec explicitly calls for distinct Ruby/Sapphire iconography.

### 4) Essential icons
These should be manual-first or AI-assisted then hand-cleaned.

- `ui_icon_attack_sm.png`
- `ui_icon_defend_sm.png`
- `ui_icon_utility_sm.png`
- `ui_icon_focus_sm.png`
- `ui_icon_stack_top_sm.png`
- `ui_icon_locked_sm.png`

Usage:
- replace raw `[ATK]` / `[DEF]` / `[UTL]` markers when card frame iteration lands
- surface FOCUS and stack-top state in the HUD
- support future lock/reserve overlays already called for by the gem-stack-machine spec

Why now:
- this is the smallest icon set that maps directly to mechanics already in the prototype
- do not spend this pass on `Pass` / `Restart` icons unless button semantics are undeniably clear and there is a real integration hook for them

## Asset Integration Notes For Future Passes

When assets land, integrate in this order:
1. Shared card-art mapping for the starter deck + reward pool
2. Placeholder card art fallback
3. Ruby/Sapphire token art in gem/top-of-stack surfaces
4. Role/focus/stack icons
5. Only revisit new portraits if the current HUD portraits prove weak

Avoid spending time on these yet:
- one-off art for every individual card variant
- final ornate card frames
- `Pass` / `Restart` button icons
- busy reward/background vignettes that fight readability

## Prompt Quality Guardrails
- Favor readability at small crop sizes
- Favor clear silhouette over decorative complexity
- Favor controlled value grouping over texture noise
- Favor portrait crops that survive chest-up or head-and-shoulders framing
- Avoid parody, meme energy, or oversexualized/fetish reads
- Avoid low-contrast backgrounds that make extraction painful
- Avoid clutter that will die when cropped into a HUD panel
- Avoid generic placeholder people when the target is a named faction or role
- Avoid semantically ambiguous button glyphs; wrong meaning is worse than no icon

## Suggested Delivery Convention
When assets begin landing, place them somewhere explicit such as:
- `assets/generated/cards/`
- `assets/generated/cards/placeholders/`
- `assets/generated/gems/`
- `assets/generated/ui/icons/`
- `assets/generated/ui/reward/`

and include a tiny README or manifest noting:
- source prompt
- model/workflow used
- selected variant
- intended integration target
- exact card ids or HUD nodes the asset is meant to cover
