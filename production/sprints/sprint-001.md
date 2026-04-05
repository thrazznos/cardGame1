# Sprint 001 Plan - Deterministic Combat Foundation (MVP Implementation Sprint)

Status: Planned
Sprint Window: 2 weeks (10 working days)
Target Capacity: 50 hours (solo-focused estimate)
Primary Platform: Browser-first (Godot 4.6.2 Web export)

## Sprint Goal
Deliver the first playable, browser-running deterministic combat slice: one seeded encounter where player card intents resolve through authoritative TSRE+ERP flow, with minimal HUD, deterministic RNG streams, and replay-test coverage proving cross-browser parity on core fixtures.

Success statement:
By end of Sprint 001, team can run the same combat seed+inputs in Chrome and Firefox and get identical outcome hash/event order for the implemented slice.

## Scope Basis (Approved MVP GDDs)
This sprint is derived from approved MVP system docs:
- design/gdd/card-data-definitions.md
- design/gdd/systems/turn-state-rules-engine.md
- design/gdd/systems/effect-resolution-pipeline.md
- design/gdd/systems/deck-lifecycle.md
- design/gdd/systems/mana-resource-economy.md
- design/gdd/systems/enemy-encounters.md
- design/gdd/systems/rng-seed-run-generation.md
- design/gdd/systems/combat-ui-hud.md
- design/gdd/systems/profile-progression-save.md (minimal profile bootstrap only)

Architecture/contract constraints applied:
- docs/architecture/ADR-0001-runtime-determinism-and-ui-boundary.md
- docs/architecture/ADR-0002-rng-seed-stream-contracts.md
- docs/architecture/ADR-0003-persistence-model-profile-and-run-state.md

## Sprint Boundaries
In scope (Must ship in Sprint 001):
- Deterministic combat runtime foundation and first vertical combat slice.
- Browser-playable build with minimal but authoritative combat HUD.
- Replay fixture harness validating core determinism.

Out of scope (explicitly deferred):
- Full map/path loop (MPS) and full reward drafting (RDS).
- Hub/meta investment UX and economy depth.
- Run Save/Resume full implementation (VS-tier system).
- Advanced onboarding/tooltips, telemetry dashboards, and audio polish.

## Epics, Features, and Tasks

### Epic E1 - Deterministic Runtime Core
Feature outcome: TSRE is authoritative, reproducible, and isolated from UI mutation.

Tasks:
- E1.T1 Implement combat state machine and phase transitions:
  CombatInit -> TurnStart -> PlayerPhase -> ResolvePhase -> EnemyPhase -> TurnEnd -> CombatEnd.
- E1.T2 Implement single authoritative resolve queue with stable ordering keys:
  (turn_index, phase_index, timing_window, speed_class, enqueue_sequence_id, source_instance_id).
- E1.T3 Implement intent pipeline: IntentCaptured -> ValidateIntent -> CommitPlay -> ResolvePlay.
- E1.T4 Enforce ResolveLock input gating (accept inspect/hover only).
- E1.T5 Emit ordered event stream entries with order metadata and pre/post hash fragment.

Acceptance criteria (Epic E1):
- Illegal transitions are rejected with deterministic reason codes.
- UI cannot mutate combat state except through submit_play_intent/submit_pass APIs.
- Queue preview order matches resolved execution order for sprint fixture set.

Estimate: 14h

### Epic E2 - Deterministic RNG + Seed Contracts
Feature outcome: all authoritative randomness uses stream-partitioned RSGC API.

Tasks:
- E2.T1 Implement run determinism manifest bootstrap (seed root, RNG algorithm version, stream schema version).
- E2.T2 Implement canonical RNG streams required for sprint slice:
  encounter.intent, combat.effect.proc, combat.effect.retarget, combat.status_chance.
- E2.T3 Implement DrawU32Next + draw index tracking and cursor persistence in runtime memory snapshot.
- E2.T4 Add guardrails blocking ambient randomness use in authoritative code paths.
- E2.T5 Add replay mismatch reporting (first mismatch stream/index/callsite for test harness).

Acceptance criteria (Epic E2):
- Duplicate commit replay does not consume extra draws.
- Same seed + same inputs -> identical draw index progression across Chrome/Firefox fixtures.
- RNG calls in this slice are traceable to stream keys.

Estimate: 8h

### Epic E3 - Combat Slice Systems Integration
Feature outcome: card play resolves end-to-end across card data, ERP, DLS, MRE, and EES.

Tasks:
- E3.T1 Define minimal playable card set as data assets (6-10 cards) using Card Data schema.
- E3.T2 Implement ERP execution for MVP subset effects:
  deal_damage, gain_block, draw_n, apply_status(add/refresh_duration only in Sprint 001 subset).
- E3.T3 Implement DLS zone transitions and deterministic draw/reshuffle for slice:
  draw_pile/hand/discard/exhaust/limbo.
- E3.T4 Implement MRE commit-time spend model (AP-as-mana shared budget, affordability check + commit spend).
- E3.T5 Implement one deterministic enemy encounter template with telegraphed intents (fixed_cycle or simple weighted_policy only).
- E3.T6 Wire TSRE integration contracts for DLS/MRE/EES calls and reason-code propagation.

Acceptance criteria (Epic E3):
- Every committed play transitions hand -> limbo -> final zone exactly once.
- Spend occurs at CommitPlay and not at resolve completion.
- Enemy telegraph and resolved action match, or explicit mutation/fizzle reason is emitted.
- No silent operation drops: fizzles/rejections/clamps always log reason codes.

Estimate: 18h

### Epic E4 - Browser-first Combat HUD (Minimal MVP Surface)
Feature outcome: player can complete encounter through readable, authoritative HUD.

Tasks:
- E4.T1 Build minimal HUD regions: phase banner, hand panel, resource display, enemy intent strip, compact combat log.
- E4.T2 Implement action submissions through TSRE APIs only (no direct state writes).
- E4.T3 Show “Why can’t I play this?” reason text for affordability/legality failures.
- E4.T4 Implement resolve-lock UI disable behavior and pending-submit anti-double-commit guard.
- E4.T5 Add lightweight queue/order chips (timing_window, speed_class, enqueue sequence).

Acceptance criteria (Epic E4):
- 100% of rejected actions shown with mapped reason text (no unknown reason string).
- Under rapid double-click test, only one authoritative commit is applied.
- HUD remains responsive and readable in browser while preserving event order.

Estimate: 7h

### Epic E5 - Test Harness, CI Gates, and Sprint Exit Evidence
Feature outcome: deterministic proof artifacts exist and gate regressions.

Tasks:
- E5.T1 Create deterministic replay fixtures for core cases:
  - order sensitivity (same hand, different order)
  - RNG status/chance application
  - deck reshuffle boundary
  - enemy intent sequence
- E5.T2 Add cross-browser fixture run procedure (Chrome Stable + Firefox Stable).
- E5.T3 Add baseline performance checks for logic-only slice (queue step median/P95).
- E5.T4 Produce sprint validation report with pass/fail matrix and known gaps.

Acceptance criteria (Epic E5):
- Minimum 100 deterministic replay fixtures pass in both target browsers for sprint subset.
- 0 determinism divergences in required fixture suite.
- Validation report archived with evidence links/log references.

Estimate: 3h

Total estimate: 50h

## Day-by-Day Execution Plan (Actionable)
Week 1
- Day 1-2: E1 core state/queue pipeline scaffold.
- Day 3: E2 RNG manifest + stream API integration.
- Day 4-5: E3 card data + ERP + DLS core transitions.

Week 2
- Day 6: E3 MRE + EES encounter wire-up.
- Day 7-8: E4 minimal HUD and input gating.
- Day 9: E5 fixture harness + cross-browser runs.
- Day 10: Stabilization, bug fixes, sprint validation report.

## Dependencies
Hard dependencies for Sprint 001 execution:
- Approved MVP contracts from TSRE, ERP, Card Data, DLS, MRE, EES, RSGC, CUI.
- ADR-0001 UI boundary and deterministic queue authority.
- ADR-0002 stream partitioning and draw-index semantics.
- Godot 4.6.2 pinned behavior reference: docs/engine-reference/godot/VERSION.md.

Soft dependencies (can be mocked/stubbed this sprint):
- Unlock/Option Gating full runtime integration.
- Reward Draft/Map/Hub full loop.
- Full persistence migration paths and cloud semantics.

## Risks and Mitigations
1) Risk: Determinism drift across browsers due to ordering/math edge cases.
- Mitigation: integer/fixed-point only for authoritative calculations; early cross-browser fixture runs (mid-sprint and end-sprint).

2) Risk: Scope creep into full run loop (map/reward/hub) before combat slice is stable.
- Mitigation: enforce out-of-scope boundary; prioritize single-encounter vertical slice.

3) Risk: UI accidentally mutates gameplay state.
- Mitigation: strict API boundary tests; lint/code review checks for direct state mutation paths.

4) Risk: Trigger or resolve loops cause hangs/perf spikes.
- Mitigation: maintain resolve budget caps and deterministic fail-safe reason events.

5) Risk: Godot 4.6.2 post-cutoff API assumptions cause implementation churn.
- Mitigation: verify all engine-specific calls against docs/engine-reference/godot/*.md before merge.

## Sprint 001 Acceptance Criteria (Sprint-level)
Sprint is accepted only if all are true:
1) Browser-playable combat demo exists with one full encounter from start to victory/defeat.
2) Combat inputs flow only through authoritative TSRE contracts.
3) Determinism fixtures pass with 0 divergences on Chrome Stable and Firefox Stable for sprint subset.
4) Core event log includes reason-coded reject/fizzle/mutation paths (no silent failures).
5) Resource spend and zone transitions satisfy commit-time and lifecycle contracts in fixture coverage.
6) Known gaps are documented with explicit Sprint 002 carry-over tasks.

## Definition of Done (Sprint 001)
A sprint item is Done when:
- Implementation completed and integrated behind authoritative contracts.
- Automated tests for the item are added and passing.
- Cross-system contract assumptions are validated against referenced approved GDDs.
- Browser verification done on target matrix for impacted behavior.
- Failure/reject paths have deterministic reason codes and UI-safe messages.
- Documentation updated (task status, known limitations, next-sprint handoff notes).

Sprint 001 overall DoD:
- All Must-Have tasks (E1-E4, plus E5 minimum fixture gate) completed.
- No open P0/P1 defects on the seeded encounter flow.
- Replay evidence and sprint validation report produced and stored in production artifacts.

## Carry-over Candidate Backlog for Sprint 002
- Expand effect/status coverage beyond sprint subset.
- Add map node progression + first reward checkpoint integration.
- Add UOG/PPS deeper integration for unlock-aware reward generation.
- Improve queue explainability surfaces and accessibility polish.
