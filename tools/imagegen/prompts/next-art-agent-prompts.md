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
- There are now generated image outputs under `tools/imagegen/output/`.
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

## Priority Order

### 1) Player combat portrait — Cat steward protagonist
Use case:
- Top priority portrait/bust for the player side of the combat HUD.
- Should read clearly at small HUD scale after cropping.

Prompt direction:
- Use the feline steward-charmer prompt family from the prompt pack.
- Favor:
  - readable silhouette
  - strong face/torso read
  - elegant courtly frontier styling
  - deadpan competence, not cutesy comedy
  - dark neutral background for easy extraction/cropping

Output target:
- portrait-friendly bust composition
- 3-6 variants
- one “safe readable” pick before trying any more stylish variants
- explicitly avoid full-body sprite framing and wide environmental scene composition

### 2) Enemy combat portrait — Sentient honeybadger warden
Use case:
- First enemy-side combat portrait/bust for the current slice.
- Chosen because it is already a strong, distinctive faction concept in the project direction.

Prompt direction:
- Use the sentient honeybadger warden prompt family from the prompt pack.
- Favor:
  - compact dangerous silhouette
  - frontier lawkeeper / warden energy
  - readable face and shoulder shape
  - strong value grouping for HUD crop use

Output target:
- portrait-friendly bust composition
- 3-6 variants
- prioritize clarity over detail density
- explicitly avoid generic placeholder humanoids that are not recognizably badger-warden themed

### 3) Reward checkpoint seal / token
Use case:
- Small visual marker for reward/checkpoint moments and future reward UI.
- Can be integrated before a full illustration pipeline lands.

Prompt direction:
- Court-frontier charm object / sealed warrant token / medallion / wax-sealed authority marker.
- Materials: brass, iron, parchment, wax seal, restrained teal rune accent if needed.
- Keep shape iconic and readable.

Output target:
- isolated object concept
- dark neutral or parchment-friendly background
- 4-8 variants
- especially useful if one version reads well as a simple UI motif

### 3b) Prototype HUD button icon set — only if semantically exact
Use case:
- Optional small icons for clearly understood prototype controls.
- Only generate if semantic meaning is unambiguous at tiny size.

Strict rules:
- `Pass` must read as **skip / end turn / forward / double-chevron / turn-end**, not death, loot, home, or memorial.
- `Restart` must read as **refresh / reset / circular arrow / retry**, not up-arrow, house, or navigation.
- If results are ambiguous, reject them and keep text-only buttons.

Output target:
- tiny high-clarity monochrome or two-tone glyph concepts
- 4-8 variants per control
- prototype-only; do not force integration if readability is worse than text

### 4) Card motif discovery set — attack / defend / utility
Use case:
- Not final UI.
- Visual motif discovery for what eventual card art families should feel like.

Prompt direction:
- One image family each for:
  - attack / strike
  - defend / guard
  - utility / scheme
- These should suggest mood and symbolic language, not final tiny icons.
- Keep anti-goals from the art bible in mind:
  - no unreadable tiny AI-generated symbol soup
  - no over-ornamented frame clutter
  - no low-contrast nonsense

Output target:
- 2-4 variants per family
- concept/motif reference only
- likely hand-built into final UI later

### 5) Reward panel motif / checkpoint vignette
Use case:
- Give the reward overlay a future visual identity beyond plain panels.
- Can later inform borders, seals, and background ornamentation.

Prompt direction:
- Courtly authority meets frontier grime.
- Emphasize:
  - parchment logic
  - wax seal / ribbon / brass / lacquered wood
  - restrained decorative framing
  - strong center focal area for text + choices

Output target:
- concept vignette, not final UI export
- 2-4 variants
- keep center readable and not overcrowded

## Asset Integration Notes for Future Passes

When actual generated assets exist in the repo, the easiest first integrations are likely:
1. Player portrait in the combat HUD
2. Enemy portrait in the combat HUD
3. Reward checkpoint token/seal in the reward overlay

Avoid spending time on these yet:
- final tiny combat icons
- final ornate card frames
- busy UI backgrounds that fight readability

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
- `assets/generated/portraits/player/`
- `assets/generated/portraits/enemy/`
- `assets/generated/ui/reward/`
- `assets/generated/card-motifs/`

and include a tiny README or manifest noting:
- source prompt
- model/workflow used
- selected variant
- intended integration target
