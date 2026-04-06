# Combat Card UI Implementation Plan

> For Hermes: implement this as a compatibility-first UI redesign. Do not commit unless the user explicitly instructs you to do so.

Goal
- Rebuild the current combat hand and reward slots so they read as Charter Warrant cards instead of wide UI buttons, while preserving current hotkeys, click behavior, smoke probes, and deterministic-safe UI boundaries.

Architecture
- Keep the current hand and reward slot roots as `Button` nodes for the first pass.
- Stop treating the root button as the visible face; instead, render a structured card face inside each slot.
- Preserve compatibility-sensitive node names and properties during the first pass: `Card1..Card5`, `Reward1..Reward3`, `ArtThumb`, `RoleIcon`, `Button.text`, `_unhandled_input`, and `card_style_variant`.
- Defer extraction to a reusable `CardView` component until the first visual pass is stable and smoke coverage is updated.

Tech stack
- Godot 4.6.2
- GDScript
- `scenes/combat/combat_slice.tscn`
- `src/ui/combat_hud/combat_hud_controller.gd`
- Existing smoke harness in `tests/smoke/test_playable_prototype.py`

Reference design docs
- `docs/plans/2026-04-06-combat-card-ui-spec.md`
- `docs/plans/2026-04-05-combat-fun-roadmap.md`
- `docs/architecture/ADR-0001-runtime-determinism-and-ui-boundary.md`

Why this plan is compatibility-first
- Several smoke probes currently assume:
  - slot names remain `Card1..Card5` and `Reward1..Reward3`
  - slot roots are `Button`
  - `ArtThumb` and `RoleIcon` are directly discoverable under the slot root
  - `Button.text` still contains useful card text
  - `card_style_variant` still toggles via `V`
  - `_unhandled_input` still routes keyboard play / pass / reward selection
- A clean-slate widget rewrite would create unnecessary regression risk before the look is proven.

Non-goals
- Full deckbuilder / inspection UI
- Map or hub UI work
- Drag-and-drop cards
- Final production foil / rarity FX
- Full tooltip framework rewrite
- Gameplay or determinism contract changes

Compatibility invariants for the first pass
1. Preserve node names:
   - `Margin/VBox/HandPanel/HandVBox/HandButtons/Card1..Card5`
   - `RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1..Reward3`
2. Preserve root slot type: `Button`
3. Preserve child names reachable from the slot root:
   - `ArtThumb`
   - `RoleIcon`
4. Preserve `Button.text` as a compatibility/debug mirror even if visible text moves to child labels
5. Preserve `_unhandled_input` and numeric hotkeys
6. Preserve `card_style_variant` and the `V` style toggle during the first pass
7. Animate internal chrome, not the slot root, to avoid layout jitter in the hand row

Implementation approach summary
- Step 1: reshape the slots so they look like cards geometrically
- Step 2: add internal card-face anatomy
- Step 3: restyle the chrome to match the Charter Warrant spec
- Step 4: populate structured face labels while keeping compatibility text alive
- Step 5: extend smoke coverage for the new face structure
- Step 6: validate in headless and in the native slice

---

## Task 1: Lock the compatibility contract before editing the UI

Objective
- Make implementation constraints explicit so the first pass does not accidentally break tests or input.

Files
- Inspect:
  - `scenes/combat/combat_slice.tscn`
  - `src/ui/combat_hud/combat_hud_controller.gd`
  - `tests/smoke/run_gameplay_art_visibility_probe.gd`
  - `tests/smoke/run_card_style_toggle_probe.gd`
  - `tests/smoke/run_keyboard_hotkey_probe.gd`
  - `tests/smoke/run_gsm_integration_probe.gd`
  - `tests/smoke/run_gsm_pilot_probe.gd`
  - `tests/smoke/run_hybrid_payoff_probe.gd`
  - `tests/smoke/test_playable_prototype.py`

Implementation notes
- Do not remove or rename compatibility-sensitive nodes in this pass.
- Do not change root slot types.
- Do not remove `Button.text` or `_unhandled_input` routing.

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- Existing smoke suite is green before UI changes begin.

---

## Task 2: Reshape hand and reward geometry so slots read as cards

Objective
- Fix the silhouette problem first: current slots are short/wide and read like toolbar buttons.

Files
- Modify:
  - `scenes/combat/combat_slice.tscn`

Target sizing
- Hand slots: target `152 x 216` (acceptable range `148-156 x 208-224`)
- Reward slots: target `200 x 280` (acceptable range `192-208 x 264-292`)

Implementation steps
1. Update hand slot sizing so each `CardN` stops behaving like a wide fill-row button.
2. Keep the hand in a straight row for this pass.
3. Keep even spacing between cards; no overlap, no fan.
4. Update reward slot sizing so reward choices feel like larger cards, not taller buttons.
5. Keep reward choices centered in the overlay.

Important constraints
- Keep `Card1..Card5` and `Reward1..Reward3` paths unchanged.
- If the current `HBoxContainer` setup fights fixed card widths, prefer explicit width floors and layout tuning rather than container replacement in the first pass.

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- Slot nodes are still found by existing probes.
- No input-path regression.

---

## Task 3: Add real card-face anatomy under the existing slot roots

Objective
- Replace the current “art thumb + role icon + text blob” composition with a structured card face.

Files
- Modify:
  - `scenes/combat/combat_slice.tscn`

Required new card-face regions
- `HotkeyBadge`
- `CostBadge`
- `ArtFrame`
- `ArtThumb` (preserve name and direct discoverability)
- `RoleIcon` (preserve name and direct discoverability)
- `NameLabel`
- `PayoffRow`
- `RulesLabel`
- `FooterLabel`

Recommended root-child layout strategy
- Keep `ArtThumb` and `RoleIcon` as direct children of the slot root so current probes keep passing.
- Add additional direct children or nested layout containers for new labels/chrome.
- Do not nest `ArtThumb` or `RoleIcon` under a renamed wrapper in this pass unless probes are updated in the same task.

Suggested first-pass node pattern
- `CardN (Button)`
  - `Chrome`
  - `HotkeyBadge`
  - `CostBadge`
  - `ArtFrame`
  - `ArtThumb`
  - `RoleIcon`
  - `ContentVBox`
    - `NameLabel`
    - `PayoffRow`
    - `RulesLabel`
    - `FooterLabel`

Implementation notes
- The visual face must now match the spec order:
  1. cost
  2. name
  3. payoff
  4. footer state
  5. supporting rules
- The root button may still store compatibility text, but visible card-face labels must become the player-facing read.

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- `ArtThumb` and `RoleIcon` are still found.
- No slot-path regressions.

---

## Task 4: Replace generic button chrome with Charter Warrant chrome

Objective
- Make the slots feel like physical tactical cards instead of flat UI controls.

Files
- Modify:
  - `src/ui/combat_hud/combat_hud_controller.gd`

Implementation steps
1. Replace or heavily revise `_apply_card_button_style()` so the root slot no longer reads like a generic button.
2. Add helper styling for:
   - parchment card body
   - dark title rail
   - framed art window
   - cost medallion
   - payoff chips
   - footer strip
3. Use role color only as accents:
   - crest
   - chips
   - trim
   - footer rail
4. Preserve a valid root `normal` stylebox for the `run_card_style_toggle_probe.gd` compatibility check.
5. Keep `card_style_variant` / `V` toggle alive in the first pass, but reinterpret it as two safe Charter Warrant accent variants if needed.

Important compatibility note
- `run_card_style_toggle_probe.gd` reads `button.get_theme_stylebox("normal")` and inspects its `bg_color`.
- Even if the player-facing chrome mostly lives in child nodes, keep a stable root stylebox so the probe still has meaningful output in the first pass.

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- card-style toggle smoke still passes
- HUD contrast smoke remains green through the Python wrapper

---

## Task 5: Populate structured face labels while preserving Button.text compatibility

Objective
- Move the visible card read to structured labels without breaking existing tests that inspect `Button.text`.

Files
- Modify:
  - `src/ui/combat_hud/combat_hud_controller.gd`
- Optional small helper additions in:
  - `src/core/card/card_presenter.gd`

Implementation steps
1. Continue assigning `Button.text` for compatibility/debug only.
2. Populate visible child labels instead:
   - `NameLabel`
   - `RulesLabel`
   - `FooterLabel`
   - `CostBadge`
   - payoff chip labels inside `PayoffRow`
3. If needed, extend `CardPresenter` with light helper methods for:
   - face title
   - short rules text
   - reward footer text
   - payoff chip summaries
4. Hide root-button text visually if necessary, but do not remove the underlying property.

Safe strategy for compatibility text
- Keep `Button.text` populated exactly as current probes expect.
- Make the root text visually non-primary using styling, layering, or label overlay rather than clearing the property.

Content rules
- Rules face text: max 2 short lines
- Footer: live gating / state truth
- Payoff row: tactical promise at a glance

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- GSM/text-based probes still pass
- visible card-face labels are populated in runtime

---

## Task 6: Make reward cards a larger ceremonial variant of the same family

Objective
- Ensure reward choices feel like drafting cards, not clicking modal options.

Files
- Modify:
  - `scenes/combat/combat_slice.tscn`
  - `src/ui/combat_hud/combat_hud_controller.gd`

Implementation steps
1. Apply the same face anatomy to reward cards.
2. Increase reward art prominence and spacing.
3. Use reward-specific footer states such as:
   - `Add to deck`
   - `Chosen`
   - `Claimed`
4. Improve hover/focus emphasis on reward cards.
5. Keep the existing reward interaction model:
   - `reward_card_id` metadata
   - reward selection by index
   - continue flow after applied state

Important constraints
- Preserve `Reward1..Reward3` node names.
- Preserve button roots and reward click paths.

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- reward art visibility still passes
- reward keyboard selection still passes

---

## Task 7: Add first-pass smoke assertions for the new card face

Objective
- Guard the redesign itself, not only the old compatibility points.

Files
- Modify:
  - `tests/smoke/run_gameplay_art_visibility_probe.gd`
  - `tests/smoke/test_playable_prototype.py`
- Optional create:
  - `tests/smoke/run_card_face_layout_probe.gd`

Recommended new assertions
- hand card exposes visible title-label text
- hand card exposes visible footer-label text
- hand card exposes visible cost-badge text
- reward card exposes visible title-label text
- reward card exposes visible footer-label text
- current compatibility checks still pass for:
  - `ArtThumb`
  - `RoleIcon`
  - root button existence
  - hotkey path

Important rule
- Add new assertions alongside old ones in the same pass.
- Do not drop old compatibility probes until the redesign has settled.

Verification
Run:
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`
Expected:
- old and new UI assertions are green together

---

## Task 8: Run full regression and perform one human visual sanity pass

Objective
- Confirm the redesign is stable and actually feels like cards in the live slice.

Files
- No required code changes
- Optional follow-up note after validation

Automated verification
Run:
- `python3 -m unittest discover -s tests -p 'test_*.py' -v`
Expected:
- full suite green

Manual verification checklist
- launch the native combat slice
- confirm the hand reads as cards immediately
- confirm reward choices read as cards immediately
- confirm cost, name, payoff, and footer state scan quickly
- confirm disabled cards remain readable
- confirm hover/focus does not shift the whole hand row unpredictably
- confirm hotkeys still feel stable and obvious
- confirm the result is visually in-family with Dungeon Steward's steward / warrant tone

---

## Optional Stage 2: Extract a reusable CardView after the first pass lands

Objective
- Reduce duplication only after the visual redesign is proven stable.

Files
- Create:
  - `scenes/ui/card_view.tscn`
  - `src/ui/card_view.gd`
- Modify:
  - `scenes/combat/combat_slice.tscn`
  - `src/ui/combat_hud/combat_hud_controller.gd`

Rules for Stage 2
- `CardView` root may still extend `Button`
- Keep `ArtThumb` and `RoleIcon` as compatibility-visible children
- Keep instance names `Card1..Card5` and `Reward1..Reward3`
- Move per-card rendering logic out of `CombatHudController` only after Stage 1 is green

Why this is deferred
- Good cleanup, but not necessary to achieve the visual win
- Higher churn against smoke paths than the first-pass in-place rebuild

---

## Risks and mitigations

Risk: probe breakage from path/type changes
- Mitigation: preserve names, root types, and `ArtThumb` / `RoleIcon` in first pass

Risk: hotkey/input regressions
- Mitigation: keep `_unhandled_input` and existing slot-button press behavior untouched

Risk: layout jitter on hover/focus
- Mitigation: animate internal chrome, not the slot root

Risk: card face still feels like a button after restyle
- Mitigation: fix geometry first, then chrome, then hierarchy

Risk: hidden compatibility text causes visual clutter
- Mitigation: preserve `Button.text` property but move player-facing text to child labels

---

## Definition of done for the first pass

- Hand cards read visually as cards, not toolbar buttons
- Reward cards read visually as card choices, not modal buttons
- Cost / name / payoff / footer state scan quickly in live play
- Existing hotkeys and click paths still work
- Existing smoke coverage remains green
- New card-face smoke assertions are added and green
- Full local test suite remains green

---

## Recommended execution order

1. Task 1 — freeze compatibility assumptions
2. Task 2 — fix geometry
3. Task 3 — add card-face structure
4. Task 4 — apply Charter Warrant chrome
5. Task 5 — move visible text to structured labels
6. Task 6 — update reward-card variant
7. Task 7 — extend smoke coverage
8. Task 8 — full regression + human sanity pass

If the first pass is successful, Stage 2 extraction becomes safe and worthwhile.
