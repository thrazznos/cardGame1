# Dungeon Steward Card UI Prompt Pack

Purpose
- Generate concept/reference material for the `Charter Warrant` combat card UI lane.
- Support hand-authored cleanup and UI-chrome development.
- Prioritize readability and strong hierarchy over decorative fantasy excess.

Read first
- `docs/plans/2026-04-06-combat-card-ui-spec.md`
- `docs/plans/2026-04-06-combat-card-ui-implementation-plan.md`
- `docs/plans/2026-04-06-combat-card-ui-asset-brief.md`
- `tools/imagegen/prompts/dungeon_steward_prompt_templates.md`
- `tools/imagegen/prompts/next-art-agent-prompts.md`

Important usage note
- These prompts are for concepting and reference generation, not final shipping UI.
- Final gameplay-critical small UI assets should be hand-authored or hand-finished after selection.
- Do not rely on raw generated outputs for tiny text-bearing UI chrome.

Visual lane
- `Charter Warrant`

Style summary
- enchanted field warrant
- steward / civic fantasy authority
- parchment and ink
- brass and iron trim
- heraldic restraint
- stamped details
- readable at small size
- collectible but disciplined

Avoid
- mobile-app gloss
- ornate tarot clutter
- muddy value grouping
- neon magic sludge
- toy-like saturation
- tiny symbol soup
- texture noise in text-safe areas

---

## Global positive tags

Use these across most card UI chrome prompts:
- fantasy UI concept art
- enchanted field warrant
- steward office authority
- readable silhouette
- controlled value grouping
- parchment and ink
- brass and iron
- heraldic restraint
- clean focal hierarchy
- no typography
- transparent-background-friendly composition
- polished game UI concept
- readable at small size

## Global negative tags

Use these across most card UI chrome prompts:
- text
- watermark
- signature
- logo
- ornate tarot clutter
- muddy composition
- unreadable silhouette
- oversaturated neon
- mobile app gloss
- busy filigree over focal area
- tiny unreadable symbols
- sticker sheet look
- plastic toy finish
- sci-fi UI

---

## Material and palette rules

Base materials
- warm parchment / bone
- dark ink / brown-black
- darkened brass / bronze / iron
- wax accents
- restrained teal only when lightly testing magical accents

Role accents
- attack = garnet / wax red
- defend = sapphire / enamel blue
- utility = verdigris / muted teal / olive-gold

Rule
- Do not flood the whole card body with role color.
- Role color should live in accents, crests, chips, trim, and footer strips.

---

## Prompt 1 — Hand card frame shell

Use for
- base hand card chrome
- the fastest fix for “looks like a button”

Prompt
`fantasy card UI frame concept, enchanted field warrant, steward office authority, hand card shell, parchment body, ink-dark title rail, brass and iron trim, heraldic restraint, readable at small size, clean interior layout zones for cost art title chips footer, no text, transparent-background-friendly, polished game UI concept art`

What good looks like
- clearly card-shaped, not button-shaped
- strong interior zones
- restrained ornament
- readable silhouette at thumbnail size

Reject if
- it looks like a menu panel
- it is overdecorated
- the frame interior becomes too busy for runtime text

---

## Prompt 2 — Reward card frame shell

Use for
- larger ceremonial reward choices
- same family as hand cards, more honored presentation

Prompt
`fantasy reward card UI frame concept, enchanted field warrant, ceremonial card shell, parchment body, dark title rail, brass medallion trim, slightly richer reward presentation, same visual family as tactical hand card, readable at small size, clean interior zones for cost art title chips footer, no text, transparent-background-friendly, polished game UI concept art`

What good looks like
- unmistakably same family as hand frame
- slightly more ceremonial, not different genre
- room for art and reward footer emphasis

Reject if
- it looks like a relic plaque instead of a card
- it becomes so ornate that reward readability suffers

---

## Prompt 3 — Cost medallion exploration

Use for
- reusable cost shell with runtime text overlay

Prompt
`fantasy UI medallion concept, steward warrant cost coin, brass and iron medallion, readable circular badge, elegant engraved rim, parchment-friendly, strong silhouette, no text, no numbers, transparent background, game UI asset concept`

What good looks like
- readable at tiny size
- strong circular silhouette
- enough inner quiet space for runtime number overlay

Reject if
- the center is too busy for a numeral
- it reads as a random coin item instead of UI chrome

---

## Prompt 4 — Role crest set

Use for
- attack / defend / utility role identity
- replacing generic tiny UI icon feeling

Prompt
`fantasy heraldic UI crest set, three role badges for attack defend utility, steward warrant style, stamped metal and wax, readable small-size silhouettes, attack crest aggressive blade motif, defend crest shield ward motif, utility crest key sigil scroll motif, cohesive family, no text, transparent background, game UI asset concept`

What good looks like
- 3 cohesive crests that feel world-specific
- readable at small size
- silhouette stronger than tiny detail

Reject if
- they look like software icons
- the 3 symbols feel unrelated stylistically

---

## Prompt 5 — Payoff chip shells

Use for
- damage / block / focus / gem-operation chips

Prompt
`fantasy UI chip set, tactical payoff capsules for card game, parchment-compatible small UI chips, restrained brass ink wax accents, attack defend utility variants, readable at tiny size, simple strong silhouettes, no text, transparent background, game UI asset concept`

What good looks like
- strong capsule/chip shapes
- runtime text can be overlaid cleanly
- accents support role without flooding the card

Reject if
- the chip body is too textured to hold text
- all variants look the same and lose category value

---

## Prompt 6 — Footer strip states

Use for
- Playable / Needs FOCUS / Needs top Ruby / Add to deck / Chosen

Prompt
`fantasy UI footer strip concept for card game, steward warrant stamped status band, parchment and ink, brass edge details, readable narrow strip, neutral version plus warning and reward variants, no text, transparent background, game UI asset concept`

What good looks like
- clean narrow strip
- obvious lane for runtime truth
- neutral / warning / reward variants feel related

Reject if
- strip becomes too decorative for runtime state text
- it reads like flavor ornament instead of a state lane

---

## Prompt 7 — Selected / chosen reward treatment

Use for
- reward confirmation
- replacing generic software-selected feel

Prompt
`fantasy UI selection marker concept, wax seal and stamped confirmation treatment for reward card, steward warrant theme, brass wax parchment materials, readable at small size, ceremonial but restrained, no text, transparent background, game UI asset concept`

What good looks like
- ceremonial confirmation treatment
- readable when applied over a reward card
- fits the warrant language

Reject if
- it becomes a giant novelty seal that hides the card
- it reads like a sticker instead of in-world confirmation

---

## Prompt 8 — Disabled / locked state overlay

Use for
- making unusable cards readable instead of washed out

Prompt
`fantasy UI disabled overlay concept for card game, subtle lock and scrim treatment, steward warrant theme, readable card state, restrained dark veil with lock motif, preserve legibility of underlying card, no text, transparent background, game UI asset concept`

What good looks like
- signals disabled state without killing readability
- works with runtime footer messaging

Reject if
- overlay is too opaque
- the lock motif turns into icon soup

---

## Prompt 9 — Art-frame cameo

Use for
- embedding illustration into the card face
- replacing pasted-thumbnail energy

Prompt
`fantasy UI art frame concept, inset cameo plaque for tactical card game, steward warrant theme, parchment brass iron materials, readable inner frame, simple strong silhouette, no text, transparent background, game UI asset concept`

What good looks like
- clear framed window
- not too ornate
- art still remains the subject once placed inside

Reject if
- the frame overpowers the art
- it looks like a portrait gallery frame instead of UI chrome

---

## Prompt 10 — Title rail

Use for
- card name home
- reducing flat button-header feel

Prompt
`fantasy UI title rail concept, ink-dark header band for warrant card, parchment-compatible, brass pins or stamped corners, readable at small size, heraldic restraint, no text, transparent background, game UI asset concept`

What good looks like
- simple strong name lane
- dark enough to support light runtime text
- consistent with frame shell

Reject if
- it is so decorative that the name becomes secondary
- the rail shape is too awkward for repeated use

---

## Prompt 11 — Hotkey badge / draft marker

Use for
- top-left hand hotkey integration
- reward draft marker treatment

Prompt
`fantasy UI hotkey badge concept, steward warrant stamped square or heraldic tab, compact readable small-size UI badge, ink parchment brass materials, no text, transparent background, game UI asset concept`

What good looks like
- compact
- readable at tiny size
- integrated with card family

Reject if
- it feels like debug UI
- it visually dominates the cost medallion

---

## Prompt 12 — Alt accent variant for style toggle

Use for
- preserving the current `card_style_variant` idea during first-pass implementation
- generating a safe secondary accent mood within the same family

Prompt
`fantasy card UI style variant concept, same enchanted steward warrant card frame family, alternate accent treatment, parchment body unchanged, variation in wax metal trim and secondary accents only, readable at small size, no text, transparent-background-friendly, polished game UI concept art`

What good looks like
- same family, different mood
- not a completely different card system

Reject if
- variant changes silhouette radically
- variant becomes louder and less readable than the base

---

## Reference sheet — What “good” looks like

A strong result should:
- read as a physical card, not a button
- preserve clear zones for:
  - cost
  - art
  - title
  - payoff chips
  - footer state
- keep role color in accents only
- survive thumbnail reduction
- feel stewardly, disciplined, and world-bound

## Reference sheet — What to reject fast

Reject outputs that show:
- giant saturated slabs
- mobile button gloss
- noisy parchment texture behind text-safe zones
- over-ornate tarot clutter
- tiny symbol soup
- generic fantasy filigree with no hierarchy
- frame interiors too busy for runtime labels

---

## Best practical workflow

1. Generate 4-8 variants per prompt.
2. Select the strongest 1-2 by silhouette and hierarchy.
3. Hand-clean and simplify.
4. Test mock them at actual hand/reward card size.
5. Reject anything that looks clever but reads badly.

## Priority order

If time is limited, generate in this order:
1. hand card frame shell
2. reward card frame shell
3. cost medallion
4. role crest set
5. payoff chip shells
6. footer strip states
7. selected/chosen reward treatment
8. disabled/locked overlay
9. art-frame cameo
10. title rail
11. hotkey badge
12. alt accent variant

## Bottom line

The fastest way to stop the cards from looking like buttons is not more portrait art.
It is a hand-authored card chrome system with:
- frame shell
- cost medallion
- role crests
- payoff chips
- footer strip

Use this pack to concept those pieces aggressively, then hand-finish the winners.