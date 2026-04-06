# Sprint 007 -- 2026-06-15 to 2026-06-26

## Sprint Goal
Make Dungeon Steward's combat turns strategically interesting and build-shaping by clarifying card roles, strengthening sequencing incentives, tightening resource pressure, and ensuring rewards materially reshape the next combats.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S7.M1 | Card role taxonomy and authored metadata pass | game-designer + gameplay-programmer | 1.0 | Sprint 006 readability baseline, current catalog/presenter contracts | Live cards and reward candidates expose meaningful functional roles such as starter, bridge, payoff, and rescue/fixup through authored metadata and combat-facing presentation |
| S7.M2 | Sequencing depth pass for live card set | gameplay-programmer + game-designer | 1.5 | S7.M1 | Strong play order produces visible upside, weak order is understandable, and the live combat slice contains fewer low-expression “dump your hand” lines |
| S7.M3 | Economy / focus tension tuning pass | gameplay-programmer + balance-check | 1.0 | S7.M2 | Energy and FOCUS pressure create decisions without producing dead turns, and obvious always-correct lines are reduced |
| S7.M4 | Reward draft in service of combat experimentation | gameplay-programmer + systems-designer | 1.0 | S7.M1-S7.M3 | Reward picks materially affect the next combats’ decision space; if non-base reward contexts are introduced live, they do so through an explicit, documented runtime contract |
| S7.M5 | Runtime consumption of additional authored card schema where it improves combat expression | gameplay-programmer | 1.0 | S7.M1 | Selected authored metadata such as more play conditions / targeting scaffolds are consumed in runtime where they deepen combat decisions without destabilizing determinism |
| S7.M6 | Balance/sim/playtest validation for decision depth | qa-tester + tools-programmer | 1.0 | S7.M2-S7.M5 | Focused playtests, smoke coverage, and sim/report tooling all confirm that multiple viable turn lines appear often enough to matter |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S7.S1 | Reward-context gameplay slice for non-base live rewards | gameplay-programmer | 0.75 | S7.M4 | If adopted, live runner emits non-base reward contexts only under explicit documented combat/run conditions |
| S7.S2 | Additional role-facing UI cleanup | ui-programmer | 0.75 | S7.M1 | Card roles read more clearly in the HUD/reward views without adding copy bloat |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S7.N1 | Extra sequencing-aware sim scenarios | tools-programmer | 0.5 | S7.M6 | Sim pack contains representative sequencing-focused scenarios for role/economy comparisons |
| S7.N2 | Narrow deck-role inspection debug view | tools-programmer + ui-programmer | 0.5 | S7.M1 | Dev-only/debug surface can summarize the current deck’s starter/bridge/payoff mix without becoming a full deckbuilder feature |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Combat readability improvements need gameplay follow-through | Once combat is readable, the next bottleneck becomes low-expression turns and unclear role identity | 2.5 days across S7.M1-S7.M3 |
| Live reward-context gameplay decision remains deferred | Reward-context contract is explicit, but live non-base contexts should only be introduced if they clearly improve combat experimentation | 1.0 day across S7.M4 / S7.S1 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Added role metadata becomes taxonomy theater instead of gameplay value | Medium | High | Require every new role distinction to change either card presentation, reward value, or actual turn decisions |
| Economy tuning improves tension but creates frustration/dead turns | Medium | High | Validate with focused playtests and preserve setup-card floor targets |
| Reward experimentation broadens content volume instead of choice quality | Medium | Medium | Measure success by changed next-combat decisions, not by number of new rewards surfaced |
| Consuming more authored schema destabilizes determinism or runtime clarity | Medium | Medium | Keep each new schema-consumption slice small, explicit, and covered by smoke + determinism checks |

## Dependencies on External Factors
- Focused native combat playtests after Sprint 006 lands its readability/feel baseline
- Existing balance/sim tooling remaining usable as combat tuning accelerates

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Live cards have clearer authored combat roles and those roles matter in gameplay
- [ ] Multiple viable sequencing lines appear often enough to make turns interesting
- [ ] Resource/focus pressure creates real tension without creating frequent dead turns
- [ ] Reward picks materially shape the next combats' decision space
- [ ] Sim/smoke/playtest evidence supports the claim that combat is becoming build-shaping rather than just readable
- [ ] Design/docs updated for any runtime contract or schema-consumption changes
