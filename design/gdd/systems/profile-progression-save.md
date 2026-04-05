# Profile Progression Save

> **Status**: Approved (Canonical Contract)
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-05
> **Implements Pillar**: High Run Variety, Low Grind; Readable Tactical Clarity
> **Upstream References**: design/gdd/systems-index.md, design/gdd/systems/unlock-option-gating.md, design/gdd/systems/meta-hub-investment.md, design/gdd/systems/hub-ui.md

## Overview

Profile Progression Save (PPS) is the canonical persistence contract for browser-first meta progression.

PPS defines:
- Persistent snapshot schema for profile progression state.
- Event application model and deterministic projection rules.
- Idempotent write behavior under retries and duplicate delivery.
- Versioning and migration guarantees.
- Conflict handling for concurrent writers (multi-tab/multi-device).
- Run-boundary semantics for when profile changes do or do not affect an active run.

This document supersedes provisional persistence assumptions in:
- `design/gdd/systems/unlock-option-gating.md`
- `design/gdd/systems/meta-hub-investment.md`
- `design/gdd/systems/hub-ui.md`

Out of scope (MVP):
- Cloud account merge across different user identities.
- Arbitrary historical replay tools for players.
- Run-internal save/resume payload (handled by Run Save/Resume system).

## Player Fantasy

The player fantasy is:
- “My progress is reliable and never randomly lost.”
- “Buying or unlocking once is applied once, even if my browser stutters or refreshes.”
- “The game never feels inconsistent between hub, run setup, and run execution.”

The player should never experience:
- Double-spends from duplicate clicks.
- Unlocks disappearing after refresh.
- Mid-run reward behavior changing unpredictably due to background persistence updates.

## Detailed Design

### Design Goals (Optional)

1) Deterministic persistence
- Same starting snapshot + same ordered event list => same ending snapshot.

2) Idempotent writes
- Retried event submissions with same identity do not duplicate effects.

3) Browser-first robustness
- Works under refresh, reconnect, offline-read transitions, and multi-tab races.

4) Contract stability
- Schema and APIs are versioned and migration-safe.

5) Cross-system clarity
- UOG, MHIS, and Hub UI consume one canonical save contract.

### Core Rules

1) Canonical write model: event application onto snapshot projection
- Writes are represented as `ProfileEvent` records.
- Snapshot is authoritative projection result, not independent mutable truth.

2) Per-profile monotonic commit sequence
- Every successful commit increments `commit_seq` by exactly 1.
- `commit_seq` total order is canonical event application order for that profile.

3) Idempotency key is mandatory for all mutating calls
- Canonical idempotency identity: `event_id` (string UUID/ULID recommended).
- Duplicate `event_id` with identical canonical payload returns prior result.
- Duplicate `event_id` with different payload is rejected (`ERR_EVENT_ID_PAYLOAD_MISMATCH`).

4) Single-profile serialization guarantee
- PPS enforces one active write lock per profile.
- Concurrent callers serialize; only one commit is applied at a time.

5) Optimistic concurrency supported
- Mutating calls may include `expected_base_seq`.
- If supplied and not equal to current `commit_seq`, commit is rejected with conflict response.

6) No regression of permanent unlock truth in MVP
- `unlock_flags[key]` can transition `false/missing -> true`.
- Normal gameplay does not transition `true -> false`.

7) Atomic commit rule
- A commit is all-or-nothing across all affected fields.
- Partial field updates are invalid.

8) Canonical run-boundary rule
- Active run binds `profile_commit_seq_at_run_start`.
- Profile writes during run persist immediately for future use, but do not alter active run legality/reward generation behavior.
- Changes become gameplay-effective at next run start (except purely cosmetic/profile UI elements outside run).

9) Fail-safe baseline accessibility
- If profile load or migration fails, client enters read-only fallback.
- `base_set` remains playable via UOG fallback policy; non-base progression writes are blocked.

10) Deterministic timestamps policy
- Server/runtime timestamps are metadata only.
- Gameplay projection logic cannot branch on wall-clock timestamp values.

### Canonical Snapshot Schema

`ProfileProgressSnapshot`:
- `schema_version: int` (snapshot schema version)
- `profile_id: string`
- `commit_seq: int` (monotonic, starts at 0 for new profile)
- `created_at_ms: int`
- `updated_at_ms: int`
- `policy_versions: map<string,int>`
  - MVP keys:
    - `unlock_catalog_version`
    - `hub_investment_policy_version`

Progression projection fields:
- `unlock_flags: map<string,bool>`
- `unlock_counters: map<string,int>`
- `first_clear_flags: map<string,bool>`
- `seen_content: map<string,int>`
  - value = first-seen timestamp ms (or 1 if timestamp unavailable)

Hub projection fields:
- `hub_currency_balances: map<string,int>`
- `hub_investments_owned: map<string,int>`
- `hub_reward_bias_profile: map<string,float>`

Operational metadata:
- `last_applied_event_id: string|null`
- `read_only_fallback: bool`
- `fallback_reason_code: string|null`
- `integrity_hash: string` (optional MVP, required post-MVP)

Schema invariants:
- Missing maps are treated as empty during read/migration.
- All counters and currency balances are clamped to >= 0.
- Unknown top-level fields must be preserved when possible (forward-compat tolerant read).

### Canonical Event Model

`ProfileEventEnvelope`:
- `event_id: string` (idempotency key)
- `event_type: string`
- `event_version: int`
- `profile_id: string`
- `source_system: enum`
  - `uog`, `mhis`, `hub_ui`, `run_end`, `debug`, `migration`
- `source_ref: string|null` (optional correlation, e.g. run_id or purchase intent id)
- `occurred_at_ms: int` (metadata)
- `payload: object`
- `payload_hash: string` (canonical hash used for mismatch detection)

MVP event types:
- `RUN_COMPLETED`
  - payload: `run_id`, `result_tier`, `counters_delta`, `seen_content_ids[]`
- `FIRST_CLEAR_GRANTED`
  - payload: `milestone_key`
- `UNLOCK_GRANTED`
  - payload: `unlock_keys[]`, `reason`
- `HUB_CURRENCY_GRANTED`
  - payload: `currency_id`, `amount`, `reason`
- `HUB_INVESTMENT_PURCHASED`
  - payload: `investment_id`, `cost_currency_id`, `cost_amount`, `rank_delta`, `grant_unlock_keys[]`, `bias_delta`
- `HUB_BIAS_SET_OR_DELTA`
  - payload: `mode` (`set`/`delta`), `tag_values`
- `SEEN_CONTENT_RECORDED`
  - payload: `content_ids[]`

Event authoring constraints:
- Event payload must be self-sufficient for deterministic projection.
- Event type semantics are append/monotonic in MVP; destructive/reset events are disallowed except migration/debug contexts.

### Projection Rules (Deterministic)

Given snapshot `S` and event `E`, `Apply(S,E) -> S'`:

Generic:
- `S'.commit_seq = S.commit_seq + 1`
- `S'.updated_at_ms = now_ms`
- `S'.last_applied_event_id = E.event_id`

Field update rules:
- Unlock flags:
  - For each `k` in unlock grant events: `unlock_flags[k] = true`
- Unlock counters:
  - `unlock_counters[key] = max(0, prior + delta)`
- First clear:
  - `first_clear_flags[milestone] = true`
- Seen content:
  - Insert if absent; never remove in MVP
- Currency:
  - `hub_currency_balances[c] = max(0, prior + delta)`
- Investment ownership:
  - `hub_investments_owned[id] = min(max_rank(id), prior + rank_delta)`
- Bias profile:
  - If delta mode: add and clamp by policy caps
  - If set mode: overwrite listed tags only

Rejected projection cases:
- Currency underflow attempt after purchase cost check.
- Unknown investment in purchase event.
- Event payload violating schema/type constraints.

### Read/Write API Contracts

Read API:
- `GetProfileProgressSnapshot(profile_id) -> ProfileProgressSnapshot`

Write API:
- `ApplyProfileEvents(profile_id, events[], expected_base_seq|null) -> ApplyEventsResult`

`ApplyEventsResult`:
- `accepted: bool`
- `reason_codes[]`
- `starting_commit_seq: int`
- `ending_commit_seq: int`
- `applied_event_ids[]`
- `duplicate_event_ids[]`
- `rejected_event_ids[]`
- `snapshot: ProfileProgressSnapshot` (post-apply or current authoritative on reject)

Idempotency query API (optional MVP, recommended):
- `GetEventCommitStatus(profile_id, event_id) -> EventStatus`
- `EventStatus` in `{unknown, committed, rejected_payload_mismatch}`

Run-boundary helper API:
- `CreateRunStartProfileView(profile_id) -> RunStartProfileView`
- Includes:
  - `profile_id`
  - `bound_commit_seq`
  - `unlock_projection`
  - `hub_modifier_projection`
  - `created_at_ms`

Contract mapping rule for MHIS/HUI:
- `purchase_event_id` MUST equal persisted `event_id` for `HUB_INVESTMENT_PURCHASED`.

### Idempotency and Retry Semantics

1) Exactly-once effect, at-least-once delivery compatibility
- Clients may retry same event safely until acknowledged.

2) Batch behavior
- Events are evaluated in provided order.
- Each event independently classified as applied/duplicate/rejected.
- If any event is rejected for schema/validation reasons, default MVP policy is fail-fast for remaining unapplied events in that call.

3) Duplicate rules
- Duplicate same payload hash: `duplicate_event_ids` and no state delta.
- Duplicate with different payload hash: hard reject (`ERR_EVENT_ID_PAYLOAD_MISMATCH`).

4) Retriable errors
- Lock contention/timeouts can be retried with same event IDs.

### Conflict Handling (Browser-First)

Conflict classes:
1) Sequence conflict (`ERR_EXPECTED_SEQ_CONFLICT`)
- Trigger: caller provided stale `expected_base_seq`.
- Response includes authoritative snapshot and current `commit_seq`.
- Caller must re-evaluate intent against latest state.

2) Duplicate conflict (`DUPLICATE_EVENT`)
- Trigger: event already committed.
- Treated as successful logical outcome; no extra mutation.

3) Payload mismatch conflict (`ERR_EVENT_ID_PAYLOAD_MISMATCH`)
- Trigger: reused event_id with different payload.
- Non-retriable for that event_id; caller must generate new id for new intent.

4) Business-rule conflict (`ERR_INSUFFICIENT_FUNDS`, `ERR_ALREADY_OWNED`, etc.)
- Deterministic reject, no mutation.

Multi-tab recommendation (MVP implementation policy):
- Use `BroadcastChannel` (or equivalent) to publish newly observed `commit_seq` and invalidate stale local views.
- Tabs should reconcile against authoritative snapshot before allowing new writes after receiving newer seq.

### Versioning and Migration

Version axes:
- `schema_version` (snapshot shape)
- `event_version` per event type
- `policy_versions` for data-driven catalogs

Migration rules:
1) Migrators are pure deterministic functions `vN -> vN+1`.
2) Migration pipeline runs sequentially until current `schema_version`.
3) Unknown/missing optional fields default safely.
4) Migration never discards known progression truth without explicit mapped replacement.

Failure behavior:
- On migration failure:
  - set `read_only_fallback = true`
  - set `fallback_reason_code = ERR_MIGRATION_FAILED`
  - block writes except internal recovery/debug tooling
  - preserve original pre-migration payload for support/recovery

Compatibility guarantees:
- Additive fields: backward compatible reads required.
- Field rename/removal requires migration plus one-version compatibility bridge.

### Contract Supersession Matrix

This section is normative and replaces provisional assumptions in related docs.

1) Unlock & Option Gating
- Replace provisional `GetProfileProgress`/`ApplyProgressEvents` with:
  - `GetProfileProgressSnapshot`
  - `ApplyProfileEvents`
- Canonical fields consumed:
  - `unlock_flags`, `unlock_counters`, `first_clear_flags`, `seen_content`
- Run semantics replaced with bound run-start snapshot (`bound_commit_seq`).

2) Meta-Hub Investment
- Replace provisional shared envelope with canonical snapshot fields:
  - `hub_currency_balances`, `hub_investments_owned`, `hub_reward_bias_profile`
- Canonical purchase mapping:
  - `purchase_event_id == event_id`
- Conflict and idempotency behavior governed by this document.

3) Hub UI
- Replace provisional reconciliation assumptions with canonical primitives:
  - `commit_seq` as ordering token
  - idempotent event identity via `event_id`
  - read-only fallback flags: `read_only_fallback`, `fallback_reason_code`

### Interactions with Other Systems

1) Unlock & Option Gating (hard downstream consumer)
- Reads unlock-related projection fields from PPS.
- Must use run-bound `RunStartProfileView` for active-run determinism.

2) Meta-Hub Investment (hard downstream consumer)
- Emits purchase/currency events into PPS.
- Reads post-commit snapshot from PPS as authority.

3) Hub UI (hard downstream consumer)
- Uses PPS commit sequence and fallback flags for reconciliation and safe UX.

4) Reward Draft / Run Generation (hard-adjacent)
- Uses run-bound profile projection; not live-updated by mid-run profile writes.

5) Telemetry/Debug (soft MVP)
- Consumes commit outcomes, conflict reasons, migration failures.

## Formulas

Notation:
- `I(condition)` in {0,1}
- `max0(x)=max(0,x)`

1) Commit progression
`commit_seq' = commit_seq + I(commit_accepted)`

2) Idempotent effect indicator
`applies_mutation(event_id) = I(event_id_not_seen_before_with_same_hash)`

3) Currency update
`balance'[c] = max0(balance[c] + delta[c])`

4) Ownership rank update
`owned_rank'[i] = clamp(owned_rank[i] + rank_delta[i], 0, max_rank[i])`

5) Unlock monotonicity
`unlock_flags'[k] = unlock_flags[k] OR grant[k]`

6) Run-bound read consistency
`effective_profile_for_run(run_id) = snapshot_at_commit_seq(bound_commit_seq(run_id))`

## Edge Cases

1) Same event replayed after success
- Returns duplicate classification, no extra mutation.

2) Same event_id with changed payload due to client bug
- Reject with payload mismatch; emit high-severity telemetry.

3) Two tabs buy same investment concurrently
- One commit succeeds first; second resolves deterministically as duplicate/insufficient funds/already owned based on event identity and latest state.

4) Missing fields in legacy snapshot
- Treated as empty maps/defaults during migration.

5) Migration code throws
- Enter read-only fallback; preserve raw payload for recovery.

6) Local stale snapshot used for write
- If `expected_base_seq` stale, reject with conflict and include authoritative snapshot.

7) Unknown event_type in production
- Reject event, log `ERR_EVENT_TYPE_UNKNOWN`, no mutation.

8) Browser offline submit
- Caller may queue locally but PPS authority unchanged until successful apply.

9) Clock skew between clients
- Harmless to projection because timestamps are non-authoritative metadata.

10) Corrupt snapshot integrity hash (if enabled)
- Enter read-only fallback with `ERR_INTEGRITY_CHECK_FAILED`.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Storage Backend (IndexedDB/local adapter) | Upstream infra | Hard | Provides atomic per-profile write transaction and durable reads. |
| Unlock & Option Gating | Downstream | Hard | Reads unlock projection fields and run-bound profile views. |
| Meta-Hub Investment | Downstream | Hard | Writes purchase/currency events and reads authoritative post-commit state. |
| Hub UI | Downstream | Hard | Uses `commit_seq`, fallback flags, and idempotent event identity for UX reconciliation. |
| Reward Draft / Run Generation | Downstream adjacent | Hard-adjacent | Consumes run-bound profile projection for deterministic run behavior. |
| Telemetry/Debug | Adjacent | Soft MVP | Records conflict/migration/idempotency diagnostics. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `profile_write_lock_timeout_ms` | int | 1500 | 500-5000 | Excess retries under contention | UI waits feel frozen |
| `max_events_per_apply_call` | int | 64 | 8-256 | Too many round trips | Large batch validation latency |
| `dedupe_index_ttl_days` | int | 30 | 7-180 | Late retries may miss dedupe | Storage growth |
| `snapshot_autoflush_interval_ms` | int | 0 (every commit) | 0-5000 | More IO overhead | Risk window for crash loss |
| `fallback_read_cache_ttl_ms` | int | 5000 | 1000-30000 | Frequent reload churn | Stale UI perception |
| `max_migration_attempts_per_load` | int | 1 | 1-3 | Fewer self-heal attempts | Startup stalls/loops |

Governance:
- Knob changes must preserve deterministic projection and idempotency guarantees.
- Any change that allows double-spend or unlock regression is blocked.

## Visual/Audio Requirements

Visual:
- Non-intrusive status indicators for:
  - Saving
  - Save failed/read-only fallback
  - Reconciled after retry
- Debug builds may show `commit_seq` and last `event_id`.

Audio:
- No direct PPS-owned audio cues.
- PPS outcomes are consumed by UI systems which may play success/deny cues.

## UI Requirements

1) Snapshot authority labeling
- UI surfaces when data is authoritative vs stale cache.

2) Read-only fallback communication
- Clear banner/message when progression writes are disabled.

3) Retry-safe interactions
- UI actions that write progression must attach stable `event_id` and survive refresh.

4) Conflict recovery path
- On sequence conflict, UI reloads/merges using authoritative snapshot before re-enabling action.

## Acceptance Criteria

1) Deterministic projection
- Replaying identical ordered events from same base snapshot yields bitwise-equivalent projection fields.

2) Idempotency
- Duplicate delivery of any event does not duplicate spends/unlocks/counter gains.

3) Conflict correctness
- Stale `expected_base_seq` reliably returns conflict without partial mutation.

4) Migration safety
- Legacy snapshots with missing fields migrate without crash and preserve known progression state.

5) Fallback safety
- Migration/integrity failure enters read-only fallback and keeps base gameplay accessible.

6) Run-boundary determinism
- Mid-run profile commits do not alter active-run reward/unlock behavior.

7) Performance
- Apply 32 valid events in <= 2 ms p95 (excluding storage IO) on target desktop browser hardware.
- Snapshot load + schema migration check <= 3 ms p95 (excluding storage IO).

8) Supersession completeness
- UOG, MHIS, and Hub UI remove or mark obsolete their provisional PPS assumptions and reference this contract.

## Telemetry & Debug Hooks (Optional)

Counters:
- `pps_snapshot_load_total`
- `pps_apply_events_total`
- `pps_apply_events_rejected_total{reason}`
- `pps_duplicate_event_total`
- `pps_expected_seq_conflict_total`
- `pps_migration_attempt_total{from,to}`
- `pps_migration_failure_total{reason}`
- `pps_readonly_fallback_total{reason}`

Histograms:
- `pps_apply_batch_size`
- `pps_apply_logic_ms`
- `pps_snapshot_load_logic_ms`
- `pps_write_lock_wait_ms`

Debug tools:
- Dump snapshot by profile_id.
- Query event status by event_id.
- Validate projection hash from event journal replay.

## Open Questions

1) Should MVP retain full local event journal indefinitely or compact aggressively after snapshot checkpoints?
2) Should cloud sync be introduced pre-1.0, and if so, what is canonical conflict resolution policy across devices?
3) Is `integrity_hash` required in MVP or post-MVP only?
4) Should `seen_content` store first-seen timestamp or simple boolean/set projection only?
5) Do we need explicit API to fetch commit range diff (`from_seq..to_seq`) for advanced multi-tab reconciliation?