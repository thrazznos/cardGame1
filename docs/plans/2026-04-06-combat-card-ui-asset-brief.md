# Combat Card UI Asset Brief — Charter Warrant Lane

Status
- Collision-safe prep document.
- Intended to guide hand-authored or hand-finished UI asset work without touching the active combat HUD implementation files.

Purpose
- Define the UI-specific asset set needed to make the combat cards feel like cards rather than buttons.
- Separate gameplay-critical hand-authored UI chrome from placeholder/generated illustration content.
- Establish replacement priorities and a naming scheme that can be wired later.

Primary references
- `docs/plans/2026-04-06-combat-card-ui-spec.md`
- `docs/plans/2026-04-06-combat-card-ui-implementation-plan.md`
- `handoff.md`
- `docs/plans/2026-04-05-art-generation-backlog.md`

Visual lane
- `Charter Warrant`

Style summary
- enchanted field warrants
- steward / civic fantasy authority
- parchment card body
- ink-dark title rail
- brass / iron cost medallion
- heraldic role crest
- stamped footer strip
- readable before ornate

Important constraint
- Gameplay-critical small UI assets should be hand-authored or hand-finished.
- Generated illustration is acceptable inside the art window, but the frame/chrome system should not rely on raw AI output quality.

---

## 1. What should remain generated/placeholder for now

These can remain shared-lane or placeholder during the first pass:
- card illustration art used inside the card window
- current portrait-lane images:
  - `card_strike_cat_duelist_md.png`
  - `card_defend_badger_bulwark_md.png`
  - `card_scheme_seep_goblin_md.png`
  - `card_ember_jab_ruby_md.png`
  - `card_ward_polish_sapphire_md.png`
  - `card_vault_focus_seal_md.png`
- gem token art
- broad mood or reward-backdrop art

Reason
- The fastest visible win is not one-image-per-card.
- The fastest visible win is better card chrome and hierarchy.

---

## 2. What should be hand-authored or hand-finished

These are the highest-value UI assets for the redesign.

### A. Base card frame system
Needed variants
- hand card frame shell
- reward card frame shell
- optional alt-accent variant for `card_style_variant`

Requirements
- parchment/bone face
- strong edge definition
- visually distinct from generic button chrome
- compatible with overlaid title, chips, and footer strips

Suggested filenames
- `assets/generated/ui/cards/card_frame_charter_hand_base_md.png`
- `assets/generated/ui/cards/card_frame_charter_reward_base_md.png`
- `assets/generated/ui/cards/card_frame_charter_hand_alt_md.png`
- `assets/generated/ui/cards/card_frame_charter_reward_alt_md.png`

Notes
- Even if later replaced by fully procedural StyleBox work, these files are good target artifacts for look development.

### B. Title rail / header plate
Needed variants
- neutral title rail
- optional role-accent trims or overlay tabs

Suggested filenames
- `assets/generated/ui/cards/card_title_rail_charter_md.png`
- `assets/generated/ui/cards/card_title_rail_charter_alt_md.png`

Purpose
- give the name a strong home
- reduce button-like flatness

### C. Cost medallion
Needed assets
- cost coin / medallion frame (text can remain runtime-rendered)
- optional alt variant if `card_style_variant` is preserved visually

Suggested filenames
- `assets/generated/ui/cards/card_cost_medallion_charter_md.png`
- `assets/generated/ui/cards/card_cost_medallion_charter_alt_md.png`

Important note
- Prefer one reusable medallion shell with runtime text rather than separate baked-number assets for each value.

### D. Role crests
These are core identity assets.

Needed assets
- attack crest
- defend crest
- utility crest

Suggested filenames
- `assets/generated/ui/cards/card_role_crest_attack_sm.png`
- `assets/generated/ui/cards/card_role_crest_defend_sm.png`
- `assets/generated/ui/cards/card_role_crest_utility_sm.png`

Design notes
- should feel heraldic, stamped, and world-specific
- should not read like generic software icons
- should work at small size

### E. Payoff chip shells
Needed assets
- neutral payoff chip capsule
- optional accent-tinted chip shells for attack / defend / utility categories

Suggested filenames
- `assets/generated/ui/cards/card_chip_payoff_neutral_sm.png`
- `assets/generated/ui/cards/card_chip_payoff_attack_sm.png`
- `assets/generated/ui/cards/card_chip_payoff_defend_sm.png`
- `assets/generated/ui/cards/card_chip_payoff_utility_sm.png`

Purpose
- make payoff summaries feel like tactical chips, not inline text

### F. Footer strip system
Needed assets
- neutral footer strip
- reward footer strip
- warning/locked footer strip if desired

Suggested filenames
- `assets/generated/ui/cards/card_footer_strip_neutral_md.png`
- `assets/generated/ui/cards/card_footer_strip_reward_md.png`
- `assets/generated/ui/cards/card_footer_strip_locked_md.png`

Purpose
- give runtime truth a dedicated visual lane
- prevent footer from feeling like leftover label text

### G. State chrome
Needed assets or treatments
- focus/hover edge highlight or overlay
- selected/chosen state for rewards
- disabled/locked scrim treatment

Possible filenames
- `assets/generated/ui/cards/card_state_selected_wax_seal_sm.png`
- `assets/generated/ui/cards/card_state_disabled_scrim_md.png`
- `assets/generated/ui/cards/card_state_focus_outline_md.png`

Note
- Some of this may end up implemented procedurally, but it should still be concepted as a real asset/state system.

---

## 3. Existing assets worth keeping or reusing

### Likely keep in first pass
- `assets/generated/ui/icons/ui_icon_focus_sm.png`
- `assets/generated/ui/icons/ui_icon_locked_sm.png`
- `assets/generated/gems/obj_gem_ruby_token_md.png`
- `assets/generated/gems/obj_gem_sapphire_token_md.png`
- `assets/generated/cards/placeholders/card_placeholder_steward_warrant_md.png`
  - especially useful as a tone reference for the Charter Warrant lane

### Likely replace later, but not urgent to block the UI redesign
- `ui_icon_attack_sm.png`
- `ui_icon_defend_sm.png`
- `ui_icon_utility_sm.png`

Reason
- Those current role icons are semantically useful, but the longer-term face language should favor heraldic role crests over generic small UI icons.

---

## 4. Replacement priorities

If only a little art time is available, do this order:

Priority 1 — frame/chrome system
1. hand card frame shell
2. reward card frame shell
3. cost medallion shell
4. role crests
5. footer strip
6. payoff chip shell

Why
- These change the objects from “buttons” to “cards” fastest.

Priority 2 — polish role language
1. attack crest refinement
2. defend crest refinement
3. utility crest refinement
4. role-accent trim tuning

Priority 3 — improve shared illustration lanes
1. strike lane
2. scheme/utility lane
3. defend lane
4. reward overlay supporting ornament

This matches the earlier guidance from `handoff.md`: replace mapped files first before expanding the mapping table.

---

## 5. Naming scheme recommendation

Use a clear UI-cards namespace to avoid mixing gameplay portrait art with card chrome.

Recommended folder
- `assets/generated/ui/cards/`

Recommended prefixes
- `card_frame_...`
- `card_title_...`
- `card_cost_...`
- `card_role_...`
- `card_chip_...`
- `card_footer_...`
- `card_state_...`

Recommended suffix size cues
- `_sm`
- `_md`
- `_lg`

Examples
- `card_frame_charter_hand_base_md.png`
- `card_role_crest_attack_sm.png`
- `card_chip_payoff_attack_sm.png`
- `card_footer_strip_reward_md.png`

Naming goal
- make future wiring obvious
- make it easy to distinguish chrome assets from card-illustration assets

---

## 6. Size and readability guidance

### Hand card chrome
Target visual frame around final card size:
- overall card target around `152 x 216`

### Reward card chrome
Target visual frame around final reward size:
- overall card target around `200 x 280`

### Crest/icon readability
- must survive reduction to live card size
- use strong silhouette over tiny internal detail

### Chip readability
- chips should support runtime text overlays
- avoid extremely textured or noisy chip interiors

### Frame readability
- parchment/chrome texture should never interfere with text bands
- high-detail ornament should be kept out of title, payoff, and footer read lanes

---

## 7. Color/material brief

Base materials
- warm parchment / bone
- dark ink / near-black brown
- darkened brass or iron trim
- restrained inner shadow

Role accents
- attack = wax/garnet red
- defend = sapphire/enamel blue
- utility = verdigris / muted teal / olive-gold

Important rule
- role color belongs in accents and chips, not full-card background floods

---

## 8. Explicit art-direction pitfalls to avoid

Avoid
- mobile-app button gloss
- bright full-card saturation slabs
- over-ornate tarot clutter
- noisy fantasy filigree in text-safe areas
- tiny icon soup
- unreadable parchment texture over rules text
- “menu option with a thumbnail” composition

Pursue
- strong silhouette
- readable hierarchy
- heraldic restraint
- tactical clarity
- collectible but disciplined tone

---

## 9. Deliverable checklist for a future art pass

A future card-ui art pass is ready when it can provide:
- [ ] hand card frame shell
- [ ] reward card frame shell
- [ ] cost medallion shell
- [ ] attack crest
- [ ] defend crest
- [ ] utility crest
- [ ] payoff chip shell(s)
- [ ] footer strip(s)
- [ ] selected/chosen reward state treatment
- [ ] disabled/locked treatment concept

Optional but nice
- [ ] title rail alt variant
- [ ] frame alt variant for `card_style_variant`
- [ ] wax-seal chosen marker for rewards

---

## 10. Bottom line

The combat card UI does not primarily need more illustration first.
It needs a hand-authored card chrome system.

If time is constrained, prioritize:
1. frame shell
2. cost medallion
3. role crests
4. footer strip
5. payoff chip shell

Those five items will do more to kill the “these are just buttons” problem than any amount of extra portrait art alone.
