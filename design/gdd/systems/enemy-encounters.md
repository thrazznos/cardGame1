# Enemy Encounter System

> **Status**: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-04
> Implements Pillars: Readable Tactical Clarity; Sequencing Mastery Over Raw Stats; High Run Variety, Low Grind
> Upstream References: design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/systems/deck-lifecycle.md, design/gdd/systems/mana-resource-economy.md, design/gdd/card-data-definitions.md

## Overview

Enemy Encounter System (EES) is the authoritative subsystem for enemy behavior in combat. It defines:
- encounter composition (which enemies appear and in what formation),
- enemy intent generation (what each enemy plans to do),
- turn scripts and policy selection (scripted, weighted, adaptive),
- player-facing telegraphing rules,
- scaling rules across floors/difficulty tiers,
- deterministic integration with TSRE queue scheduling.

Design intent:
- Enemy turns must be legible enough for tactical planning.
- Enemy behavior must create sequencing puzzles, not opaque coin flips.
- Replay of identical seed + state + inputs must produce identical enemy decisions and outcomes.

Scope split:
- TSRE decides phase gates and final queue ordering.
- ERP resolves effect math of enemy actions once queued.
- EES decides which enemy action intents are generated, with explicit deterministic metadata.

Non-goals (MVP):
- Hidden reaction logic outside event stream.
- Frame-time-driven AI behavior changes.
- Machine-learned or non-replayable behavior policies.

## Player Fantasy

The player should feel like they are outsmarting dangerous but readable opponents:
- “I can see what enemies are planning and sequence around it.”
- “When enemies pivot, I understand the trigger and can adapt.”
- “Losses feel fair because intent order and resolution are explainable.”

Emotional outcome:
- Tension from pressure, not ambiguity.
- Satisfaction from predicting and disrupting enemy plans.
- Replayability from enemy pattern variety that stays deterministic.

## Detailed Design

### Core Rules

1) Encounter is data-authored, runtime-instanced
- Encounter templates define enemy roster pools, formation slots, tags, and scaling hooks.
- Runtime creates enemy instances with immutable `enemy_instance_id` and deterministic spawn sequence.

2) Enemy behavior uses explicit intent objects
- Every enemy action for EnemyPhase is represented as `EnemyActionIntent`.
- Canonical schema is defined in "Encounter Data Model and Contracts" and is the only valid runtime shape.
- Field aliases are not allowed in MVP runtime payloads (no dual-name variants).

3) Intent generation is deterministic
- Enemy intent generation may consume RNG only through indexed RNG service.
- Selection order is fixed by `enemy_slot_index` then `enemy_instance_id`.
- Weighted choices are resolved by deterministic sorted candidate list + indexed RNG roll.

4) Telegraphing is authoritative and binding
- Intent reveal occurs in EnemyIntentReveal state before EnemyActionResolve.
- Telegraphed fields are binding unless action explicitly carries a data flag allowing deterministic retarget/fallback (`retarget_if_possible`, `retarget_random_deterministic`, `fizzle`).
- Any divergence between telegraph and execution must emit a reason code event.

5) Script modes (MVP)
- `fixed_cycle`: deterministic loop over authored script steps.
- `conditional_branch`: deterministic branch by explicit predicates evaluated against authoritative state.
- `weighted_policy`: weighted candidate set with deterministic RNG selection.
- `state_reactive`: deterministic priority score from visible combat state; no hidden information reads.

6) Enemy actions use same TSRE queue semantics as player actions
- EES submits intents to TSRE during EnemyPhase gate.
- TSRE converts intents into resolve items ordered by global `order_key`.
- Enemy action ordering never depends on animation timing.

7) Target policy is explicit and stable
- `lock_on_commit`: target set fixed at intent reveal.
- `lock_on_resolve`: target computed at action resolve from deterministic candidate ordering.
- `retarget_if_possible` and `retarget_random_deterministic` behaviors mirror card invalid target policy rules.

8) Multi-enemy encounter coordination
- Enemies can publish encounter-scoped signals (for example `ally_wounded`, `shield_broken`, `summoner_alive`).
- Signals are deterministic event flags consumed only at script evaluation boundaries.
- No mid-resolution reactive interruption outside queued triggers.

9) Reinforcements and summons are bounded
- Summon/reinforcement actions must be explicit intent outcomes.
- Spawn limits per turn and per encounter prevent board-flood loops.
- New entities enter with deterministic insertion order and spawn sickness policy (MVP: cannot act until next EnemyPhase unless explicit `spawn_ready=true`).

10) Scaling is layered and capped
- Encounter difficulty scales from base template by floor depth, biome tier, ascension/modifier tier, and elite/boss flags.
- Scaling affects HP, damage, status potency, and script aggressiveness weights within safe ranges.

11) Anti-stall and anti-loop guardrails
- Turn pressure systems (enrage/escalation) activate if combat exceeds configured turn thresholds.
- Per-turn enemy action count and generated-trigger caps are enforced through TSRE/ERP guardrails.

12) Readability-first logging
- Every intent generation, reveal, mutation, and resolve emits structured events with reason codes:
  - `EVENT_ENEMY_INTENT_GENERATED`
  - `EVENT_ENEMY_INTENT_REVEALED`
  - `EVENT_ENEMY_INTENT_MUTATED`
  - `EVENT_ENEMY_ACTION_RESOLVED`
  - `ERR_ENEMY_INTENT_INVALID`

### States and Transitions

Encounter lifecycle states:
- EncounterInit
- FormationSpawn
- TurnLoopActive
- ReinforcementWindow (optional)
- EncounterEnd

Enemy AI sub-states (per enemy):
- Idle
- IntentPlanning
- IntentRevealed
- AwaitResolve
- ActionResolved
- Defeated

EnemyPhase flow (aligned to TSRE):
1. EnemyIntentReveal
   - Build/refresh intents for active enemies in deterministic enemy order.
   - Publish telegraphs to UI and log.
2. EnemyActionResolve
   - Submit intents to TSRE queue.
   - TSRE drains queue with global ordering.
3. EnemyPostResolve
   - Execute end-of-enemy-phase script hooks and expiry checks.

Legal transitions:
- EncounterInit -> FormationSpawn
- FormationSpawn -> TurnLoopActive
- Idle -> IntentPlanning
- IntentPlanning -> IntentRevealed
- IntentRevealed -> AwaitResolve
- AwaitResolve -> ActionResolved
- ActionResolved -> Idle (next turn)
- Any live state -> Defeated (hp <= 0)
- TurnLoopActive -> EncounterEnd (all enemies defeated or player defeated)

Illegal transitions (hard reject):
- Idle -> ActionResolved (without planning/reveal)
- Defeated -> IntentPlanning
- EncounterEnd -> TurnLoopActive

### Encounter Data Model and Contracts

Encounter template minimum schema:
- `encounter_id`
- `encounter_type` (normal/elite/boss/event_combat)
- `biome_tag`
- `threat_budget_base`
- `formation_slots[]`
- `enemy_pool_refs[]`
- `reinforcement_rules`
- `telegraph_style_profile`
- `scaling_profile_id`

Enemy behavior profile minimum schema:
- `enemy_id`
- `stats_base {hp, shield, armor, speed}`
- `intent_library[]`
- `script_mode`
- `script_table[]`
- `targeting_profile`
- `ai_tags[]`
- `reward_weight`

EnemyActionIntent runtime contract (canonical):
- `intent_id`
- `enemy_instance_id`
- `turn_index`
- `phase_index`
- `timing_window`
- `speed_class`
- `script_step_index`
- `telegraph_key`
- `telegraph_payload`
- `target_policy`
- `target_snapshot[]`
- `effect_payload_ref`
- `enqueue_hint_priority`
- `rng_call_index_start`

Alias policy (MVP):
- Deprecated aliases such as `declared_target_policy`, `declared_targets_snapshot`, and `telegraph_magnitude_preview` are not accepted at runtime.
- Content/build validators must fail on alias presence with `ERR_INTENT_SCHEMA_ALIAS_FORBIDDEN`.

### Interactions with Other Systems

1) Turn State & Rules Engine (hard)
- EES submits `EnemyActionIntent[]` only at EnemyPhase gate.
- TSRE validates legality, assigns `enqueue_sequence_id`, and orders by global key.
- EES cannot bypass ResolveLock or mutate queue order post-commit.

2) Effect Resolution Pipeline (hard)
- ERP resolves enemy effect payloads exactly like player effects.
- `effect_payload_ref` binding contract:
  - At intent commit, `effect_payload_ref` is resolved into immutable `effect_list[]` and hashed as `effect_payload_digest`.
  - TSRE queue item stores `{effect_payload_ref, effect_payload_digest, resolved_effect_list_version}`.
  - ERP executes only the committed immutable `effect_list[]`; live data hot-swaps are disallowed for that committed item.
- EES may annotate intent metadata for ERP explanation text.
- Replacement/fizzle/retarget outcomes follow ERP policies and emit enemy-specific reason tags.

3) Mana & Resource Economy (hard-adjacent)
- Enemy resources (if present) are managed through MRE-compatible ledger ops.
- Enemy drains/locks on player resources are expressed as ERP resource deltas, not ad-hoc side effects.

4) Deck Lifecycle System (hard-adjacent)
- Enemy actions that force draw/discard/exhaust/tax use DLS requests via ERP.
- No direct deck mutation from EES.

5) Card Data & Definitions (hard)
- Enemy intent targeting filters and counter-tags must remain compatible with card targeting and status taxonomy.
- Any enemy-generated temporary cards must comply with card schema and DLS generated-card policy.

6) RNG/Seed service (hard)
- Encounter composition and weighted behavior decisions use indexed deterministic RNG.
- EES uses canonical streams: `encounter.composition`, `encounter.intent`, `encounter.targeting`, `encounter.reinforcement`.
- All RNG draw indices are logged for replay verification.

7) Combat UI/HUD (hard downstream)
- UI receives revealed intents, order chips, threat previews, and mutation reasons.
- UI cannot alter intent content; it only displays authoritative event stream.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a),b)`
- `floor_i` = current floor index (1-based)
- `tier` = difficulty tier scalar

1) Encounter threat budget

`threat_budget = clamp(B_base + floor((floor_i - 1) * B_floor_ramp) + B_tier_bonus + B_biome_mod, B_min, B_max)`

MVP defaults:
- `B_base = 100`
- `B_floor_ramp = 12`
- `B_tier_bonus = 0`
- `B_biome_mod = 0`
- `B_min = 60`
- `B_max = 400`

Safe ranges:
- `B_base` [80, 140]
- `B_floor_ramp` [8, 18]
- `B_max` [300, 600]

Failure behavior:
- Over-budget authored encounter at build time: validation fail.
- Runtime overflow from reinforcements: clamp spawn and emit `ERR_THREAT_BUDGET_CAP`.

2) Enemy stat scaling

For each enemy stat `S` in {hp, damage, shield}:

`S_scaled = floor(S_base * (1 + floor_i * S_floor_mult + tier * S_tier_mult + elite_flag * S_elite_mult))`
`S_final = clamp(S_scaled + S_flat_bonus, S_min, S_cap)`

MVP defaults:
- `S_floor_mult = 0.035`
- `S_tier_mult = 0.08`
- `S_elite_mult = 0.20`
- `S_cap`: hp 9999, damage 999, shield 9999

Safe ranges:
- `S_floor_mult` [0.02, 0.06]
- `S_tier_mult` [0.04, 0.15]
- `S_elite_mult` [0.10, 0.35]

Failure behavior:
- Cap clamp emits `WARN_ENEMY_STAT_CLAMPED`.

3) Weighted intent selection score

For each candidate intent `i`:

`score_i = max(0, w_base_i + w_turn_i + w_state_i + w_counter_i + w_cooldown_i + w_script_bias_i)`

Selection:
- Build candidate list sorted by `intent_id` ascending.
- Compute `sum = Σ score_i`.
- If `sum = 0`, fallback to lowest `fallback_priority` intent.
- Else deterministic draw:
  - `roll = rng_u32(rng_idx) mod sum`
  - pick first cumulative bucket > `roll`.

MVP defaults:
- `w_base_i` authored per intent [1..100]
- `w_cooldown_i` default `-50` when on cooldown
- `w_counter_i` from observed player-state tags (range -40..+40)

Failure behavior:
- Missing weight field defaults to 0 with `WARN_INTENT_WEIGHT_DEFAULTED`.
- No legal candidates: apply `intent_noop_guard` and emit `ERR_NO_LEGAL_INTENT`.

4) Telegraph horizon and certainty

`telegraph_horizon_turns = clamp(H_base + H_boss_bonus + H_status_mod, H_min, H_max)`

MVP defaults:
- `H_base = 1`
- `H_boss_bonus = 1` (boss only)
- `H_status_mod = 0`
- `H_min = 1`
- `H_max = 2`

Execution certainty classes:
- `exact` (magnitude locked)
- `ranged` (min/max locked)
- `pattern_only` (action family locked, exact target may vary)

Failure behavior:
- Hidden certainty downgrade disallowed; must emit `EVENT_ENEMY_INTENT_MUTATED` with reason.

5) Reinforcement pacing

`reinforcement_points_turn = clamp(R_base + floor(turn_index / R_turn_step) + R_modifier, 0, R_cap)`

Spawn allowed if:
`reinforcement_points_bank >= reinforcement_cost_unit` and `active_enemies < ACTIVE_ENEMY_CAP`

MVP defaults:
- `R_base = 0`
- `R_turn_step = 3`
- `R_cap = 6`
- `ACTIVE_ENEMY_CAP = 5`

Safe ranges:
- `R_turn_step` [2, 5]
- `ACTIVE_ENEMY_CAP` [3, 6]

Failure behavior:
- Spawn attempt over cap is rejected with `ERR_ACTIVE_ENEMY_CAP`.

6) Enrage/escalation anti-stall

If `turn_index >= ENRAGE_START_TURN`:
`enrage_stacks = min(ENRAGE_MAX, turn_index - ENRAGE_START_TURN + 1)`
`damage_mult_enrage = 1 + enrage_stacks * ENRAGE_DAMAGE_STEP`

MVP defaults:
- `ENRAGE_START_TURN = 12`
- `ENRAGE_MAX = 8`
- `ENRAGE_DAMAGE_STEP = 0.05`

Safe ranges:
- `ENRAGE_START_TURN` [8, 16]
- `ENRAGE_DAMAGE_STEP` [0.03, 0.10]

Failure behavior:
- If enrage would exceed cap, clamp and log `WARN_ENRAGE_CLAMPED`.

7) Enemy intent queue pressure cap

`enemy_intents_committed_turn <= ENEMY_INTENT_CAP_TURN`

MVP default:
- `ENEMY_INTENT_CAP_TURN = 24`

Safe range:
- [12, 40]

Failure behavior:
- Additional intents dropped newest-first with `ERR_ENEMY_INTENT_CAP_REACHED`.

8) Determinism digest extension (encounter)

`encounter_hash_next = FNV1a64(encounter_hash_prev || encounter_id || enemy_state_digest || intent_digest || rng_call_index || turn_index)`

Used with TSRE/ERP/MRE/DLS hash chain for replay verification.

## Edge Cases

1) Telegraphed target dies before action resolves
- Apply intent target policy (`fizzle` / deterministic retarget). Emit explicit reason.

2) Enemy stunned/silenced after intent reveal
- Intent remains in queue but resolves to no-op or altered payload per status rules, with mutation event.

3) Enemy defeated before its queued action
- Queued action fizzles unless intent has `persist_after_source_death` flag.

4) Simultaneous multiple enemy intents same timing/speed
- TSRE tie-break by enqueue sequence then source instance ID.

5) Reinforcement spawn into full board
- Spawn denied deterministically with cap reason code.

6) Script branch reads hidden/uninitialized value
- Validation fail in content pipeline; runtime fallback to safe idle intent with telemetry.

7) Weighted policy with all zero/negative scores
- Deterministic fallback intent selected; no random undefined behavior.

8) Boss phase transition and queued old-phase intent collision
- Phase shift applies at boundary; already committed intents resolve unless explicitly canceled by phase script rule.

9) Enemy action requests illegal deck/resource mutation
- Rejected by DLS/MRE contracts; intent still considered resolved with error event.

10) Determinism replay mismatch isolated to intent selection
- Emit replay trace: candidate list, scores, rng index, selected intent ID.

## Dependencies

Hard upstream dependencies:
- Turn State & Rules Engine (phase gates, queue ordering, resolve lock)
- Effect Resolution Pipeline (action execution)
- Card Data & Definitions (taxonomy and targeting compatibility)
- RNG/Seed service (deterministic selection)

Hard-adjacent dependencies:
- Mana & Resource Economy (resource drain/lock effects)
- Deck Lifecycle System (draw/discard/exhaust impacts from enemy effects)

Downstream dependents:
- Combat Balance Model
- Map/Pathing System
- Combat UI/HUD
- Telemetry/Debug tooling

Integration contract (MVP):
- `build_enemy_intents(EncounterAIContext)`
  - input: `{encounter_id, turn_index, enemy_snapshots[], visible_player_state, rng_stream_cursors, determinism_manifest_ref}`
  - output: `EnemyActionIntent[]` (deterministic order)
- `submit_enemy_intents_to_tsre(EnemyActionIntent[])`
  - output: `{accepted_intents[], rejected_intents[], enqueue_sequence_ids[]}`
- `get_revealed_intents_view()`
  - output: UI-safe telegraph payloads + certainty classes + reason text keys

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `B_base` | int | 100 | 80-140 | Encounters too easy | Early spike difficulty |
| `B_floor_ramp` | int | 12 | 8-18 | Flat progression | Overtuned late floors |
| `S_floor_mult` | float | 0.035 | 0.02-0.06 | Enemies scale weakly | Stat bloat |
| `S_tier_mult` | float | 0.08 | 0.04-0.15 | Difficulty tiers feel same | Tier cliffs |
| `ENRAGE_START_TURN` | int | 12 | 8-16 | Stall metas persist | Punishing long fights |
| `ENRAGE_DAMAGE_STEP` | float | 0.05 | 0.03-0.10 | Anti-stall weak | Burst lethality spikes |
| `ACTIVE_ENEMY_CAP` | int | 5 | 3-6 | Summoner fantasy clipped | UI clutter/perf pressure |
| `ENEMY_INTENT_CAP_TURN` | int | 24 | 12-40 | Scripted variety clipped | Queue pressure/perf risk |
| `H_max` | int | 2 | 1-3 | Low planning horizon | Over-predictable fights |
| `w_cooldown_i` | int | -50 | -80 to -20 | Intent spam loops | Interesting repeats suppressed |
| `intent_mutation_visibility` | bool | true | true/false* | Hidden unfair pivots if false | Extra UI noise if true |

`*` Must remain true for ranked/challenge/replay validation modes.

## Visual/Audio Requirements

Visual requirements:
- Each enemy displays current revealed intent icon + text + magnitude/range chip.
- Intent update/mutation uses distinct visual change state (not same as normal refresh).
- Queue order chips for enemy actions mirror TSRE ordering keys where relevant.
- Reinforcement/summon entries show slot insertion indicator and spawn-order badge.

Audio requirements:
- Separate cues for intent reveal, intent mutation, action resolve, and fizzle/cancel.
- Boss phase transition has priority cue that ducks low-priority chain sounds.
- Guardrail hits (cap/invalid/no-op fallback) use subtle warning cue, non-modal.

Presentation event contract:
- `enemy_intent_event_id`
- `enemy_instance_id`
- `intent_id`
- `telegraph_key`
- `certainty_class`
- `mutation_reason_code?`
- `vfx_event_id`
- `sfx_event_id`

## UI Requirements

1) Enemy Intent Strip
- Shows all living enemies in deterministic order with current intent and certainty class.
- Displays threat preview (damage/status/resource pressure) with explicit ranges when not exact.

2) Ordering/Explainability Popover
- “Why this resolves now” uses TSRE comparator chain.
- Includes script source (`fixed_cycle`, `weighted_policy`, etc.) and any mutation reason.

3) Multi-turn Telegraph (boss/elite)
- If horizon > 1, show next planned intent ghosted with lower emphasis.
- Ghost intents must be marked as provisional if mutable by deterministic conditions.

4) Mutation and Fizzle Feedback
- If intent changes or fizzles, show explicit badge and combat log reason.
- No silent telegraph mismatch permitted.

5) Accessibility
- Intent icons must be distinguishable without color alone.
- Text fallback required for all icon-only intents.

6) Dev Debug Overlay
- Shows candidate intent scores, RNG index consumed, selected bucket, and queue insertion IDs.

## Acceptance Criteria

1) Deterministic intent replay
- Same snapshot/seed/player input sequence yields identical per-turn intent lists, selections, RNG indices, and final hash chain.

2) Telegraph fidelity
- For all fixtures, revealed intent payload matches resolved action or emits explicit mutation/fizzle reason.
- Zero silent mismatches in test corpus.

3) Queue integration correctness
- Enemy intents enter TSRE queue with stable ordering and never bypass resolve lock.

4) Script mode correctness
- Fixture suite validates `fixed_cycle`, `conditional_branch`, `weighted_policy`, and `state_reactive` behavior deterministically.

5) Scaling envelope
- Encounter win-rate and time-to-kill remain within target bounds across floor/tier simulation matrix after applying scaling formulas.

6) Guardrail containment
- Summon/reinforcement/action caps prevent unbounded queue growth in stress fixtures.

7) UI explainability coverage
- Every enemy action resolve entry has mapped human-readable reason text.

8) Cross-system contract compliance
- EES integration tests pass with TSRE/ERP/MRE/DLS on enemy effects involving damage, statuses, deck pressure, and resource pressure.

9) Browser performance envelope
- Enemy intent build + submit remains within TSRE logical step budget targets on supported browsers/hardware matrix.

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should some elite enemies intentionally hide exact magnitude while still revealing action family, or keep exact-only for MVP clarity? | Combat Design | Sprint 2 | Open |
| Do we want separate enemy resource bars in MVP, or keep enemy costs abstracted to script cooldowns only? | Systems Design | Sprint 3 | Open |
| Should boss multi-turn telegraphs be interruptible by player break mechanics in MVP or defer to vertical slice? | Design Director | Vertical Slice planning | Open |
| How much AI score detail should be exposed in non-debug UI to preserve trust without overloading players? | UX | Sprint 2 | Open |