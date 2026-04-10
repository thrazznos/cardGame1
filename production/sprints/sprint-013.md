# Sprint 013 -- 2026-09-07 to 2026-09-18

## Sprint Goal
Polish the combat presentation layer so card readability, HUD information hierarchy, reward interaction, and map readability feel intentional in live play, while hardening the shared preflight workflow so polish work can ship reliably through CI.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S13.M1 | Card presentation polish pass | ui-programmer | 1.5 | Existing combat stage renderer, current generated card art | Hovered cards keep cost/title readability, no stray header/role background artifacts remain, and card hierarchy reads consistently across idle and hovered states. |
| S13.M2 | Combat HUD information layout pass | ui-programmer | 1.5 | S13.M1, current combat stage layout | Energy appears in the hand-selection region, gem stack sits directly beneath it with a readable label, combat log is centered below the intent preview, and key arena information reads clearly at the project window target. |
| S13.M3 | Reward / hover / hit-area visual QA | ui-programmer + qa-tester | 1.0 | S13.M1-S13.M2, existing reward overlay probes | Reward overlay hit areas match visual cards, hand hover state does not hide critical information, and combat stage event feed remains readable in real play and probe coverage. |
| S13.M4 | Preflight / CI reliability hardening | devops-engineer + tools-programmer | 1.0 | Existing shared preflight script + workflow | Local preflight stays strict, CI preflight handles detached HEAD safely, stale-branch warnings remain informative, and workflow YAML runs successfully on pull requests. |
| S13.M5 | Validation and regression proof pass | qa-tester | 1.0 | S13.M1-S13.M4 | Headless Godot startup passes, key combat UI smoke probes pass, and at least one targeted regression probe or assertion covers the most recent HUD/layout fixes. |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S13.S1 | Map HUD readability / hover polish | ui-programmer | 1.0 | Existing map HUD, viewport-scaling pass | Hover affordances are obvious, objective banners remain readable at scaled sizes, and map room clickability remains visually clear after the recent sizing/layout changes. |
| S13.S2 | Visual asset import hygiene | tools-programmer + ui-programmer | 0.5 | Current generated card/reward assets | Asset import metadata expectations are documented or normalized so recurring `.import` confusion does not slow UI branches. |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S13.N1 | Card style token cleanup | ui-programmer | 0.5 | S13.M1 | More card draw constants live in `src/ui/theme.gd`, reducing one-off styling values inside the combat stage renderer. |
| S13.N2 | UI layout proof probes | qa-tester | 0.5 | S13.M2-S13.M3 | Add or refine narrow smoke probes that would catch invisible hover cost badges, misplaced gem stack/energy labels, and combat-log placement regressions. |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Combat UI is functionally complete but still has presentation-level rough edges | Sprint 012 completed runtime contract work, exposing small but meaningful HUD/layout polish issues during live play | 3.0 days across S13.M1-S13.M3 |
| Shared preflight exists but CI behavior still needs hardening | Sprint 012 and follow-up workflow work introduced a shared script, but GitHub Actions edge cases and YAML reliability still need cleanup | 1.0 day in S13.M4 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| UI polish changes accidentally hide or regress critical combat information | Medium | High | Make small, reviewable changes with immediate manual verification and targeted smoke coverage after each cluster of fixes. |
| Draw-order or hit-area changes break hover/click behavior without parser failures | Medium | Medium | Keep hover/hitbox adjustments narrow and use existing combat stage probes to validate interaction zones. |
| CI workflow fixes improve one environment but regress local preflight assumptions | Medium | Medium | Preserve strict local behavior, isolate CI-only handling, and verify both modes explicitly. |
| Asset/import metadata churn distracts from real UI work | Medium | Low | Decide and document a clear policy for `.import` handling before broadening art polish scope. |

## Dependencies on External Factors
- Generated combat card and reward art assets remain available at their current project paths.
- Godot headless startup remains the baseline validation check for UI/presentation changes.
- Shared preflight workflow continues to be the required path for agent and developer validation before concluding implementation work.

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Card hover state preserves cost and title readability
- [ ] Energy, gem stack, and combat log placement read clearly in the combat HUD
- [ ] Reward overlay interaction and event-feed readability are verified in play and probe coverage
- [ ] Preflight passes reliably in both local and CI modes
- [ ] Headless Godot startup passes
- [ ] Any new probe coverage is narrow, intentional, and tied to real UI regressions
