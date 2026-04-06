# Sprint 004 -- 2026-05-04 to 2026-05-15

## Sprint Goal
Ship a deterministic Gem Stack Machine MVP in the existing combat slice so players can sequence producer/consumer cards with visible stack and FOCUS state, without expanding scope into map/meta systems.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S4.M1 | Gem Stack Machine data contracts and reason-code taxonomy | gameplay-programmer + systems-designer | 1.0 | Card schema, ERP extension points | Gem stack and FOCUS fields are represented in runtime/view-model contracts; deterministic reason codes are defined for legal, fail, and reject paths |
| S4.M2 | Core GSM runtime module (LIFO stack + basic operations) | gameplay-programmer | 1.5 | S4.M1 | New GSM module supports Produce, ConsumeTop, PeekTop/PeekN, and deterministic failure behavior (empty/mismatch) |
| S4.M3 | FOCUS gate + first Advanced selector | gameplay-programmer | 1.0 | S4.M2 | Non-top consume path (ConsumeFromTopOffset(1)) rejects without FOCUS and resolves with FOCUS, with explicit reason-coded events |
| S4.M4 | ERP/combat integration for gem operations | gameplay-programmer + godot-gdscript-specialist | 1.5 | S4.M2, S4.M3 | Card effects can mutate/query gem stack through ERP; combat loop remains deterministic and stable |
| S4.M5 | HUD/log readability for stack + FOCUS | ui-programmer + ux-designer | 1.0 | S4.M4 | Top-of-stack window (top 3) and FOCUS indicator are visible in combat HUD; event log explains consumed/produced gems and why |
| S4.M6 | Pilot card pack implementation (8-card GSM subset) | game-designer + gameplay-programmer | 1.0 | S4.M4 | Implemented subset includes producer/consumer/advanced cards; common producers still provide useful baseline value (~75/25 target) |
| S4.M7 | Determinism and smoke validation for GSM | qa-tester + tools-programmer | 1.0 | S4.M4, S4.M5, S4.M6 | New deterministic fixtures and smoke tests cover produce/consume/focus gate paths; full local suite remains green |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S4.S1 | Stability extension: ReserveTop(1) visibility path | gameplay-programmer + ui-programmer | 0.5 | S4.M5 | Reserved top gem is represented in state and visually marked in HUD/log |
| S4.S2 | Second advanced selector path (ConsumeFirstMatch) with deterministic tie-break | gameplay-programmer | 0.5 | S4.M3 | Selector behavior is deterministic and validated with at least one fixture |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S4.N1 | Audio event hook stubs for produce/consume/fail | ui-programmer + sound-designer | 0.5 | S4.M4 | GSM events expose clean hook points for future audio cues without changing deterministic outcomes |
| S4.N2 | Debug counters for gem mutation frequency and fail reasons | tools-programmer | 0.5 | S4.M7 | Lightweight counters/log summary can be generated from deterministic runs |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Gem Stack Machine implementation | Designed in GDD, not yet implemented in runtime | 6.0 days across S4.M1-S4.M6 |
| Deterministic validation for gem interactions | Existing determinism coverage does not include gem operations | 1.0 day (S4.M7) |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Scope creep into full map/meta progression | High | High | Hard boundary: sprint limited to combat GSM only; no map/hub/save-loop expansion |
| Gem logic introduces nondeterministic ordering | Medium | High | Keep operations atomic and reason-coded; add fixtures for repeat-seed hash checks |
| HUD clarity degrades with added stack complexity | Medium | Medium | Keep top-3 stack visibility and concise event lines; validate with focused local smoke pass |
| Advanced selector complexity stalls core delivery | Medium | Medium | Limit MVP advanced support to one selector (top offset 1), defer additional selectors to Should Have |
| Producer cards feel like dead setup | Medium | Medium | Enforce baseline value target in pilot cards; include quick gameplay check before freeze |

## Dependencies on External Factors
- Focused local playtest feedback for readability of stack + FOCUS surfaces
- Final confirmation on FOCUS model shape for MVP was resolved in implementation/docs: shipped MVP uses spendable FOCUS charges (typically 0/1 in live play) rather than a pure boolean flag

## Definition of Done for this Sprint
- [x] All Must Have tasks completed
- [x] Gem Stack Machine is playable in the combat slice with deterministic outcomes
- [x] FOCUS gate behavior is visible, reason-coded, and validated
- [x] HUD/log readability answers what gem changed and why without debugger use
- [x] Full local test suite is green, including new GSM deterministic coverage
- [x] No S1 or S2 bugs in delivered slice
- [x] Design/docs updated for any contract deviations
