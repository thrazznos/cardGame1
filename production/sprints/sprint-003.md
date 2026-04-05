# Sprint 003 -- 2026-04-20 to 2026-05-01

## Sprint Goal
Advance the combat vertical slice from “readable and rewarding” to “visually parseable and meaningfully varied” by improving card identity surfaces and differentiating the second encounter without expanding into map/meta scope.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S3.M1 | Card identity pass for hand + reward choices (icon/glyph treatment, stronger labels, clearer role cues) | ui-programmer + ux-designer | 2.0 | Existing HUD/reward flow | At-a-glance card role recognition is improved; hand and reward choices are distinguishable without full text parsing; readability remains high-contrast |
| S3.M2 | Encounter 2 differentiation (distinct intent feel/pattern + presentation cue) | gameplay-programmer + ui-programmer | 2.0 | Existing multi-encounter flow | Encounter 2 is observably different from Encounter 1 in behavior and/or presentation while preserving deterministic contracts |
| S3.M3 | Determinism + smoke validation updates for new identity/differentiation behavior | tools-programmer + qa-tester | 1.5 | S3.M1, S3.M2 | Existing deterministic suites remain green; new behavior has at least one explicit validation path |
| S3.M4 | Focused playtest + evidence artifact for readability and encounter differentiation | qa-tester | 1.0 | S3.M1, S3.M2 | One playtest artifact is archived with findings on card readability and encounter distinction |
| S3.M5 | Portrait/emblem cleanup integration path (non-blocking asset fallback + swap points) | ui-programmer | 1.0 | Current art-loading fallback | HUD remains robust when generated-art paths are missing; swap points for improved portraits/emblems are documented |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S3.S1 | Lightweight local smoke path for combat readability checks | qa-tester + tools-programmer | 1.0 | S3.M1 | One local-run smoke procedure is documented and repeatable on this machine |
| S3.S2 | Reward-card identity polish (micro-copy/tooltip refinement) | ui-programmer | 0.5 | S3.M1 | Reward options communicate role/value clearly with reduced ambiguity |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S3.N1 | Additional encounter intro flavor polish | ui-programmer | 0.5 | S3.M2 | Encounter transition improves perceived variety without logic churn |
| S3.N2 | Optional alternate card-style skin experiment | ui-programmer + ux-designer | 0.5 | S3.M1 | One alternate visual card treatment can be toggled for playtest comparison |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Card readability/identity clarity in hand cards | Prior playtest and handoff call out continued dependence on text-heavy parsing | 2.0 days (S3.M1) |
| Second encounter uniqueness | Handoff identifies encounter 2 differentiation as next high-value slice | 2.0 days (S3.M2) |
| Asset quality cleanup path | Current portraits/emblems rely on interim generated/cropped assets | 1.0 day (S3.M5) |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Scope creeps into map/meta systems | High | High | Hard boundary: sprint limited to combat readability + encounter differentiation only |
| Card identity changes reduce readability contrast | Medium | Medium | Preserve high-contrast palette and validate with focused playtest pass |
| Encounter differentiation accidentally breaks deterministic fixtures | Medium | High | Add/update deterministic checks alongside implementation and compare cursor/hash outputs |
| Generated art paths missing in repo on some machines | High | Medium | Keep fallback-safe loading behavior; do not hard-fail UI when art assets are absent |

## Dependencies on External Factors
- Focused human playtest session for readability and encounter distinction feedback
- Availability of improved portrait/emblem assets (non-blocking due fallback path)

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Card identity/readability improvements validated in hand and reward surfaces
- [ ] Encounter 2 is meaningfully differentiated while preserving deterministic behavior
- [ ] Deterministic and smoke validations are green on this machine
- [ ] At least one playtest evidence artifact is archived
- [ ] No S1 or S2 bugs in delivered slice
- [ ] Design/docs updated for any contract or behavior deviations
