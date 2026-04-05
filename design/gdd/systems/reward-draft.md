# Reward Draft System

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats; Readable Tactical Clarity
> **Upstream References**: design/gdd/card-data-definitions.md, design/gdd/systems/unlock-option-gating.md, design/gdd/systems/relics-passive-modifiers.md, design/gdd/systems/enemy-encounters.md

## Overview

Reward Draft System (RDS) is the authoritative post-encounter offer generator for Dungeon Steward MVP.

It decides which cards, relics, and optional run choices are shown to the player after eligible reward checkpoints, using deterministic weighted sampling with strict eligibility and variety guardrails.

RDS goals:
- Keep rewards exciting and high-variety across runs.
- Keep progression low-grind by never withholding core viability behind excessive unlock pressure.
- Keep reward generation deterministic and replay-verifiable.
- Keep offer outcomes explainable: each shown/hidden item must be traceable to filters and weights.

RDS does not execute reward effects itself; it only generates and presents selectable offers. Selection application is delegated to downstream systems (Deck Lifecycle, Relic ownership, Mode/Option setup).

Out of scope (MVP):
- Player-to-player draft modes.
- Real-time reroll economies with premium currencies.
- Hidden live-ops tuning not represented in data/versioning.

## Player Fantasy

The player fantasy is:
- “After each fight, I get meaningful build decisions, not filler.”
- “I can feel my run identity forming through coherent options.”
- “I still see fresh possibilities instead of the same three offers forever.”
- “If something is missing, the game’s logic is fair and understandable.”

The reward screen should feel like strategic steering, not lottery confusion.

## Detailed Design

### Design Goals (Optional)

1) Variety without chaos
- Frequent exposure to distinct lines (cards/relics/options) while preserving enough consistency to build around choices.

2) Low-grind compatibility
- New profiles retain complete core-loop viability (`base_set` available).
- Unlocks mostly expand option space; they do not gate baseline run functionality.

3) Deterministic reproducibility
- Same seed + same profile snapshot + same run state + same prior reward history -> identical offers.

4) Explainable weighting
- Selection can be reconstructed from logged candidate set, filters, multipliers, normalization, and RNG draws.

### Core Rules

1) Reward checkpoints are deterministic
- Rewards are generated only at explicit checkpoints (for example: post-combat resolve, elite clear, boss clear, event resolution).
- No mid-animation or frame-time generation.

2) Reward channels are explicit
- MVP reward channels:
  - `card_offer`
  - `relic_offer`
  - `option_offer` (mode/challenge/special run options where applicable)
- Each channel has independent pool rules and offer size.

3) Eligibility-first pipeline
- Candidate generation order is fixed:
  1. Source pool build (by node/reward context)
  2. Unlock & Option Gating filter (`unlock_key` eligibility)
  3. Context legality filter (run node rules, duplicate policy, mode conflicts)
  4. Weight assembly
  5. Variety dampening modifiers
  6. Deterministic sampling without replacement
  7. Stable offer sorting for UI

4) Alignment with Card Data contract
- Card offer weighting must consume Card Data fields (`weight_base`, `pool_tags`, `exclusion_tags`, `unlock_key`, `rarity`, optional `weight_modifiers`).
- Card Data unlock multiplier is binary and sourced from UOG:
  - `A_unlock(card) in {0,1}`

5) Alignment with Unlock & Option Gating contract
- RDS calls UOG before weighting normalization.
- Ineligible content must be removed before probability computation.
- Lock state reasons are retained for analytics/debug and optional locked-entry UI variants.

6) Deterministic RNG isolation
- RDS never calls ambient/random runtime APIs.
- All randomness is consumed through indexed deterministic RNG service.
- Reward draws are stream-isolated from combat/effect draws.

7) No duplicate picks within one offer panel
- Sampling is without replacement inside each offer generation call.

8) Fail-safe behavior
- If eligible weighted set becomes empty, fallback to deterministic safety pool for that channel.
- Fallback pools are authored and versioned (`base.fallback_*`).

### Reward Contexts and Defaults (Optional)

MVP default checkpoints and bundle shapes:
- Standard combat clear:
  - `card_offer` (pick 1 of 3)
- Elite clear:
  - `card_offer` (pick 1 of 3)
  - `relic_offer` (pick 1 of 1 or 1 of 2 based on node config)
- Boss clear:
  - `relic_offer` (pick 1 of 3, rarity-skewed)
  - optional `option_offer` if mode rules allow

All bundle shapes are data-authored per node type; RDS only executes the configured policy.

### Candidate Ordering and Deterministic Sampling

Deterministic candidate sort key before sampling:
1. `content_type_priority` (fixed mapping: `card_offer=1`, `relic_offer=2`, `option_offer=3`)
2. `rarity_priority` (fixed mapping ascending power: `common=1`, `uncommon=2`, `rare=3`, `boss=4`)
3. `content_id` lexicographic ascending

Sampling algorithm (MVP): weighted draw without replacement by integer bucket walk.
- Compute non-negative integer bucket weights from clamped effective weight.
- Draw `roll = rng_u32(draw_index) mod total_weight`.
- Select first cumulative bucket greater than `roll`.
- Remove selected candidate, recompute total, repeat until offer size reached or pool exhausted.

Determinism requirements:
- Candidate list must be identically ordered across platforms.
- Float-to-int conversion for bucket weights must use fixed policy (defined in formulas).
- RNG draw index advancement is exactly one increment per draw attempt.

### States and Transitions

Reward generation lifecycle:
- Idle
- CheckpointTriggered
- CandidateAssembled
- CandidateFiltered
- Weighted
- Sampled
- OfferPresented
- ChoiceCommitted
- Closed

Primary transitions:
- Idle -> CheckpointTriggered (node/combat reward event)
- CheckpointTriggered -> CandidateAssembled
- CandidateAssembled -> CandidateFiltered
- CandidateFiltered -> Weighted
- Weighted -> Sampled
- Sampled -> OfferPresented
- OfferPresented -> ChoiceCommitted (player picks or skip path)
- ChoiceCommitted -> Closed

Invalid transitions:
- OfferPresented -> CandidateAssembled (no silent reroll)
- Closed -> OfferPresented (same offer instance cannot reopen without explicit resume contract)

### Data Model and API Contracts (Optional)

Reward generation request:
- `RewardDraftRequest`
  - `run_id`
  - `profile_id`
  - `reward_checkpoint_id`
  - `node_type`
  - `channel_configs[]` (offer count, pick count, pool tags, rarity policy)
  - `run_context_snapshot`
  - `mode_context_snapshot`
  - `hub_modifier_snapshot` (optional in schema, required when MHIS enabled)
  - `hub_modifier_version`
  - `reward_history_digest`

Reward generation response:
- `RewardDraftResult`
  - `draft_instance_id`
  - `offers[]` by channel
  - `rng_cursor_start`
  - `rng_cursor_end`
  - `generation_trace_id`
  - `fallback_used_flags[]`

Offer entry contract:
- `RewardOfferEntry`
  - `content_type`
  - `content_id`
  - `display_payload_ref`
  - `effective_weight_debug` (debug-only)
  - `selection_rank_index`
  - `eligibility_snapshot` (debug-only optional)

Selection commit request:
- `CommitRewardSelection(draft_instance_id, chosen_entry_ids[])`
- Must be idempotent by `(draft_instance_id, commit_event_id)`.

### RNG Contract Binding (Canonical)

RDS is bound to RNG/Seed & Run Generation Control canonical API and manifest contract.

Required API usage:
- Indexed draw (debug/replay reconstruction):
  - `DrawU32At(stream_key, draw_index) -> uint32`
- Cursor-consuming draw (runtime sampling):
  - `DrawU32Next(stream_key) -> uint32`

Required stream keys for reward generation:
- `reward.card`
- `reward.relic`
- `reward.option`

Contract requirements:
- RDS persists and restores per-stream cursor state through run snapshots (no reroll on resume).
- RDS pins reward policy/config versions inside run determinism manifest context.
- RDS logs `stream_key` + `draw_index` per sample step for replay verification.

### Interactions with Other Systems

1) Card Data & Definitions (hard upstream)
- Provides card pool metadata and weight fields.
- RDS applies Card Data weighting formula components for cards.

2) Unlock & Option Gating (hard upstream)
- Supplies deterministic eligibility by `unlock_key` and context.
- RDS must filter ineligible entries pre-normalization.

3) Relics/Passive Modifiers (hard-adjacent)
- Supplies relic duplicate policies and relic pool constraints.
- RDS respects unique/stacking eligibility before sampling.

4) Meta-Hub Investment System (hard upstream/adjacent)
- Supplies deterministic `hub_modifier_snapshot` and `hub_modifier_version` consumed as `A_hub` inputs.
- Snapshot is pinned per run/checkpoint request and must be included in generation trace for replay parity.

5) RNG/Seed service (hard upstream)
- Supplies deterministic indexed draws.
- RDS logs draw indices and stream IDs for replay verification.

6) Deck Lifecycle / Relic Ownership / Mode Option systems (hard downstream)
- Consume committed reward selections and apply runtime ownership/state changes.

7) UI systems (hard downstream)
- Present offers in stable order with clear rarity/type identity and optional explainability overlays.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a), b)`
- Boolean gates are represented as {0,1}

1) Card effective reward weight (aligned with Card Data)

`W_card_raw = weight_base * A_unlock * A_pool * A_hub * A_run * A_duplicates * A_variety * A_weight_mods`
`W_card = clamp(W_card_raw, 0, 10)`

Where:
- `A_unlock` from UOG eligibility, binary {0,1}
- `A_pool` from pool/exclusion tag legality, binary {0,1}
- `A_hub` hub modifier scalar (default 1.0)
- `A_run` run-context scalar clamp [0.5, 1.5]
- `A_duplicates` duplicate dampener floor 0.6 (or channel-specific)
- `A_variety` anti-repeat dampener clamp [0.5, 1.2]
- `A_weight_mods` deterministic aggregate of Card Data `weight_modifiers[]`:
  - Apply modifiers in stable order by `modifier_id` ascending.
  - Multiplicative fold: `A_weight_mods = Π clamp(mod_i, 0.5, 2.0)`.
  - Final `A_weight_mods` clamp [0.5, 2.0].

2) Relic effective weight

`W_relic_raw = relic_weight_base * A_unlock * A_pool * A_duplicate_policy * A_run_synergy * A_variety`
`W_relic = clamp(W_relic_raw, 0, RELIC_WEIGHT_CAP)`

MVP defaults:
- `A_run_synergy` clamp [0.75, 1.25]
- `A_duplicate_policy` binary eligibility from relic duplicate rules
- `RELIC_WEIGHT_CAP = 10`

3) Option effective weight

`W_option_raw = option_weight_base * A_unlock * A_mode_compat * A_context * A_variety`
`W_option = clamp(W_option_raw, 0, OPTION_WEIGHT_CAP)`

All gating terms that are hard legality constraints are binary.

MVP defaults:
- `OPTION_WEIGHT_CAP = 10`

4) Normalization for explainability

Given eligible set `E`:

`P(i) = W_i / Σ(W_j for j in E)`

If `Σ(W_j)=0`, use deterministic fallback pool `F` and recompute on `F`.

5) Integer bucket conversion (cross-platform stability)

`bucket_i = max(0, floor(W_i * WEIGHT_SCALE))`

MVP default:
- `WEIGHT_SCALE = 1000`

If all `bucket_i=0`, fallback pool activates.

6) Weighted draw without replacement

For draw step `t` over remaining set `R_t`:
- `T_t = Σ bucket_j for j in R_t`
- `roll_t = DrawU32At(stream_key, draw_index_t) mod T_t`
- Select first `k` in deterministic order where cumulative bucket exceeds `roll_t`
- `R_{t+1} = R_t \ {k}`

7) Variety dampener example

`A_variety(i) = clamp(1 - seen_recent(i) * V_repeat_penalty, V_floor, V_cap)`

MVP defaults:
- `V_repeat_penalty = 0.15`
- `V_floor = 0.5`
- `V_cap = 1.2`

## Edge Cases

1) Empty eligible set after gating
- Activate fallback pool for that channel.
- Emit `ERR_REWARD_POOL_EMPTY_AFTER_FILTER`.

2) Unknown unlock key at runtime
- Respect UOG runtime policy: treat as ineligible.
- Emit telemetry and continue deterministic generation.

3) All effective weights collapse to zero
- Fallback pool path; no divide-by-zero behavior.

4) Offer size exceeds eligible pool size
- Show all eligible items (or fallback fill if policy allows), preserve deterministic order.

5) Mid-offer unlock/profile updates
- Current open draft instance is immutable.
- New eligibility applies only on next checkpoint.

6) Save/load during open draft
- Restore exact offer entries, selection state, and RNG cursors.
- No reroll on resume.

7) Duplicate policy invalidation after candidate assembly
- Re-run legality filter before final presentation with deterministic reject ordering.

8) Node config requests unsupported channel
- Validation hard fail in content pipeline; runtime safe fallback skips channel with error event.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Card Data & Definitions | Upstream data provider | Hard | Provides card weight/pool/unlock metadata and clamps used by card reward weighting. |
| Unlock & Option Gating | Upstream eligibility provider | Hard | RDS evaluates `unlock_key` eligibility before weight normalization; consumes reason/state for diagnostics. |
| RNG/Seed & Run Generation Control | Upstream random service | Hard | Supplies indexed deterministic draws via stream + draw index contract. |
| Relics/Passive Modifiers | Upstream/adjacent data provider | Hard | Supplies relic duplicate/stack policies and relic pool constraints for eligibility filtering. |
| Deck Lifecycle System | Downstream consumer | Hard | Applies selected card rewards to run deck state. |
| Relic Ownership Runtime | Downstream consumer | Hard | Applies selected relic ownership and activation state. |
| Mode/Option Runtime | Downstream consumer | Soft in MVP, Hard post-MVP | Applies selected option rewards and validates mode conflicts. |
| Map/Node UI | Downstream consumer | Hard | Presents deterministic offers, stable ordering, and selection flow. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `offer_size_card` | int | 3 | 2-5 | Choices feel flat | Decision fatigue/UI clutter |
| `offer_size_relic` | int | 1 or 2 | 1-3 | Low excitement | Overhigh-roll variance |
| `WEIGHT_SCALE` | int | 1000 | 100-10000 | Coarse probability buckets | Integer overflow/perf cost |
| `RELIC_WEIGHT_CAP` | float | 10 | 5-20 | Relic weighting too compressed | Outlier relic dominance |
| `OPTION_WEIGHT_CAP` | float | 10 | 5-20 | Option channel too flat | Option outlier dominance |
| `A_run_clamp` | float range | 0.5-1.5 | 0.3-2.0 | Run context feels irrelevant | Overforced archetypes |
| `A_variety_floor` | float | 0.5 | 0.3-0.8 | Repeats dominate | Desired consistency lost |
| `V_repeat_penalty` | float | 0.15 | 0.05-0.30 | Anti-repeat too weak | Build coherence collapses |
| `fallback_pool_min_size` | int | 5 | 3-15 | Fallbacks repetitive | Content burden grows |
| `max_channels_per_checkpoint` | int | 2 | 1-4 | Sparse rewards | Screen bloat and pacing drag |
| `no_pick_allowance` | bool | false (cards), true (some options) | bool | Forced junk picks | Excessive skip abuse |

Governance:
- Any knob change must preserve low-grind baseline and deterministic replay equivalence for fixed seeds.

## Visual/Audio Requirements

Visual:
- Reward panels by channel with stable slot positions.
- Card/relic/option rarity identity and tags visible at glance.
- Optional explainability panel in debug mode (weights, filters, reason codes).

Audio:
- Distinct stingers for panel reveal and reward confirmation.
- Subtle denied cue for invalid/locked interactions.
- No repeated stinger spam when multiple channels open.

## UI Requirements

1) Stable presentation
- Offer entry order is deterministic and does not reshuffle while panel is open.

2) Explainable outcomes
- Debug/advanced tooltip can expose why an item was eligible/ineligible and major weight factors.

3) Clear pick rules
- UI clearly indicates pick count (`pick 1 of 3`, etc.) and whether skipping is allowed.

4) Lock and context feedback
- If locked entries are shown in special contexts, include UOG reason/hint text.

5) Resume safety
- On load/resume, open reward panel restores exact entries and selection state.

## Acceptance Criteria

1) Card Data alignment
- Card rewards use Card Data weighting fields and never include cards with `A_unlock=0`.

2) UOG alignment
- All channels filter by UOG eligibility before normalization/sampling.
- Ineligible items never appear in selectable offers.

3) Determinism
- Same seed + profile snapshot + run snapshot + reward history yields byte-identical offer outputs and RNG cursor advancement.

4) Explainability
- Generation trace can reconstruct candidate filtering and draw outcomes for every offer.

5) Variety guardrails
- Repeat-rate metrics remain within configured targets while preserving viable archetype continuity.

6) Fallback safety
- Empty/zero-weight pools always resolve to deterministic fallback behavior without crash or soft-lock.

7) Save/Resume integrity
- Open draft state survives save/load with no reroll and no duplicate commit side effects.

8) Performance
- Offer generation for 3 channels over 500 total candidates completes within 4 ms on target desktop browser hardware (excluding UI render).

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `rds_generation_calls_total`
- `rds_candidates_pre_filter_count{channel}`
- `rds_candidates_post_filter_count{channel}`
- `rds_fallback_used_total{channel,reason}`
- `rds_repeat_offer_rate{content_type}`
- `rds_rng_draws_per_offer_histogram`

Debug tools (dev only):
- Dump full generation trace for latest draft instance.
- Replay generation from `(seed, snapshot, checkpoint_id)`.
- Force channel fallback to validate UI and fail-safe behavior.

## Open Questions

1) Should MVP include optional one-time reroll for card offers, or defer to post-MVP?
2) Should option rewards be interleaved with card/relic panels or shown in separate sequential panels?
3) What exact repeat-rate target should define “high variety” for first balancing pass?
4) Should some archetype-signature cards have soft protection from over-dampening to preserve run identity?
5) Should reward-channel stream derivation remain root-only (`reward.card/relic/option`) or adopt scoped substreams by checkpoint for trace readability?