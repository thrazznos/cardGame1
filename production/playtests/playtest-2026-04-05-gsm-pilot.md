# Playtest Report

## Session Info
- **Date**: 2026-04-05
- **Build**: Sprint 004 closeout working tree
- **Duration**: Focused GSM pilot validation
- **Tester**: Hermes agent (local runtime + automated smoke probes)
- **Platform**: Local native desktop
- **Input Method**: Scripted + live starter-deck sanity pass
- **Session Type**: Focused validation

## Test Focus
Validate Sprint 004 closeout for:
1) explicit GSM contract completeness (`PeekTop` / `PeekN`),
2) live starter-deck surfacing of the GSM pilot,
3) continued deterministic coverage for produce/consume/focus-gate paths,
4) readability of stack + FOCUS surfaces in the current HUD.

## Evidence Captured
- Full tests green: `python3 -m unittest discover -s tests -p 'test_*.py' -v` (27 tests, all pass)
- GSM core probe now confirms non-mutating peek helpers:
  - `peek_top_before_consume = Sapphire`
  - `peek_two_before_consume = [Ruby, Sapphire]`
- Live starter pilot probe confirms GSM is immediately visible in the real slice:
  - deck size: 12
  - GSM cards in deck: 8
  - opening hand includes `gem_focus_a`, `gem_produce_ruby_a`, and `gem_offset_consume_ruby_ok`
- Existing GSM integration probe remains green:
  - no-FOCUS advanced consume rejects deterministically
  - FOCUS-enabled advanced consume resolves and updates stack/event log correctly
- Existing deterministic fixtures remain green, including `seed_gsm_001`

## What Worked Well
- GSM is no longer mostly sequestered in probes; the live starter deck now exposes the mechanic immediately.
- Peek helpers close the remaining obvious contract gap between the sprint plan and runtime implementation.
- HUD remains readable for stack-state inspection (`Gem Top`) and FOCUS tracking without debugger use.
- Keeping fixture starter decks separate from the live starter deck preserved determinism baselines while allowing the playable slice to evolve.

## Issues / Risks Observed
- The normal reward pool still keeps GSM cards opt-in. This is acceptable for Sprint 004 scope control, but it means later content migration should formalize when GSM cards enter reward drafting.
- Several non-hybrid GSM cards still rely on fairly thin prototype behavior and presentation copy; they are good enough for the pilot, but not yet clean data-driven content.
- Card definition/presentation logic is still too stringly-typed in runner/HUD code, which is the obvious next cleanup sprint.

## Recommended Next Steps
1. Start the card-data cleanup sprint: move card definitions, display names, rules text, starter deck composition, and reward pool content into authoritative data assets.
2. Remove duplicated card copy/mapping logic from `combat_slice_runner.gd` and `combat_hud_controller.gd` behind a shared card catalog/presenter layer.
3. Once card data is externalized, revisit deterministic hashing so gameplay state hashes do not depend on mutable presentation copy.
