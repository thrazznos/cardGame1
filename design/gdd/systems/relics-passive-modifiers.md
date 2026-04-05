# Relics/Passive Modifiers

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillars**: Compounding Value Every Turn; Sequencing Mastery Over Raw Stats; High Run Variety, Low Grind; Readable Tactical Clarity
> **Upstream References**: design/gdd/systems/effect-resolution-pipeline.md, design/gdd/systems/unlock-option-gating.md, design/gdd/systems/turn-state-rules-engine.md, design/gdd/card-data-definitions.md

## Overview

Relics/Passive Modifiers (RPM) is the system that grants persistent, mostly automatic combat effects during a run. RPM exists to increase strategic line diversity and compounding decision value without introducing mandatory grind or opaque power spikes.

RPM governs:
- relic acquisition and ownership in a run,
- passive trigger registration and deterministic resolution hooks,
- stat/effect modifier application policy,
- duplicate handling, rarity bands, and anti-snowball guardrails,
- UI-visible explanation of why a passive fired and what it changed.

Scope split:
- TSRE decides when combat events/timing windows occur and global queue ordering.
- ERP computes and applies effect payloads once a relic passive trigger is queued.
- UOG determines whether relics/options are eligible to appear/select.
- RPM defines relic data contracts, trigger registration, and how passives convert events into ERP work.

Non-goals (MVP):
- permanent profile power-stat bonuses from relics,
- hidden passive rules not represented in logs/UI reason codes,
- frame-time or animation-time dependent trigger ordering.

## Player Fantasy

Player should feel:
- “My run engine comes together through relic synergies, not just bigger numbers.”
- “If I sequence correctly, my passives chain predictably and I can plan around them.”
- “Newly unlocked relics expand playstyle options, not mandatory grind power.”

Emotional outcomes:
- engine-building satisfaction from compounding interactions,
- trust from deterministic trigger behavior,
- replayability from varied passive combinations.

## Detailed Design

### Design Goals (Optional)

1) Strategic compounding over stat inflation
- RPM should favor conversion, timing, and conditional value over flat unconditional scaling.

2) Deterministic sequencing
- Passive effects must be replay-stable and explainable under TSRE + ERP contracts.

3) Low-grind progression compatibility
- Unlocking relics broadens option space; base viable relic set is available at new profile.

4) Readability at chain depth
- Even multi-passive turns must remain inspectable via queue/log/UI explanation surfaces.

### Core Rules

1) Relics are run-scoped owned instances
- Each acquired relic creates immutable `relic_instance_id` linked to static `relic_id`.
- Ownership persists for current run only (profile unlock state is managed by UOG, not RPM).

2) Every relic has an `unlock_key` and uses UOG eligibility
- `unlock_key` is required in relic data.
- Eligibility is resolved via UOG; unknown/missing keys fail content validation and runtime-lock fallback follows UOG policy.

3) RPM never mutates combat state directly
- Relics produce deterministic trigger intents and modifier descriptors.
- All combat mutations execute through ERP operation application.

4) Trigger model is explicit
- Passive effects bind to declared `trigger_event` values (example: `on_turn_start`, `on_card_play_commit`, `on_damage_dealt`, `on_status_applied`, `on_turn_end`).
- Trigger declarations include:
  - `timing_window` (`pre`, `main`, `post`)
  - `speed_class` (`fast`, `normal`, `slow`)
  - `trigger_cooldown_policy` (`none`, `once_per_turn`, `n_per_turn`, `once_per_combat`)
  - `trigger_cap_per_turn`

5) Passive resolution ordering is deterministic and TSRE-compatible
- Global ordering remains TSRE-owned.
- RPM defines local trigger tie-break keys before enqueue:
  - `event_phase_priority`
  - `trigger_timing_priority`
  - `owner_side_index`
  - `relic_instance_id`
  - `registration_seq`
- This local key is serialized into queued metadata and must not conflict with TSRE order semantics.

6) Modifier classes (MVP)
- `scalar_modifier`: modifies authored numeric params before ERP op apply.
- `replacement_hook`: transforms operation shape (must respect ERP replacement cap/loop prevention).
- `conditional_grant`: grants temporary status/resource/effect on predicate pass.
- `triggered_effect`: enqueues explicit ERP effect list.

7) Duplicate relic policy
- Each relic declares `duplicate_policy`:
  - `unique` (cannot be re-acquired)
  - `stack_linear` (additive bounded stacks)
  - `stack_diminishing` (each extra copy reduced coefficient)
  - `upgrade_instead` (duplicate converts to tier upgrade)
- Duplicate behavior must be data-authored and deterministic.

8) Compounding guardrails (hard)
- Per-relic and per-turn trigger caps are mandatory.
- Global passive trigger budget per turn is enforced (aligned to TSRE/ERP anti-loop budgets).
- Replacement hooks from relics share ERP replacement caps and fingerprint loop prevention.

9) Readability contract
- Every passive trigger attempt emits one of:
  - applied,
  - prevented/blocked,
  - fizzled (invalid context),
  - cap-dropped.
- Each emits reason code + human-readable text mapping key.

10) MVP content philosophy
- Starter relic pool supports at least 3 archetype lines without unlocks.
- Unlockable relics primarily add routing/conditional play patterns, not mandatory raw throughput.

### States and Transitions

Relic instance lifecycle:
- DefinedData
- EligibleInPool
- Offered
- Acquired
- Active
- Suppressed (temporarily disabled by context/rule)
- Exhausted (for one-shot relics)
- Removed (run end or explicit remove effect)

Trigger execution states (per trigger attempt):
- EventObserved
- GateCheck
- EnqueueTrigger
- ResolvingViaERP
- Applied | Fizzled | DroppedByCap

Primary transitions:
- DefinedData -> EligibleInPool (UOG pass)
- EligibleInPool -> Offered (reward generation)
- Offered -> Acquired (player selection)
- Acquired -> Active (immediate unless delayed activation flag)
- Active -> Suppressed (context gate fails, silence debuff, etc.)
- Suppressed -> Active (gate restored)
- Active -> Exhausted (one-shot consumed)
- Active/Exhausted -> Removed (run end or explicit removal)

Illegal transitions:
- Offered -> Active without acquisition
- Removed -> Active in same run
- Exhausted -> Applied without explicit recharge rule

### Data Model and API Contracts (Optional)

Relic data minimum schema:
- `relic_id`
- `schema_version`
- `rarity`
- `unlock_key`
- `pool_tags[]`
- `duplicate_policy`
- `passive_nodes[]`
- `ui_name_key`, `ui_rules_key`, `icon_key`, `vfx_key`, `sfx_key`

Passive node schema:
- `passive_node_id`
- `trigger_event`
- `timing_window`
- `speed_class`
- `predicate_clause` (typed condition tree)
- `effect_payload_ref` OR `modifier_descriptor`
- `cooldown_policy`
- `trigger_cap_per_turn`
- `priority_bias` (for deterministic comparator only)

Runtime registration contract:
- `RegisterRelicPassives(relic_instance_id, passive_nodes[], registration_seq_base)`
- Returns deterministic `PassiveRegistrationResult {registered_ids[], rejected_ids[], reason_codes[]}`

Runtime trigger contract:
- `EvaluatePassiveTriggers(event_context)`
- Returns ordered list of `PassiveTriggerIntent[]` ready for TSRE enqueue.

ERP bridge contract:
- `PassiveTriggerIntent` includes:
  - `source_type = relic_passive`
  - `source_instance_id = relic_instance_id`
  - `effect_list[]` (ERP-valid effect payload)
  - `bound_targets[]`
  - `invalid_target_policy`
  - `order_metadata` (local comparator + TSRE fields)

### Reward + RNG Contract Binding (Canonical)

RPM binds to approved Reward Draft and RNG/Seed contracts.

Required alignment:
- Relic offer candidates are generated only at deterministic reward checkpoints.
- Sampling uses canonical reward stream (`reward.relic`) via indexed RNG API.
- Filtering order remains deterministic:
  1) candidate source set
  2) UOG eligibility filter
  3) duplicate-policy filter
  4) rarity/weight normalization
  5) deterministic sampling
- Save/load persists relic runtime state and RNG cursor state without reroll.

### Interactions with Other Systems

1) Effect Resolution Pipeline (hard)
- RPM-generated effects must be valid ERP `effects[]` payloads.
- Replacement-type passives use ERP replacement precedence and caps.
- RPM cannot bypass ERP clamps, stack policy, rounding, or error code emission.

2) Unlock & Option Gating (hard)
- Relic offers and mode-dependent relic enabling use UOG `unlock_key` eligibility.
- Runtime unknown key fallback remains locked with telemetry (UOG policy).
- RPM does not own unlock progression state; only consumes eligibility outputs.

3) Turn State & Rules Engine (hard)
- TSRE emits event boundaries that RPM listens to for trigger evaluation.
- TSRE owns global queue order and resolve lock.
- RPM trigger enqueue must respect TSRE queue/item caps and phase legality.

4) Mana & Resource Economy (adjacent hard)
- Relic effects modifying costs/resources must flow through ERP->MRE mutation path.
- No direct resource mutation outside ledger events.

5) Enemy Encounter System (adjacent)
- Enemy telegraphed actions can satisfy passive predicates (example: on enemy buff apply).
- Trigger eligibility reads only authoritative visible state/events.

6) Combat UI/HUD (hard downstream)
- UI needs passive trigger badges, reason codes, cooldown/uses left, and ordering explanation hooks.

7) Reward Draft System (hard downstream)
- Reward system requests eligible relic pool from UOG + RPM duplicate policy constraints.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a),b)`
- Integer/fixed-point conventions follow ERP.

1) Relic Offer Eligibility (alignment with UOG)

`eligible_relic(r) = gate_profile(r.unlock_key) * gate_run(r.unlock_key) * gate_mode(r.unlock_key) * gate_duplicate(r)`

Where:
- first three gates are UOG outputs in {0,1},
- `gate_duplicate(r)` is RPM duplicate-policy eligibility in {0,1}.

Constraint:
- If UOG returns unknown/locked, `eligible_relic=0` regardless of duplicate state.

2) Relic Offer Weight

`offer_weight(r) = weight_base(r) * eligible_relic(r) * W_rarity(r) * W_run_synergy(r) * W_recent_seen_damp(r)`

MVP defaults:
- `weight_base = 1.0`
- `W_rarity`: common 1.0, uncommon 0.65, rare 0.35
- `W_run_synergy` clamped [0.75, 1.25]
- `W_recent_seen_damp` floor 0.5

Failure behavior:
- If all candidate weights become 0, fallback to deterministic safety relic subset tagged `base.fallback_relic_pool`.

3) Passive Trigger Chance

For passives with chance fields:

`triggered = (rng_u32(cursor_i) % 10000) < chance_bp`

- `chance_bp` in [0..10000]
- one cursor increment per chance check
- deterministic order of checks follows trigger comparator

4) Diminishing Duplicate Coefficient

For `duplicate_policy = stack_diminishing` and copy count `k >= 1`:

`coeff_k = max(coeff_floor, 1 / (1 + alpha * (k-1)))`

MVP defaults:
- `alpha = 0.35`
- `coeff_floor = 0.40`
- effective modifier: `effective_bonus = base_bonus * coeff_k`

5) Passive Budget Guardrail

Per turn passive trigger budget:

`budget_remaining_t = B_turn - triggers_fired_t`

- default `B_turn = 20`
- if `budget_remaining_t <= 0`, additional passive trigger intents are dropped in deterministic comparator order with `ERR_PASSIVE_BUDGET_EXCEEDED`.

6) Scalar Modifier Assembly (ERP alignment)

For any relic-contributed scalar modifier to an ERP op:

`mag_q' = mag_q + relic_flat_q`
`mag_q' = mag_q' * (SCALE + relic_mult_q) / SCALE`
`mag_q_final = clamp(mag_q', op_min_q, op_max_q)`

- final integer conversion and clamp policy is ERP-authoritative.

## Edge Cases

1) Relic references unknown `unlock_key`
- Content pipeline: hard fail.
- Runtime mismatch: relic is ineligible/locked, telemetry `ERR_UNLOCK_KEY_UNKNOWN_RUNTIME`.

2) Passive trigger fires after relic removed in same queue window
- Snapshot-at-commit policy: if trigger intent already committed, resolve with committed snapshot; later triggers from removed relic are blocked.

3) Duplicate relic acquired for `unique` policy
- Offer should be prefiltered; if forced by debug/corrupt path, convert to deterministic fallback reward (gold/resource/shard placeholder) with reason event.

4) Replacement passives create loop
- ERP replacement fingerprint/pass cap prevents infinite traversal; emit loop-prevented reason.

5) Trigger cap hit on one passive
- Additional attempts for that passive this turn drop with explicit reason; other passives continue.

6) Global passive budget hit
- Remaining pending passive intents for that turn drop in deterministic order, no soft random pruning.

7) Passive targets become invalid between enqueue and resolve
- Apply declared `invalid_target_policy` exactly as ERP/card contract.

8) Mid-run unlock change affects relic pool
- Current presented offer remains unchanged; new eligibility applies at next deterministic reward checkpoint.

9) Save/load during cooldown state
- Cooldown counters and trigger counts must restore exactly; mismatch is determinism test failure.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Effect Resolution Pipeline | Upstream executor | Hard | RPM emits ERP-valid effect payloads and consumes ERP result/error events; ERP remains mutation authority. |
| Unlock & Option Gating | Upstream eligibility | Hard | RPM consumes deterministic eligibility for relic availability and mode compatibility via `unlock_key`. |
| Turn State & Rules Engine | Upstream event/order authority | Hard | RPM listens to TSRE event windows and enqueues trigger intents through TSRE queue contracts. |
| Reward Draft System | Downstream/adjacent | Hard | Reward generation must filter by UOG + RPM duplicate policy before normalization/sampling. |
| RNG/Seed & Run Generation | Upstream random service | Hard | Offer and chance checks consume indexed deterministic RNG cursor. |
| Combat UI/HUD | Downstream | Hard | UI surfaces trigger reasons, ordering, cooldown/uses, and passive status badges. |
| Profile Progression Save | Indirect via UOG | Hard indirect | RPM does not read profile unlock state directly; accesses through UOG responses only. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `passive_budget_per_turn` | int | 20 | 10-36 | Synergy lines feel cut off | Long resolve chains/perf risk |
| `trigger_cap_default_per_passive` | int | 3 | 1-8 | Passive identity too muted | Trigger spam/loop pressure |
| `duplicate_diminish_alpha` | float | 0.35 | 0.15-0.6 | Duplicates too strong | Duplicates feel worthless |
| `duplicate_coeff_floor` | float | 0.40 | 0.25-0.7 | Hard anti-synergy feel | Snowball from stackable relics |
| `rarity_weight_common` | float | 1.0 | 0.6-1.4 | Commons underrepresented | Run variety flattens |
| `rarity_weight_uncommon` | float | 0.65 | 0.4-1.0 | Mid-tier relics rare | Mid-tier floods pool |
| `rarity_weight_rare` | float | 0.35 | 0.2-0.8 | Rare fantasy absent | High-roll meta spikes |
| `run_synergy_weight_clamp` | range | 0.75-1.25 | 0.6-1.4 | Synergy drafting irrelevant | Over-forced archetype rails |
| `recent_seen_damp_floor` | float | 0.5 | 0.3-0.8 | Repeat offers too common | Desired repeats impossible |
| `one_shot_relic_share_cap` | float | 0.25 | 0.1-0.4 | Fewer tactical burst tools | Too many dead-state relics |

Governance:
- Knob changes must preserve low-grind baseline and UOG core-access guarantees.
- Any out-of-safe-range change requires deterministic replay fixture pass and perf smoke pass.

## Visual/Audio Requirements

Visual:
- Relic tray with per-relic state chips: Active, Suppressed, Exhausted, Cooldown(N).
- Trigger pulse on source relic at enqueue moment; distinct colors/icons for applied vs blocked/fizzled.
- Chain-heavy turns use compact batching indicators to avoid VFX spam.

Audio:
- Soft cue on passive trigger enqueue.
- Distinct blocked/fizzle cue (short, non-intrusive).
- Rare relic trigger can use stronger accent cue, but batch-limited per second.

Presentation event contract:
- `relic_instance_id`, `passive_node_id`, `trigger_event`, `outcome_flag`, `reason_code`, `order_index_ref`, `vfx_event_id`, `sfx_event_id`.

## UI Requirements

1) Relic Bar / Passive Panel
- Always visible in combat.
- Shows icon, short rule summary, cooldown/uses left, suppression state.

2) Trigger Explanation
- Hover/click shows last trigger outcome and reason.
- “Why did this fire first?” popover uses comparator chain and TSRE order reference.

3) Offer Screen Integration
- Locked relics (if shown) must include UOG reason/hint.
- Ineligible due to mode context shows temporary badge, not permanent lock language.

4) Combat Log Integration
- Every passive trigger attempt writes one row with outcome and reason.
- Expanded debug row includes ERP operation ids and magnitude breakdown if applicable.

5) Input Safety
- During ResolveLock, relic interactions are inspect-only; no toggles that mutate order.

## Acceptance Criteria

1) ERP contract alignment
- 100% of RPM-emitted trigger payloads validate as ERP effect payloads or fail deterministically with explicit error code.

2) UOG contract alignment
- Relic offer generation never includes entries with failed `unlock_key` eligibility.
- Unknown keys are blocked pre-ship and runtime-fallback locked with telemetry.

3) Deterministic ordering
- Same seed + profile snapshot + run state + inputs yields identical passive trigger order, outcomes, and state hash across supported browsers.

4) Guardrail containment
- Loop/cap fixtures demonstrate queue drain completion without hang when high-chain passives are present.

5) Duplicate policy correctness
- Fixture suite validates `unique`, `stack_linear`, `stack_diminishing`, and `upgrade_instead` deterministically.

6) Readability
- Every trigger attempt (applied/blocked/fizzled/dropped) emits reason code and mapped player-readable text.

7) Low-grind compliance
- New profile has access to baseline viable relic pool through `base_set`/equivalent open keys; locked relics increase variety, not mandatory baseline power.

8) Performance
- 20 simultaneous passive trigger evaluations plus ERP enqueue stays within MVP per-frame resolve budget on target browser hardware.

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `rpm_trigger_attempt_total{outcome}`
- `rpm_trigger_drop_cap_total{cap_type}`
- `rpm_relic_offer_filtered_total{reason}`
- `rpm_duplicate_policy_resolution_total{policy}`
- `rpm_order_mismatch_detected_total`

Debug tools (dev only):
- Dump active relic/passive registry with registration sequence.
- Trace comparator chain for a selected trigger.
- Force-trigger specific passive node for fixture validation.

## Open Questions

1) Should MVP include any player-controlled relic activation toggles, or keep all passives automatic?
2) How many relic rarity tiers are needed at MVP launch vs post-MVP content growth?
3) Should one-shot relics consume an inventory slot after exhaustion or remain as inert history markers?
4) What fallback reward is preferred for forced duplicate on `unique` policy in final economy design?
5) Should mode options be allowed to globally suppress relic categories (for challenge presets) in MVP?