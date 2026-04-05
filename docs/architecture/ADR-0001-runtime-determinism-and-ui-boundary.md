# ADR-0001: Runtime determinism and UI authority boundary

Status: Accepted
Date: 2026-04-05

## Context
Dungeon Steward is browser-first and heavily order-sensitive (card sequencing, trigger chains, enemy intents).
Gameplay must be deterministic for QA replay, balancing, and player trust.

Without strict authority boundaries, browser timing variance can create non-reproducible behavior.

## Decision
Adopt a single authoritative simulation model:

1) Turn-state authority
- One TSRE-aligned simulation owner is the only writer of combat state.
- State transitions are explicit (CombatInit -> TurnStart -> PlayerPhase -> ResolvePhase -> EnemyPhase -> TurnEnd -> CombatEnd).

2) Queue authority
- One globally ordered deterministic queue handles committed actions/effects.
- Stable ordering key: (turn_index, phase_index, timing_window_priority, speed_class_priority, enqueue_sequence_id, source_instance_id).

3) UI boundary
- UI never mutates gameplay state directly.
- UI can only submit intents/commands.
- UI renders authoritative snapshots + ordered event stream.
- ResolveLock disables mutating controls; inspect/hover remains allowed.

4) Determinism policy
- Logic stepping is decoupled from render cadence.
- Authoritative randomness must use canonical seeded streams only.
- Event stream includes ordering metadata and hash/checkpoint fields for replay diagnostics.

## Consequences
Positive
- Reproducible combat outcomes and first-mismatch replay debugging.
- Fewer race-condition bugs between UI/animation and gameplay logic.
- Clear player-facing explainability for legality and result ordering.

Costs
- More up-front architecture rigor and contract tests.
- Slightly slower prototype iteration if a feature bypasses contracts.

## Alternatives considered
- Animation/frame-driven resolution ordering: rejected (browser timing variance).
- Multiple independent runtime queues: rejected (merge ambiguity, replay complexity).
- UI-side optimistic simulation for combat: rejected for MVP (desync and correction complexity).
