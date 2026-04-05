# Mana & Resource Economy

> Status: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-04
> Implements Pillars: Compounding Value Every Turn; Sequencing Mastery Over Raw Stats; Readable Tactical Clarity; High Run Variety, Low Grind
> Upstream References: design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/card-data-definitions.md, design/gdd/systems/deck-lifecycle.md

## Overview

Mana & Resource Economy (MRE) defines how players gain, store, spend, and transform combat resources in Dungeon Steward. It is the authoritative subsystem for:
- per-turn mana refresh/ramp,
- temporary and conditional resource grants,
- cost modification and payment ordering,
- refund and rebate semantics,
- anti-loop and anti-hoarding guardrails.

Design intent:
- Keep baseline turns readable and predictable.
- Reward sequencing skill through timing-sensitive resource conversion.
- Enable compounding value builds without infinite-turn degeneracy.

Scope split:
- TSRE decides when spend validation and commit happen.
- ERP computes effect outcomes that may grant/convert/refund resources.
- MRE validates affordability, executes payment, and updates resource ledgers deterministically.

Non-goals (MVP):
- Hidden asynchronous income not represented in event log.
- Float-based economy math.
- Resource theft mechanics between actors.

## Player Fantasy

The player should feel like a deliberate engine-builder:
- “I can invest early mana to ramp and cash out later.”
- “If I sequence my setup and rebate cards correctly, I extend the turn in a predictable way.”
- “I always know why I can or cannot play a card right now.”

Emotional outcome:
- Mastery from planning spend order.
- Satisfaction from compounding ramp lines.
- Trust from explicit, auditable resource changes.

## Detailed Design

### Core Rules

1) Canonical resource families (MVP)
- `mana` (primary spend resource for most cards).
- `momentum` (secondary stack-like combat resource used by specific effects; not a default card play cost in MVP schema).
- `overcharge` (temporary bonus mana bucket that expires at TurnEnd unless converted).

2) Turn mana/AP shared model
- Actor has shared budget state: `budget_max`, `budget_current` (presented as mana; TSRE tracks AP on same stream in MVP).
- At TurnStart:
  - `budget_max` follows TSRE ramp parameters.
  - `budget_current` refills to `budget_max`.
  - Then transient start-of-turn adjustments apply (relics/status/effects).

3) Ramp is deterministic and capped (TSRE-authoritative)
- Baseline ramp follows TSRE formula (`AP_base`, `AP_flat_bonus`, `AP_turn_ramp`, `AP_min`, `AP_max`).
- MRE may request additive AP bonus modifiers through `AP_flat_bonus_t`; final cap/clamp is TSRE-authoritative.
- No negative budget below `AP_min`.

4) Spend timing and legality (aligned to TSRE)
- TSRE remains authority for action budget gate and commit timing.
- In MVP, AP budget and mana spend are the same budget stream (AP-as-mana); one committed play consumes from the shared budget.
- Affordability check occurs in TSRE validation and re-checks immediately before CommitPlay.
- Spend occurs at CommitPlay, not at resolve completion.
- Spend emits immutable `ResourceSpendRecord` linked to `commit_id`.

5) Cost construction order (authoritative)
For each play attempt:
1. `base_cost` from card data
2. static modifiers (card/relic/status persistent)
3. conditional modifiers (tags, chain state, target state)
4. floor/ceiling clamps
5. payment source priority resolution

6) Payment source priority
Default source order for `cost_type=mana`:
1. `overcharge` (expiring first)
2. `mana_current`
3. explicit substitute resource if card/effect grants `can_pay_mana_with_momentum` flag

7) Refund and rebate semantics
- Refunds are explicit ERP outcomes; never inferred from fizzles unless effect text says so.
- `refund_on_fail` is explicit data flag per effect/card path.
- Refund cannot exceed spend amount of originating `commit_id`.

8) Carryover policy
- Base rule: leftover `mana_current` is lost at TurnEnd.
- Carryover is only possible via explicit effects/status converting leftover mana to `overcharge_next_turn` or `momentum`.
- Carryover conversion resolves at TurnEnd boundary in deterministic order.

9) Secondary resource behavior
- `momentum` is integer, non-negative, capped.
- Momentum gain/loss is event-driven via ERP effects.
- Momentum does not auto-refresh each turn.

10) Anti-exploit guardrails
- Per-turn net resource gain caps.
- Per-commit refund cap and per-turn refund cap.
- Conversion pass cap to prevent convert-loop abuse (`mana -> momentum -> mana`).

11) Readability-first ledger
- Every resource mutation emits:
  - actor_id, resource_id, delta, reason_code, source_commit_id?, order_key_ref, pre_value, post_value.
- HUD and combat log use same ledger events.

### States and Transitions

Per-actor resource phase states:
- ResourceInit
- TurnStartRefresh
- PreCommitValidation
- CommitSpend
- ResolveAdjustments
- TurnEndSettlement

Primary transitions:
- ResourceInit -> TurnStartRefresh (new turn)
- TurnStartRefresh -> PreCommitValidation (player input window)
- PreCommitValidation -> CommitSpend (valid commit)
- PreCommitValidation -> PreCommitValidation (invalid commit rejected)
- CommitSpend -> ResolveAdjustments (ERP item resolving)
- ResolveAdjustments -> PreCommitValidation (queue drained and actions remain)
- ResolveAdjustments -> TurnEndSettlement (turn passes/ends)
- TurnEndSettlement -> TurnStartRefresh (next turn)

Illegal transitions (must reject):
- PreCommitValidation -> ResolveAdjustments without commit
- CommitSpend -> CommitSpend for same `commit_id`
- TurnEndSettlement -> CommitSpend

Settlement order at TurnEnd:
1. resolve pending end-turn resource effects,
2. execute carryover/conversion effects,
3. expire overcharge,
4. clamp and finalize ledger snapshot hash.

### Interactions with Other Systems

1) Turn State & Rules Engine (hard)
- TSRE calls MRE for affordability and spending during intent/commit.
- TSRE remains phase authority and blocks spending during ResolveLock.
- MVP contract alignment: AP and mana use a shared budget stream for play costs.
- Contract (aligned to TSRE MVP interface):
  - `ResourceSpendRequest {actor, amount, source_commit_id}` -> `ResourceSpendResult {ok|error_code, remaining_resource}`
- Optional extended diagnostics (non-blocking):
  - `check_affordability(request) -> {ok, effective_cost, breakdown[], code}`
  - `commit_spend(request) -> {ok, spend_record, remaining, code}`

2) Effect Resolution Pipeline (hard)
- ERP emits resource deltas: gain, drain, convert, refund, cost-modifier grants.
- MRE applies deltas with clamp/cap rules and returns deterministic result codes.
- Conversion and refund operations must include source reference for anti-loop accounting.

3) Card Data & Definitions (hard)
- MRE consumes:
  - `base_cost`, `cost_type`, `cost_mod_flags`, `combo_tags`, `chain_flags`, `effects[]` resource params.
- MVP cost_type handling:
  - `mana`: resolved by MRE shared AP/mana budget.
  - `other`: non-mana gating path handled by owning system/effect contract; MRE does not auto-charge mana.
- Unknown `cost_type` outside schema is content validation hard-fail; runtime fallback rejects deterministically.

4) Deck Lifecycle System (hard-adjacent)
- CommitSpend must succeed before card transitions `hand -> limbo_pending_resolve`.
- If spend fails, no zone movement occurs.

5) Combat UI/HUD (hard downstream)
- HUD displays current/max mana, overcharge, momentum, and projected post-play cost.
- UI receives rejection reason codes (insufficient, locked, capped, invalid substitute).

6) Telemetry/Debug (soft MVP, hard VS)
- MRE publishes economy counters per turn/combat:
  - gross gain, gross spend, refunds, conversions, wasted mana, cap hits.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a),b)`
- All values integer in MVP.

1) TurnStart shared budget ramp (TSRE-authoritative)

`budget_max_t = clamp(AP_base + AP_flat_bonus_t + floor(turn_index * AP_turn_ramp), AP_min, AP_max)`

MVP defaults (mirror TSRE):
- `AP_base = 3`
- `AP_flat_bonus_t = 0` (default)
- `AP_turn_ramp = 0`
- `AP_min = 0`
- `AP_max = 6`

Safe ranges:
- `AP_base` in [2, 4]
- `AP_flat_bonus_t` in [-2, 4]
- `AP_turn_ramp` in [0.0, 0.5]
- `AP_max` in [4, 8]

Failure behavior:
- Over-cap ramp is clamped with `WARN_BUDGET_MAX_CLAMPED`.

2) TurnStart refill

`budget_current_t_start = clamp(budget_max_t + start_turn_mana_flat_t, 0, MANA_TURN_START_CAP)`

MVP defaults:
- `MANA_TURN_START_CAP = 12`
- `start_turn_mana_flat_t` default 0

Safe ranges:
- `MANA_TURN_START_CAP` in [10, 16]

Failure behavior:
- Above cap -> clamp + `WARN_TURN_START_MANA_CLAMPED`.

3) Effective card cost

`cost_effective = clamp(base_cost + mod_flat_persistent + mod_flat_conditional, COST_MIN, COST_MAX)`

Then multiplicative modifiers (if enabled by flags):
`cost_effective = clamp(round_half_up(cost_effective * cost_mult_num / cost_mult_den), COST_MIN, COST_MAX)`

MVP defaults:
- `COST_MIN = 0`
- `COST_MAX = 10`
- Multiplicative modifiers disabled by default except explicit card/relic flags.

Safe ranges:
- `COST_MAX` in [6, 20]

Failure behavior:
- Invalid multiplier denominator -> reject with `ERR_COST_MULT_INVALID`.

4) Spend decomposition (mana cost)

`pay_overcharge = min(cost_effective, overcharge_current)`
`cost_after_overcharge = cost_effective - pay_overcharge`
`pay_mana = min(cost_after_overcharge, mana_current)`
`cost_remaining = cost_after_overcharge - pay_mana`

If `cost_remaining > 0` and substitute allowed:
`pay_momentum = min(cost_remaining * momentum_pay_ratio_num / momentum_pay_ratio_den, momentum_current)`

Affordability requires exact satisfaction of remaining cost after substitutions.

MVP defaults:
- Substitution disabled unless granted.
- Default ratio for enabled substitute: 1:1.

Failure behavior:
- Unsatisfied remaining cost -> `ERR_RESOURCE_INSUFFICIENT` (no mutation).

5) Refund limits

`refund_applied = min(refund_requested, spend_record.amount_spent - refunds_already_applied_for_commit)`
`refund_applied = min(refund_applied, REFUND_CAP_PER_TURN_REMAINING)`

MVP defaults:
- `REFUND_CAP_PER_TURN = 6`

Safe ranges:
- `REFUND_CAP_PER_TURN` in [3, 12]

Failure behavior:
- Excess refund amount is truncated with `WARN_REFUND_CAPPED`.

6) Net gain cap per turn (anti-loop)

`net_gain_turn(resource) = gains_turn(resource) - spends_turn(resource) + refunds_turn(resource)`
Constraint:
`net_gain_turn(mana) <= NET_MANA_GAIN_CAP_TURN`
`net_gain_turn(momentum) <= NET_MOMENTUM_GAIN_CAP_TURN`

MVP defaults:
- `NET_MANA_GAIN_CAP_TURN = 12`
- `NET_MOMENTUM_GAIN_CAP_TURN = 20`

Safe ranges:
- mana cap [8, 20]
- momentum cap [10, 40]

Failure behavior:
- Gain beyond cap is dropped (or truncated) with `ERR_NET_GAIN_CAP_REACHED`.

7) Overcharge expiry and conversion

At TurnEnd:
`overcharge_expiring = overcharge_current`
`convert_to_momentum = min(overcharge_expiring * OC_TO_MOM_NUM / OC_TO_MOM_DEN, MOMENTUM_GAIN_CAP_PER_SETTLEMENT_REMAINING)` when conversion effect exists
`overcharge_next = 0`

MVP defaults:
- No default conversion.
- Typical conversion ratio for effects: 2 overcharge -> 1 momentum.

Failure behavior:
- Missing conversion metadata on conversion-tagged effect -> no conversion + `ERR_OVERCHARGE_CONVERSION_INVALID`.

8) Economy determinism digest extension

`resource_hash_next = FNV1a64(resource_hash_prev || spend_record_digest || resource_delta_digest || turn_index || order_key_ref || rng_call_index?)`

Used with TSRE/ERP hash chain for replay verification.

## Edge Cases

1) Cost changed between intent preview and commit
- Recompute effective cost at commit using authoritative current state; charge commit-time value only.

2) Card fizzles after commit spend
- Default: no auto-refund.
- If effect/card has explicit refund clause, apply through ERP -> MRE refund op.

3) Multiple refunds referencing same commit
- Clamp total refunds for commit to spend amount; extras are dropped with warning code.

4) Negative resource delta from corrupt payload
- Reject operation with `ERR_RESOURCE_DELTA_INVALID`; continue resolving remaining item paths deterministically.

5) End-turn overcharge conversion and expiration collision
- Conversion always executes before expiration sink, ordered by settlement sequence.

6) Simultaneous gain and spend in same resolve item
- Apply in ERP-declared operation order; each mutation logged.

7) Affordability under ResolveLock race attempt
- TSRE blocks player-origin submit; MRE receives no commit call.

8) Substitution permission revoked mid-turn
- Commit-time check controls legality; previously committed spends are unaffected.

9) Resource cap lowered below current value by debuff
- Immediate saturating clamp to new cap with explicit event `WARN_RESOURCE_CLAMPED_BY_CAP_CHANGE`.

10) Infinite convert loop (mana<->momentum)
- Enforce per-item conversion pass cap and per-turn net gain caps; drop excess operations.

## Dependencies

Hard upstream dependencies:
- Turn State & Rules Engine (phase gates, commit timing, resolve lock, deterministic order)
- Effect Resolution Pipeline (resource gain/refund/conversion operations)
- Card Data & Definitions (cost and modifier fields)

Hard-adjacent dependencies:
- Deck Lifecycle System (commit spend must precede zone move)

Downstream dependents:
- Combat Balance Model
- Enemy Encounter System (resource denial/drain behavior)
- Relics/Passive Modifiers
- Combat UI/HUD
- Telemetry/Debug Hooks

Integration contracts (MVP):
- `check_affordability(ResourceCheckRequest)`
  - input: `{actor_id, card_instance_id, card_id, commit_nonce, projected_targets[]}`
  - output: `{ok|rejected, effective_cost, payment_plan_preview[], reason_code}`
- `commit_spend(ResourceSpendRequest)`
  - input: `{actor, amount, source_commit_id}`
  - output: `{ok|error_code, remaining_resource}`
- `commit_spend_extended(ExtendedSpendContext)` (optional diagnostics path, non-authoritative)
  - input: `{actor_id, commit_id, card_instance_id, cost_type, amount, payment_policy}`
  - output: `{ok|error, spend_record_id, ledger_events[], remaining_by_resource, reason_code}`
- `apply_resource_delta(ResourceDeltaRequest)`
  - input: `{actor_id, resource_id, delta, op_kind, source_commit_id?, source_effect_id?, order_key_ref}`
  - output: `{applied_delta, pre_value, post_value, clamped, reason_code}`
- `get_resource_snapshot(actor_id)`
  - output: `{mana_current, mana_max, overcharge, momentum, caps, per_turn_counters}`

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `AP_base` | int | 3 | 2-4 | Slow early turns | Front-loaded burst meta |
| `AP_turn_ramp` | float | 0.0 | 0.0-0.5 | Flat progression feel | Snowball pacing |
| `AP_max` | int | 6 | 4-8 | Late game constrained | Long turns, combo bloat |
| `MANA_TURN_START_CAP` | int | 12 | 10-16 | Ramp cards feel wasted | Excess opening burst |
| `COST_MAX` | int | 10 | 6-20 | High-cost cards unusable | Cost readability loss |
| `REFUND_CAP_PER_TURN` | int | 6 | 3-12 | Rebate archetypes weak | Pseudo-infinite turns |
| `NET_MANA_GAIN_CAP_TURN` | int | 12 | 8-20 | Combo lines over-clipped | Loop exploit window |
| `NET_MOMENTUM_GAIN_CAP_TURN` | int | 20 | 10-40 | Momentum archetypes weak | Status/resource runaway |
| `momentum_cap` | int | 30 | 15-60 | Conversion builds constrained | Hoarding spikes |
| `overcharge_cap` | int | 8 | 4-16 | Temporary resource effects weak | One-turn burst abuse |
| `conversion_pass_cap_per_item` | int | 4 | 2-8 | Legit chain conversions truncate | Conversion loops/perf risk |
| `allow_cost_substitution_default` | bool | false | true/false | Less archetype variety | Resource identity blur |

Governance:
- All knobs are data-configurable and versioned.
- Any out-of-range adjustment requires replay fixture pass and economy exploit regression pass.

## Visual/Audio Requirements

Visual requirements:
- Mana orb bar with clear `current / max` readout and cap marker.
- Separate overcharge pips with “expiring” pulse at end-turn warning threshold.
- Momentum shown as stack badge near player portrait.
- Spend animation order mirrors payment source order (overcharge spend shown before mana spend).
- Clamp/refund/cap events use distinct icons (cap-lock, rewind, warning).

Audio requirements:
- Unique cues for: spend, gain, refund, cap-hit, and expiration.
- Overcharge expiration has soft warning cue at TurnEnd, non-modal.
- Batched micro-gain sounds in chain turns to reduce fatigue.

Presentation event contract:
- `resource_event_id`, `resource_id`, `delta`, `pre_value`, `post_value`, `reason_code`, `source_commit_id?`, `presentation_hint`.

## UI Requirements

1) Resource HUD
- Always visible mana current/max, overcharge, and momentum.
- Colorblind-safe state encoding plus numeric text.

2) Card affordability preview
- On hover/select, show effective cost and payment source plan.
- If unaffordable, show deterministic reason code text.

3) Commit feedback
- On commit, show exact paid amounts by source (example: `2 overcharge + 1 mana`).
- Display spend record in combat log entry.

4) Turn settlement strip
- At TurnEnd, show ordered settlement chips: conversion, expiration, clamp.

5) Explainability popover
- “Why can’t I play this?” includes:
  - required cost,
  - available resources by source,
  - active locks/caps/modifiers.

6) Debug overlay (dev)
- Per-turn counters: gross gain/spend/refund, net gain cap usage, dropped deltas.
- Determinism digest fragment for resource ledger.

## Acceptance Criteria

1) Deterministic spend parity
- Identical snapshot/seed/inputs produce identical spend records and resource ledger events across supported browsers.

2) Commit timing correctness
- Spend occurs exactly at CommitPlay and never after resolution.
- Test suite verifies no resource mutation on failed intent validation.

3) Cost calculation consistency
- Effective cost preview equals commit-time charged cost except when state changed between preview and commit, in which case commit recompute explanation appears.

4) Refund governance
- Refunds never exceed originating spend and obey per-turn refund cap.

5) Anti-loop containment
- Conversion/refund/gain loop fixtures terminate within caps and emit safeguard codes.

6) Cap and clamp visibility
- Every truncated/capped/clamped mutation emits exactly one explicit ledger event.

7) UI explainability
- No unaffordable play rejection without a mapped human-readable reason.

8) Integration compatibility
- TSRE + ERP integration tests pass for all resource operations in fixture card set.

9) Performance envelope
- Resource checks and commit spend operations stay within combat-step performance envelope defined by TSRE (no additional frame hitch in 95th percentile tests).

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should momentum be globally visible to enemies (for future enemy-reactive AI) or player-only in MVP? | Combat Design | Sprint 2 | Open |
| Do we want a small default mana carryover (e.g., 1) to reduce feel-bad waste, or keep strict zero-carry baseline? | Economy Design | Sprint 2 | Open |
| Should cost substitution (momentum->mana) remain effect-granted only, or become a broader archetype rule later? | Systems Design | Vertical Slice planning | Open |
| How much cap-hit detail should be exposed in non-debug UI to preserve clarity without overwhelming players? | UX | Sprint 2 | Open |
| Should challenge/ranked modes enforce stricter economy caps than casual mode? | Design Director | Pre-alpha | Open |