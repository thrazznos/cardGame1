# Validation Note

## Session Info
- **Date**: 2026-04-05
- **Build**: Sprint 005 card-data migration working tree
- **Tester**: Hermes agent
- **Platform**: Local native desktop / headless validation
- **Session Type**: Regression + migration validation

## Migration Goal
Verify that moving card definitions, reward-pool content, starter deck composition, and card-facing presentation text into repo-tracked data assets did not break the combat slice.

## Evidence Captured
- Full suite green: `python3 -m unittest discover -s tests -p 'test_*.py' -v` (31 tests, all pass)
- New standalone card-catalog probe confirms catalog validity and alias resolution.
- New regression check confirms reward variants no longer collapse into generic text:
  - `strike_plus` vs `strike_precise`
  - `defend_plus` vs `defend_hold`
- Existing GSM pilot probe still confirms live starter visibility:
  - deck size 12
  - GSM cards in deck 8
  - opening hand still surfaces GSM cards immediately
- Determinism baselines updated intentionally after event-payload/presentation migration

## What Changed
- Card content now loads from:
  - `data/cards/catalog_v1.json`
  - `data/decks/starter_run_v1.json`
- Runtime loaders/presentation now flow through:
  - `src/core/card/card_catalog.gd`
  - `src/core/card/card_presenter.gd`
  - `src/core/card/card_validator.gd`
  - `src/core/card/card_instance.gd`
- Runner, reward draft, and HUD no longer rely on the previous large prefix switch tables for card content.
- Encounter transition toast now auto-dismisses instead of waiting for Enter.


## Remaining Debt
- Runtime still uses string card instance identifiers in several places (`strike_01`, etc.) instead of a clean `card_id` + instance UID split. A smaller cleanup did land: exact play requests no longer silently degrade to prefix matches, so intent semantics are stricter than before.
- Balance-sim now reads per-card value proxies from catalog effect data, but deeper reporting/heuristic layers are still only MVP-grade and may want richer explicit metadata later.

## Recommended Next Steps
1. Split stable card definition identity from runtime instance identity.
2. Make balance-sim heuristics and reporting pull from catalog metadata.
3. If the project wants richer authoring later, consider whether JSON remains sufficient or whether custom Godot Resources are worth the ceremony. For now, JSON is mercifully adequate.
