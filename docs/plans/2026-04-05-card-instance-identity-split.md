# Card Instance Identity Split Implementation Plan

> For Hermes: Use subagent-driven-development skill to implement this plan task-by-task.

Goal: Separate stable card definition identity from runtime card instance identity without breaking the current deterministic combat slice, probes, or fixtures.

Architecture: Keep `CardCatalog` as the authoritative definition layer and introduce an explicit runtime card-instance representation that carries both `instance_id` and canonical `card_id`. Migrate DeckLifecycle and CombatSliceRunner first, then adapt fixture/probe compatibility shims so existing test authoring can evolve gradually instead of exploding all at once, which would be vulgar.

Tech Stack: Godot 4.6 GDScript, existing JSON card assets, unittest smoke/determinism suite.

---

## Scope and non-goals

In scope:
- explicit runtime representation for card instances
- DeckLifecycle storage of instances rather than raw strings
- runner/view-model compatibility shims
- deterministic fixture compatibility for existing authored inputs

Out of scope for this slice:
- replacing every test fixture with canonical `card_id` + `instance_id` payloads immediately
- inventory/deckbuilder/meta-layer identity migration
- localization / UI overhaul

---

## Canonical file map

Create:
- `src/core/card/card_instance.gd`
- `tests/smoke/run_card_instance_probe.gd`

Modify:
- `src/core/dls/deck_lifecycle.gd`
- `src/bootstrap/combat_slice_runner.gd`
- `tests/smoke/test_playable_prototype.py`
- affected smoke probes under `tests/smoke/`
- affected determinism fixtures under `tests/determinism/fixtures/`

---

## Data contract

Runtime card instance shape:
```json
{
  "instance_id": "strike_01",
  "card_id": "strike"
}
```

Compatibility rules:
- authored fixture/test inputs may still provide a string; loader converts via `CardCatalog.resolved_card_id(...)`
- view-model may continue exposing instance IDs in `hand` for hotkey/probe stability during transition
- authoritative internal zone state should store explicit dictionaries

---

## Tasks

### Task 1: Add card-instance helper
Objective: create one place that knows how to convert between strings and runtime instances.

Files:
- Create: `src/core/card/card_instance.gd`
- Test: `tests/smoke/run_card_instance_probe.gd`
- Modify: `tests/smoke/test_playable_prototype.py`

Steps:
1. Write failing smoke test expecting string input like `strike_01` to normalize into `{instance_id: strike_01, card_id: strike}`.
2. Run targeted test and verify fail.
3. Implement helper functions:
   - `from_value(value, card_catalog)`
   - `instance_id_of(value)`
   - `card_id_of(value, card_catalog)`
   - `to_debug_string(value)`
4. Re-run targeted test to green.

Suggested commit:
`feat(cards): add runtime card instance helper`

### Task 2: Migrate DeckLifecycle internals
Objective: store explicit card instances in zones instead of raw strings.

Files:
- Modify: `src/core/dls/deck_lifecycle.gd`
- Test: targeted smoke/determinism coverage

Steps:
1. Write failing regression for draw/commit/finalize behavior using instance dictionaries.
2. Migrate zone mutation methods to normalize incoming values and compare by `instance_id`.
3. Preserve reshuffle semantics.
4. Re-run targeted tests.

Suggested commit:
`refactor(dls): store explicit card instances in runtime zones`

### Task 3: Migrate CombatSliceRunner compatibility boundary
Objective: keep the prototype working while the runtime uses explicit instances internally.

Files:
- Modify: `src/bootstrap/combat_slice_runner.gd`

Steps:
1. Update `_bootstrap_demo_state()` and fixture/setup helpers to create proper instances.
2. Update `get_view_model()` so hand/reward probes continue to receive stable strings or explicitly documented shapes.
3. Update play/resolve/event paths to use `instance_id` for exact play requests and canonical `card_id` for content lookup.
4. Re-run smoke suite.

Suggested commit:
`refactor(combat): separate card instance identity from card definitions`

### Task 4: Fixture and probe migration
Objective: make tests explicit where they currently rely on stringly coincidence.

Files:
- Modify: affected `tests/smoke/*.gd`
- Modify: affected `tests/determinism/fixtures/*.json`

Steps:
1. Update probes that directly poke `dls.hand`/zones.
2. Keep old fixture authoring accepted via compatibility shims where reasonable.
3. Refresh deterministic baselines intentionally.
4. Re-run full suite.

Suggested commit:
`test(cards): migrate probes and fixtures for card instance identity`

---

## Validation commands

- `python3 -m unittest tests.smoke.test_playable_prototype -v`
- `python3 -m unittest tests.determinism.test_fixture_compare -v`
- `python3 -m unittest discover -s tests -p 'test_*.py' -v`

---

## Success criteria

1. DeckLifecycle zones store explicit runtime card instances.
2. Combat runner uses canonical `card_id` for content lookup and `instance_id` for exact play resolution.
3. No silent prefix fallback remains in play/resolve paths.
4. Full smoke + determinism suite remains green.
5. Prototype behavior is unchanged except for stricter, cleaner identity semantics.
