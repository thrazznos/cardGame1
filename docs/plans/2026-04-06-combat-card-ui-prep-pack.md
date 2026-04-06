# Combat Card UI Prep Pack — Collision-Safe Support Work

Status
- Prepared specifically to avoid colliding with live HUD implementation already underway elsewhere in the repo.
- This document is non-authoritative implementation support, not a replacement for the approved card UI spec or implementation plan.

Purpose
- Capture the safe prep work that can be done while another agent is editing the live combat HUD files.
- Make collision boundaries explicit.
- Preserve implementation momentum by centralizing swap points, probe assumptions, asset inventory, and follow-up sequencing.

Primary references
- `docs/plans/2026-04-06-combat-card-ui-spec.md`
- `docs/plans/2026-04-06-combat-card-ui-implementation-plan.md`
- `handoff.md`

---

## 1. Current collision boundaries

At the time this prep pack was written, `git status --short` showed live work already touching these files:
- `assets/generated/README.md`
- `scenes/combat/combat_slice.tscn`
- `src/bootstrap/combat_slice_runner.gd`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `tests/smoke/run_card_instance_probe.gd`
- `tests/smoke/test_playable_prototype.py`
- `tests/smoke/run_gameplay_art_visibility_probe.gd`
- `handoff.md`

Implication
- Avoid direct edits to the current combat HUD implementation files until the other agent's changes are integrated or a clear handoff is established.
- Safe prep work should happen in isolated documentation or new future-facing references only.

---

## 2. Files explicitly treated as hot / do-not-touch during parallel work

These should be treated as collision-prone right now:
- `scenes/combat/combat_slice.tscn`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `tests/smoke/test_playable_prototype.py`
- `tests/smoke/run_gameplay_art_visibility_probe.gd`
- `assets/generated/README.md`

Conditionally hot
- `src/bootstrap/combat_slice_runner.gd`
- any currently modified smoke probes in `tests/smoke/`

Safe prep locations
- `docs/plans/`
- other new documentation files not currently modified
- future asset briefs or checklists that do not change runtime wiring

---

## 3. What is already known and should not be rediscovered

### Approved design direction
- Combat cards should follow the `Charter Warrant` lane:
  - parchment card body
  - dark title rail
  - brass / iron cost medallion
  - framed art cameo
  - heraldic role crest
  - stamped footer strip

### Approved implementation strategy
- First pass is compatibility-first.
- Keep root hand/reward slots as `Button` nodes during the first pass.
- Preserve compatibility-sensitive node names and properties.
- Extract reusable `CardView` only after the first visual pass is stable.

### Already-implemented gameplay-art swap points
From `handoff.md`, the current HUD already exposes:

Hand buttons
- `CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1..Card5/ArtThumb`
- `CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1..Card5/RoleIcon`

Reward buttons
- `CombatHud/RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1..Reward3/ArtThumb`
- `CombatHud/RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1..Reward3/RoleIcon`

Generated status strip
- `CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop1`
- `.../GemTop2`
- `.../GemTop3`
- `.../FocusIcon`
- `.../FocusValue`
- `.../LockIcon`

---

## 4. Current smoke/probe contract assumptions

Several smoke probes currently assume the following remain true.

### Slot/root assumptions
- `Card1..Card5` still exist at their current scene paths
- `Reward1..Reward3` still exist at their current scene paths
- root slot nodes are `Button`

### Child lookup assumptions
- `ArtThumb` exists and is directly discoverable under the slot root
- `RoleIcon` exists and is directly discoverable under the slot root

### Text compatibility assumptions
- `Button.text` still contains useful card text in at least some probes

Examples
- `tests/smoke/run_gsm_integration_probe.gd`
- `tests/smoke/run_gsm_pilot_probe.gd`
- `tests/smoke/run_hybrid_payoff_probe.gd`

### Input assumptions
- `_unhandled_input` still exists on the HUD
- numeric hotkeys still route through the current keyboard path
- `Enter` still handles pass / reward continue as currently implemented

### Style assumptions
- `card_style_variant` still exists
- pressing `V` still changes style state
- `run_card_style_toggle_probe.gd` still reads a root `normal` stylebox from `Card1`

Takeaway
- Any first-pass redesign must preserve those invariants unless the probes are updated in the same slice.

---

## 5. Current generated asset inventory relevant to the card surfaces

### Shared card art lanes
Current mapped files present under `assets/generated/cards/`:
- `card_ember_jab_ruby_md.png`
- `card_defend_badger_bulwark_md.png`
- `card_ward_polish_sapphire_md.png`
- `card_strike_cat_duelist_md.png`
- `card_vault_focus_seal_md.png`
- `card_scheme_seep_goblin_md.png`
- placeholder: `cards/placeholders/card_placeholder_steward_warrant_md.png`

### Icons
Current mapped files under `assets/generated/ui/icons/`:
- `ui_icon_attack_sm.png`
- `ui_icon_defend_sm.png`
- `ui_icon_utility_sm.png`
- `ui_icon_focus_sm.png`
- `ui_icon_locked_sm.png`
- `ui_icon_stack_top_sm.png`

### Gem tokens
Current mapped files under `assets/generated/gems/`:
- `obj_gem_ruby_token_md.png`
- `obj_gem_sapphire_token_md.png`

---

## 6. Collision-safe prep work that can continue independently

These tasks are safe to perform without touching the active HUD implementation files.

### A. Asset briefing and naming
- define the hand-authored Charter Warrant UI asset list
- define naming conventions for frame, medallion, crest, chip, and footer assets
- define which existing mapped art lanes should be replaced first before code expands mapping tables

Output location
- `docs/plans/2026-04-06-combat-card-ui-asset-brief.md`

### B. Merge-readiness checklist
- maintain a checklist of what must be true before the card-UI implementation starts editing hot files again

Suggested checklist
- other agent's working tree is committed/stashed/handed off
- full smoke suite remains green
- current scene/controller paths are known
- no open disagreement on the Charter Warrant face anatomy

### C. Post-merge implementation priorities
- maintain a short sequence for the actual merge window:
  1. geometry change
  2. card-face structure
  3. chrome restyle
  4. structured labels
  5. reward variant
  6. smoke expansion

### D. Manual review checklist for card-feel validation
Prepare the review questions now so the first visual pass can be judged quickly:
- Does the hand read as cards at first glance?
- Do they still resemble utility buttons?
- Is cost visible in peripheral vision?
- Are payoff chips clearer than rules text?
- Is disabled state readable rather than washed out?
- Do reward choices feel like drafting cards?

---

## 7. Do-not-forget integration notes for the eventual implementation window

1. Preserve `Button.text` in first pass even if visible labels take over.
2. Preserve `ArtThumb` and `RoleIcon` names during the first pass.
3. Animate internal chrome rather than the slot root to avoid container jitter.
4. Keep role color in accents, not full-body flood fills.
5. Keep reward cards in the same visual family as hand cards.
6. Do not let cost get buried in sentence text again.
7. Do not let footer become flavor text; it is runtime truth.

---

## 8. Suggested split of responsibilities during parallel work

### Safe for the currently active HUD implementer
- edits to `combat_slice.tscn`
- edits to `combat_hud_controller.gd`
- edits to live UI smoke probes
- visual integration and runtime validation

### Safe for a collision-avoiding support agent
- asset briefs
- naming conventions
- test/risk checklists
- design clarification notes
- manual review checklists
- future `CardView` extraction notes that do not touch the active files

---

## 9. Immediate next steps after merge window opens

1. Re-check `git status --short`
2. Re-read `handoff.md`
3. Confirm whether the gameplay-art visibility changes are already incorporated in the version to modify
4. Use the approved implementation plan as the active sequencing document
5. Only then begin editing:
   - `scenes/combat/combat_slice.tscn`
   - `src/ui/combat_hud/combat_hud_controller.gd`
   - relevant smoke probes

---

## 10. Bottom line

This prep pack exists to keep momentum without stepping on active HUD work.

What is already solved
- direction
- implementation strategy
- current swap-point knowledge
- known probe constraints

What remains for the active implementation window
- the actual card-face rebuild in scene/controller/test files

The biggest risk is not design ambiguity anymore.
The biggest risk is collision with currently modified live files.
