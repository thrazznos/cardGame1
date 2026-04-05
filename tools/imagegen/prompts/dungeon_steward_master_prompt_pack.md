# Dungeon Steward Master Prompt Pack

This file consolidates three working sources into one practical generation brief:
- `design/art-bible.md`
- `docs/plans/2026-04-05-art-generation-backlog.md`
- `tools/imagegen/prompts/dungeon_steward_character_faction_prompt_pack.md`

Use this as the primary prompting reference for concept generation and batch curation.

It is a concept-generation guide, not a permission slip to let a model improvise the game’s final visual truth.

---

## 1. Visual Contract

Dungeon Steward should read as:
- deadpan fantasy absurdism
- courtly glamour versus frontier grime
- browser-first strategy presentation
- readable silhouettes and controlled value grouping
- a coherent social world rather than random fantasy collage
- serious tactical play inside an absurd but sincere setting

The world treats its absurdities as normal.
The joke is premise plus sincerity, never clowning.

### Hard anti-goals
Do not generate toward:
- parody comedy
- meme culture
- pinup-first fantasy
- random monster collage
- final tiny UI assets
- text-bearing card frames
- oversaturated “AI fantasy sludge”

---

## 2. Runtime Truth

AI is for concepting and visual lane discovery.
Manual craft is for gameplay-critical truth.

### AI-first
Use generation for:
- character/faction sheets
- enemy family sheets
- boss concepts
- relic/object ideation
- hub mood pieces
- ornament motif ideation
- signature portrait bases

### Manual-first
Do not trust generation for final:
- gameplay icons
- badges/chips
- queue symbols
- node icons
- rarity markers
- card frame production exports
- tiny UI states
- text-bearing assets

### Production rule
Preferred process:
1. generate concept base
2. select silhouette, materials, and composition
3. reduce complexity manually
4. rebuild or finish for runtime use by hand

---

## 3. Global Style Guidance

### Shared positive tags
- browser-first game art
- readable silhouette
- controlled value grouping
- portrait-friendly composition
- strong focal hierarchy
- restrained fantasy detail
- elegant absurdity
- deadpan fantasy absurdism
- coherent faction design
- high clarity concept art
- dark neutral or parchment-friendly background

### Shared negative tags
- text
- watermark
- signature
- border
- frame
- muddy composition
- unreadable silhouette
- low contrast focal point
- over-rendered background
- random extra limbs
- costume clutter
- parody comedy
- meme expression
- pinup pose
- fetish styling
- oversaturated neon

---

## 4. Material and Motif Anchors

Use one or two of these strongly per prompt, not all of them at once:
- courtly cat steward-charmer
- portable favors, introductions, warrants, and named allies
- oxblood ribbon or knot favor
- tarnished gold clasp or seal
- frontier charter-house
- brass, iron, parchment, wax, lacquer, velvet, satin
- warm lamplight against cool stone
- restrained rune-teal magical accents

### Palette anchors
- Lamp Black `#1A1719`
- Parchment Cream `#E7DDC7`
- Oxblood Velvet `#6E2430`
- Tarnished Gold `#B18A4B`
- Steel Blue `#51657D`
- Stone Moss `#66715B`
- Candle Amber `#D7A35A`
- Rune Teal `#3E8C8E`
- Plum Violet `#6E4A85`
- Slime Mint `#7BC8A4`

---

## 5. Character and Faction Guardrails

### Cat steward-charmer / duelist
Must read as:
- feline-first
- poised
- socially dangerous
- legally or ceremonially empowered

Avoid:
- anime catboy cliché
- internet-cat chaos
- pirate clutter
- baroque noise

### Violet pard elves
Must read as:
- aristocratic
- predatory
- moonlit
- biologically patterned, not novelty fashion

Avoid:
- tacky all-over leopard chaos
- visual confusion with the protagonist
- patterning on every surface at once

### Seep-goblins
Must read as:
- goblins first
- slime-bodied second
- cunning, useful, improvised, clever

Avoid:
- goo pinup logic
- fanservice silhouette
- silhouette loss through transparency

### Badger wardens
Must read as:
- compact menace
- civic authority
- practical gear
- dead-serious competence

Avoid:
- mascot cuteness
- meme expressions
- comedy armor

---

## 6. Batch Priorities

Use this order when generating exploratory batches.

### P0 Manual foundations first
Design before heavy generation:
- icon/chip/badge system
- combat/readability UI shell
- card frame/base layout

### P1 Style-lane validation
Generate first:
1. cat steward-charmer sheet
2. violet pard elf sheet
3. seep-goblin sheet
4. badger warden sheet
5. mixed retinue sheet
6. charter-house hub mood sheet

### P2 Combat identity validation
Then:
- enemy family sheet
- boss concept sheet
- signature portrait masters

### P3 Object and motif exploration
Then:
- relic concepts
- charm objects / seals / warrants
- hub investment objects
- UI ornament ideation

---

## 7. Output Folder Conventions

Suggested batch outputs under `tools/imagegen/output/batches/`:
- `characters/cat_steward_01/`
- `characters/pard_elf_01/`
- `characters/seep_goblin_01/`
- `characters/badger_warden_01/`
- `characters/retinue_mix_01/`
- `environments/charter_house_01/`
- `enemies/family_01/`
- `enemies/boss_01/`
- `portraits/signature_cards_01/`
- `relics/relics_01/`
- `relics/charm_objects_01/`
- `relics/hub_objects_01/`
- `ui_motifs/court_frontier_01/`

---

## 8. Core Prompt Templates

## 8.1 Cat Steward-Charmer / Duelist
Positive:
`fantasy character concept art, elegant feline steward-charmer duelist, courtly cat protagonist, poised narrow silhouette, rapier-ready posture, velvet coat, satin lining, gloves, signet detail, oxblood ribbon favor, tarnished gold clasp, deadpan fantasy absurdism, browser-first game art, readable silhouette, controlled value grouping, portrait-friendly composition, strong focal hierarchy, dark neutral background`

Negative:
`text, watermark, signature, border, muddy composition, unreadable silhouette, meme cat expression, parody, clownish costume, excessive jewelry clutter, pinup pose, anime catboy cliché, low contrast`

## 8.2 Violet Pard Elf
Positive:
`fantasy character concept art, violet pard elf court duelist, aristocratic elf with elegant purple leopard rosette patterning, moonlit court fashion, silk and lacquered leather, silver accents, severe posture, refined predatory grace, oxblood favor marker, deadpan fantasy absurdism, browser-first game art, readable silhouette, portrait-friendly composition, controlled value grouping, dark neutral background`

Negative:
`text, watermark, muddy composition, unreadable silhouette, tacky all-over leopard print, costume noise, parody glamour, pinup pose, random cat features, low contrast`

## 8.3 Seep-Goblin
Positive:
`fantasy character concept art, seep-goblin alchemist, slime-bodied goblin woman, translucent mint and teal body with readable internal core, clever scavenger-engineer styling, utility straps, cropped coat, satchel, bottle-glass and rusted hardware, expressive goblin face, oxblood charm marker, deadpan fantasy absurdism, browser-first game art, readable silhouette, portrait-friendly composition, strong focal hierarchy, dark neutral background`

Negative:
`text, watermark, muddy composition, unreadable silhouette, fetish styling, bikini logic, oversexualized pose, goo puddle anatomy, random fanservice, low contrast, parody face`

## 8.4 Badger Warden
Positive:
`fantasy character concept art, sentient honeybadger warden, compact dangerous silhouette, practical frontier lawkeeper, roughhide, iron plates, gloves, harness, scarred wood tool or short brutal weapon, soot black and dirty cream patterning, oxblood favor marker, deadpan fantasy absurdism, browser-first game art, readable silhouette, portrait-friendly composition, strong focal hierarchy, dark neutral background`

Negative:
`text, watermark, mascot cute, meme expression, muddy composition, unreadable silhouette, cartoon comedy, parody armor, low contrast`

## 8.5 Mixed Retinue Sheet
Positive:
`fantasy character lineup concept art, coherent frontier charter-house retinue, feline steward-charmer, violet pard elf, seep-goblin, sentient honeybadger, deadpan fantasy absurdism, courtly glamour versus frontier grime, oxblood favor markers, restrained fantasy detail, browser-first game art, readable silhouettes, controlled value grouping, ensemble portrait composition, strong focal hierarchy`

Negative:
`text, watermark, chaotic crowding, muddy composition, parody comedy, random species clutter, unreadable silhouettes, oversaturated neon`

## 8.6 Enemy Family Sheet
Positive:
`fantasy enemy concept sheet, coherent enemy family for a frontier dungeon strategy game, readable silhouettes, one clear threat motif, elegant absurdity, restrained fantasy detail, browser-first gameplay readability, presentation sheet feel, muted materials with one accent color`

Negative:
`text labels, watermark, muddy composition, visual noise, indistinct roles, generic fantasy sludge`

## 8.7 Boss Concept
Positive:
`fantasy boss concept art, frontier dungeon court-aberration boss, imposing readable silhouette, ceremonial menace, elegant absurdity treated seriously, one dominant motif, browser-first gameplay readability, high-contrast focal hierarchy, portrait-friendly or poster-like concept presentation`

Negative:
`text, watermark, muddy composition, overcomplicated anatomy, joke monster, low-contrast silhouette`

## 8.8 Relic Concept
Positive:
`fantasy relic concept art, court-frontier charm object, sealed medallion or warrant token, brass, iron, wax seal, parchment logic, restrained rune teal glow, elegant engraving, readable silhouette, isolated asset presentation, dark neutral background, high clarity concept art`

Negative:
`text, watermark, signature, border, muddy composition, unreadable silhouette, over-ornamented clutter, random glowing junk`

## 8.9 Civic Investment Object
Positive:
`fantasy civic investment artifact concept, charter-house frontier upgrade token, elegant administrative magic object, brass, lacquer, parchment, seal, bell, measured rune accents, readable silhouette, isolated object concept, dark neutral background`

Negative:
`text, watermark, muddy composition, unreadable silhouette, generic magic-shop trinket, excessive filigree noise`

## 8.10 Charter-House Hub Mood
Positive:
`fantasy outpost hub concept art, frontier charter-house, courtly glamour versus frontier grime, warm lamplight against cool stone, parchment, bells, seals, lacquered wood, brass and iron, compact management space, readable layout, game environment concept art`

Negative:
`text, watermark, muddy composition, generic tavern, over-busy architecture, low focal clarity, random high fantasy palace clutter`

---

## 9. Signature Portrait Rules

When prompting portraits that may become card art:
- prefer bust, waist-up, or bust-to-knee compositions
- one face + one prop + one faction cue
- keep backgrounds simple
- preserve top-third readability
- no action-scene chaos unless deliberately testing rare/boss lanes

If the image fails a thumbnail test, discard it.
No mercy.

---

## 10. Batch Evaluation Checklist

Use this after every batch:

### World coherence
- do all outputs feel like one authored world?
- do materials and trims repeat coherently?
- does absurdity remain sincere rather than jokey?

### Readability
- does the silhouette survive reduction?
- is the focal read clear in under one second?
- is there one dominant read rather than five competing reads?

### Faction integrity
- cat reads as elegant duelist, not meme cat
- goblin reads as goblin, not slime pinup
- elf patterning is selective and prestigious
- badger reads as civic menace, not mascot

### Deckbuilder utility
- could this image plausibly crop to card scale?
- would it sit behind a rules panel without visual war crimes?
- is ornament serving identity rather than sabotaging UI?

---

## 11. Pipeline Test Pack A Addendum

For quick engineering pipeline tests, prioritize these placeholder-safe assets:
- `char_player_placeholder_068.png`
- `char_enemy_placeholder_068.png`
- `ui_crest_steward_064.png`
- `ui_icon_pass_032.png`
- `ui_icon_restart_032.png`

These are for ingestion and layout verification, not final art direction.

Use them to validate:
- transparent PNG import
- TextureRect placement
- button icon hookup
- small/medium asset scaling
- scene layout survival in the current combat prototype

---

## 12. Practical Command Pairing

Use with the local workspace under `tools/imagegen/`.

Examples:

FLUX character batch:
`tools/imagegen/.venv/bin/python tools/imagegen/run_workflow.py flux_schnell_fp8_api.json --prompt "<character prompt here>" --steps 4 --set __SCHEDULER__='"simple"' --filename-prefix "batches/characters/test_run"`

SDXL object batch:
`tools/imagegen/.venv/bin/python tools/imagegen/run_workflow.py sdxl_relic_concept_api.json --prompt "<object prompt here>" --filename-prefix "batches/relics/test_run"`

PixelLab character exploration:
`python3 tools/imagegen/pixellab_character_test.py "<prompt here>" --name "<asset name>"`

---

## 13. Final Reminder

If a generated image is charming but unreadable, it has failed.
If it is readable but tonally generic, it has also failed.
The target is coherent, elegant, serious absurdity under tactical constraints.
Which is, admittedly, a fussy thing to ask of a machine. That is why we curate.