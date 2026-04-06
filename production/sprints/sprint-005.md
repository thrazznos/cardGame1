# Sprint 005 -- 2026-05-18 to 2026-05-29

## Sprint Goal
Move card definitions, starter deck content, reward-pool content, and card-facing presentation strings out of hardcoded runner/HUD logic into authoritative data assets, while preserving deterministic combat behavior in the native prototype.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S5.M1 | Author MVP card catalog and starter deck data assets | gameplay-programmer + systems-designer | 1.5 | Card Data & Definitions GDD | A repo-tracked card catalog defines current playable/reward cards, including effect payloads, reward metadata, role/presentation fields, and the live starter deck composition |
| S5.M2 | Add runtime card catalog loader/validator | gameplay-programmer + tools-programmer | 1.0 | S5.M1 | Runtime can load/validate card definitions from data assets; duplicate IDs and missing fields fail fast in dev/test |
| S5.M3 | Refactor combat runner to use data-driven card definitions | gameplay-programmer | 2.0 | S5.M1, S5.M2 | `combat_slice_runner.gd` no longer hardcodes starter deck composition, card display names, or per-card effect payload switches |
| S5.M4 | Refactor reward draft to consume catalog-defined reward data | gameplay-programmer | 1.0 | S5.M1, S5.M2 | Reward candidate pools/weights come from card data rather than inline arrays and prefix conventions |
| S5.M5 | Refactor HUD card presentation to use shared presenter + data | ui-programmer | 1.5 | S5.M1, S5.M2 | HUD/reward button text, tooltips, role markers, and palette decisions are data-driven instead of large prefix switch tables |
| S5.M6 | Validation, fixture, and smoke migration for data-driven cards | qa-tester + tools-programmer | 1.0 | S5.M3, S5.M4, S5.M5 | Full local suite is green; determinism baselines updated only where authoritative state/contracts changed; reward-card variants render distinctly |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S5.S1 | Separate stable `card_id` from runtime instance identity | gameplay-programmer | 0.75 | S5.M3 | Runtime no longer depends on prefix hacks like `strike_01` -> `strike`; instance identity and card definition identity are explicit |
| S5.S2 | Move deterministic reports off presentation copy | tools-programmer | 0.5 | S5.M3, S5.M5 | Determinism hashing/reporting no longer changes because card-facing English text changed |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S5.N1 | Add headless card catalog validation probe | tools-programmer | 0.25 | S5.M2 | A single smoke probe can assert card catalog integrity without launching the full fixture path |
| S5.N2 | Make balance-sim proxies pull from catalog metadata | gameplay-programmer + tools-programmer | 0.5 | S5.M2 | Simulation heuristics stop hardcoding card-family assumptions in test scripts |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Card/resource-file cleanup for runner/HUD/reward logic | Sprint 004 deliberately stopped at a playable GSM pilot and left card content stringly-typed | 6.0 days across S5.M1-S5.M5 |
| Determinism decoupling from presentation copy | Too large to bundle into Sprint 004 closeout without mixing system migration with pilot delivery | 0.5 day (S5.S2) |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Data migration silently changes gameplay behavior | Medium | High | Keep effect payloads byte-explicit in data; rerun determinism + smoke after each migration slice |
| Reward candidate ordering changes due to data-load iteration order | Medium | High | Preserve stable catalog ordering and explicitly sort candidates by `card_id` before weighted selection |
| HUD refactor breaks card readability or collapses reward-card distinctions | Medium | Medium | Add explicit smoke coverage for card/rule text and reward-card variant rendering |
| Scope creep into full localization/framework work | High | Medium | Keep sprint limited to authoritative data assets for the current English prototype, not a full localization system |
| Godot resource/import churn slows iteration | Medium | Medium | Prefer plain repo-tracked JSON data assets for MVP card content rather than custom `.tres` authoring |

## Dependencies on External Factors
- JSON data assets were accepted as the MVP interpretation of “resource files” for this sprint and are now implemented under `data/`.
- Focused local validation after runner/HUD migration confirmed the slice still behaves like the same game rather than a museum of prefix hacks.

## Definition of Done for this Sprint
- [x] All Must Have tasks completed
- [x] Card definitions/presentation no longer depend on hardcoded prefix switch tables in runner/HUD/reward code
- [x] Live starter deck composition is sourced from data assets
- [x] Reward pool content and weighting metadata are sourced from data assets
- [x] Full local test suite is green after migration
- [x] Any determinism baseline changes are documented and intentional
- [x] Design/docs updated for contract deviations discovered during migration
