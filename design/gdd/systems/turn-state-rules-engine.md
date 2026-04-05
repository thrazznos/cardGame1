# Turn State & Rules Engine

> Status: Approved
> Author: Hermes Agent
> Last Updated: 2026-04-04
> Implements Pillars: Sequencing Mastery Over Raw Stats; Readable Tactical Clarity; High Run Variety, Low Grind
> Upstream References: design/gdd/game-concept.md, design/gdd/card-data-definitions.md

## Overview

Turn State & Rules Engine is the authoritative runtime arbiter for combat flow in Dungeon Steward. It defines:
- legal turn phases and timing windows,
- the deterministic order in which actions and triggers resolve,
- the queue model that transforms player input into reproducible outcomes,
- hard guardrails for invalid or ambiguous transitions.

This system is intentionally strict: if two players make the same choices from the same seeded state, outcomes must be byte-for-byte identical in combat logs and state snapshots. The engine separates intention capture (player selects a card/target) from execution (rules engine validates, schedules, and resolves), so tactical sequencing stays readable and debuggable in a browser-first environment.

Primary design goal:
- Deterministic, order-sensitive card play that feels fair, legible, and strategically deep.

Secondary design goals:
- Keep phase model simple enough for onboarding while supporting rich interactions.
- Provide stable contracts for effect resolution, deck lifecycle, mana economy, enemy logic, UI, and tutorials.

Non-goals (MVP):
- Hidden simultaneous-resolution ambiguity.
- Soft/random tie-breakers not represented in state.
- Animation-driven logic ordering.

Deferred beyond MVP (Vertical Slice/Alpha candidates):
- Checkpoint rollback recovery for corrupted runtime states.
- Full replay authoring/debug UI (core deterministic replay fixtures remain in MVP).
- Advanced adaptive degradation heuristics beyond basic resolve batching and hard caps.

## Player Fantasy

The player should feel like a tactical conductor, not a gambler. Every turn is a deliberate sequence puzzle:
- “If I play this setup card first, I can accelerate mana, then cash out with a finisher before enemy retaliation.”
- “I can predict exactly when each trigger will fire.”
- “When I lose, I can explain why from the sequence.”

The emotional promise:
- Mastery through ordering precision.
- Confidence through transparent cause-and-effect.
- Replayability through different sequence lines, not opaque RNG spikes.

## Detailed Design

### Core Rules

1) Single authoritative combat state
- Combat state is mutated only by the Turn State & Rules Engine (TSRE).
- UI, animation, and VFX are consumers of state events, never source of truth.

2) Deterministic scheduling model
- All executable items enter a single Resolve Queue with stable sort keys:
  1. turn_index
  2. phase_index
  3. timing_window_priority (pre < main < post)
  4. speed_class_priority (fast < normal < slow)
  5. enqueue_sequence_id (monotonic per combat)
  6. source_instance_id (final deterministic tie-break)
- No random tie resolution inside combat.

3) Intent then commit
- Card play pipeline:
  - IntentCaptured(card_instance_id, proposed_targets)
  - ValidateIntent (resources, legality, conditions, targets)
  - CommitPlay (resource spend + queue insertion + immutable PlayRecord)
  - ResolvePlay (effect pipeline execution)
- If validation fails, no state mutation except rejection feedback event.

4) Timing windows align to card schema
- `timing_window` and `speed_class` from card data are mandatory ordering inputs.
- `combo_tags` and `chain_flags` can modify generated triggers, but cannot violate queue determinism.

5) Trigger ownership and scope
- Trigger source scopes:
  - Card-local (during this play)
  - Turn-scoped (expires end of turn)
  - Encounter-scoped (persists combat)
- Trigger registration/removal must happen at explicit phase boundaries to avoid ghost triggers.

6) Action budget and lock states
- MVP uses dual budget axes: AP budget (resource economy) plus action-count cap (anti-spam safeguard).
- Player can only enqueue new play intents in PlayerPhase and when not in ResolveLock.
- ResolveLock is active while queue is draining to prevent mid-resolution race conditions.

7) Readability-first event stream
- Every state mutation emits a structured log event with:
  - event_id, source, target(s), pre_state_hash, post_state_hash, order_index, human_readable_reason.
- UI queue and combat log consume this same stream.

8) Browser-safe determinism
- Use integer/fixed-point math for combat-critical calculations where feasible.
- Explicit rounding policy per operation family (damage, shields, resource gain) to avoid runtime drift.

9) Failure policy
- Illegal transitions: hard block + debug telemetry.
- Impossible runtime state: fail-fast in debug; in release, abort remaining queue work for the turn, force TurnEnd fail-safe, and flag session telemetry.

10) Seed isolation
- TSRE consumes RNG only via RNG/Seed service and records each RNG call index in event stream.
- Rule ordering never depends on animation time, frame timing, or UI event race.

### States and Transitions

Combat lifecycle states:
- CombatInit
- TurnStart
- PlayerPhase
- ResolvePhase
- EnemyPhase
- TurnEnd
- CombatEnd

PlayerPhase sub-states:
- AwaitInput
- Targeting
- IntentValidation
- IntentCommitted

ResolvePhase sub-states:
- QueueOpenForSystemEnqueue (no player enqueue)
- ResolvingItem
- CheckingStateActions
- QueueDrainComplete

EnemyPhase sub-states:
- EnemyIntentReveal (if not already revealed)
- EnemyActionResolve
- EnemyPostResolve

Turn state machine (high-level):
- CombatInit -> TurnStart
- TurnStart -> PlayerPhase.AwaitInput
- AwaitInput -> Targeting (if card requires target)
- Targeting -> IntentValidation
- IntentValidation -> IntentCommitted (valid)
- IntentValidation -> AwaitInput (invalid)
- IntentCommitted -> ResolvePhase
- ResolvePhase -> PlayerPhase.AwaitInput (if actions remain and no forced pass)
- ResolvePhase -> EnemyPhase (if player passed/no legal actions)
- EnemyPhase -> TurnEnd
- TurnEnd -> TurnStart (next turn) OR CombatEnd

Illegal examples:
- AwaitInput -> EnemyActionResolve directly
- Targeting -> IntentCommitted bypassing validation
- QueueDrainComplete -> CombatInit

State transition guards:
- GuardResourceSufficiency
- GuardPlayConditionsMet
- GuardTargetLegality
- GuardZoneLegality (card must be in hand unless explicit override)
- GuardNotResolveLocked

State actions (automatic checks after each queue item):
- Defeat check (player/enemy HP <= 0)
- Empty-queue progression check
- Duration expiry checks (turn-scoped effects)
- Pending replacement effects check

### Interactions

1) Card Data & Definitions
- TSRE consumes card metadata for legality and order:
  - `speed_class`, `timing_window`, `combo_tags`, `chain_flags`, `play_conditions[]`, targeting fields.
- TSRE never interprets flavor/UI fields as logic.

2) Effect Resolution Pipeline
- TSRE owns when an effect is resolved.
- Effect Pipeline owns what effect does.
- Contract:
  - Input: PlayRecord + current state + effect payload.
  - Output: deterministic StateDelta list + TriggerRegistrations + LogEvents.

3) Deck Lifecycle System
- TSRE emits zone transition intents at precise points:
  - On CommitPlay: card leaves hand (pending resolution marker).
  - On resolution complete: move per `zone_on_play` and lifecycle flags.
- Deck system executes transitions atomically and reports success/failure.

4) Mana & Resource Economy
- Resource validation happens before CommitPlay.
- Resource spending happens at CommitPlay, not on effect completion.
- Refund semantics (if any future cards grant partial refund on fail) must be explicit effect outcomes.

5) Enemy Encounter System
- Enemy intents become queue items with deterministic priorities in EnemyPhase.
- Player and enemy use same queue semantics; only phase permissions differ.

6) Combat UI/HUD
- UI receives:
  - current phase/sub-state,
  - legal actions list,
  - projected queue order (preview),
  - resolved event stream.
- UI cannot reorder committed queue items.

7) Onboarding & Tooltips
- TSRE exposes explanation hooks:
  - Why action is illegal.
  - Why this trigger resolved before another.
  - Which rule/priority key decided ordering.

8) Save/Resume and Debug Tools
- TSRE supports state snapshot + replay via event stream and seed index.
- Deterministic replay is required for bug reproduction and balance verification.

## Formulas

1) Turn AP Budget

`ap_budget_turn = clamp(AP_base + AP_flat_bonus + floor(turn_index * AP_turn_ramp), AP_min, AP_max)`

MVP defaults:
- `AP_base = 3`
- `AP_flat_bonus = 0`
- `AP_turn_ramp = 0`
- `AP_min = 0`
- `AP_max = 6`

Safe range:
- `AP_base` in [2, 5]
- `AP_max` in [4, 8]
- `AP_turn_ramp` in [0.0, 0.5]

Failure behavior:
- If computed AP exceeds `AP_max`, clamp and log `WARN_AP_CLAMPED`.
- If spend request exceeds current AP, reject action (`ERR_AP_INSUFFICIENT`) without queue mutation.

2) Turn Action Count Cap (independent of AP)

`actions_cap_turn = clamp(ACT_base + ACT_flat_bonus, ACT_min, ACT_max)`

Player can commit action only if:
`actions_committed_this_turn < actions_cap_turn`

MVP defaults:
- `ACT_base = 12`, `ACT_flat_bonus = 0`, `ACT_min = 4`, `ACT_max = 24`

Safe range:
- `ACT_base` [8, 16]
- `ACT_max` [16, 32]

Failure behavior:
- On cap hit, auto-close player input and transition to EnemyPhase with event `INFO_ACTION_CAP_REACHED`.

3) Resolve Budget Per Turn (anti-loop)

`resolve_budget_turn = clamp(RES_base + floor(turn_index * RES_turn_ramp), RES_min, RES_max)`

Every queue pop decrements remaining budget.

MVP defaults:
- `RES_base = 128`
- `RES_turn_ramp = 0`
- `RES_min = 64`
- `RES_max = 256`

Safe range:
- `RES_base` [96, 192]
- `RES_max` [192, 512]

Failure behavior:
- If budget reaches 0 before queue empty: stop new trigger generation, emit `ERR_RESOLVE_BUDGET_EXHAUSTED`, then force `TurnEnd` fail-safe.

4) Queue Hard/Soft Limits

Pending queue capacity:
`queue_soft_limit = Q_soft`
`queue_hard_limit = Q_hard`

Per-source enqueue throttle per resolve tick:
`source_enqueue_limit_tick = Q_src_tick`

MVP defaults:
- `Q_soft = 128`
- `Q_hard = 256`
- `Q_src_tick = 32`

Safe range:
- `Q_soft` [64, 256]
- `Q_hard` [128, 512]
- `Q_src_tick` [8, 64]

Failure behavior:
- Above `Q_soft`: continue with warning telemetry.
- At `Q_hard`: deterministically reject the newest enqueue attempt with `ERR_QUEUE_OVERFLOW`; preserve deterministic order for accepted items.
- If overflow repeats 3+ times in one turn, force `TurnEnd` fail-safe.

5) Trigger Chain Depth Cap

`chain_depth_current <= chain_depth_cap`

MVP default: `chain_depth_cap = 16`
Safe range: [8, 24]

Failure behavior:
- New generated trigger beyond cap is discarded with `ERR_CHAIN_DEPTH_CAP`.
- Existing queued items continue resolving in deterministic order.

6) Per-Item Trigger Spawn Cap

`spawned_triggers_from_single_item <= per_item_trigger_cap`

MVP default: `per_item_trigger_cap = 8`
Safe range: [4, 16]

Failure behavior:
- Additional triggers from the same resolving item beyond cap are dropped with `ERR_PER_ITEM_TRIGGER_CAP`.
- Dropped-trigger count is logged for balance telemetry.

7) Deterministic Queue Ordering Key

`order_key = (turn_index, phase_index, timing_window_priority, speed_class_priority, enqueue_sequence_id, source_instance_id)`

Fixed priorities from card schema:
- `timing_window`: pre=0, main=1, post=2
- `speed_class`: fast=0, normal=1, slow=2

Failure behavior:
- Missing/unknown enum during validation: hard fail publish/load for that card.
- Unknown enum at runtime (corrupt state): mapped to lowest priority bucket + `ERR_UNKNOWN_ORDER_ENUM`.

7) Determinism Fingerprint

After each resolved item:
`combat_state_hash_next = FNV1a64(combat_state_hash_prev || order_key || rng_call_index || state_delta_digest)`

Checkpoint comparison at TurnEnd/CombatEnd ensures replay stability.

Failure behavior:
- In test/replay mode: mismatch => hard fail with trace dump.
- In release: continue session but mark telemetry `ERR_DETERMINISM_MISMATCH`.

8) Browser Step Budget

Per logical resolve step:
`step_cpu_ms <= step_budget_ms`

Per turn:
`turn_cpu_ms <= turn_budget_ms`

MVP defaults:
- `step_budget_ms = 2.0` (median target)
- `turn_budget_ms = 12.0` (P95 target)
- `turn_budget_hard_ms = 25.0`

Safe range:
- `step_budget_ms` [1.5, 4.0]
- `turn_budget_ms` [8.0, 20.0]
- `turn_budget_hard_ms` [16.0, 40.0]

Failure behavior:
- If step exceeds budget repeatedly: switch to batched resolution mode (`resolve_batch_size` clamp).
- If hard turn budget exceeded: stop non-critical follow-up triggers, force `TurnEnd`, emit `ERR_TURN_CPU_BUDGET`.

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `AP_base` | int | 3 | 2-5 | Turns feel starved | Turns too long / AP hoarding |
| `AP_max` | int | 6 | 4-8 | Low sequencing expression | Input bloat, harder readability |
| `ACT_base` | int | 12 | 8-16 | Forced early passes | Zero-cost spam windows |
| `RES_base` | int | 128 | 96-192 | Premature combo truncation | Infinite-loop risk/perf spikes |
| `Q_soft` | int | 128 | 64-256 | Early warnings, noisy logs | Late warning detection |
| `Q_hard` | int | 256 | 128-512 | Queue overflow in normal play | Memory/perf instability |
| `Q_src_tick` | int | 32 | 8-64 | Legit burst throttled | Flood risk from one trigger source |
| `chain_depth_cap` | int | 16 | 8-24 | Synergies clipped | Recursive explosion risk |
| `per_item_trigger_cap` | int | 8 | 4-16 | Interesting combos clipped | Single-item trigger floods |
| `resolve_batch_size` | int | 24 | 12-48 | Slow queue drain | Frame spikes in browser |
| `step_budget_ms` | float | 2.0 | 1.5-4.0 | Over-throttled simulation | Stutter risk |
| `turn_budget_hard_ms` | float | 25.0 | 16.0-40.0 | Too many forced turn ends | Browser hitch/soft-freeze risk |
| `determinism_strict_mode` | bool | true | true/false* | Less replay certainty | More false positives if toolchain unstable |

`*` Keep true for dev/QA and ranked/challenge modes; false only for experimental local prototyping.

Knob governance:
- All knobs must be data-configurable (project settings or external data table) with no code changes required.
- Any value outside safe range requires playtest signoff + deterministic replay fixture pass.

## Edge Cases

1) Multiple triggers with same timing and speed
- Resolution: stable tie-break by enqueue_sequence_id then source_instance_id.
- Requirement: always identical across replays.

2) Card leaves hand before resolution due to replacement effect
- Resolution: PlayRecord binds to card_instance_id; effects resolve from record even if zone changed, unless explicitly canceled by rule text.

3) Target dies mid-queue before pending effect resolves
- Resolution: retarget only if effect has retarget policy; otherwise fizzle with explicit log reason.

4) Resource changes between intent and commit
- Resolution: commit re-validates resource sufficiency immediately before spend; if invalid, reject and return to AwaitInput.

5) Infinite/near-infinite trigger loops
- Resolution: enforce per-turn and per-item trigger cap; when cap hit, halt further looped triggers, emit safeguard event, continue combat.

6) Simultaneous lethal (player and enemy reduced to 0 in same drain cycle)
- Resolution policy (MVP): resolve strictly from queued event/state-action order; no extra actor-priority exception. Documented in log and UI recap.

7) Generated temporary card with missing metadata
- Resolution: hard invalid at generation boundary; card cannot enter hand if mandatory order fields absent.

8) Browser tab throttling/frame drops during resolution
- Resolution: logic ticks are decoupled from render frames; queue drain proceeds by deterministic simulation step, not wall-clock animation time.

9) Undo requests after partial resolution
- Resolution (MVP): no gameplay undo after CommitPlay. Optional pre-commit cancel only during Targeting.

10) Desync between UI preview and actual resolve order
- Resolution: preview is generated from same scheduler function and hash-checked against first resolve item; mismatch raises debug error.

## Dependencies

Upstream dependencies:
- None (foundation-layer system in build/design order).
- Co-foundation contract: Card Data & Definitions schema must be available for runtime validation of ordering/timing/targeting fields.
- Co-foundation contract: RNG/Seed service integration is required before full combat implementation, but does not block this GDD’s foundational design.

Downstream dependents:
- Effect Resolution Pipeline (hard)
- Deck Lifecycle System (hard)
- Mana & Resource Economy (hard)
- Enemy Encounter System (hard)
- Combat UI/HUD (hard)
- Onboarding & Tooltips (soft-hard; required for clarity goals)
- Run Save/Resume (soft in MVP, hard in vertical slice)
- Telemetry/Debug Hooks (soft in MVP)

Integration contracts (MVP):
- TSRE exposes:
  - `get_legal_actions(state)` -> `LegalActionList` (deterministic order, reason codes)
  - `submit_play_intent(intent)` -> `IntentResult {accepted|rejected, code, commit_id?}`
  - `submit_pass(actor_id)` -> `PassResult {accepted|rejected, code, pass_streak_after}`
  - `step_resolve_queue()` -> `ResolveStepResult {events_applied, queue_remaining, budget_remaining}`
  - `get_phase_state()` -> `PhaseState {phase, sub_state, resolve_lock, active_actor}`
  - `get_event_log_slice(from_index)` -> ordered append-only `EventLogEntry[]`
  - `snapshot_state()` / `replay_from_snapshot(snapshot, inputs, seed)`
- Deck Lifecycle contract:
  - Input: `ZoneTransitionIntent[]`
  - Output: `ZoneTransitionResult {ok|error_code, applied_transitions[]}`
- Mana & Resource contract:
  - Input: `ResourceSpendRequest {actor, amount, source_commit_id}`
  - Output: `ResourceSpendResult {ok|error_code, remaining_resource}`
- Enemy Encounter contract:
  - Input: `EnemyActionIntent[]` at EnemyPhase gate
  - Output: deterministic queue inserts with returned `enqueue_sequence_id[]`
- Combat UI contract:
  - Input to UI: `PhaseState`, `LegalActionList`, queue preview, explanation reason codes
  - UI->TSRE only via `submit_play_intent`/`submit_pass`; no direct state mutation

Performance envelope (browser target):
- Common queue drain step: <= 2 ms median on target desktop browser.
- Worst-case heavy turn (95th percentile): <= 12 ms logic time excluding animations.

## Acceptance Criteria

1) Deterministic Replay
- Given identical initial snapshot, seed, and player inputs, full combat replay produces identical:
  - final state hash,
  - ordered event IDs,
  - RNG call index sequence.
- Pass threshold: 1000 automated replay fixtures, 0 divergences.

2) Order-Sensitivity Correctness
- Fixture suite confirms that changing only card play order changes outcomes exactly according to scheduler rules.
- Pass threshold: >= 200 precedence fixtures across timing_window, speed_class, enqueue order, and tie-break categories; 100% pass.

3) Illegal Transition Protection
- All defined illegal state transitions are blocked and logged with reason code.
- Pass threshold: 100% of transition guard tests pass.

4) Readable Sequencing Output
- Every resolve item emits a human-readable reason string referencing ordering keys.
- Pass threshold: no "unknown reason" events in test corpus.

5) Input/Resolve Race Safety
- No player action can mutate combat state during ResolveLock.
- Pass threshold: race-condition stress tests show 0 unauthorized mutations.

6) Contract Compatibility
- TSRE accepts all valid card schema fixtures from card-data-definitions and rejects invalid ones with deterministic error codes.
- Pass threshold: 100% fixture pass/fail expected outcomes.

7) Loop Safeguards
- Trigger loop guard prevents non-terminating resolution.
- Pass threshold: all loop-fixture combats terminate within configured cap and emit safeguard telemetry.

8) Browser Performance
- TSRE remains within logic performance envelope on pinned test matrix: Chrome Stable and Firefox Stable on baseline hardware defined as Intel i5-1240P or Ryzen 5 5600U equivalent, 16 GB RAM, integrated GPU.
- Pass threshold: median and P95 metrics meet envelope in 10k-turn simulation batch on both browsers.

9) UI Consistency
- Queue preview order matches actual resolution order for all test fixtures.
- Pass threshold: 0 preview/resolve mismatches.

10) Onboarding Explainability Hooks
- Illegal action reasons and ordering explanations are accessible through API for tooltip system.
- Pass threshold: onboarding fixture can query explanation fields for all scripted tutorial steps.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|---|---|---|---|
| Phase transition | Clear phase banner + subtle timeline pulse | Soft phase stinger | High |
| Illegal action reject | Red outline + reason tooltip | Short reject click | High |
| Queue item resolve | Queue item highlight + source/target flash | Distinct resolve tick by speed_class | High |
| Resolve safeguard triggered | Warning badge in combat log | Warning tone (non-intrusive) | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| Current phase/sub-state | Top combat HUD | On every state transition | Always |
| Legal actions list + reason codes | Hand/action panel | On input focus and state updates | PlayerPhase |
| Queue preview order | Right-side queue panel | On enqueue/dequeue | When queue non-empty |
| Resolve lock status | Action bar lock icon | Real-time | During ResolvePhase |
| Determinism/debug hash (dev) | Debug overlay | After each resolve item | Debug mode only |

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Do we expose full queue internals to players, or only simplified preview labels in MVP UX? | UX Designer | Sprint 1 end | Resolved: simplified preview labels in MVP; full internals remain debug-only. |
