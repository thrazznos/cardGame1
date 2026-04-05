# ADR-0002: RNG seed, stream partitioning, and replay contracts

Status: Accepted
Date: 2026-04-05

## Context
Map generation, rewards, encounters, and combat all depend on deterministic RNG behavior.
Cross-system coupling or inconsistent draw-index handling will break replay parity and enable exploit patterns.

## Decision
Adopt RSGC-owned deterministic RNG contracts:

1) Seed ownership
- Run creation pins immutable determinism metadata (seed root, rng_algorithm_version, rng_stream_schema_version, content/version digests).
- Only RSGC may initialize and restore stream cursors.

2) Stream partitioning
- Canonical stream families (map.*, reward.*, encounter.*, combat.*).
- Callsites must use assigned streams; shared ad-hoc streams are forbidden.

3) Draw-index semantics
- DrawNext consumes exactly one index and advances cursor atomically.
- Rejection-sampling retries still consume deterministic indices.
- Duplicate commit replay must not consume new draws.

4) Replay validation
- Every authoritative draw logs stream_key, draw_index, value, callsite_code, cursor_before/after.
- Mismatch reports first divergence location.

5) Anti-exploit policy
- No ambient randomness for authoritative outcomes.
- Single-writer run lock for concurrent-tab protection.
- No hidden post-commit rerolls.

## Consequences
Positive
- Stable seed sharing and reproducible debugging.
- Isolated RNG changes reduce regression blast radius.

Costs
- Additional instrumentation and version-governance overhead.
- More fixture upkeep when stream schema changes.

## Alternatives considered
- Single global RNG stream: rejected (high coupling).
- Per-system RNG without central ownership: rejected (inconsistent policy).
- Ambient RNG for noncritical paths: rejected (leaks into authoritative behavior).
