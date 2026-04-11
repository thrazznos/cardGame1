# Deck Inspection MVP Plan

> For Hermes: implement this as a shared read-only inspection system used by combat and map contexts. Do not commit unless the user explicitly instructs you to do so.

Goal
- Add a reusable deck inspection overlay so players can inspect:
  - the current combat deck by zone,
  - the current discard pile as a focused combat view,
  - the current run deck from the map.

Architecture
- Build one shared inspection pipeline instead of three separate UIs.
- Use a shared snapshot builder to normalize authoritative runtime deck data into a UI-safe inspection model.
- Use one reusable overlay/controller for combat full deck, combat discard-focused mode, and map run-deck mode.
- Keep the entire system read-only in MVP.
- Preserve the authority boundary: DLS/runtime owns deck state; UI only renders inspection snapshots.

Tech stack
- Godot 4.6.2
- GDScript
- Existing combat runtime:
  - `src/bootstrap/combat_slice_runner.gd`
  - `src/core/dls/deck_lifecycle.gd`
  - `src/ui/combat_hud/combat_hud_controller.gd`
  - `scenes/combat/combat_slice.tscn`
- Existing map runtime/UI:
  - `src/ui/map_hud/map_hud_controller.gd`
- Existing card presentation/runtime data:
  - `src/core/card/card_catalog.gd`
  - `src/core/card/card_presenter.gd`
- Design reference:
  - `design/gdd/systems/deck-inspection-ui.md`

Non-goals
- Deck editing/removal/transforms
- Full deckbuilder UI
- Hub collection browser
- Search in MVP
- Advanced filters in MVP
- Manual sort controls in MVP
- Relic/passive synergy explanation in MVP
- Any hidden-information expansion such as revealing future draw order

MVP decisions locked by this plan
1. One reusable overlay for all inspection contexts
2. Read-only only
3. Compact inspection cards, not combat-hand-sized cards
4. Combat access uses both a button and hotkey
5. Discard view is a filtered mode of the main overlay, not a bespoke popup
6. Map view shows the current run deck, not combat zones
7. Draw pile must not imply future draw order unless explicitly intended later

---

## Task 1: Define the shared inspection snapshot contract

Objective
- Create a single normalized snapshot shape that can power all deck inspection entry points.

Files
- Create:
  - `src/ui/deck_inspection/deck_inspection_snapshot_builder.gd`

Implementation details
- Add a snapshot builder class responsible for returning deterministic UI-ready dictionaries.
- Support initial modes:
  - `combat_full`
  - `combat_discard`
  - `map_run_deck`
- Define shared snapshot fields:
  - `context`
  - `title`
  - `read_only`
  - `total_count`
  - `active_filter`
  - `sections`
  - `cards`
- Define normalized card fields:
  - `card_id`
  - `card_instance_id`
  - `display_name`
  - `cost`
  - `role_label`
  - `rules_text`
  - `zone`
  - `zone_label`
  - `art_path` or equivalent presentation payload
  - `sort_key`
  - minimal flags dictionary for future extension
- Keep tie-breakers deterministic.

Ordering rules
- Combat:
  - group by visible zone
  - tie-break by stable card identity
  - do not communicate future draw order
- Map:
  - stable default ordering such as cost then name, or authored identity fallback

Verification
- Builder can return a valid dictionary for each target mode without referencing scene nodes.
- Snapshot shape is identical regardless of caller.

Acceptance criteria
- A single builder exists for all three viewer modes.
- Snapshot output is deterministic and UI-ready.
- No scene-specific coupling is embedded in the builder.

---

## Task 2: Build the reusable inspection overlay scene and controller

Objective
- Create one shared UI overlay that can render any inspection snapshot.

Files
- Create:
  - `scenes/ui/deck_inspection_overlay.tscn`
  - `src/ui/deck_inspection/deck_inspection_controller.gd`

Implementation details
- Build a modal overlay with:
  - dimmer/background
  - header row
  - optional filter/tab row
  - scrollable card grid
  - small card detail preview
  - close button
- Required controller API:
  - `open_with_snapshot(snapshot: Dictionary) -> void`
  - `close_overlay() -> void`
  - `set_active_filter(filter_id: String) -> void`
  - render/update helpers for sections and cards
- Keep controls minimal in MVP:
  - open
  - close
  - change active filter/tab
  - hover/select card
- Keep everything read-only.
- Use compact inspection cards, not large combat-hand cards.

Recommended first-pass overlay regions
- `OverlayRoot`
  - `Dimmer`
  - `Panel`
    - `HeaderRow`
      - `Title`
      - `ContextBadge`
      - `CountLabel`
      - `CloseButton`
    - `FilterRow`
    - `BodyRow`
      - `CardScroll`
      - `DetailPanel`
    - `FooterRow`

Verification
- Overlay can render a synthetic snapshot without combat/map runtime.
- Filter switching updates visible cards correctly.
- Close button and close behavior work reliably.

Acceptance criteria
- One reusable overlay/controller exists.
- Overlay renders snapshot title, counts, filters, cards, and small detail preview.
- No gameplay mutations are possible through this UI.

---

## Task 3: Integrate combat full deck inspection

Objective
- Let players inspect the current combat deck by zone from combat.

Files
- Modify:
  - `src/bootstrap/combat_slice_runner.gd`
  - `src/ui/combat_hud/combat_hud_controller.gd`
  - `scenes/combat/combat_slice.tscn`

Implementation details
- In `combat_slice_runner.gd`, add a method like:
  - `get_deck_inspection_snapshot(mode: String = "combat_full") -> Dictionary`
- That method should:
  - call `dls.normalize_zones()`
  - collect runtime card data from:
    - `draw_pile`
    - `hand`
    - `discard_pile`
    - `exhaust_pile`
  - optionally omit `limbo` in normal user-facing mode
  - feed authoritative card data into the shared snapshot builder
- In `combat_hud_controller.gd`:
  - instantiate or fetch the inspection overlay
  - request a snapshot from the runner
  - open the overlay on demand
  - support close behavior and focus/input restoration
- In `combat_slice.tscn`:
  - add a small `Deck` button in the combat HUD controls
- Add a hotkey, recommended:
  - `D`

Important constraints
- Opening the viewer must not mutate DLS state.
- Viewer remains inspect-only during resolve lock.
- Draw pile display must not imply top-deck order.

Combat filters/tabs for MVP
- `All`
- `Draw`
- `Hand`
- `Discard`
- `Exhaust`

Verification
- Open viewer from button.
- Open viewer from hotkey.
- Close viewer and resume combat cleanly.
- Verify zone counts match DLS state.
- Verify every combat card appears once.

Acceptance criteria
- Combat deck inspection opens and closes reliably.
- Zone grouping is correct.
- No combat state changes happen on open/close.
- Viewer works during normal input-ready and resolve-lock states.

---

## Task 4: Add combat discard-focused mode using the shared viewer

Objective
- Make discard inspection fast without creating a second bespoke UI system.

Files
- Modify:
  - `src/bootstrap/combat_slice_runner.gd`
  - `src/ui/combat_hud/combat_hud_controller.gd`

Implementation details
- Add support for `combat_discard` snapshot mode.
- Reuse the same overlay and same card rendering.
- Start the overlay with:
  - discard filter active, or
  - discard-only cards visible
- Do not build a separate discard popup in MVP.
- Keep this mode accessible from the same deck inspection entry path first.
- Optional later extension:
  - dedicated discard shortcut/button after MVP proves useful

Verification
- Open discard-focused inspection.
- Confirm only discard cards are visible when discard mode is active.
- Confirm discard count matches DLS state.
- Confirm returning to the broader deck view is possible if using tabs.

Acceptance criteria
- Discard mode reuses the same shared overlay.
- No duplicate rendering/controller logic exists for discard view.
- Discard contents are correct and easy to inspect.

---

## Task 5: Integrate map-accessible run deck inspection

Objective
- Let players inspect their current run deck from the map screen.

Files
- Modify:
  - `src/ui/map_hud/map_hud_controller.gd`
- Possibly modify:
  - map/bootstrap runtime file that owns current run deck state
- Reuse:
  - `src/ui/deck_inspection/deck_inspection_snapshot_builder.gd`
  - `scenes/ui/deck_inspection_overlay.tscn`
  - `src/ui/deck_inspection/deck_inspection_controller.gd`

Implementation details
- Add a map entry point for deck inspection.
- Preferred first-pass access:
  - visible `Deck` button if practical in current map setup
- Acceptable fallback:
  - keyboard shortcut plus visible hint text
- Build/obtain a `map_run_deck` snapshot from authoritative run deck state.
- Map mode should:
  - show current run deck only
  - avoid combat-zone presentation
  - use the same compact inspection cards
  - show context header such as `Run Deck`

Important constraints
- Do not overextend into full deckbuilder scope.
- Keep map mode strategic and calm, not debug-heavy.

Verification
- Open the deck inspection from the map.
- Confirm card count matches current run deck state.
- Close and resume map interaction cleanly.
- Confirm no combat-only zone labels appear in map mode.

Acceptance criteria
- Map deck inspection uses the same shared overlay.
- Current run deck is visible and accurate.
- Open/close flow works without breaking map interaction.

---

## Task 6: Add smoke coverage for inspection safety and correctness

Objective
- Protect the new viewer from regressions in runtime correctness and input safety.

Files
- Create/Modify:
  - `tests/smoke/` probes for combat deck inspection
  - `tests/smoke/` probes for map deck inspection
  - `tests/smoke/test_playable_prototype.py` if central harness updates are needed

Recommended smoke coverage
- Combat deck viewer open does not mutate:
  - hand
  - draw
  - discard
  - exhaust
- Combat viewer zone counts match runtime values
- Discard mode only shows discard cards
- Map deck view count matches run deck count
- Open/close input flow returns cleanly after inspection
- Viewer remains read-only under resolve lock

Verification command
- `python3 -m unittest discover -s tests/smoke -p 'test_playable_prototype.py' -v`

Acceptance criteria
- New inspection-related smoke checks pass.
- Existing combat/map smoke coverage remains green.

---

## File touch summary

Create
- `src/ui/deck_inspection/deck_inspection_snapshot_builder.gd`
- `src/ui/deck_inspection/deck_inspection_controller.gd`
- `scenes/ui/deck_inspection_overlay.tscn`

Modify
- `src/bootstrap/combat_slice_runner.gd`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `scenes/combat/combat_slice.tscn`
- `src/ui/map_hud/map_hud_controller.gd`
- relevant map/runtime bootstrap file if needed to expose current run deck
- smoke tests under `tests/smoke/`

---

## MVP acceptance summary

The feature is complete when:
1. Combat has a read-only deck viewer accessible by button and hotkey
2. Combat discard inspection works through the same overlay
3. Map can open the same overlay in run-deck mode
4. All cards shown come from authoritative data
5. Draw pile display does not leak unintended future order
6. Open/close actions do not mutate gameplay state
7. Smoke coverage protects the core flows

---

## Post-MVP backlog

Defer until after MVP:
- search
- sort controls
- advanced filters
- richer detail pane
- relic/passive interaction lens
- planning pins
- deckbuilder mutations
- hub collection/codex expansion
