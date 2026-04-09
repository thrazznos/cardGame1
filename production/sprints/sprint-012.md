# Sprint 012 -- 2026-08-24 to 2026-09-04

## Sprint Goal
Finish the combat runtime contract so authored card metadata, reward context, and runtime card identity drive legality and progression without more stringly special-casing in live code.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S12.M1 | Play-condition runtime dispatcher | gameplay-programmer | 1.5 | Existing CardCatalog + CombatSliceRunner legality flow | Combat runtime consumes authored `play_conditions` through a dispatcher/helper instead of a single inline special case. Existing `focus_at_least` behavior is preserved. At least one additional authored condition type is supported end-to-end with readable reject reasons. |
| S12.M2 | Target legality and invalid-target policy pass | gameplay-programmer + ui-programmer | 1.5 | S12.M1, existing card schema fields | Live play honors authored `target_mode`, `max_targets`, and `invalid_target_policy`. Invalid targets reject or fizzle according to data. HUD/view-model surfaces remain readable and deterministic. |
| S12.M3 | Runtime card-instance contract completion | gameplay-programmer | 2.0 | Existing CardInstance helper, DeckLifecycle, CombatSliceRunner | Authoritative runtime zones store explicit `{instance_id, card_id}` dictionaries. Exact play resolution uses `instance_id`, content lookup uses canonical `card_id`, and no silent prefix fallback remains in play/resolve paths. Existing fixtures and probes remain compatible through narrow shims. |
| S12.M4 | Validation and determinism true-up | qa-tester | 1.0 | S12.M1-S12.M3 | New targeted smoke probes cover expanded play conditions, target legality, and identity boundary behavior. Determinism expectations are refreshed only where behavior changes intentionally. `python3 -m unittest discover -s tests -p 'test_*.py' -v` and headless Godot startup both pass. |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S12.S1 | Live reward-context contract hardening | gameplay-programmer | 1.0 | Existing RewardDraft metadata path, current live reward probes | Current live reward routing rules are explicitly covered by code/tests. First live checkpoint remains `base_reward`, GSM-heavy decks switch to `gsm_reward` only on second+ live checkpoints, and base-only decks stay on base rewards. |
| S12.S2 | Authored proof cards for fuller runtime contract | game-designer + gameplay-programmer | 1.0 | S12.M1, S12.M2 | Add 1-2 cards that exercise the expanded play-condition/targeting path without broad balance churn. They play correctly in live combat, appear in the appropriate reward pools, and have probe coverage. |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S12.N1 | Effect schema proof migration | gameplay-programmer | 0.5 | S12.S2 | Convert one small card slice from legacy inline effect payloads to `effect_id` + `params` while preserving runtime behavior and determinism. |
| S12.N2 | Reject/event text polish for legality paths | ui-programmer | 0.5 | S12.M2 | Reject and event surfaces explain new legality failures without leaking raw schema jargon or debug-shaped wording. |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Expanded card schema is validated but not fully consumed at runtime | Sprint 011 delivered status effects and floor objectives, but card metadata follow-through remains partial in live combat | 3.0 days across S12.M1-S12.M2 |
| Full runtime instance-vs-definition split remains incomplete | Current branch is cleaner, but authored alias strings still leak through parts of live setup and fixture compatibility | 2.0 days in S12.M3 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| New legality rules break existing smoke and determinism fixtures unexpectedly | Medium | High | Add narrow probes before broad refactors. Keep compatibility shims at the fixture boundary until runtime internals are stable. |
| Instance cleanup leaks into UI/view-model contracts and churns too many tests at once | Medium | Medium | Keep internal zones canonical first, preserve outward-facing hand/reward shapes where possible, then tighten probes intentionally. |
| Reward-context tweaks perturb determinism or build-shaping unexpectedly | Medium | Medium | Treat current live reward routing as the baseline contract. Probe it before changing thresholds or reward-pool selection behavior. |
| Authored schema outpaces live content and creates a false sense of completion | Medium | Medium | Require 1-2 proof cards that exercise the fuller path instead of calling the sprint done on validator-only support. |

## Dependencies on External Factors
- `data/cards/catalog_v1.json` remains the authoritative contract for card metadata.
- Combat runner and HUD reject-reason surfaces must stay stable enough for smoke probes to assert on them.
- RewardDraft must remain deterministic and stream-isolated from combat RNG while reward-context hardening lands.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed
- [x] Authored play conditions beyond the current focus-only path are enforced in live runtime
- [x] Target legality is driven by card metadata rather than ad hoc runner assumptions
- [x] Runtime zones use explicit card instances internally
- [x] Full unittest suite and headless Godot startup pass
- [x] Any intentional determinism baseline changes are documented and scoped
- [x] New proof cards validate the expanded runtime contract without destabilizing combat feel
