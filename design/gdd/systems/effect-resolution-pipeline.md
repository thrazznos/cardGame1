# Effect Resolution Pipeline

> Status: Approved
> Author: Hermes Agent
> Last Updated: 2026-04-04
> Implements Pillar: Sequencing Mastery Over Raw Stats; Readable Tactical Clarity
> Upstream References: design/gdd/systems/turn-state-rules-engine.md, design/gdd/card-data-definitions.md

## Overview

Effect Resolution Pipeline (ERP) is the deterministic executor for card and trigger effects once TSRE has decided ordering. TSRE decides when an item resolves; ERP decides exactly how state changes are computed and emitted.

MVP design constraints:
- Deterministic in browser runtime (no float drift dependence).
- Data-driven via card `effects[]` payload.
- Bounded/guarded against runaway trigger loops.
- Legible logs for QA and player-facing recap.

Scope split:
- TSRE: queue scheduling, phase legality, resolve lock, hard anti-loop budgets.
- ERP: pure effect computation, replacement handling, status stacking, clamps, deterministic rounding, failure codes.

## Player Fantasy

Players should feel that combo timing and effect text are reliable:
- "My trigger resolved first because I played/setup first, and the game explains it."
- "Poison stacks exactly as expected and never randomly rounds up/down."
- "If a replacement changed damage to shield, I can see where and why."

## Detailed Design

### Core Rules

1) Input contract from TSRE
- ERP entrypoint receives immutable `ResolveContext`:
  - `resolve_item_id`, `play_record_id`, `source_instance_id`, `order_key`
  - `effect_list[]` (from card or generated trigger)
  - `bound_targets[]` and target policy
  - `rng_stream_key_map` (`proc`, `retarget`, `status_chance` -> canonical `combat.*` stream keys)
  - `rng_cursor_start_snapshot`
  - `guardrail_snapshot` (remaining resolve budget, chain depth, spawn counters)

2) Deterministic local execution
- ERP resolves effects in declared `effects[]` order unless an effect explicitly spawns sub-effects.
- Sub-effects are appended to a local FIFO `micro_stack` owned by this resolve item.
- ERP never reorders across TSRE queue items.

3) Snapshot and lock-vs-live policy (MVP, resolved)
- Snapshot-at-commit for: source card params, source-owned scalar modifiers, declared targets, and effect list order.
- Live-at-apply for: target current HP/shield/status and battlefield occupancy.
- This hybrid policy is deterministic because both snapshot payload and live reads are derived from authoritative TSRE state at fixed resolve points.

4) Numeric model
- Combat-critical math uses fixed-point integer scale `SCALE = 1000`.
- Stored scalar values are `int32`/`int53-safe` JS numbers in scaled units.
- Final externally visible integer quantities (HP, shield, stacks) use deterministic rounding policy below.

5) Replacement effects are explicit and bounded
- Replacement effects can transform an operation before it applies (example: damage -> shield gain).
- Canonical replacement precedence comparator (resolved): `replacement_tier -> controller_apnap_index -> source_instance_id -> registration_seq`.
- Replacement chain has per-operation cap and dedup key to prevent recursion.

5) Status application is policy-driven
- Each status defines stack policy in data registry, not ad-hoc per card code.
- Default policy set (MVP): `add`, `refresh_duration`, `max_override`, `unique_instance`.

6) Readable event emission
- Every applied or canceled operation emits machine code + human-readable reason.
- Failed operations never silently disappear; they emit fizzle/reject events.

7) Determinism mismatch policy (aligned with TSRE)
- In test/replay mode: any determinism mismatch is a hard failure with trace dump.
- In release mode: continue session, emit telemetry flag `ERR_DETERMINISM_MISMATCH`, and preserve user-facing continuity.

### States and Transitions

Per-resolve-item ERP states:
- ValidatePayload
- BuildOperations
- ApplyReplacements
- ApplyOperations
- ApplyStateActionsHook
- EmitResult
- Done | Aborted

Transitions:
- ValidatePayload -> BuildOperations (valid)
- ValidatePayload -> Aborted (schema/runtime invalid)
- BuildOperations -> ApplyReplacements
- ApplyReplacements -> ApplyOperations
- ApplyOperations -> ApplyStateActionsHook
- ApplyStateActionsHook -> EmitResult
- EmitResult -> Done

Abort policy:
- Aborted item is considered resolved (consumes TSRE budget), emits deterministic error event, and returns no state mutation except telemetry-safe counters.

### Interactions with Other Systems

1) TSRE compatibility
- Uses TSRE `order_key` for traceability only; does not mutate queue ordering.
- Honors TSRE guardrails: resolve budget, chain depth, per-item trigger spawn caps.

2) Card Data compatibility
- Consumes `effects[].effect_id`, `effects[].params`, `effects[].stack_behavior`, `preview_priority`.
- Unknown `effect_id` is validation hard-fail in content pipeline; runtime fallback is deterministic no-op + error event.

3) Status registry
- ERP consults status metadata table:
  - `max_stacks`, `max_duration_turns`, `tick_timing`, `stack_policy`, `overflow_policy`.

4) Telemetry/debug
- Returns `EffectResult` with:
  - `state_deltas[]`, `generated_triggers[]`, `dropped_ops[]`, `error_codes[]`, `determinism_digest_fragment`.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a),b)`
- `Q(x) = round_half_even(x * SCALE)` fixed-point encoding
- `fromQ(q) = q / SCALE`

### 1) Base Magnitude Assembly

For an operation magnitude in scaled units:

`mag_q = base_q + stat_flat_q + tag_flat_q`
`mag_q = mag_q * (SCALE + stat_mult_q) / SCALE`
`mag_q = mag_q * (SCALE + vuln_mult_q - resist_mult_q) / SCALE`
`mag_q = clamp(mag_q, min_q, max_q)`

MVP defaults/safe ranges:
- `SCALE = 1000` (fixed)
- `min_q` usually `Q(0)` for non-negative ops
- `max_q` by op family:
  - damage/heal per op: `Q(9999)` safe `Q(1999)..Q(19999)`
  - shield gain per op: `Q(9999)` safe `Q(999)..Q(19999)`

Failure behavior:
- If intermediate exceeds int53 safe range, abort item with `ERR_NUMERIC_OVERFLOW`.
- If `min_q > max_q` from bad data, swap bounds and emit `WARN_CLAMP_BOUNDS_SWAPPED`.

### 2) Deterministic Finalization and Rounding

When converting scaled quantity to integer game stat:
- Damage/heal/shield/stacks use `round_half_even` (banker’s rounding).
- Duration turns use `floor`.
- Percent displays use `round_half_up` for UI only (non-authoritative).

`final_int = round_half_even(mag_q / SCALE)`
`final_int = clamp(final_int, final_min, final_max)`

Safe ranges:
- `final_max` per operation family default `9999`, safe `999..99999`.

Failure behavior:
- NaN/undefined impossible in int model; if encountered from corrupt payload, operation dropped with `ERR_INVALID_MAGNITUDE`.

### 3) Trigger Ordering Compatibility

ERP local execution key for operations within one resolve item:

`local_op_key = (op_phase_priority, replacement_pass_index, op_decl_index, micro_seq_id)`

Where:
- `op_phase_priority`: pre-op checks(0), apply(1), post-op hooks(2)
- `replacement_pass_index`: 0..N during replacement traversal
- `op_decl_index`: index in card `effects[]`
- `micro_seq_id`: monotonic local append id

Compatibility rule:
- `TSRE.order_key` remains dominant globally.
- `local_op_key` only orders within same queue item.

Failure behavior:
- If two ops collide completely (should not happen), tie-break with deterministic `op_runtime_id`; emit `WARN_LOCAL_KEY_COLLISION`.

### 4) Stack Behavior Formula (status)

Given existing status `S` on target with `(stacks_old, dur_old)` and incoming `(stacks_in, dur_in)`:

Policy `add`:
- `stacks_new = clamp(stacks_old + stacks_in, 0, stacks_cap)`
- `dur_new = max(dur_old, dur_in)`

Policy `refresh_duration`:
- `stacks_new = clamp(stacks_old + stacks_in, 0, stacks_cap)`
- `dur_new = dur_base_on_refresh`

Policy `max_override`:
- `stacks_new = max(stacks_old, stacks_in)`
- `dur_new = max(dur_old, dur_in)`

Policy `unique_instance`:
- If same `source_instance_id` exists, refresh existing; else create another instance until `instance_cap`.

MVP defaults/safe ranges:
- `stacks_cap` default 99, safe 20..999
- `dur_cap_turns` default 9, safe 3..30
- `instance_cap` default 4, safe 1..8

Failure behavior:
- Above caps => clamp with `WARN_STATUS_CLAMPED`.
- Unknown stack policy => reject operation `ERR_UNKNOWN_STACK_POLICY`.

### 5) Status Application Chance (deterministic RNG)

Optional for effects with chance:

`apply = (DrawU32Next(combat.status_chance) % 10000) < chance_bp`

- `chance_bp` in basis points [0..10000].
- Uses recorded RNG cursor for `combat.status_chance`; each roll increments cursor exactly once.

MVP defaults/safe ranges:
- `chance_bp` default from card params.
- Safe authored range: 500..10000 for meaningful statuses; allow full [0..10000].

Failure behavior:
- Out-of-range chance => clamp and emit `WARN_CHANCE_CLAMPED`.

### 5b) Invalid Target Policy Execution (deterministic)

Given initial candidate target set `T` sorted by stable `instance_id` ascending:

- Policy `fizzle`:
  - If bound target invalid at apply time -> operation skipped for that target.

- Policy `retarget_if_possible`:
  - Select first legal candidate in sorted `T`.
  - If none legal -> fizzle.

- Policy `retarget_random_deterministic`:
  - Build legal candidate list `L` from sorted `T`.
  - If `|L| = 0` -> fizzle.
  - Else draw index deterministically:
    - `idx = DrawU32Next(combat.effect.retarget) mod |L|`
    - increment retarget stream cursor exactly once per retarget attempt.
  - Apply to `L[idx]`.

Failure behavior:
- Unknown policy => `ERR_UNKNOWN_INVALID_TARGET_POLICY` and fizzle.
- Candidate list mutation during same resolve item uses snapshot-at-attempt semantics; no mid-attempt reselection.

### 6) Replacement Effect Traversal

Each raw operation is transformed by ordered replacement hooks:

`op_k+1 = replace_k(op_k, context)` for `k=0..n-1`

Stop conditions:
- `k >= replacement_pass_cap`
- replacement returns same `replacement_fingerprint` already seen
- operation canceled

MVP defaults/safe ranges:
- `replacement_pass_cap` default 8, safe 4..16
- `replacement_hooks_per_scope` soft limit 16, hard 32

Failure behavior:
- Hit pass cap => freeze current op, apply as-is, emit `ERR_REPLACEMENT_PASS_CAP`.
- Fingerprint repeat => break loop, emit `ERR_REPLACEMENT_LOOP_PREVENTED`.
- Hard hook overflow => reject newest hook registration deterministically.

### 7) Global Clamps and Saturation

Canonical stat clamps (authoritative):
- HP: `[0, hp_max_cap]`, default cap 9999, safe 999..99999
- Shield: `[0, shield_cap]`, default 9999, safe 999..99999
- Resource delta per op: `[-res_delta_cap, +res_delta_cap]`, default 99, safe 10..999
- Status stacks/duration per registry caps above

Failure behavior:
- Saturating clamp always applies, never wraparound.
- Clamp events include `before`, `after`, `cap`, `reason_code`.

### 8) Anti-loop Safeguards (ERP-local)

In addition to TSRE turn-level budgets, ERP enforces per-item limits:

- `micro_ops_cap_per_item` default 64, safe 32..256
- `generated_triggers_cap_per_item` default 8, safe 4..16 (must be <= TSRE cap)
- `status_mutations_cap_per_item` default 32, safe 16..128

Failure behavior:
- On cap hit: drop remaining same-category operations from current item, emit `ERR_ITEM_CAP_REACHED`, continue resolving rest deterministically.

## Dependencies

Hard dependencies:
- TSRE ordering and guardrail counters.
- Card effect schema and enum validation.
- RNG/Seed service with indexed deterministic draws and canonical `combat.*` stream partitioning.

Downstream dependents:
- Combat log/UI (reason text, previews, recap).
- Balance telemetry dashboards.
- Replay verifier (state hash/digest chain).

## Tuning Knobs

| Knob | Type | Default | Safe Range | Failure/Risk if too low | Failure/Risk if too high |
|---|---|---:|---|---|---|
| `SCALE` | const int | 1000 | fixed | Precision loss if reduced | Overflow risk if increased |
| `damage_op_cap` | int | 9999 | 1999-19999 | Big hits truncate too early | Burst spikes, balance volatility |
| `status_stacks_cap_default` | int | 99 | 20-999 | Synergies feel dead | Runaway stat snowball |
| `status_duration_cap_default` | int | 9 | 3-30 | DOT/BUFF uptime too short | Long stale state, UI clutter |
| `replacement_pass_cap` | int | 8 | 4-16 | Legit replacements stop early | Loop/perf risk |
| `replacement_hooks_hard` | int | 32 | 16-64 | Build variety constrained | Replacement storms |
| `micro_ops_cap_per_item` | int | 64 | 32-256 | Complex cards truncate | Browser spikes |
| `status_mutations_cap_per_item` | int | 32 | 16-128 | Multi-target statuses clipped | O(N^2) style spikes |
| `chance_bp_minmax` | int range | 0..10000 | fixed | N/A | N/A |
| `hp_max_cap` | int | 9999 | 999-99999 | Defensive scaling cramped | Overflow/perf risk |
| `shield_cap` | int | 9999 | 999-99999 | Shield archetypes underperform | Stall metas |
| `res_delta_cap` | int | 99 | 10-999 | Resource cards feel weak | Infinite-turn enable risk |
| `coalesce_overflow_logs` | bool | true | true/false | Log spam if off | Slightly less forensic detail if on |

Governance:
- Knobs must be data-configurable and versioned.
- Any value outside safe range requires replay fixture pass and perf smoke pass on target browsers.

## Edge Cases

QA-ready matrix (each case requires unit fixture + replay fixture + UI reason assertion):

| ID | Scenario | Expected Behavior | Required UI/Log Explanation | Exploit Prevention Hook |
|---|---|---|---|---|
| ERP-EC-001 | Target invalid at resolve | Apply `invalid_target_policy`: `fizzle`, `retarget_if_possible` (lowest `instance_id`), or `retarget_random_deterministic` (seeded pick over sorted candidates) | "No effect: target no longer valid" or "Retargeted deterministically" | No implicit retarget outside explicit policy; deterministic candidate ordering prevents abuse |
| ERP-EC-002 | Source removed before effect resolves | Resolve from committed snapshot unless effect requires live source | "Resolved from source snapshot" | Prevent self-delete to dodge downside clauses |
| ERP-EC-003 | Duplicate submit/double click on play | Idempotent commit by nonce; second request no-ops | "Action already committed" | Blocks AP bypass via packet/input spam |
| ERP-EC-004 | Replacement loop (A replaces B, B replaces A) | Deterministic ordering + visited token stops recursion | "Replacement loop prevented" | Prevents infinite recursion exploit |
| ERP-EC-005 | Trigger generation exceeds per-item cap | Accept first N in order; drop rest with reason code | "Trigger cap reached" | Prevent queue flood from one source |
| ERP-EC-006 | Queue at hard limit | Reject newest enqueue deterministically | "Queue full: extra trigger ignored" | Prevent overflow-based ordering abuse |
| ERP-EC-007 | Simultaneous lethal | Outcome follows queue/state-action order policy | "Simultaneous lethal resolved by order key" | Prevent hidden actor-priority exploit |
| ERP-EC-008 | Zero/negative final magnitude after prevention | Emit explicit no-op delta event | "Blocked" / "No damage dealt" | Prevent silent outcomes/dispute abuse |
| ERP-EC-009 | End-step expiry and delayed trigger collide | Resolve in fixed global boundary order | Boundary strip shows order chips | Prevent ambiguous timing manipulation |
| ERP-EC-010 | Hidden-info field referenced in effect explanation | Redact to visibility-safe summary | "Unknown/hidden attribute" | Prevent info leakage via logs/tooltips |
| ERP-EC-011 | Hand overflow during draw chain | Apply cap atomically then emit discard triggers once per moved card | "Hand full: X burned" | Prevent draw/discard feedback loop abuse |
| ERP-EC-012 | Determinism mismatch in replay | Emit mismatch telemetry + trace chunk; release behavior per mode | Dev HUD mismatch badge | Supports exploit detection + reproducibility |

## Visual/Audio Requirements

Resolve-stage presentation anchors (logic-authoritative):
- S0 Validate/Commit
- S1 Snapshot/Target Lock
- S2 Replacement/Prevention
- S3 Compute
- S4 Apply Delta
- S5 State Actions
- S6 Trigger Enqueue
- S7 Finalize

VFX requirements:
- Distinct visual language for applied vs blocked vs fizzled outcomes (never reuse hit VFX for fizzles).
- Source highlight at S1, impact marker at S4, aftermath marker at S5.
- Cap/guardrail drops show compact queue-adjacent glyph (non-modal, non-spam).
- Fast-forward/reduced mode may shorten animation but must still emit stage outcome markers.

SFX requirements:
- Stage-coupled cues: commit (S0), impact/block/fizzle variant (S4), chain tick (S6), major finalize stinger (S7).
- Priority ducking: lethal/guard-break/resource-swing cues override low-salience chain ticks.
- Batch micro-event sounds beyond threshold N into grouped cue to avoid fatigue.

Event contract to presentation layer (required even on no-op):
- `resolve_stage`, `source_instance_id`, `target_instance_ids[]`, `vfx_event_id`, `sfx_event_id`, `outcome_flag`.

## UI Requirements

Readability contract:
- UI must explain both outcome and ordering cause using same ERP/TSRE event stream.

Required surfaces:
1) Resolve Stack Panel
- Shows queued items with ordering chips (`timing_window`, `speed_class`, `enqueue_sequence`).
- Active item expands to stage progression (S0-S7).

2) Combat Log
- Always includes human-readable reason text mapped from reason code.
- Expandable debug row includes source/target IDs and magnitude breakdown.

3) Outcome Badges
- Per target badge set: Applied, Blocked, Fizzled, Partial.
- Badge text/icon must be colorblind-safe and distinct.

4) "Why First?" Ordering Popover
- Explicit comparator chain shown: `timing_window -> speed_class -> enqueue_sequence -> source_id`.

5) Safeguard Notices
- Queue/chain/loop cap notices are compact toasts linked to specific log entries.
- Modal interruption only for fatal turn fail-safe.

Exploit/readability hooks:
- Controls hard-disabled during ResolveLock with visible reason.
- Duplicate submission feedback must indicate idempotent no-op.
- No "Unknown reason" strings permitted in production UI paths.
- Preview top item hash-checks against next resolved item in dev builds.

## Open Questions

1) Canonical partial-resolve policy granularity for multi-step multi-target effects (single global rule vs per-effect override)?
2) Should simultaneous lethal ever produce explicit draw state beyond order-based result?
3) How much safeguard internals (caps/loop guards) should be player-visible in non-debug UI?
4) Minimum player log verbosity vs QA/debug verbosity tiers?
5) Need signed resolve transcripts for ranked/challenge anti-cheat?

## Acceptance Criteria

1) Deterministic numeric parity
- Same seed/snapshot/input yields identical per-op integers and state hash across Chrome/Firefox.

2) Replacement safety
- Replacement loop fixtures terminate via fingerprint/pass cap with deterministic result and error code.

3) Stack policy correctness
- Status fixture suite validates `add`, `refresh_duration`, `max_override`, `unique_instance` exactly.

4) Clamp visibility
- All clamped operations emit exactly one clamp event with before/after/cap.

5) Anti-loop containment
- Per-item caps + TSRE caps guarantee queue drains without hang in all loop fixtures.

6) Schema compatibility
- Every published card `effects[]` payload either resolves or fails with deterministic error code set (no silent undefined behavior).

