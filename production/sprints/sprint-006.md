# Sprint 006 -- 2026-06-01 to 2026-06-12

## Sprint Goal
Make Dungeon Steward's combat slice fast to parse and satisfying to play by giving the hand dominant card presence, clearer legality/explainability surfaces, and stronger early-turn feel without broadening scope into map, hub, or deckbuilder systems.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S6.M1 | Hand-dominant combat HUD layout and card-face scaling pass | ui-programmer + ux-designer | 1.5 | Sprint 005 card presenter path, current HUD scene/controller | Resting hand cards read as real cards rather than utility buttons, occupy clear visual priority in combat, and remain compatibility-safe with hotkeys, probes, and Button-root paths intact |
| S6.M2 | Legality / explainability affordance cleanup | ui-programmer + gameplay-programmer | 1.0 | S6.M1, current `play_reason` / `last_reject_reason` contracts | Illegal cards, resolve-lock, and reject states are readable inline and on hover, hotkeys respect card legality, and “why unavailable?” answers are visible without debugger use |
| S6.M3 | Deterministic turn-feel feedback pass | ui-programmer + gameplay-programmer | 1.0 | S6.M1 | Played-card impact, block gain, gem produce/consume, FOCUS gain, and reject outcomes all have lightweight deterministic feedback that improves feel without adding timing authority |
| S6.M4 | Starter deck and opening-turn fun audit | game-designer + gameplay-programmer | 1.5 | S6.M2, Sprint 005 card catalog/deck data | Opening hands regularly show at least one meaningful sequencing line, setup cards have a visible floor, and low-value opener patterns are reduced in the live starter deck |
| S6.M5 | Queue / event log readability cleanup | ui-programmer + tools-programmer | 1.0 | S6.M2, S6.M3 | Queue and recent-event surfaces explain “what changed / why” more cleanly, with less text sludge and better support for player trust |
| S6.M6 | Focused readability validation and evidence capture | qa-tester + tools-programmer | 1.0 | S6.M1-S6.M5 | Focused native playtests are captured for the first two encounters, smoke coverage expands for readability promises, and determinism fixtures remain green or are intentionally updated with documentation |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S6.S1 | Reward presentation readability pass | ui-programmer | 0.75 | S6.M1 | Reward choices feel like drafting cards from the same visual family as the hand and remain easy to compare quickly |
| S6.S2 | Encounter-two readability polish pass | gameplay-programmer + ui-programmer | 0.75 | S6.M4, S6.M6 | Second-encounter readability issues discovered in playtests are addressed without broadening system scope |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S6.N1 | Additional hover/focus choreography polish | ui-programmer | 0.5 | S6.M1 | Hover/focus enlargement feels smooth and legible without causing layout jitter or accidental input ambiguity |
| S6.N2 | Readability-specific smoke probe pack cleanup | tools-programmer | 0.5 | S6.M6 | New readability probes are easier to maintain and grouped around concrete UI promises |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Combat card UI still undersized / under-dominant at rest | Compatibility-first redesign improved direction but the hand still needs a stronger screen claim before combat can feel card-first | 3.0 days across S6.M1-S6.M3 |
| Opening-turn sequencing still needs a fun/readability pass | Card/data migration stabilized the runtime, but early turns still need design and feel iteration before broader loop work is justified | 2.0 days across S6.M2-S6.M4 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| UI polish improves appearance but not decision quality | Medium | High | Tie every HUD/UI change to a specific combat-readability or sequencing-read claim and validate with playtests |
| Bigger card presentation causes layout/input regressions | Medium | Medium | Preserve compatibility-safe Button roots, hotkeys, and smoke probes; animate internal chrome rather than breaking node contracts |
| Event/log cleanup hides causal detail | Medium | Medium | Keep deterministic source of truth intact and prefer concise phrasing over removing information |
| Starter-deck tuning drifts into broad rebalance churn | Medium | Medium | Keep Sprint 006 focused on opener floor and sequencing teaching value, not full archetype redesign |

## Dependencies on External Factors
- Focused native playtest feedback for first- and second-encounter readability
- Stable local Godot validation on the current prototype branch and upstream PR branch

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Combat cards are visually dominant enough to read as actual cards in the live HUD
- [ ] First-turn / opening-hand sequencing is clearer and more satisfying than the current baseline
- [ ] Reject reasons and queue/event feedback are understandable without debugger use
- [ ] Focused native playtest evidence is captured for the first two encounters
- [ ] Smoke and determinism coverage remain green or intentional baseline changes are documented
- [ ] Design/docs updated for any contract deviations discovered during implementation
