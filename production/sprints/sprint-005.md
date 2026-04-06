# Sprint 005 -- Card Data Resource Extraction (2026-05-18 to 2026-05-29)

## Sprint Goal
Decouple card content from combat/UI logic by moving card definitions into resource files so gameplay, UI text, and art workflows can iterate without touching engine code.

## Capacity
- Total days: 10
- Buffer (20%): 2 days
- Available: 8 days

## Problem Statement
Card behavior and presentation are currently duplicated through hard-coded string checks and per-card if/else branches in multiple systems. This slows iteration, increases defects, and blocks parallel content/art pipeline work.

## Must Have

| ID | Task | Est | Acceptance |
|---|---|---:|---|
| S5.M1 | Create canonical card resource schema | 1.0d | Schema supports id, role, name, rarity, cost, effects[], ui text/tooltip, tags, art key |
| S5.M2 | Add card catalog loader/service | 1.0d | Single API returns card defs by id; deterministic startup load + validation |
| S5.M3 | Combat runner uses catalog for effects | 1.5d | `_card_to_effect` no longer hard-codes card-specific branches for catalog-backed cards |
| S5.M4 | HUD uses catalog for card text/tooltip/role | 1.5d | Hand + reward cards render from resource data (not per-card if chains) |
| S5.M5 | Reward pool references catalog ids/resources | 1.0d | Reward drafting uses catalog metadata and pool tags |
| S5.M6 | Validation + smoke coverage | 1.0d | Invalid schema/unknown card ids fail fast; all smoke + determinism tests green |
| S5.M7 | Content migration pass for current card set | 1.0d | Existing starter/base/GSM/hybrid cards represented in resources |

## Should Have

| ID | Task | Est | Acceptance |
|---|---:|---:|---|
| S5.S1 | Content lint script for duplicate IDs and invalid effect payloads | 0.5d | CI/local script reports actionable errors |
| S5.S2 | Authoring template for new card entries | 0.5d | New card creation flow documented for art/design agents |

## Nice to Have

| ID | Task | Est | Acceptance |
|---|---:|---:|---|
| S5.N1 | Split resources by set file (base/gsm/hybrid) | 0.5d | Modular files load into one merged catalog |
| S5.N2 | Lightweight hot-reload helper in dev mode | 0.5d | Refresh catalog without full restart in local debug |

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Schema too narrow for future mechanics | Medium | High | Use extensible effect payload arrays + metadata tags |
| Migration introduces behavior drift | Medium | High | Golden smoke probes for representative cards before/after |
| Determinism regressions from load/order changes | Medium | High | Stable sort + deterministic parse + fixture guardrails |
| Content errors increase after decoupling | Medium | Medium | Strict validator + fail-fast startup checks |

## Definition of Done
- Card-specific magic-string branches removed for migrated cards in runner/HUD
- Card catalog resource is single source of truth for behavior + display text
- Determinism baselines still pass
- Smoke tests pass
- New card can be added by editing resource data only (no GDScript code edits)
