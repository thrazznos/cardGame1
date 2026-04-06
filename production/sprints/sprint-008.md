# Sprint 008 -- 2026-06-29 to 2026-07-10

## Sprint Goal
Make Dungeon Steward's combat replayable across encounters by creating distinct pressure profiles, improving fight pacing, and making players adapt sequencing plans between combats without broadening into map, hub, or deckbuilder implementation.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S8.M1 | Encounter pressure profile pass | gameplay-programmer + game-designer | 1.5 | Sprint 007 combat-depth baseline | At least three clearly different encounter pressure profiles exist, each asking for different sequencing habits rather than the same math problem |
| S8.M2 | Enemy intent readability and pressure communication pass | gameplay-programmer + ui-programmer | 1.0 | S8.M1 | Enemy telegraphs remain readable as encounter variety grows, and pressure differences are understandable from combat-facing surfaces |
| S8.M3 | Encounter-specific response-tool pass in cards/rewards | game-designer + gameplay-programmer | 1.0 | S8.M1, Sprint 007 reward/build-shaping baseline | Current rewards/cards provide meaningful tools for responding to different encounter pressures instead of one generic answer line |
| S8.M4 | Fight pacing and dead-turn reduction pass | gameplay-programmer + balance-check | 1.0 | S8.M1-S8.M3 | Slow or repetitive fights shorten, compounding turns still have room to matter, and combat avoids devolving into pure stat-race pacing |
| S8.M5 | Variety-focused validation coverage | qa-tester + tools-programmer | 1.0 | S8.M1-S8.M4 | Smoke and determinism coverage include representative encounter styles and pacing edge cases |
| S8.M6 | Replayability playtest pass and outcome synthesis | qa-tester + producer + game-designer | 1.0 | S8.M1-S8.M5 | Focused playtests confirm that players adapt plans between fights and that encounters are memorable for decisions, not just numbers |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S8.S1 | Elite / boss pressure differentiation pass | gameplay-programmer + game-designer | 0.75 | S8.M1 | Elite/boss fights begin to establish their own pressure identity rather than just being larger-number versions of normals |
| S8.S2 | Lightweight encounter-pressure debug counters | tools-programmer | 0.5 | S8.M5 | Dev-facing counters summarize pacing, pressure, and outcome patterns for representative encounter sets |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S8.N1 | Additional intent-surface polish for high-pressure fights | ui-programmer | 0.5 | S8.M2 | High-pressure encounters remain readable without turning intent UI into clutter |
| S8.N2 | Encounter comparison report snippets from sim/playtests | tools-programmer + qa-tester | 0.5 | S8.M6 | Short report snippets make it easier to compare how different encounters pressure different sequencing styles |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Card/reward depth needs encounter context to prove replayability | Once turns are interesting in isolation, the next question is whether different fights actually demand different plans | 2.5 days across S8.M1-S8.M3 |
| Reward/build identity needs pressure-specific validation | Build-shaping combat only matters if different encounters reward different responses | 1.5 days across S8.M3-S8.M6 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Encounter variety balloons into content-scope creep | Medium | High | Keep Sprint 008 focused on a few distinct pressure profiles, not broad biome/map expansion |
| New pressure profiles are different on paper but not in player decision-making | Medium | High | Validate with playtests focused on whether players actually change sequencing plans between encounters |
| Pacing changes shorten fights but erase compounding satisfaction | Medium | Medium | Preserve room for payoff/setup turns while targeting dead-turn and repetition reduction |
| Added encounter variation makes intent/UI readability collapse | Medium | Medium | Pair each encounter-pressure change with readable telegraph/UI adjustments and validation coverage |

## Dependencies on External Factors
- Focused native playtests on multiple encounter profiles after Sprint 007 depth work lands
- Continued availability of sim/report tooling for encounter-comparison support

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] At least a few clearly different combat pressures exist in the live slice
- [ ] Players adapt sequencing plans between encounters instead of repeating one dominant line
- [ ] Fight pacing is more varied and less repetitive without turning combat into a stat race
- [ ] Encounter and intent readability remains strong under the added pressure variety
- [ ] Smoke/determinism/playtest evidence supports the claim that combat is becoming replayable on its own
- [ ] Design/docs updated for encounter-pressure or runtime contract changes
