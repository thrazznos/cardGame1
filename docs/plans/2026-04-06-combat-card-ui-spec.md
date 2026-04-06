# Combat Card UI Spec — 2026-04-06

Status
- Draft written from approved direction review.
- Focus: combat hand cards and reward cards only.

Goal
- Make the combat cards read as real cards instead of interface buttons.
- Improve hand scan speed so players can read cost, role, payoff, and gating quickly.
- Preserve Dungeon Steward's tactical clarity while giving the cards a stronger world identity.

Scope
- Combat hand cards in the live combat HUD.
- Reward cards in the current reward overlay.
- Visual language, information hierarchy, state behavior, and prototype-safe implementation guidance.

Non-goals
- Full deckbuilder UI.
- Map or hub UI.
- Drag-and-drop interaction.
- Final production VFX / rarity shine / foil effects.
- Full localization framework work.
- Rewriting combat rules or runtime authority.

Relevant current files
- `scenes/combat/combat_slice.tscn`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `src/core/card/card_presenter.gd`

Problem statement
- The current hand and reward surfaces are structurally and visually closer to buttons than to cards.
- They use short, wide `Button` roots with text-heavy button styling, small overlaid thumbnails, and role icons that feel like accessory UI rather than card anatomy.
- Because the visible hierarchy is weak, the player must read too much text to understand what a card is and why it matters.

Design decision
- Adopt the `Charter Warrant` visual lane for combat cards.
- Cards should feel like enchanted field warrants issued by the steward's office:
  - parchment body
  - dark title rail
  - brass / iron cost medallion
  - framed art cameo
  - heraldic role crest
  - stamped footer strip for condition or state

Why this lane
- Best fit for Dungeon Steward's steward / frontier / civic fantasy tone.
- Strongest balance of readability, card feel, and prototype feasibility.
- More distinctive than a plain ledger treatment.
- Safer and cleaner at small sizes than ornate tarot / gilded CCG treatment.

Core player-facing outcomes
1. The player should immediately read the objects in hand as cards, not menu options.
2. The player should be able to scan a hand in under ~2 seconds for:
   - cost
   - name
   - primary payoff
   - play requirement / gating
3. Reward choices should feel like drafting cards, not clicking three modal buttons.
4. Card identity should come from layout and hierarchy first, not just background color.

Visual thesis
- These are formal tactical directives.
- They should feel authoritative, collectible, and world-bound.
- They should not feel like soft rounded app controls or generic web buttons.

Style keywords
- stewardly
- parchment
- heraldic
- stamped
- disciplined
- tactile
- readable

Avoid keywords
- neon
- glossy mobile UI
- over-ornate tarot clutter
- noisy fantasy chrome
- toy-like saturated slabs

## 1. Silhouette and proportions

### Hand cards
Target shape
- Fixed-width portrait-leaning cards.
- No full-row stretch-fill behavior.
- No wide-toolbar look.

Recommended first-pass size
- `152 x 216`

Allowed range
- width: `148-156`
- height: `208-224`

Layout rules
- Center cards in a hand tray.
- Keep equal spacing between cards.
- Do not overlap in first pass.
- Do not fan in first pass.
- Do not stretch cards to fill all available width.

### Reward cards
Reward cards should be the same visual family as hand cards, but larger and more ceremonial.

Recommended first-pass size
- `200 x 280`

Allowed range
- width: `192-208`
- height: `264-292`

Reward layout rules
- Center the 3 rewards in the overlay.
- Preserve family resemblance to hand cards.
- Increase breathing room and perceived importance.

## 2. Card anatomy

Each card should have clear regions.

### Region A — Top edge utilities
Contents
- hotkey or draft marker at top-left
- cost medallion at top-right

Purpose
- Expose interaction affordance without making the card feel like a control.
- Make cost a first-class read.

### Region B — Art frame
Contents
- framed art window
- optional role crest overlapping frame corner

Purpose
- Replace the current “thumbnail pasted on a button” look.
- Make the art feel embedded in a card object.

### Region C — Title rail
Contents
- card name
- optional small subtype / role label

Purpose
- Give the card name a real home.
- Improve world feel and readability.

### Region D — Payoff band
Contents
- 1-2 dominant payoff chips

Examples
- `6 DMG`
- `5 BLK`
- `+1 FOCUS`
- `Produce Ruby`
- `Consume Sapphire`
- `Draw 1`

Purpose
- Answer “why would I play this?” before the player reads body text.

### Region E — Rules body
Contents
- max 1-2 short lines of supporting rules text

Purpose
- Confirm understanding without turning the card into a paragraph.

### Region F — Footer strip
Contents
- play condition / legality / runtime state / reward state

Examples
- `Playable`
- `Needs top Ruby`
- `Needs FOCUS`
- `Resolve Locked`
- `Add to deck`
- `Chosen`

Purpose
- Keep runtime truth in a dedicated stable lane.

## 3. Information hierarchy

Cards must be readable in this order:
1. Cost
2. Name
3. Primary payoff
4. Requirement / state
5. Supporting rules
6. Art mood / flavor

Important rule
- The player should not need to read the rules body first to understand the card's broad intent.

## 4. Hand card wireframe

Suggested hand card face

```text
┌────────────────────────┐
│ 1                  1◎ │
│ ┌──────────────────┐  │
│ │      art         │  │
│ └──────────────────┘  │
│ [ATK crest] Strike    │
│ 6 DMG   Consume Ruby  │
│ Hit harder if top gem │
│ is Ruby               │
│ Needs top Ruby        │
└────────────────────────┘
```

Interpretation
- `1` = hotkey badge
- `1◎` = cost medallion
- crest = role badge
- `6 DMG` / `Consume Ruby` = payoff chips
- last line = footer condition

## 5. Reward card wireframe

Suggested reward card face

```text
┌────────────────────────────┐
│ Reward                 1◎ │
│ ┌──────────────────────┐  │
│ │       art            │  │
│ └──────────────────────┘  │
│ [DEF crest] Hold Fast     │
│ 7 BLK   +1 FOCUS          │
│ Gain block and prepare    │
│ next turn                 │
│ Add to deck permanently   │
└────────────────────────────┘
```

Reward-specific notes
- Reward cards may devote slightly more space to art and payoff because their use-case is comparison, not rapid in-turn execution.
- The reward footer should communicate acquisition truth, not combat legality.

## 6. Role system on the face

Current issue
- Role is currently carried too heavily by bracket markers and background fills.

New rule
Role must be communicated by 3 layers together:
1. crest / icon shape
2. accent color
3. role label or visual chip near title

### Attack
- accent: garnet / wax red
- crest motifs: blade, slash, fang, spearhead
- emotional read: aggressive, assertive, immediate payoff

### Defend
- accent: sapphire / enamel blue
- crest motifs: shield, bulwark, ward, wall
- emotional read: stable, prepared, protective

### Utility
- accent: verdigris / muted teal / olive-gold
- crest motifs: key, seal, knot, sigil, scroll
- emotional read: flexible, clever, enabling

Important constraint
- Do not make the entire card body red / blue / green.
- Role color should be used in accents, chips, crests, tabs, and footer details.
- The main card body should remain neutral parchment / bone.

## 7. Materials and palette

### Base materials
- parchment / warm bone face
- dark ink or brown-black text
- brass / iron medallion details
- leather / metal / ink-dark title rail
- subtle inner shadow and card edge definition

### Accent usage
Allowed uses for role color
- role crest
- cost medallion trim if desired
- payoff chip fills
- small frame tabs
- footer accent rail

Disallowed uses
- full-card background flood fills
- giant saturated panel slabs behind all text
- anything that makes the card read like a large colored button

### Texture guidance
- subtle paper grain only
- no heavy noise texture over text areas
- no “aged fantasy UI dirt” that lowers clarity

## 8. Typography hierarchy

### Cost numeral
- most visually dominant numeric element on the card
- high contrast
- large enough to read at hand distance

### Card name
- second-highest hierarchy
- formal readable display style if available
- avoid ornate decorative type that hurts clarity

### Payoff chips
- bold and compact
- numerals large
- chip language should be simpler and faster than body text

### Rules body
- simplest readable face
- smaller than payoff and name
- still high contrast
- max 2 lines in first pass

### Footer strip
- may use uppercase or small caps if legible
- should feel like a stamped status strip

## 9. Hotkey treatment

Hand cards
- Hotkey badge stays visible on the face.
- It should feel integrated into the card, not debug text.
- Suggested treatment: stamped square, heraldic tab, or small black-ink seal.

Reward cards
- Numeric keyboard selection can remain, but should be styled as a draft marker rather than a hand hotkey.

## 10. Cost treatment

- Cost must live in a dedicated medallion.
- Cost cannot be hidden inside the name or body text.
- Zero-cost cards still render a cost medallion.
- Cost medallion should be readable in peripheral vision.

## 11. Art-frame treatment

Current issue
- The current art thumb reads like an avatar thumbnail.

New rule
- The art must sit in a framed plaque / cameo / inset panel.
- The frame does important “card object” work even if the art itself is still placeholder.
- The frame may be simple, but must be deliberate.

Constraints
- Art area must not overwhelm title, payoff, and rules.
- Portrait art should survive reduction to actual hand size.
- Existing placeholder/generated art is acceptable inside the new frame for now.

## 12. Payoff chips

Payoff chips are a mandatory part of the redesign.

Purpose
- Make the card's tactical promise visible.
- Reduce dependence on full sentence reads.

Rules
- Each card face shows 1-2 dominant chips.
- Chips must be more visually prominent than rules body text.
- Chips should use explicit text/numbers, not icon-only language.

Examples
- `6 DMG`
- `5 BLK`
- `+1 FOCUS`
- `Ruby`
- `Sapphire`
- `Produce Ruby`
- `Consume Top`
- `Offset 1`

For GSM / sequencing cards
- The chip language should emphasize the tactical operation, not the full resolution prose.

## 13. Rules-body copy guidance

Face-copy constraints
- 1-2 short lines max.
- Use supporting language only.
- Avoid paragraph-face cards.

Good prototype face copy
- `Hit harder if top gem is Ruby.`
- `Gain block and prepare next turn.`
- `Spend FOCUS to reach deeper gems.`

Bad prototype face copy
- verbose exact rules implementation language
- long chained clauses
- multi-sentence body text blocks

## 14. Footer strip behavior

The footer strip is the runtime truth lane.

Hand-card footer examples
- `Playable`
- `Needs top Ruby`
- `Needs FOCUS`
- `No energy`
- `Resolve Locked`

Reward-card footer examples
- `Add to deck`
- `Pick one`
- `Chosen`
- `Claimed`

Important rule
- Footer is not flavor text.
- Footer communicates condition, acquisition, or live state.

## 15. State behavior

### Idle
- Card sits as a physical object.
- Clear shadow and edge definition.
- No generic button-face look.

### Hover
- Raise card slightly (`~8-12 px`).
- Strengthen shadow.
- Slightly brighten frame edge.
- Update detail surface immediately.

### Focus
- Same emphasis as hover.
- Add explicit focus ring or high-contrast focus treatment.
- Must work for keyboard/controller, not hover alone.

### Pressed
- Brief compression / snap.
- Should feel like committing a card, not pressing a menu button.

### Disabled
- Keep face readable.
- Add muted overlay or reduced saturation without destroying legibility.
- Footer should state the reason or gating.

Bad disabled behavior
- fully washed-out gray mush
- unreadable text
- unexplained inaction

### Reward selected
- Strong confirmation treatment:
  - wax seal
  - ribbon
  - framed confirmation edge
  - or stamped `Chosen`
- Avoid generic checkbox / software-selected feel.

## 16. Hand tray behavior

The tray matters as much as the cards.

Rules
- Use fixed-width cards in a centered row.
- Keep enough horizontal gap for silhouettes to read.
- Do not stretch-fill the row.
- The tray should read as a hand or laid-out tactical set, not an action bar.

First pass
- straight row
- no overlap
- no fan

Future optional upgrade
- subtle hand fan or depth stagger if readability survives

## 17. Face vs tooltip/detail split

### Always on face
- cost
- name
- role
- primary payoff
- short condition / gating
- hotkey or draft marker

### Move to tooltip / detail surface
- full rules wording
- exact unavailable reason sentence
- deeper sequencing explanation
- gem/focus glossary detail
- reward permanence explanation if needed

Principle
- The card face answers:
  - what is this?
  - what does it mostly do?
  - can I play it?
- The detail surface answers:
  - how exactly does it work?

## 18. Implementation guidance

Recommended technical shape
- Move toward a reusable `CardView` component.
- For first pass, root may remain a `Button` for compatibility with current combat HUD wiring and smoke tests.
- The visible content should be built from child layout nodes, not primarily from `Button.text` styling.

Prototype-safe first pass
1. Stop visually treating the slot root as the card face.
2. Give hand and reward cards fixed card proportions.
3. Add card-face structure:
   - hotkey badge
   - cost badge
   - art frame
   - title label
   - payoff chip row
   - rules label
   - footer label
4. Preserve current click / hotkey behavior.
5. Preserve deterministic-safe UI boundary.

Likely touch points when implementing
- `scenes/combat/combat_slice.tscn`
- `src/ui/combat_hud/combat_hud_controller.gd`
- likely a new reusable `CardView` scene/script if implementation proceeds

## 19. Asset guidance

Must be hand-authored or hand-finished
- base card frame shell
- title rail
- cost medallion
- role crests / badges
- payoff chip shapes
- footer strip states
- selected / chosen / disabled chrome states

Can remain placeholder/generated for now
- portrait art inside the frame
- some ornament motif exploration
- reward backdrop mood art

Important art rule
- Gameplay-critical small UI assets should be hand-authored or hand-finished once direction is locked.

## 20. Explicit non-goals for the first implementation pass

- Drag-and-drop card interaction
- Full deck inspection screen
- Full card tooltip framework rewrite
- Final rarity animation system
- Foil / holographic effects
- Major map / hub UI integration

## 21. Success criteria

This redesign is successful when:
- A screenshot of the hand reads as `cards` immediately.
- The cards no longer resemble utility buttons.
- Cost, name, payoff, and gating scan quickly.
- Reward choices feel like drafting cards, not clicking menu items.
- The design fits Dungeon Steward's steward / warrant fantasy.
- Readability remains strong at actual play size.

## 22. Recommended next follow-up

If this spec remains approved, the next practical artifact should be an implementation plan for a low-risk first pass covering:
- updated hand/reward layout
- card-face node structure
- compatibility with existing hotkeys and smoke probes
- staged migration toward a reusable card view component
