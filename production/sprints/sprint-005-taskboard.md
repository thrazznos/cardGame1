# Sprint 005 Taskboard - Execution

Status: Complete
Sprint: production/sprints/sprint-005.md
Updated: 2026-04-05
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - Card Data Assets (S5.M1-S5.M2)
- [x] E1.T1 Create repo-tracked card catalog asset for current playable and reward cards
- [x] E1.T2 Create repo-tracked starter deck asset for the live combat slice
- [x] E1.T3 Implement runtime card catalog loader and validation helpers
- [x] E1.T4 Add a light validation path for duplicate IDs / missing fields

## Epic E2 - Runner Migration (S5.M3)
- [x] E2.T1 Replace hardcoded starter deck constant with deck data asset loading
- [x] E2.T2 Replace `_card_to_effect` switch logic with catalog effect lookup
- [x] E2.T3 Replace runner-side card-name switches with catalog/presenter lookups
- [x] E2.T4 Keep fixture flows stable while live starter content becomes data-driven

## Epic E3 - Reward Migration (S5.M4)
- [x] E3.T1 Replace inline reward card pools with catalog-defined pool metadata
- [x] E3.T2 Preserve deterministic offer ordering after data migration
- [x] E3.T3 Ensure reward-card variants render with distinct authored identities

## Epic E4 - HUD Presentation Migration (S5.M5)
- [x] E4.T1 Add shared card presenter helper sourced from card data
- [x] E4.T2 Replace HUD hand-card text/tooltip switch tables with presenter output
- [x] E4.T3 Replace reward-card text/tooltip switch tables with presenter output
- [x] E4.T4 Replace role/palette mapping hacks with data-driven fields

## Epic E5 - Validation and Cleanup (S5.M6)
- [x] E5.T1 Add a regression check proving reward-card variants no longer collapse to generic Strike/Defend text
- [x] E5.T2 Run and update smoke/determinism validation as needed
- [x] E5.T3 Capture follow-up notes on remaining instance-ID and determinism-copy debt

## Optional Stretch (Should/Nice)
- [~] O1 Split stable `card_id` from runtime instance identity end-to-end (S5.S1) — partial slice landed via `CardInstance` helper and dictionary-backed DeckLifecycle zones
- [x] O2 Remove presentation copy from authoritative determinism hashes (S5.S2)
- [x] O3 Add standalone card catalog validation probe (S5.N1)
- [x] O4 Make balance-sim proxies data-driven (S5.N2)

## Outcome Notes
- Card definitions, reward-pool metadata, and live starter deck composition now live in repo-tracked JSON data assets under `data/`.
- Runner and HUD card behavior/presentation now flow through `CardCatalog` and `CardPresenter` instead of large prefix-based switch tables.
- Reward-card variants (`strike_plus`, `strike_precise`, `defend_plus`, `defend_hold`) now render as distinct authored cards rather than collapsing into generic Strike/Defend labels.
- Determinism baselines were updated intentionally after the data migration changed event payload representation; `reward_summary_text` was then removed from authoritative final-state hashing so microcopy no longer perturbs the hash.
- Added a standalone card catalog validation probe and moved balance-sim value proxies onto card catalog effect data.
- Encounter transition toast now auto-dismisses instead of waiting for Enter.
- Remaining debt is now narrower and explicit rather than smeared across helper functions: runtime instance IDs still masquerade as card IDs in several paths, but exact play requests no longer silently degrade to prefix matches and DeckLifecycle can now carry explicit `{instance_id, card_id}` pairs internally.
