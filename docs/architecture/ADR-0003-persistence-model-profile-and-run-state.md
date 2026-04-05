# ADR-0003: Persistence model for profile progression and run state

Status: Accepted
Date: 2026-04-05

## Context
The project requires both long-lived account progression and deterministic in-run resume behavior in browser environments.
Risk areas include duplicate writes, stale snapshots, multi-tab races, and state corruption during reconnect/crash.

## Decision
Use a split persistence model with shared idempotent event semantics:

1) Profile progression store (long-lived)
- Event-backed progression updates with canonical idempotency key `event_id`.
- Monotonic commit sequence (`commit_seq`) for conflict detection.
- Optimistic UI allowed only for reversible low-risk interactions.

2) Run save/resume store (session-scoped)
- Atomic checkpoints include determinism manifest, RNG cursors, authoritative run state digest, and resume token.
- Resume fails closed on manifest/digest mismatch and surfaces recovery UX.

3) Cross-system contract
- Progression purchase identity maps `purchase_event_id -> event_id` 1:1.
- Duplicate submit must never double-charge or double-grant.
- Save writes are single-writer per run/profile lock domain.

## Consequences
Positive
- Prevents duplicate grants and replay drift after resume.
- Supports reliable offline/reconnect behavior for browser users.

Costs
- Requires strict schema/version migration discipline.
- Additional validation and telemetry plumbing.

## Alternatives considered
- Snapshot-only profile persistence: rejected (weak idempotency/auditability).
- Shared single blob for profile+run with no separation: rejected (higher corruption blast radius).
- Last-write-wins everywhere: rejected (silent loss/duplication risk).
