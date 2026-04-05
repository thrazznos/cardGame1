# RNG/Seed & Run Generation Control

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-05
> **Implements Pillar**: Readable Tactical Clarity; High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats
> **Upstream References**: design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/map-pathing.md, design/gdd/systems/reward-draft.md, design/gdd/systems/enemy-encounters.md, design/gdd/systems/effect-resolution-pipeline.md

## Overview

RNG/Seed & Run Generation Control (RSGC) is the canonical determinism authority for all random outcomes in Dungeon Steward.

RSGC defines:
- How run seeds are derived and pinned.
- How deterministic random numbers are generated in browser-first runtime.
- How RNG streams are partitioned to prevent cross-system coupling.
- How stream cursors are persisted across save/load/resume.
- How content/config versions are pinned so replay remains valid.
- How replay validation detects and localizes mismatches.

Design intent:
- Same run manifest + same input event stream must produce identical outcomes on Chrome/Firefox/Safari and across machines.
- Randomness must be explainable and auditable, not ambient.
- System teams can change internals without silently desyncing existing runs.

Out of scope (MVP):
- Cryptographic fairness guarantees for adversarial PvP.
- Networked lockstep multiplayer.
- Live-ops “silent seed mutation” for in-progress runs.

## Player Fantasy

The player-facing fantasy is fairness and trust:
- “If I replay this seed and make the same choices, I get the same run.”
- “When outcomes differ, the game can prove why.”
- “Randomness feels varied, but never arbitrary or bugged.”

For advanced users, shared seeds and replay verification should feel reliable, not approximate.

## Detailed Design

### Design Goals (Optional)

1) Determinism first
- Deterministic parity is a hard requirement across supported browsers.

2) Isolation by stream
- Random decisions in one subsystem must not perturb another subsystem’s results.

3) Resume safety
- Save/load and app refresh restore exact RNG cursors and manifest context.

4) Replay forensics
- Any mismatch can be traced to stream, draw index, and callsite.

5) Browser-first practicality
- Integer-only operations (`Math.imul`, bitwise ops) with no float-dependent RNG behavior.

### Core Rules

1) No ambient randomness
- Gameplay/runtime systems must never call `Math.random()`, crypto RNG, engine RNG, or time-based RNG for authoritative outcomes.
- All authoritative randomness must flow through RSGC API.

2) Canonical RNG API surface
- Pure indexed draw:
  - `DrawU32At(stream_key, draw_index) -> uint32`
- Cursor-consuming draw:
  - `DrawU32Next(stream_key) -> uint32`
- Uniform bounded integer:
  - `DrawIntRangeNext(stream_key, min_inclusive, max_inclusive) -> int`
- Cursor inspection:
  - `GetNextDrawIndex(stream_key) -> uint32`

`DrawU32At` must be side-effect free.
`DrawU32Next` and `DrawIntRangeNext` must atomically advance the stream cursor.

3) Deterministic stream partitioning is mandatory
- RSGC owns a fixed stream registry and schema version.
- Each random consumer callsite must declare one canonical stream key.
- Cross-system sharing of a stream key is forbidden unless explicitly documented.

MVP canonical stream set:
- Map generation/traversal:
  - `map.layout`
  - `map.node_type`
  - `map.encounter_pick`
  - `map.event_variant`
- Reward generation:
  - `reward.card`
  - `reward.relic`
  - `reward.option`
- Encounter generation/AI:
  - `encounter.composition`
  - `encounter.intent`
  - `encounter.targeting`
  - `encounter.reinforcement`
- Effect/combat random checks:
  - `combat.effect.proc`
  - `combat.effect.retarget`
  - `combat.status_chance`

4) Stream key scope derivation
- Systems may derive scoped stream keys under a canonical root, but only via canonical formatter:
  - `ScopedStreamKey(root, scope_fields[])`
- `scope_fields[]` must be stable, serialized in fixed field order, and versioned under `rng_stream_schema_version`.
- Example: `ScopedStreamKey("map.encounter_pick", [act_index, node_instance_id])`.

5) Cursor persistence
- Run snapshot stores `rng_cursors: Map<stream_key, next_draw_index>`.
- Cursors are persisted at each authoritative checkpoint/commit event.
- Save/load must restore byte-identical cursor map.
- Rollback/retry logic must never “replay-consume” draws differently.

6) Transaction and idempotency policy
- RNG consumption occurs only inside authoritative commit pipeline.
- Duplicate commits with same idempotency key must not consume additional draws.
- Rejected commits must not mutate cursor state.

7) Version pinning
- At run creation, RSGC writes immutable `RunDeterminismManifest` containing:
  - `rng_algorithm_version`
  - `rng_stream_schema_version`
  - `content_manifest_digest`
  - `system_version_bundle` (map profile, reward policy, encounter tables, card data, relic data, unlock tables)
- In-progress runs cannot hot-swap manifest versions.

8) Replay validation chain
- Every authoritative RNG draw emits a compact `RngDrawRecord`:
  - `stream_key`
  - `draw_index`
  - `u32_value`
  - `callsite_code`
  - `event_id`
- Draw records contribute to run replay hash chain.
- Replay verifier must be able to stop at first mismatch and report exact stream/index/callsite.

9) Browser implementation constraints
- RNG core and hashing must use deterministic integer math only.
- 64-bit digests may use BigInt for logs/validation only; authoritative draw generation must not depend on float conversion.
- All serialization for deterministic inputs must use canonical field order and UTF-8 normalization policy.

10) Failure policy by mode
- Dev/test/replay mode:
  - Determinism mismatch is hard-fail.
- Release mode:
  - Session continues if safe, emits `ERR_DETERMINISM_MISMATCH`, and captures forensic trace chunk.

### States and Transitions

RSGC run-level states:
- SeedUninitialized
- SeedDerived
- ManifestPinned
- StreamsInitialized
- Active
- Suspended
- Completed
- Invalid

Primary transitions:
- SeedUninitialized -> SeedDerived (run seed derivation complete)
- SeedDerived -> ManifestPinned (determinism manifest committed)
- ManifestPinned -> StreamsInitialized (cursor map created)
- StreamsInitialized -> Active (run starts)
- Active -> Suspended (save/background/interrupt)
- Suspended -> Active (resume with matching manifest + cursors)
- Active -> Completed (run end)
- Any -> Invalid (manifest mismatch/cursor corruption hard failure)

Illegal transitions (hard reject):
- Active -> SeedDerived (cannot re-seed in-place)
- Suspended -> SeedDerived (resume cannot mutate seed)
- Completed -> Active

### Data Model and API Contracts (Optional)

Run seed request:
- `CreateRunSeedRequest`
  - `profile_id`
  - `mode_id`
  - `difficulty_tier`
  - `player_seed_input?` (optional share-code input)
  - `run_ordinal`
  - `content_manifest_digest`

Run determinism manifest:
- `RunDeterminismManifest`
  - `run_id`
  - `seed_root_u32`
  - `seed_variant_u32`
  - `rng_algorithm_version`
  - `rng_stream_schema_version`
  - `content_manifest_digest`
  - `system_version_bundle`
  - `created_at_tick`

RNG draw record:
- `RngDrawRecord`
  - `run_id`
  - `stream_key`
  - `draw_index`
  - `u32_value`
  - `callsite_code`
  - `event_id`
  - `cursor_before`
  - `cursor_after`

Cursor snapshot:
- `RngCursorSnapshot`
  - `run_id`
  - `checkpoint_id`
  - `rng_cursors{stream_key: next_draw_index}`
  - `manifest_digest`

Replay verify request:
- `VerifyReplayRequest`
  - `run_id`
  - `manifest`
  - `input_event_stream[]`
  - `rng_draw_records[]` (optional when regenerating expected records)

Replay verify response:
- `VerifyReplayResult`
  - `status` (`match` | `mismatch` | `invalid_manifest`)
  - `first_mismatch?`
    - `stream_key`
    - `draw_index`
    - `expected_u32`
    - `actual_u32`
    - `callsite_code`

### Interactions with Other Systems

1) Turn State & Rules Engine (hard upstream/adjacent)
- TSRE ensures RNG-consuming actions occur in deterministic commit order.
- TSRE commit ids enforce idempotent RNG consumption.

2) Map/Pathing System (hard downstream consumer)
- Uses `map.*` streams for graph generation, node typing, encounter pick routing, and event variants.

3) Reward Draft System (hard downstream consumer)
- Uses `reward.*` streams for weighted offer sampling.
- Must log stream/index in reward generation trace.

4) Enemy Encounter System (hard downstream consumer)
- Uses `encounter.*` streams for composition, weighted intents, targeting randomization, and reinforcement checks.

5) Effect Resolution Pipeline (hard downstream consumer)
- Uses `combat.effect.proc`, `combat.effect.retarget`, `combat.status_chance` for proc/chance/retarget branches.

6) Run Save/Resume (hard downstream/adjacent)
- Persists and restores cursor snapshots + determinism manifest atomically.

7) Telemetry/Debug Hooks (hard downstream)
- Consumes RNG draw events and mismatch diagnostics.

## Formulas

Notation:
- `u32(x)` = `x >>> 0`
- `imul(a,b)` = `Math.imul(a,b)`
- `FNV1a32(bytes)` = canonical 32-bit FNV-1a over UTF-8 bytes

1) Seed derivation

`seed_material = canonical_join("|", [profile_id, mode_id, difficulty_tier, run_ordinal, player_seed_input_or_empty, content_manifest_digest])`

`seed_root_u32 = FNV1a32(seed_material)`

`seed_variant_u32 = FNV1a32(seed_material || "|variant|" || rng_algorithm_version)`

2) Stream hash

`stream_hash_u32 = FNV1a32(stream_key_normalized)`

3) Canonical u32 draw function (algorithm version `rng_v1_imul32`)

Given `seed_root_u32`, `seed_variant_u32`, `stream_hash_u32`, and `draw_index`:

`x0 = u32(seed_root_u32 + imul(stream_hash_u32, 0x9E3779B1) + imul(draw_index, 0x85EBCA77) + seed_variant_u32)`
`x1 = u32(x0 ^ (x0 >>> 16))`
`x2 = u32(imul(x1, 0x85EBCA6B))`
`x3 = u32(x2 ^ (x2 >>> 13))`
`x4 = u32(imul(x3, 0xC2B2AE35))`
`u32_out = u32(x4 ^ (x4 >>> 16))`

`DrawU32At(stream_key, draw_index) = u32_out`

4) Cursor-consuming draw

`value = DrawU32At(stream_key, next_draw_index)`
`next_draw_index = next_draw_index + 1`

5) Uniform bounded integer without modulo bias

For span `n = max_inclusive - min_inclusive + 1` (`n >= 1`):

`threshold = (2^32 mod n)`

Loop:
- `r = DrawU32Next(stream_key)`
- if `r < threshold`, reject and continue
- else `result = min_inclusive + (r mod n)`

All rejection draws are consumed and therefore replay-stable.

6) Determinism digest extension (RNG)

`rng_hash_next = FNV1a64(rng_hash_prev || stream_key || draw_index || u32_value || callsite_code || event_id)`

This digest composes with map/combat/reward digests for full-run replay validation.

## Edge Cases

1) Unknown stream key requested
- Dev/test: hard fail `ERR_RNG_STREAM_UNKNOWN`.
- Release: deterministic hard reject of caller action; cursor unchanged.

2) Cursor missing on resume
- Treat as corrupted snapshot.
- Enter Invalid state with `ERR_RNG_CURSOR_MISSING`.

3) Cursor overflow (`next_draw_index > UINT32_MAX`)
- Hard fail run continuation `ERR_RNG_CURSOR_OVERFLOW`.
- This should be unreachable in MVP pacing but remains guarded.

4) Manifest mismatch on resume
- If any pinned version differs, reject resume as incompatible replay context.

5) Duplicate commit event replay
- Idempotency guard returns existing result and does not consume new RNG draws.

6) Cross-tab/browser concurrent writes
- Persistence layer must enforce single-writer lock per run id.
- Loser tab transitions to read-only observer state.

7) Rejection-sampling loops in narrow ranges
- Bounded expected iterations remain low; still deterministic.
- Perf telemetry captures abnormal rejection spikes.

8) Callsite stream misuse (wrong stream key for subsystem)
- Content/runtime validation fails in dev CI.
- Replay verifier flags callsite/stream mismatch.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Turn State & Rules Engine | Adjacent authority | Hard | Provides deterministic commit ordering and idempotency keys that gate RNG consumption. |
| Run Save/Resume | Persistence | Hard | Atomically stores/restores `RunDeterminismManifest` and per-stream cursor map. |
| Map/Pathing System | Consumer | Hard | Consumes `map.*` streams and logs draw indices in map generation traces. |
| Reward Draft System | Consumer | Hard | Consumes `reward.*` streams and records draw traces per checkpoint. |
| Enemy Encounter System | Consumer | Hard | Consumes `encounter.*` streams for composition/intent/targeting/reinforcement. |
| Effect Resolution Pipeline | Consumer | Hard | Consumes `combat.*` streams for proc/chance/retarget outcomes. |
| Telemetry/Debug Hooks | Downstream analytics | Hard-adjacent | Ingests draw records and mismatch diagnostics. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `rng_algorithm_version` | enum | `rng_v1_imul32` | versioned only | N/A | Migration complexity |
| `rng_stream_schema_version` | int | 1 | increment on breaking stream layout changes | Hidden coupling if not bumped | Excessive migration churn |
| `rng_trace_capture_mode` | enum | `sampled` | `off/sampled/full` | Harder mismatch forensics | Log volume/perf overhead |
| `rng_trace_sample_rate` | float | 0.10 | 0.01-1.00 | Sparse forensic coverage | Storage overhead |
| `max_replay_trace_records` | int | 200000 | 50000-1000000 | Truncated investigations | Memory/storage pressure |
| `single_writer_lock_timeout_ms` | int | 2000 | 500-5000 | False lock contention | Slow takeover on crash |

Governance:
- Any change to algorithm or stream schema requires version bump + replay fixture regeneration.
- Mid-run manifest mutation is forbidden.

## Visual/Audio Requirements

Visual:
- Seed/share panel displays:
  - run seed code
  - determinism manifest digest (short form)
  - replay verification status badge (dev/debug modes)
- Debug overlay can show per-stream cursor heads.

Audio:
- No gameplay SFX tied directly to RNG service.
- Optional subtle debug cue on determinism hard-fail in dev builds only.

## UI Requirements

1) Seed transparency
- Players can copy run seed/share code.
- Seed display must map to immutable run manifest.

2) Resume integrity messaging
- If resume fails due manifest mismatch/cursor corruption, show explicit reason text (no generic “load failed”).

3) Replay tooling (debug)
- UI can load replay and show first mismatch location (`stream_key`, `draw_index`, callsite).

4) No hidden reroll affordances
- UI flows must not implicitly regenerate random outcomes after commit.

## Acceptance Criteria

1) Cross-browser deterministic parity
- Fixed fixture suite yields byte-identical draw outputs and cursor advancement on Chrome/Firefox/Safari.

2) Stream isolation guarantee
- Adding/removing draws in one stream does not change outputs of other streams for same seed and manifest.

3) Save/load cursor parity
- Save/load at any checkpoint restores exact per-stream `next_draw_index` map.

4) Version pinning enforcement
- In-progress runs reject incompatible content/version manifests.

5) Replay mismatch localization
- Verifier reports first mismatch with exact stream/index/callsite within one pass.

6) Idempotent commit safety
- Duplicate commit events do not consume additional draws.

7) Performance target
- `DrawU32Next` median < 50 ns equivalent in desktop browser benchmark harness (excluding logging), and replay validation of 100k draws < 150 ms on target desktop profile.

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `rng_draw_calls_total{stream_key}`
- `rng_cursor_advance_total{stream_key}`
- `rng_unknown_stream_total{stream_key}`
- `rng_resume_manifest_mismatch_total`
- `rng_replay_verify_runs_total{status}`
- `rng_replay_first_mismatch_total{stream_key,callsite_code}`

Debug tools:
- Dump deterministic manifest for active run.
- Dump cursor snapshot at checkpoint.
- Recompute expected draw for `(stream_key, draw_index)`.
- Diff two replay traces and stop at first divergence.

## Open Questions

1) Should public seed share code include full manifest hash or only player-seed + compatibility tag?
2) Do we want optional ranked-mode signed replay transcripts in MVP+1?
3) Should long-run mode introduce cursor widening to uint64 in a future algorithm version?