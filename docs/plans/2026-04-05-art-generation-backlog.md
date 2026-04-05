# Dungeon Steward Character/Faction Art Generation Backlog

> For Hermes: use the existing local Apple Silicon toolchain in `tools/imagegen/` and treat this as a concept-generation and curation plan, not a final asset-production plan.

Goal: establish a coherent first visual lane for Dungeon Steward's new character/faction direction while preserving browser-first card readability and tactical clarity.

Architecture: AI generation is used for concepting, portrait ideation, faction sheets, boss sheets, relic/object exploration, and mood pieces. Final gameplay-critical small assets — icons, frames, chips, badges, node symbols, and text-bearing UI — are hand-authored or hand-finished after concept direction is locked.

Tech stack:
- ComfyUI local server via `tools/imagegen/launch_comfyui.sh`
- FLUX Schnell FP8 workflow for character/faction ideation
- SDXL relic workflow for objects, relics, and UI motif ideation
- Manual cleanup/pixel reduction in downstream art tools

---

## Approved Direction Summary

This backlog assumes the approved art-bible direction:
- deadpan fantasy absurdism
- protagonist is a courtly cat steward-charmer / duelist
- the deck is framed as a cast of charmed fantasy people, favors, and formal interventions
- purple leopard-print elves are treated as an elegant biological/cultural variety
- goblins are slime-bodied goblins / seep-goblins
- sentient honeybadgers are serious, dangerous civic hardliners
- strategy readability remains more important than ornament

---

## Production Principles

1. Strategy-first
- The game must still read as a high-skill deckbuilder before it reads as a joke.

2. Recurring cast over random portrait soup
- Prefer a stable visual roster and family sheets over dozens of disconnected one-off generations.

3. AI for ideation, not for tiny truth-bearing UI
- Small symbols, state markers, and frame systems are manual-first.

4. Browser thumbnail discipline
- Every portrait must survive reduction to actual card-hand size.

5. One biome / one polished lane first
- Do not scale art production to all imagined content until the first lane is readable and coherent.

---

## Explicit Non-Goals for This Pass

Do not generate or productionize yet:
- final tiny icons
- final card frame exports
- full 80-card illustration coverage
- full hub art set
- full map art set
- final onboarding art set
- broad enemy roster beyond the first slice

---

## Asset Priority Table

| Priority | Category | AI-First or Manual-First | Purpose |
| --- | --- | --- | --- |
| P0 | Icon/chip/badge system | Manual-first | Preserve gameplay readability |
| P0 | Card frame/base layout | Manual-first | Establish card structure before portrait volume |
| P1 | Character/faction concept sheets | AI-first | Lock visual lane and cast coherence |
| P1 | Enemy family + boss sheets | AI-first | Prove the setting supports combat identity |
| P1 | Relic/object concepts | AI-first | Establish object/material language |
| P2 | Signature card portrait masters | AI-first + manual cleanup | Create first playable card art set |
| P2 | Hub mood piece | AI-first | Establish one environment anchor |
| P2 | UI ornament motif explorations | AI-first | Inspire hand-authored UI chrome |

---

## Phase 0: Manual Foundations Before Pretty Pictures

These items should be designed or at least structurally planned before any large-scale portrait push:

### P0.1 Combat/readability UI kit
Needed:
- phase banner shell
- resource HUD shell
- enemy intent tile
- queue/order chip system
- reject / lock / pending toasts or banners
- reward panel shell

Reason:
- portraits should be fit into a stable reading system, not force the layout after the fact

### P0.2 Small icon library
Manual-first targets:
- HP
- block
- energy / mana
- overcharge / momentum if used
- attack / defend / buff / debuff / summon intent
- locked / available / pending / owned
- retain / temp / generated / illegal / unaffordable
- reward card / relic / option

Acceptance rule:
- every icon must work at 24-64 px without relying on color alone

### P0.3 Base card frame system
Build one base frame with:
- portrait window
- cost medallion
- text-safe rules panel
- footer rail for state chips/tags
- rarity accent slot

Guardrail:
- no bespoke frame per card
- no text over art

---

## Phase 1: Style Lane Validation

This is the first serious AI generation pass.

### Batch A: Core cast sheets

Generate:
1. cat steward-charmer / duelist sheet
2. violet pard elf sheet
3. seep-goblin sheet
4. badger warden sheet
5. mixed retinue sheet

Workflow:
- `flux_schnell_fp8_api.json`

Target count:
- 4-8 outputs per sheet
- curate to 1-2 finalists per sheet

Output folders:
- `tools/imagegen/output/batches/characters/cat_steward_01/`
- `tools/imagegen/output/batches/characters/pard_elf_01/`
- `tools/imagegen/output/batches/characters/seep_goblin_01/`
- `tools/imagegen/output/batches/characters/badger_warden_01/`
- `tools/imagegen/output/batches/characters/retinue_mix_01/`

Success criteria:
- all factions feel like one authored world
- silhouettes survive reduction
- cat reads as elegant duelist, not meme-cat
- goblins remain goblins, not goo pinups
- elf patterning stays selective and legible
- honeybadgers feel formidable and civic, not mascot-like

### Batch B: Hub / charter-house mood sheet

Generate:
- 6-8 environment mood pieces for the outpost / charter-house

Workflow:
- `flux_schnell_fp8_api.json`

Output folder:
- `tools/imagegen/output/batches/environments/charter_house_01/`

Success criteria:
- environment supports the courtly-frontier tension from the art bible
- warm lamplight vs cool stone is present
- architecture feels civic and inhabited, not generic tavern sludge

---

## Phase 2: Combat Identity Validation

### Batch C: Enemy family sheet

Generate:
- 1 enemy family sheet with 6-10 concepts
- 1 boss sheet with 6-10 concepts

Workflow:
- `flux_schnell_fp8_api.json`

Output folders:
- `tools/imagegen/output/batches/enemies/family_01/`
- `tools/imagegen/output/batches/enemies/boss_01/`

Success criteria:
- enemy roles feel mechanically distinct at a glance
- boss silhouette is strong enough for key art or reward framing
- no drift into generic fantasy sludge or joke-monster parody

### Batch D: Signature card portrait masters

Generate:
- 3-5 portrait bases for signature cards only

Recommended coverage:
- one cat-aligned card
- one violet pard elf card
- one seep-goblin card
- one badger card
- one mixed/favor/warrant card if needed

Workflow:
- `flux_schnell_fp8_api.json`

Success criteria:
- bust or waist-up crops hold at card size
- one face + one prop + one faction cue remains readable
- backgrounds stay quiet enough for eventual card framing

Guardrail:
- do not scale to broad card-set portrait generation yet

---

## Phase 3: Objects, Relics, and Civic Magic

### Batch E: Relic/object exploration

Generate:
- 10-15 relic concepts
- 6-8 charm-object / seal / warrant token concepts
- 4-6 investment or hub-object concepts

Workflow:
- `sdxl_relic_concept_api.json`

Output folders:
- `tools/imagegen/output/batches/relics/relics_01/`
- `tools/imagegen/output/batches/relics/charm_objects_01/`
- `tools/imagegen/output/batches/relics/hub_objects_01/`

Success criteria:
- silhouettes are clear and emblematic
- materials align with brass / iron / parchment / wax / restrained rune-teal
- objects feel like frontier-court magic, not random loot-goblin clutter

### Batch F: UI ornament ideation

Generate:
- 8-12 ornament motif explorations
- 6-8 panel corner / crest ideas
- 4-6 reward banner motifs

Workflow:
- `sdxl_relic_concept_api.json`

Output folder:
- `tools/imagegen/output/batches/ui_motifs/court_frontier_01/`

Use case:
- inspiration only for hand-authored UI chrome

Guardrail:
- these are not final frame assets

---

## Curation and Approval Rules

Every generated image must pass the following before promotion to approved concept status:

### Readability Gate
- clear focal point
- readable silhouette
- no text artifacts
- no muddy value grouping
- no costume noise that destroys first read

### Tone Gate
- no meme expression
- no overt parody
- no fetish drift
- no clownish exaggeration
- no generic fantasy sludge

### Theme Gate
- fits courtly glamour versus frontier grime
- fits deadpan fantasy absurdism
- feels like part of a coherent charter-house world
- could plausibly sit beside the current art-bible standards

### Gameplay Gate
- would still read if reduced into a card portrait window
- does not require background detail to communicate identity
- can be cropped without losing the subject

---

## Manual Follow-Up After Each Batch

For any concept promoted from AI output to approved direction:
1. choose 1-2 winners only
2. note what works:
   - silhouette
   - palette
   - materials
   - facial attitude
   - prop language
3. note what must be corrected:
   - anatomy
   - costume clutter
   - pattern noise
   - sexualization drift
   - background noise
4. create a hand-finished target brief for later cleanup / repaint / pixel reduction

---

## Suggested 10-Day De-Risk Slice

### Days 1-2
- Generate core cast sheets
- Generate charter-house mood sheet
- Select one winning style lane

### Days 3-4
- Hand-author base icon/chip system
- Hand-author card frame skeleton
- Hand-author first HUD shell concepts

### Days 5-6
- Generate enemy family, boss, relic, and first signature card portrait bases

### Days 7-8
- Curate and manually clean 3-5 selected portraits and 3-5 relic/object concepts
- Mock them into card/reward layouts

### Days 9-10
- Run browser-size readability review
- Freeze style rules for the first visual lane
- Cut anything that looks clever but reads badly

---

## Local Command Starters

### Launch ComfyUI
```bash
bash tools/imagegen/launch_comfyui.sh
```

### Run character workflow
```bash
tools/imagegen/.venv/bin/python tools/imagegen/run_workflow.py flux_schnell_fp8_api.json --prompt "<character prompt>" --negative "<negative prompt>" --filename-prefix "batches/characters/<name>"
```

### Run relic workflow
```bash
tools/imagegen/.venv/bin/python tools/imagegen/run_workflow.py sdxl_relic_concept_api.json --prompt "<relic prompt>" --negative "<negative prompt>" --filename-prefix "batches/relics/<name>"
```

---

## Backlog Exit Criteria

This first art-generation backlog is considered successful when:
- one coherent visual lane is selected
- the four core faction/species sheets feel like one world
- one enemy family and one boss read clearly
- 3-5 card portrait bases hold at mock card size
- one relic/object language is chosen
- UI ornament direction is known well enough to hand-build the actual UI kit

## Next Likely Follow-Up Docs
- `tools/imagegen/prompts/dungeon_steward_character_faction_prompt_pack.md`
- future patch to `tools/imagegen/prompts/dungeon_steward_prompt_templates.md`
- eventual asset registry or schema note for portrait keys separate from `icon_key`
