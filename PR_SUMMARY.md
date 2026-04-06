# PR Summary Draft

## Title
Close Sprint 004 GSM pilot, migrate card content to data assets, and remove hardcoded card switch tables

## Summary
This changeset does three related things:
1. closes Sprint 004 by making the GSM pilot explicitly playable in the live combat slice,
2. migrates current card content/presentation into authoritative repo-tracked data assets,
3. removes the largest remaining card-related hardcoded logic from the runner, reward draft, and HUD.

## What changed

### Sprint 004 closeout
- Added explicit GSM `peek_top()` / `peek_n()` helpers.
- Surfaced an 8-card GSM pilot subset in the live starter deck.
- Added live GSM pilot smoke coverage.
- Updated Sprint 004 docs/taskboard/playtest evidence.

### Card data migration
- Added card data assets:
  - `data/cards/catalog_v1.json`
  - `data/decks/starter_run_v1.json`
- Added runtime card helpers:
  - `src/core/card/card_catalog.gd`
  - `src/core/card/card_presenter.gd`
  - `src/core/card/card_validator.gd`
- Refactored:
  - `src/bootstrap/combat_slice_runner.gd`
  - `src/core/reward/reward_draft.gd`
  - `src/ui/combat_hud/combat_hud_controller.gd`

### Regression protection
- Reward-card variants now render distinct identities instead of collapsing into generic Strike/Defend labels.
- Determinism fixtures were refreshed intentionally after the migration.
- `reward_summary_text` was removed from authoritative final-state hashing so reward microcopy no longer perturbs determinism hashes.
- Exact play requests no longer silently degrade to prefix matches, which makes card intent semantics stricter and a little less haunted.
- Added a standalone card-catalog validation probe and made balance-sim value proxies pull from catalog effect data.
- Encounter transition toast now auto-dismisses instead of waiting for Enter.
- Added the first runtime card-instance helper/integration slice so internal zones can begin carrying `{instance_id, card_id}` pairs while the view-model still exposes stable strings.

## Why
The repo had reached the usual point where card behavior and presentation were smeared across prefix checks, duplicated switch tables, and reward-pool literals. Charming in a prehistoric sense, but not especially maintainable. This PR moves the current prototype onto a cleaner path without expanding into a full localization or authoring framework.

## Validation
- `python3 -m unittest discover -s tests -p 'test_*.py' -v`
- Result: 28 tests passed

## Follow-up work
- Split stable `card_id` from runtime instance identity (`strike_01`-style strings still exist in runtime paths).
- Make balance-sim heuristics pull from catalog metadata.
- Consider whether future content authoring still wants JSON or eventually merits custom Godot Resources.
