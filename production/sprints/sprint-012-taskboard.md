# Sprint 012 Taskboard - Execution

Status: Complete
Sprint: production/sprints/sprint-012.md
Updated: 2026-04-07
Commitment: Must Have + Should Have
Platform: Native-only (no browser automation)

## Epic E1 - Play-Condition Runtime Expansion (S12.M1)
- [x] E1.T1 Introduce a play-condition dispatcher/helper instead of inline special-casing in CombatSliceRunner
- [x] E1.T2 Preserve `focus_at_least` behavior and move it into the shared legality path
- [x] E1.T3 Add at least one new authored condition path end-to-end
- [x] E1.T4 Surface readable reject reasons for new condition failures in the live HUD/view-model

## Epic E2 - Target Legality and Policy Runtime Pass (S12.M2)
- [x] E2.T1 Enforce authored `target_mode` in live legality checks
- [x] E2.T2 Respect `max_targets` and `invalid_target_policy` at play/resolve boundaries
- [x] E2.T3 Add smoke coverage for self, no-target, and single-enemy legality paths
- [x] E2.T4 Verify reject/event text remains readable for target failures

## Epic E3 - Runtime Card Identity Cleanup (S12.M3)
- [x] E3.T1 Normalize DeckLifecycle runtime zones to explicit `{instance_id, card_id}` values
- [x] E3.T2 Update runner bootstrap and fixture setup helpers to create proper instances
- [x] E3.T3 Keep view-model and probe compatibility shims stable during migration
- [x] E3.T4 Remove remaining silent prefix-fallback assumptions from play paths

## Epic E4 - Reward Context Contract Hardening (S12.S1)
- [x] E4.T1 Document the current live reward-routing rules in code/tests
- [x] E4.T2 Probe that the first live checkpoint remains `base_reward`
- [x] E4.T3 Probe that GSM-heavy decks switch to `gsm_reward` only on second+ live checkpoints
- [x] E4.T4 Probe that base-only decks stay on base rewards deterministically

## Epic E5 - Validation and Proof Slice (S12.M4 + S12.S2)
- [x] E5.T1 Add targeted smoke probes for expanded play-condition coverage
- [x] E5.T2 Add targeted smoke probes for target legality and invalid-target policy behavior
- [x] E5.T3 Refresh determinism expectations only where behavior changed intentionally
- [x] E5.T4 Run full unittest discover and headless Godot startup verification
- [x] E5.T5 Add 1-2 proof cards that exercise the fuller runtime contract without broad balance churn

## Optional Stretch
- [x] O1 Migrate one small card family to `effect_id` + `params` (S12.N1)
- [x] O2 Polish reject/event text for the new legality paths (S12.N2)

## Outcome Notes
- Sprint 012 is contract hardening, not run-loop breadth expansion.
- Success means new card content can be authored through data without one-off runner logic for legality and identity.
- Determinism and current live combat feel should stay stable unless a behavior change is deliberate and verified.
