# Sprint 004 Taskboard - Execution

Status: Planned
Sprint: production/sprints/sprint-004.md
Updated: 2026-04-05
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - GSM Contracts and Core Runtime (S4.M1-S4.M2)
- [ ] E1.T1 Define runtime/view-model fields for gem stack + FOCUS state
- [ ] E1.T2 Define deterministic reason-code set for produce/consume/reject paths
- [ ] E1.T3 Implement Gem Stack Machine core module with ordered LIFO storage
- [ ] E1.T4 Implement Produce, ConsumeTop, PeekTop/PeekN, and deterministic fail behavior

## Epic E2 - Advanced Access + FOCUS Gate (S4.M3)
- [ ] E2.T1 Implement binary FOCUS gate contract for MVP
- [ ] E2.T2 Implement ConsumeFromTopOffset(1) selector path
- [ ] E2.T3 Ensure no-FOCUS reject and with-FOCUS resolve outcomes are reason-coded and deterministic

## Epic E3 - Runtime Integration (S4.M4)
- [ ] E3.T1 Extend ERP effect handling for gem operations
- [ ] E3.T2 Wire GSM state transitions into combat runner resolve flow
- [ ] E3.T3 Ensure existing combat/reward flow contracts remain stable after GSM integration

## Epic E4 - HUD and Explainability (S4.M5)
- [ ] E4.T1 Add top-of-stack (top 3) display to combat HUD
- [ ] E4.T2 Add visible FOCUS indicator near hand/resources context
- [ ] E4.T3 Add/adjust event log lines for gem produce/consume/focus-gate outcomes

## Epic E5 - Card Pilot and Balance Guardrails (S4.M6)
- [ ] E5.T1 Implement 8-card GSM pilot subset in combat slice
- [ ] E5.T2 Validate common producer cards maintain useful baseline value
- [ ] E5.T3 Validate consumer variance (hybrid floor + conditional spikes) does not break encounter readability

## Epic E6 - Validation and Evidence (S4.M7)
- [ ] E6.T1 Add deterministic fixtures for produce/consume/focus-gate scenarios
- [ ] E6.T2 Add/update smoke path to verify HUD stack + FOCUS presentation
- [ ] E6.T3 Run full local test suite and archive pass/fail outcome
- [ ] E6.T4 Capture one focused playtest artifact for stack readability and sequencing feel

## Optional Stretch (Should/Nice)
- [ ] O1 ReserveTop(1) state + HUD marker (S4.S1)
- [ ] O2 ConsumeFirstMatch selector with deterministic tie-break (S4.S2)
- [ ] O3 Audio hook stubs for produce/consume/fail events (S4.N1)
- [ ] O4 Debug counters for gem mutation and fail reasons (S4.N2)

## Current Focus
- Start with E1 + E2 to lock deterministic GSM contracts before any large HUD/content changes
- Then integrate through ERP/combat runner (E3)
- Then ship readability surfaces (E4)
- Then complete card pilot and validation (E5 + E6)
