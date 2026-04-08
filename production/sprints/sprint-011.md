# Sprint 011 -- 2026-08-10 to 2026-08-21

## Sprint Goal
Add a status effect system (poison, weakness, strength, vulnerability) to deepen combat decisions, integrate status effects with gem stack payoffs, and implement circuit + seal floor objectives to complete map variety.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S11.M1 | Status effect data model and registry | gameplay-programmer + game-designer | 1.0 | Existing ERP/TSRE contracts | Data-driven status effect definitions in JSON (poison, weakness, strength, vulnerability). Each has: id, duration, stack_behavior, tick_timing, effect_formula, display_name, icon_key. Registry loads and validates at startup. |
| S11.M2 | Status effect resolution in ERP | gameplay-programmer | 1.5 | S11.M1 | ERP resolves new effect types: apply_status, tick_status. Poison ticks damage at turn start. Weakness reduces outgoing damage by 25%. Strength increases outgoing damage by 50%. Vulnerability increases incoming damage by 50%. Status stacks tracked on player and enemy with duration countdown. |
| S11.M3 | Player cards that apply status effects | game-designer + gameplay-programmer | 1.0 | S11.M1, S11.M2 | Add 3-4 new cards to catalog: a poison applicator, a strength buffer, a vulnerability striker, and a gem-consume status payoff card. Wire into reward pool. |
| S11.M4 | Enemy intents with status effects | gameplay-programmer | 1.0 | S11.M1, S11.M2 | Pressure profiles can include status-applying intents. Attrition profile gains poison/weakness intents. Burst profile gains vulnerability-on-charge. Telegraph text shows status effect clearly. |
| S11.M5 | Combat stage status display | ui-programmer | 1.0 | S11.M2 | Status effect icons/text shown below player and enemy portraits on combat stage. Duration counters visible. Status tick events appear in event feed. |
| S11.M6 | Smoke tests and determinism coverage | qa-tester | 0.5 | S11.M1-M5 | Status effect probe validates apply/tick/expire cycle. Determinism fixture covers status-heavy combat. Existing probes still pass. |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S11.S1 | Circuit floor objective | gameplay-programmer | 1.0 | Existing FloorController + conduit implementation | Circuit pattern tracker: target gem color sequence shown at floor entry, visiting correct-color room advances tracker, wrong color triggers penalty (reduced rewards or harder next fight). Generator verifies sequence is achievable. |
| S11.S2 | Seal floor objective | gameplay-programmer | 1.0 | Existing FloorController + conduit implementation | 3 seal nodes with gem costs scattered across graph. All 3 must be cleared to open boss gate. Generator verifies solvability. Boss node locked until seals broken. |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S11.N1 | Gem-consume status payoff card | game-designer + gameplay-programmer | 0.5 | S11.M3 | A card that consumes 2+ gems and applies a powerful status effect (e.g., consume 2 Ruby = apply 3 Strength). Bridges gem stack and status systems. |
| S11.N2 | Status effect icons on map room preview | ui-programmer | 0.5 | S11.M5, S11.S1 | When hovering a map room, show any status effects the encounter might apply (based on pressure profile). |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Circuit and seal objectives designed but not implemented | Sprint 009 built conduit only; circuit/seal deferred | 2.0 days across S11.S1-S11.S2 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Status effect stacking creates degenerate combos | Medium | High | Cap max stacks per effect at 5. Validate with sim/balance tooling after implementation. |
| Status effects break existing determinism fixtures | Medium | Medium | Status ticks at turn boundaries only. No mid-resolve status mutations. Re-baseline fixtures after. |
| Circuit/seal generator solvability check is complex | Medium | Medium | Start with simple greedy check (BFS from start, verify pattern/seals reachable). Full solver is Sprint 012. |
| Status display clutters the combat stage | Medium | Medium | Compact icon strip below portraits. Max 4 visible status effects per entity with "+N more" overflow. |

## Dependencies on External Factors
- Existing ERP effect resolution pipeline must support new effect types without restructuring
- Pressure profile JSON format must accept status-applying intents

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Player and enemies can apply, tick, and expire status effects
- [ ] At least 3 new status-applying cards in the reward pool
- [ ] Enemy pressure profiles include status-applying intents
- [ ] Status effects display on combat stage with duration counters
- [ ] Determinism verified with status effects active
- [ ] Circuit and seal floor objectives functional (Should Have)
- [ ] Design docs updated for status effect system
