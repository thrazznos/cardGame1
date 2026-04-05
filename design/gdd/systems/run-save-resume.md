# Run Save/Resume System

> Status: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-05
> Implements Pillars: Readable Tactical Clarity; High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats
> Upstream References: design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/deck-lifecycle.md, design/gdd/systems/map-pathing.md, design/gdd/systems/reward-draft.md, design/gdd/systems/relics-passive-modifiers.md, design/gdd/systems/rng-seed-run-generation.md, design/gdd/systems/profile-progression-save.md

## Overview

Run Save/Resume System (RSR) is the canonical persistence authority for in-progress run state in Dungeon Steward vertical slice.

RSR guarantees that disconnects, browser closes, refreshes, tab crashes, and short offline interruptions can resume an active run without rerolling outcomes or corrupting deterministic flow.

RSR governs:
- What run state is persisted and when.
- Atomic checkpoint commit semantics.
- Deterministic restore of combat/map/reward/relic context.
- RNG cursor and index integrity across resume.
- Idempotent recovery under duplicated commits/retries.
- Compatibility boundaries with profile progression save.

Core promise:
- Same run snapshot + same determinism manifest + same input continuation => identical outcomes after resume.

Out of scope (MVP/VS):
- Manual rewind to arbitrary historical checkpoints.
- Player-facing branch-select rollback after a committed choice.
- Cross-account merge of active runs.

## Player Fantasy

The player fantasy is continuity and trust:
- “If I close my browser mid-run, I return exactly where I left off.”
- “I never lose a run to a random disconnect.”
- “The game does not reroll rewards, map nodes, or combat outcomes when I resume.”

The system must avoid:
- Double-application of actions after reconnect.
- Phantom cursor jumps that alter randomness.
- UI mismatch where screen state and simulation state disagree.

## Detailed Design

### Core Rules

1) One active run snapshot authority per run_id
- RSR owns authoritative persisted `ActiveRunSnapshot` for each active `run_id`.
- Runtime memory state is not authoritative until checkpoint commit succeeds.

2) Commit-point persistence only
- RSR persists only at deterministic commit boundaries, never at animation/frame boundaries.
- Canonical commit boundaries:
  - map/path commit accepted,
  - node entry checkpoint committed,
  - combat commit boundary (TSRE phase-safe points),
  - reward offer generated/presented,
  - reward choice committed,
  - run completion/failure transition.

3) Atomic snapshot + cursor persistence
- Snapshot write is atomic across:
  - run gameplay state,
  - RNG cursor map,
  - determinism manifest reference,
  - last committed input/event identity.
- Partial write visibility is forbidden.

4) Idempotent commit semantics
- Every mutating checkpoint write uses `run_commit_event_id`.
- Duplicate `run_commit_event_id` with identical payload returns prior success result.
- Duplicate `run_commit_event_id` with payload mismatch is rejected (`ERR_RUN_COMMIT_ID_PAYLOAD_MISMATCH`).

5) Deterministic RNG integrity
- RSR stores full `rng_cursors{stream_key: next_draw_index}` required by RSGC.
- Resume restores cursors exactly; no stream rewinds or catch-up rerolls.
- Resume is rejected if required stream cursor is missing/corrupt.

6) TSRE restore lock discipline
- If snapshot captured in combat, resume enters `ResolveLock`-safe restoration path before accepting inputs.
- Player input remains blocked until TSRE state hash and queue integrity checks pass.

7) Cursor/index integrity is explicit
- RSR stores and validates all monotonic indices used by deterministic systems:
  - TSRE `enqueue_sequence_id`, event log index, turn index, phase/sub-state index.
  - DLS `creation_seq_id`, shuffle counters, zone ordering.
  - RDS draft instance ids and channel selection indices.
  - MPS traversal commit sequence and current node pointer.
  - RPM passive registration sequence/cooldown counters.

8) Profile/run boundary isolation
- Active run stores `profile_commit_seq_at_run_start` and `RunStartProfileView` digest.
- Mid-run profile progression writes (PPS) do not mutate active run legality/generation.
- Resume uses bound run-start profile projection for deterministic continuity.

9) One-shot reward and path decisions remain one-shot
- Resume cannot reopen a committed reward choice or committed map transition.
- Uncommitted reward offers may reopen exactly in prior offer state without reroll.

10) Safe fallback policy
- If integrity verification fails, run enters `ResumeBlocked` with reason code and support-safe UX.
- No silent auto-repair that would mutate deterministic outcomes.

### States and Transitions

Run persistence lifecycle states:
- NoActiveRun
- ActiveInMemory
- CheckpointPendingWrite
- CheckpointCommitted
- SuspendedPersisted
- ResumeValidating
- ResumeReady
- ResumeBlocked
- RunCompletedArchived

Primary transitions:
- NoActiveRun -> ActiveInMemory (run start)
- ActiveInMemory -> CheckpointPendingWrite (commit boundary reached)
- CheckpointPendingWrite -> CheckpointCommitted (atomic write success)
- CheckpointCommitted -> ActiveInMemory (continue play)
- CheckpointCommitted -> SuspendedPersisted (app background/close/disconnect)
- SuspendedPersisted -> ResumeValidating (resume request)
- ResumeValidating -> ResumeReady (all integrity checks pass)
- ResumeValidating -> ResumeBlocked (manifest/hash/cursor/index mismatch)
- ResumeReady -> ActiveInMemory (runtime restored)
- ActiveInMemory -> RunCompletedArchived (run end)

Invalid transitions (hard reject):
- SuspendedPersisted -> ActiveInMemory (without ResumeValidating)
- ResumeBlocked -> ActiveInMemory (without explicit operator recovery path)
- RunCompletedArchived -> ActiveInMemory

Combat-local resume states (if snapshot captured mid-combat):
- CombatSnapshotLoaded
- TSREStateRehydrated
- QueueRebound
- DeckZonesRebound
- RelicPassivesRebound
- CombatIntegrityVerified
- InputUnlocked

Required order:
- CombatSnapshotLoaded -> TSREStateRehydrated -> QueueRebound -> DeckZonesRebound -> RelicPassivesRebound -> CombatIntegrityVerified -> InputUnlocked

### Snapshot Scope and Data Contracts

Canonical persisted object:
- `ActiveRunSnapshot`
  - `snapshot_schema_version`
  - `run_id`
  - `run_state` (`map`, `combat`, `reward`, `event`, `completed`, `failed`)
  - `checkpoint_seq` (monotonic per run)
  - `last_run_commit_event_id`
  - `profile_commit_seq_at_run_start`
  - `run_start_profile_view_digest`
  - `run_determinism_manifest_digest`
  - `rng_cursors{stream_key: next_draw_index}`
  - `map_state_blob`
  - `combat_state_blob`
  - `deck_state_blob`
  - `relic_state_blob`
  - `reward_state_blob`
  - `encounter_state_blob` (if active encounter node)
  - `ui_projection_hints` (non-authoritative)
  - `snapshot_hash`
  - `created_at_ms`, `updated_at_ms`

Authoritative sub-state requirements:

1) Map/Pathing payload (from MPS)
- `map_instance_id`
- `nodes[]`, `edges[]` (or immutable ref + digest)
- `current_node_id`
- `resolved_node_ids[]`
- `revealed_node_ids[]`
- `lock_state_map`
- `pending_checkpoint_events[]`
- `map_traversal_commit_seq`

2) Combat payload (from TSRE/ERP/EES)
- `combat_instance_id`
- `phase`, `sub_state`, `turn_index`, `active_actor`
- `resolve_lock` flag
- `resolve_queue[]` with canonical order keys
- `enqueue_sequence_id_next`
- `event_log_next_index`
- `combat_state_hash_current`
- `pending_state_actions[]`
- `last_commit_id_applied`

3) Deck payload (from DLS)
- zone arrays preserving order:
  - `draw_pile[]`, `hand[]`, `discard_pile[]`, `exhaust_pile[]`, `limbo_pending_resolve[]`
- `instance_registry`
- `shuffle_count_turn`, `shuffle_count_combat`
- `creation_seq_id_next`
- `generated_counters`

4) Reward payload (from RDS)
- `draft_instance_id` (if draft active)
- `reward_checkpoint_id`
- `channel_offers[]` in stable presented order
- `selected_entry_ids[]`
- `draft_state` (`presented`, `committed`, `closed`)
- `fallback_used_flags[]`

5) Relic payload (from RPM)
- `owned_relic_instances[]`
- `passive_registration_table`
- `registration_seq_next`
- per-trigger runtime state:
  - cooldown counters,
  - per-turn caps consumed,
  - suppression flags,
  - one-shot exhausted flags

6) RNG/manifest payload (from RSGC)
- full `RunDeterminismManifest` reference/digest:
  - `rng_algorithm_version`
  - `rng_stream_schema_version`
  - `content_manifest_digest`
  - `system_version_bundle`
- complete cursor map for all streams used to date.

### Restore Pipeline (Deterministic)

1) Load latest committed snapshot by `run_id`.
2) Validate schema version/migrations.
3) Validate manifest digest matches snapshot manifest payload.
4) Validate required RNG stream cursor presence and non-negative indices.
5) Rehydrate map state.
6) Rehydrate encounter/combat state (if applicable).
7) Rehydrate deck zones/registry and enforce single-zone invariant.
8) Rehydrate relic runtime registrations and caps.
9) Rehydrate reward draft state exactly as stored.
10) Recompute integrity digests and compare against stored snapshot hash chain.
11) If all pass, transition to `ResumeReady` and unlock legal input surface for current run_state.

Resume validation hard gates:
- `ERR_RESUME_SCHEMA_UNSUPPORTED`
- `ERR_RESUME_MANIFEST_MISMATCH`
- `ERR_RESUME_RNG_CURSOR_MISSING`
- `ERR_RESUME_QUEUE_ORDER_INVALID`
- `ERR_RESUME_ZONE_INTEGRITY`
- `ERR_RESUME_REWARD_STATE_INVALID`
- `ERR_RESUME_HASH_MISMATCH`

### Interactions with Other Systems

1) Turn State & Rules Engine (hard)
- RSR stores TSRE phase/sub-state/queue and deterministic ordering metadata.
- TSRE supplies `snapshot_state()` and `rehydrate_state(snapshot)` contracts.
- RSR resume unlock requires TSRE integrity check pass.

2) Deck Lifecycle System (hard)
- RSR persists full zone ordering + instance registry.
- DLS validates zone invariants during rehydrate.
- Any zone corruption blocks resume.

3) Map/Pathing System (hard)
- RSR persists map graph state, reveal and lock states, current node pointer, traversal seq.
- Resume must never regenerate map for an existing run.

4) Reward Draft System (hard)
- RSR stores active draft instance and offer ordering.
- Resume reopens same offer state when uncommitted; committed selections remain committed.
- No reroll on resume.

5) Relics/Passive Modifiers (hard)
- RSR persists runtime relic instance state including per-turn/per-combat counters and suppression/exhaustion.
- Registration sequence continuity is required to avoid trigger reorder drift.

6) RNG/Seed & Run Generation Control (hard)
- RSR persists and restores full cursor map atomically with gameplay snapshot.
- RSR enforces manifest pinning continuity.

7) Profile Progression Save (hard-adjacent)
- RSR binds run to run-start profile seq/digest.
- PPS updates during run do not mutate active run snapshot legality.
- Run-end progression writes occur after run completion boundary, outside active-run determinism envelope.

8) UI Systems (hard downstream)
- UI reads resume status (`validating`, `blocked`, `ready`) and reason codes.
- UI cannot bypass resume validation gates.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a), b)`
- `R_e`: committed run mutations/sec (EWMA over 60s, floor 0.1)
- `B_s`: mean compressed snapshot bytes
- `B_d`: mean compressed delta bytes
- `W_max`: write budget bytes/min
- `L_t`: allowed time-progress loss (sec)
- `L_e`: allowed mutation-loss count
- `RTT95`: backend RTT p95 (0 for local-only)
- `V95`: local verify+deserialize p95
- `Q_free`: available browser quota bytes

1) Snapshot cadence (loss + budget constrained)

Base loss target interval:
`I_base = min(3 * L_t, max(10, L_e / R_e))`

Budget floor:
`I_budget = 60 * B_s / max(1, (W_max - 60 * R_e * B_d))`

Final cadence:
`I_snap = clamp(I_min, I_max, max(I_base, I_budget))`

Browser-first defaults:
- `L_t=5s`, `L_e=3`
- `I_min=12s`, `I_max=90s`
- Typical effective cadence: ~20s in combat, ~45s on map/hub.

2) Delta journal window (bounded replay)

Time window:
`W_j_time = clamp(20, 180, max(2 * I_snap, 6 * L_t, 4 * RTT95 + 10))`

Count window:
`W_j_count = clamp(64, 512, ceil(W_j_time * max(R_e, 1)))`

Replay cap:
`ReplayCap = min(W_j_count, 240)`

Operational rule:
- If journal tail exceeds `W_j_count`, force snapshot and prune older deltas.
- Delta apply is idempotent by `op_id`; duplicate `op_id` is no-op.

3) Resume timeout policy

Soft timeout:
`T_soft = clamp(4, 20, max(2 * RTT95 + V95, 6))`

Hard timeout:
`T_hard = clamp(10, 45, 2.5 * T_soft)`

Lease TTL:
`LeaseTTL = max(T_hard + 5, 30)`

Heartbeat:
`LeaseHeartbeat = LeaseTTL / 3`

Defaults: `T_soft=8s`, `T_hard=25s`, `LeaseTTL=30s`.

4) Integrity and rollback checks

Delta hash chain:
`delta_hash_i = H(run_id || checkpoint_seq || delta_seq || op_id || payload_hash || prev_hash || schema_v)`

Checkpoint header integrity:
- stores `checkpoint_hash`, `tip_delta_hash`, `checkpoint_seq`, `schema_v`.

Resume-ready predicate:
`resume_ready = schema_ok * checkpoint_hash_ok * delta_chain_ok * seq_monotonic_ok * invariants_ok`

Rollback guard:
- Persist `max_seen_checkpoint_seq` separately.
- Reject lower seq loads unless explicit user-acknowledged recovery path.

Any integrity failure => block economy/progression writes and enter controlled recovery flow.

5) Storage budget limits

Per-profile budget:
`Budget_profile = clamp(32MB, 256MB, 0.20 * Q_free)`

Per-active-run budget:
`Budget_run = clamp(2MB, 16MB, 0.15 * Budget_profile)`

Allocation:
- snapshots: `0.60 * Budget_run`
- deltas: `0.35 * Budget_run`
- metadata/index/hash: `0.05 * Budget_run`

Snapshot retention count:
`N_snap = clamp(2, 8, floor((0.60 * Budget_run) / B_s))`

Prune order on budget pressure:
1. completed/abandoned runs oldest-first
2. snapshots older than newest `N_snap`
3. deltas fully covered by newest valid snapshot

Never prune active run below safety floor:
- latest 2 valid snapshots (current + LKG)
- delta tail sufficient for `min(W_j_count, ReplayCap)`.

## Edge Cases

1) Browser closes during atomic write
- Expected: on reload, system observes pre-state or post-state snapshot only; no partial snapshot accepted.

2) Disconnect after server accepted commit but before client ack
- Expected: resume uses idempotency query/path by `run_commit_event_id`; no double-apply.

3) Duplicate commit delivery on reconnect
- Expected: duplicate classified and ignored (or prior result returned) with no cursor drift.

4) Snapshot captured during TSRE ResolveLock
- Expected: resume restores same lock/sub-state, drains/resumes deterministically, and only then unlocks input.

5) Reward screen open, no pick yet, app closes
- Expected: same offer panel resumes with identical entry order and pick availability.

6) Reward pick submitted twice due to retry
- Expected: one committed choice only; second submit idempotent duplicate.

7) Map transition committed but node-entry animation not finished before close
- Expected: resume at committed node entry state, not pre-commit node.

8) Relic cooldown/per-turn cap at boundary
- Expected: counters restore exactly; no free extra trigger usage after resume.

9) Deck limbo card present at snapshot
- Expected: limbo zone restored and TSRE/DLS pipeline resolves destination per pending state; no card duplication.

10) Missing RNG cursor for a previously used stream
- Expected: resume blocked (`ERR_RESUME_RNG_CURSOR_MISSING`) and run not continued silently.

11) Profile progression changed in another tab mid-run
- Expected: active run remains bound to run-start profile view; new profile state applies only to future runs.

12) Snapshot schema migration required at resume
- Expected: deterministic migration pipeline executes before validation; failure enters `ResumeBlocked`.

13) Multi-tab same run resumed concurrently
- Expected: one writer lock holder proceeds; stale tab becomes read-only observer until refreshed.

14) Corrupt map current_node_id not in node set
- Expected: resume blocked (`ERR_RESUME_MAP_POINTER_INVALID`).

15) Event log index mismatch with TSRE queue metadata
- Expected: resume blocked (`ERR_RESUME_EVENT_INDEX_MISMATCH`).

## Dependencies

Hard upstream dependencies:
- Turn State & Rules Engine
- Deck Lifecycle System
- Map/Pathing System
- Reward Draft System
- Relics/Passive Modifiers
- RNG/Seed & Run Generation Control
- Profile Progression Save (run-boundary semantics)

Hard downstream dependents:
- Combat UI/HUD (resume gating)
- Map & Node UI (resume location/render state)
- Reward UI surfaces (offer reopen semantics)
- Telemetry/Debug tooling

Integration contracts (MVP/VS):
- `SaveRunCheckpoint(run_id, checkpoint_payload, run_commit_event_id, expected_checkpoint_seq?) -> SaveResult`
- `LoadActiveRun(run_id) -> ActiveRunSnapshot|none`
- `ValidateRunSnapshot(snapshot) -> ValidationResult`
- `ResumeRun(run_id) -> ResumeResult {ready|blocked, reason_codes[], restored_state_ref}`
- `GetRunCommitStatus(run_id, run_commit_event_id) -> {unknown|committed|payload_mismatch}`

Contract invariants:
- Save is atomic.
- Save is idempotent by `run_commit_event_id`.
- Resume does not mutate authoritative state unless explicit repair/migration path is executed and committed.

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `L_t` | sec | 5 | 3-15 | Larger loss window if raised too high | Excessive writes if too low |
| `L_e` | int | 3 | 1-8 | More mutation loss in crash path | Write churn/checkpoint thrash |
| `I_min` | sec | 12 | 8-20 | May checkpoint too often when very low | Delayed safety floor when too high |
| `I_max` | sec | 90 | 45-180 | More churn if too low | Long stale intervals if too high |
| `W_max` | bytes/min | 262144 | 131072-1048576 | Save lag under heavy mutation | Quota pressure and battery/IO cost |
| `W_j_count` cap | int | 240 | 120-512 | Frequent forced snapshots/prune churn | Long replay times and wider corruption blast radius |
| `T_soft` | sec | 8 | 4-20 | Premature user-facing timeout | UI hangs before recovery message |
| `T_hard` | sec | 25 | 10-45 | False recoveries on slower devices | Player waits too long on dead path |
| `LeaseTTL` | sec | 30 | 20-90 | Lease flapping/multi-tab races | Slow takeover/failover |
| `Budget_run` | MB | 6 | 2-16 | Frequent prune, less history | Quota exhaustion pressure |
| `N_snap` floor | int | 2 | 2-4 | Weak fallback resilience if <2 | Storage amplification if very high |
| `op_id_dedupe_ttl_h` | hours | 24 | 1-72 | Replay duplicate exploit window | Larger dedupe index/storage |
| `run_completion_idem_ttl_d` | days | 7 | 1-30 | Duplicate completion reward risk | Long-lived key index growth |

Browser-first preset:
- Standard: defaults above.
- Low-storage mode: `Budget_run=3MB`, `I_max=120s`, keep `N_snap` floor at 2.
- High-integrity mode: enforce strict hash/HMAC checks, `I_max=60s`, `T_hard=30s`.

## Visual/Audio Requirements

Visual requirements:
- Resume overlay states:
  - `Resuming...`
  - `Validating run state...`
  - `Resume blocked` with readable reason.
- Must display exact resume destination context:
  - map node name/type if on map,
  - turn/phase if in combat,
  - reward checkpoint label if in draft.
- On blocked resume, show deterministic error token for support (`run_id`, `checkpoint_seq`, reason_code primary).

Audio requirements:
- Soft confirmation cue when resume succeeds.
- Distinct warning cue for blocked resume.
- No combat/action SFX should play until `ResumeReady` is reached and input state is valid.

## UI Requirements

1) Launch flow integration
- If active run exists, main menu presents `Resume Run` primary action.
- If validation is running, disable conflicting actions.

2) Resume status panel
- Show current step: load, validate, rehydrate, ready.
- Surface high-level reason codes in player-friendly text.
- Expose expanded diagnostics in debug mode.

3) Combat resume UX
- Freeze input until TSRE integrity gate passes.
- Show phase/sub-state summary before unfreeze.

4) Reward resume UX
- If draft `presented`, reopen same offer with same order and disabled reroll.
- If committed, show resolution result state and continue.

5) Multi-tab conflict UX
- If lock denied/stale, show `Run open in another session` message and refresh action.

6) Recovery UX
- If resume blocked, provide:
  - retry validation,
  - export diagnostics (debug/dev),
  - abandon run (explicit confirmation and irreversible warning).

## Acceptance Criteria

1) Deterministic resume parity
- Given snapshot S at checkpoint C, resuming and continuing with identical inputs yields same:
  - final run outcome,
  - RNG draw records,
  - TSRE/combat/map/reward digests.
- Pass threshold: 1000 automated resume fixtures, 0 divergences.

2) No reroll on resume
- Map node outcomes, reward offers, encounter choices, and combat queue order remain unchanged by save/load cycle.
- Pass threshold: 100% of reroll-guard fixtures pass.

3) Cursor/index integrity
- All stored monotonic indices resume exactly with no duplicate/skip behavior.
- Pass threshold: 100% index continuity checks pass across stress tests.

4) Atomicity under fault injection
- Crash/power-loss simulation during write yields valid pre or post snapshot only.
- Pass threshold: 0 partial snapshots accepted across 10k injected faults.

5) Idempotency under retries
- Duplicate save and duplicate choice commits with same id do not double-apply.
- Pass threshold: 100% duplicate replay tests pass.

6) Safe blocked-resume behavior
- Corrupt/invalid snapshots are blocked with reason codes and no silent state mutation.
- Pass threshold: 100% corruption fixtures yield deterministic blocked state.

7) Multi-tab safety
- Concurrent resume/write attempts serialize correctly with no data corruption.
- Pass threshold: 0 race-condition corruption across stress matrix.

8) Profile boundary correctness
- Mid-run PPS updates do not alter active run generation/legality.
- Pass threshold: all bound-profile fixtures pass.

9) Performance envelope
- Resume validation + rehydrate P95 <= 2.0s on baseline desktop browser hardware.
- Snapshot write P95 <= 75ms at standard checkpoint payload sizes.

## Open Questions

1) Should vertical slice include optional encrypted local cache for offline-first resume, or defer to post-VS?
2) Do we persist full event log history in snapshot or only compact digests + tail window for diagnostics?
3) What is the exact support policy for blocked resume in release (auto-abandon after N failures vs manual-only)?
4) Should run checkpoint snapshots be mirrored server-side and local-side simultaneously in VS, or single authority first?
5) Is partial run export/import needed for QA tooling during VS or post-VS only?
6) Should mobile browser constraints require a lower `Budget_run`/`I_max` profile and more aggressive compaction?