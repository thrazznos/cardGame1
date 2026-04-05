# Sprint 001 Taskboard - Execution

Status: Active
Sprint: production/sprints/sprint-001.md
Updated: 2026-04-05

## Epic E1 - Deterministic Runtime Core
- [ ] E1.T1 Combat state machine phases wired
- [ ] E1.T2 Single authoritative resolve queue
- [ ] E1.T3 Intent pipeline (capture -> validate -> commit -> resolve)
- [ ] E1.T4 ResolveLock input gating
- [ ] E1.T5 Ordered event stream + hash fragment emission

## Epic E2 - Deterministic RNG + Seed Contracts
- [ ] E2.T1 Run determinism manifest bootstrap
- [ ] E2.T2 Canonical streams for sprint slice
- [ ] E2.T3 Draw index tracking + cursor state
- [ ] E2.T4 Ambient RNG guardrails
- [ ] E2.T5 First-mismatch replay reporting

## Epic E3 - Combat Slice Integration
- [ ] E3.T1 Minimal card set data (6-10 cards)
- [ ] E3.T2 ERP subset effects
- [ ] E3.T3 DLS zone transitions and deterministic draw/reshuffle
- [ ] E3.T4 MRE commit-time spend model
- [ ] E3.T5 One deterministic enemy encounter template
- [ ] E3.T6 TSRE integration contracts + reason propagation

## Epic E4 - Minimal Browser HUD
- [ ] E4.T1 HUD regions scaffolded
- [ ] E4.T2 TSRE-only action submission path
- [ ] E4.T3 Rejection reason mapping in UI
- [ ] E4.T4 Pending-submit + ResolveLock guards
- [ ] E4.T5 Queue/order chips for readability

## Epic E5 - Test Harness & Exit Evidence
- [ ] E5.T1 Determinism fixtures and harness scaffolding
- [ ] E5.T2 Cross-browser replay script/procedure
- [ ] E5.T3 Budget checks: frame/draw/memory
- [ ] E5.T4 Sprint evidence bundle assembly

## Current Focus
- In progress: E1.T1/E1.T2 scaffolding
- Next: E2.T1 manifest wiring, then E3 thin-slice integration
