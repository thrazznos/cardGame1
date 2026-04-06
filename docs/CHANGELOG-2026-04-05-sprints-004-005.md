# Internal Changelog: Sprint 004 + Sprint 005 Closeout
Date: 2026-04-05
Scope: GSM pilot closeout + card data migration

## New Features
- Gem Stack Machine pilot is now surfaced directly in the live combat slice via the starter deck.
- Added explicit GSM peek helpers (`peek_top`, `peek_n`) to the runtime contract.
- Added repo-tracked card data assets for the current playable and reward card set.

## Improvements
- Runner, reward draft, and HUD card behavior/presentation now flow through a shared card catalog/presenter layer instead of large prefix switch tables.
- Reward-card variants (`strike_plus`, `strike_precise`, `defend_plus`, `defend_hold`) now render with distinct authored text.
- Determinism final-state hashing no longer depends on reward summary microcopy.
- Balance-sim value proxies now derive from card catalog effect data instead of hardcoded family guesses.
- Added a standalone card-catalog validation probe for headless regression coverage.
- Encounter transition toast now auto-dismisses rather than waiting for Enter.
- Internal runtime zone storage has started moving toward explicit card-instance dictionaries.

## Bug Fixes
- Fixed reward-card presentation collapsing multiple authored reward cards into generic Strike/Defend labels.
- Fixed GSM remaining too hidden in the live slice by surfacing the pilot deck directly to the player.

## Technical Debt / Refactoring
- Added `src/core/card/card_catalog.gd`
- Added `src/core/card/card_presenter.gd`
- Added `src/core/card/card_validator.gd`
- Moved starter deck data to `data/decks/starter_run_v1.json`
- Moved current card content to `data/cards/catalog_v1.json`
- Refreshed determinism fixtures after intentional contract/event representation changes

## Known Issues
- Runtime still mixes stable card identity with pseudo-instance strings like `strike_01`.
- Balance-sim heuristics still assume some card-family behavior rather than reading catalog metadata.

---

# Player-Facing Changelog Draft

## New Features
- The Gem Stack Machine combat pilot is now part of the live combat slice, so gem setup, FOCUS, and advanced consume cards are available immediately instead of being mostly hidden behind test-only paths.

## Improvements
- Card rewards now read more clearly and distinct reward cards show their own names and effects instead of collapsing into generic labels.
- Combat card presentation is now driven by a shared data source, which makes the prototype more consistent and easier to tune.

## Fixes
- Fixed reward choices that could previously look too similar even when they were meant to be different cards.
- Fixed a determinism edge where reward summary text changes could perturb authoritative hashes.

## Known Issues
- Some internal card instance handling is still prototype-grade and will be cleaned up in a follow-up pass.
