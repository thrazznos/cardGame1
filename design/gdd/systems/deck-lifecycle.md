# Deck Lifecycle System

> Status: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-04
> Implements Pillars: Sequencing Mastery Over Raw Stats; Readable Tactical Clarity; High Run Variety, Low Grind
> Upstream References: design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/card-data-definitions.md

## Overview

Deck Lifecycle System (DLS) is the authoritative zone-management subsystem for combat cards in Dungeon Steward. It owns card-instance movement across zones and guarantees deterministic, auditable transitions under TSRE scheduling.

Core responsibilities:
- Maintain authoritative per-combat card zones.
- Execute zone transitions from TSRE/ERP intents atomically.
- Perform deterministic shuffle and draw behavior.
- Enforce hand-size, retain, temporary-card, generated-card, and exhaust rules.
- Apply anti-exploit guardrails (duplication abuse, infinite generation loops, hidden state ambiguity).

Scope split:
- TSRE decides when transitions happen and legality gates.
- ERP determines effect outcomes that may request transitions/draw/create actions.
- DLS executes lifecycle operations and returns deterministic results/events.

Non-goals (MVP):
- Permanent deck editing during combat.
- Animation-timed movement logic.
- Hidden asynchronous zone changes not represented in event stream.

## Player Fantasy

The player should feel total trust in card flow:
- “I know where my cards go and why.”
- “My reshuffle timing is predictable, not random chaos.”
- “Retain and temporary card behavior are clear and exploitable strategically, not via loopholes.”

The emotional outcome:
- Confidence in sequencing plans.
- Clear memory model of deck state.
- Satisfying combo expression without degenerate exploit lines.

## Detailed Design

### Core Rules

1) Authoritative card instance identity
- Every runtime card has immutable `card_instance_id` unique within combat.
- Card definition identity (`card_id`) and runtime identity (`card_instance_id`) are never conflated.

2) Canonical combat zones
- `draw_pile`
- `hand`
- `discard_pile`
- `exhaust_pile`
- `limbo_pending_resolve` (internal transient zone after commit, before final destination)
- `out_of_combat_purge` (terminal sink for temp/generated cleanup, not player-visible zone)

3) Single-zone invariant
- A card instance exists in exactly one zone at any moment.
- Transition is atomic: remove from source + add to destination in one state mutation unit.

4) Commit-to-limbo contract (aligned with TSRE)
- On `CommitPlay`, DLS must move card `hand -> limbo_pending_resolve`.
- On resolve completion, DLS moves card to destination from lifecycle policy:
  - `zone_on_play=discard` -> `discard_pile`
  - `zone_on_play=exhaust` -> `exhaust_pile`
  - `zone_on_play=retain` -> return to `hand` with retain flag (for current turn unless persistent retain granted)
  - `zone_on_play=temp` -> `exhaust_pile` and mark consumed-temp in event reason (`INFO_TEMP_CONSUMED_ON_PLAY`)
- Explicit effects may override destination deterministically, but override must be present in resolved effect output (never inferred).

5) Draw is pull-based and deterministic
- Draw requests are explicit operations (`draw_n`).
- DLS processes each card draw sequentially in stable order.
- If `draw_pile` empty, DLS shuffles `discard_pile` into `draw_pile` using deterministic RNG contract before continuing draw resolution.

6) Hand cap and overflow
- Hand has hard cap `HAND_CAP`.
- If draw/generation would exceed cap, overflow policy applies deterministically:
  - Normal cards: move to `discard_pile` with `INFO_HAND_OVERFLOW_TO_DISCARD`.
  - Temp cards flagged `ephemeral=true`: move to `exhaust_pile` with `INFO_TEMP_OVERFLOW_EXHAUSTED`.
- Overflow still emits draw-attempt event for readability and telemetry.

7) Retain policy at TurnEnd
- At TurnEnd boundary, each card in hand is evaluated:
  - If retained (intrinsic retain, granted retain, or persistent retain status): stays in hand.
  - Else moves to `discard_pile` (or `exhaust_pile` for ephemeral cards with exhaust-on-end-turn policy).
- Retain never bypasses hand cap on future draw; cap is enforced at all insert points.

8) Temporary card policy
- Temporary card = runtime instance with `ephemeral=true` or generated temp flag in instance metadata.
- Temp cards are legal for combat play but cannot be added to run master deck.
- End-of-combat cleanup: all temp cards in any combat zone move to `out_of_combat_purge`.

9) Generated card policy
- Generated cards have provenance metadata:
  - `generated_by_source_instance_id`
  - `generated_on_turn_index`
  - `generated_scope` (`combat_only` MVP)
- Generated cards are runtime instances only; they never mutate persistent deck list in MVP.

10) Anti-exploit guardrails
- Per-source/per-turn generation caps.
- Per-combat generated-instance cap.
- Duplicate instance-id prevention and replay-safe id allocation.
- No implicit cloning from zone visibility or UI race.

11) Readability-first logging
- Every transition emits structured event:
  - `event_id`, `card_instance_id`, `from_zone`, `to_zone`, `reason_code`, `order_key_ref`, `rng_call_index?`, `pre_hash`, `post_hash`.

### States and Transitions

Per-card lifecycle states (runtime projection):
- InDrawPile
- InHand
- InLimboPendingResolve
- InDiscard
- InExhaust
- PurgedOutOfCombat

Primary legal transitions:
- InDrawPile -> InHand (draw)
- InDiscard -> InDrawPile (reshuffle)
- InHand -> InLimboPendingResolve (commit play)
- InLimboPendingResolve -> InDiscard (default resolved play)
- InLimboPendingResolve -> InExhaust (exhaust policy/effect)
- InHand -> InDiscard (TurnEnd non-retained)
- InHand -> InExhaust (temp expiry/exhaust effects)
- Any combat zone -> PurgedOutOfCombat (combat cleanup for temp/generated scope)

Illegal transitions (must hard reject):
- InDrawPile -> InLimboPendingResolve (bypassing hand/commit)
- InExhaust -> any combat zone (unless explicit resurrection effect with contract tag)
- PurgedOutOfCombat -> any zone
- Any -> same zone via duplicate transition in same atomic batch

Turn boundary transition order (aligned to TSRE boundaries):
1. TurnStart hooks affecting draw/retain replacement registration.
2. Draw step transitions.
3. Player/Enemy phase transitions from play/effects.
4. TurnEnd hand sweep (retain evaluation then movement).
5. End-turn cleanup events.

### Zone Data Model and Contracts

Authoritative combat deck state:
- `draw_pile: card_instance_id[]` (top at end of array for O(1) pop)
- `hand: card_instance_id[]` (stable insertion order)
- `discard_pile: card_instance_id[]`
- `exhaust_pile: card_instance_id[]`
- `limbo_pending_resolve: card_instance_id[]`
- `instance_registry: map<card_instance_id, CardInstanceRuntime>`
- `shuffle_count_combat: int`
- `generated_count_turn/combat/run: counters`

CardInstanceRuntime minimum fields:
- `card_instance_id`
- `card_id`
- `owner_actor_id`
- `ephemeral` (bool)
- `generated` (bool)
- `generated_scope` (enum)
- `retain_flags` (bitset: intrinsic, granted_until_turn_end, granted_persistent)
- `creation_seq_id`

TSRE -> DLS execution contract (MVP):
- Input: `ZoneTransitionIntent[]`
- Each intent fields:
  - `intent_id`
  - `card_instance_id`
  - `expected_from_zone`
  - `to_zone`
  - `reason_code`
  - `order_key_ref`
  - `allow_override_if_missing` (default false)
- Output: `ZoneTransitionResult`
  - `status`: ok | error
  - `error_code?`
  - `applied_transitions[]`
  - `rejected_transitions[]`
  - `event_log_entries[]`

ERP -> DLS helper requests:
- `DrawRequest {actor_id, count, source_reason}`
- `CreateCardRequest {card_id, count, destination_pref, ephemeral, generated_scope, source_instance_id}`
- `RetainGrantRequest {card_instance_id|filter, duration_policy}`

### Deterministic Algorithms

1) Shuffle algorithm
- Uses seeded RNG service via TSRE-indexed calls.
- Algorithm: Fisher-Yates over `discard_pile` snapshot into new `draw_pile`.
- Determinism requirement: same seed + same discard ordering + same rng cursor => identical permutation.

2) Draw pipeline
For each requested draw step i:
- If hand full, apply overflow policy and continue i+1.
- If draw_pile empty:
  - If discard empty: emit `INFO_DRAW_NO_CARDS_AVAILABLE`, terminate remaining draws.
  - Else reshuffle discard -> draw.
- Move top card draw_pile -> hand.
- Emit `EVENT_CARD_DRAWN`.

3) End-turn hand sweep
- Evaluate cards in deterministic hand index order (oldest to newest insertion).
- Retained cards remain in place preserving relative order.
- Non-retained cards transition to discard/exhaust by policy.

4) Generated-card insertion order
- When creating N cards at once, assign ascending `creation_seq_id` and append to destination in request order.
- If destination unavailable (hand full), apply overflow policy card-by-card in that same order.

### Interactions with Other Systems

1) Turn State & Rules Engine (hard)
- TSRE is timing authority; DLS is execution authority for zone mutations.
- DLS must honor `ResolveLock` semantics (no direct player-origin writes during lock).
- DLS returns deterministic error codes for TSRE guard handling.

2) Effect Resolution Pipeline (hard)
- ERP can request draw/create/move/exhaust/retain operations.
- DLS executes operation order exactly as ERP emits within current resolve item.
- Replacement effects that alter destination (discard -> exhaust) are finalized before DLS apply call.
- DLS emits deck lifecycle events in ERP-consumable shape so ERP `EffectResult` can append them as `state_deltas[]` + `error_codes[]` + `log_events[]` without re-derivation.

3) Card Data & Definitions (hard)
- DLS consumes lifecycle schema fields:
  - `zone_on_play`
  - `ephemeral`
  - `generated_only`
- Invalid combinations are blocked in content validation; DLS still defends at runtime with deterministic rejections.

4) Combat UI/HUD (hard downstream)
- UI receives zone counts, top-of-draw preview entitlement (if enabled), and transition events.
- UI never mutates zones directly.

5) Save/Resume and Replay (soft MVP, hard VS)
- Snapshot includes all zones, registry metadata, counters, and RNG cursor linkage.
- Replay must reproduce exact zone ordering and shuffle outcomes.

## Formulas

1) Turn draw count

`draw_effective = clamp(draw_requested + draw_bonus - draw_penalty, 0, DRAW_MAX_PER_EVENT)`

MVP defaults:
- `DRAW_MAX_PER_EVENT = 20`

Safe range:
- `DRAW_MAX_PER_EVENT` in [8, 40]

Failure behavior:
- If computed draw exceeds cap, clamp and emit `WARN_DRAW_CLAMPED`.
- If drawable cards are insufficient after legal reshuffle attempts, draw partial and emit `INFO_DRAW_PARTIAL`.

2) Hand insertion capacity / hand limit

`hand_space = HAND_CAP - hand_count_current`
`draw_admitted = min(draw_remaining, max(hand_space, 0))`
`draw_overflow = draw_remaining - draw_admitted`

MVP defaults:
- `HAND_CAP = 10`

Safe range:
- `HAND_CAP` in [7, 12]

Failure behavior:
- Overflow cards processed with deterministic overflow policy and explicit per-card events.
- If overflow policy handler fails (corrupt enum/state), fallback to discard by ascending `card_instance_id` and emit `ERR_OVERFLOW_POLICY_FALLBACK`.

3) Reshuffle trigger and cap

`needs_reshuffle = (draw_pile_count == 0) AND (discard_pile_count > 0) AND (draw_remaining > 0)`

`shuffle_count_turn = shuffle_count_turn + 1`
`shuffle_count_combat = shuffle_count_combat + 1`

MVP defaults:
- `RESHUFFLE_CAP_TURN = 3`
- `RESHUFFLE_WARN_THRESHOLD_COMBAT = 12`

Safe range:
- `RESHUFFLE_CAP_TURN` in [1, 5]
- `RESHUFFLE_WARN_THRESHOLD_COMBAT` in [6, 20]

Failure behavior:
- If turn cap reached, remaining draw resolves as partial, emit `ERR_RESHUFFLE_CAP_REACHED`.
- Shuffle integrity mismatch (dup/missing instance IDs) => reject batch with `ERR_SHUFFLE_INTEGRITY` and request TSRE fail-safe TurnEnd.

4) Exhaust cap (anti-thinning)

`exhaust_cap_turn = clamp(EXHAUST_BASE + exhaust_cap_mod_turn, EXHAUST_MIN, EXHAUST_MAX)`
`exhaust_cap_combat = floor(deck_start_size_combat * EXHAUST_FRAC_CAP)`
`exhaust_allowed = min(exhaust_cap_turn - exhausted_this_turn, exhaust_cap_combat - exhausted_this_combat)`

MVP defaults:
- `EXHAUST_BASE = 4`
- `EXHAUST_MIN = 1`
- `EXHAUST_MAX = 8`
- `EXHAUST_FRAC_CAP = 0.60`

Safe range:
- `EXHAUST_BASE` in [2, 6]
- `EXHAUST_FRAC_CAP` in [0.40, 0.75]

Failure behavior:
- Exhaust requests beyond cap downgrade to discard when legal and emit `ERR_EXHAUST_CAP_REACHED`.
- If effect is tagged `must_exhaust`, reject that transition deterministically and emit `ERR_MUST_EXHAUST_BLOCKED_BY_CAP`.

5) Retain cap

`retained_in_hand_end_turn <= RETAIN_CAP`

MVP defaults:
- `RETAIN_CAP = 10` (equal to hand cap)

Safe range:
- `RETAIN_CAP` in [6, 12]

Failure behavior:
- If retained candidates exceed cap, keep highest-priority retained cards by deterministic hand-order precedence and move remainder to discard with `INFO_RETAIN_OVER_CAP`.

6) Generated card guardrails and lifetime

`generated_by_source_this_turn <= GEN_CAP_PER_SOURCE_TURN`
`generated_total_combat <= GEN_CAP_COMBAT`
`generated_total_run <= GEN_CAP_RUN`

Lifetime expiry rule:
`generated_expired = (ttl_turns_remaining <= 0) OR (ttl_plays_remaining <= 0) OR end_of_turn_flag`

MVP defaults:
- `GEN_CAP_PER_SOURCE_TURN = 6`
- `GEN_CAP_COMBAT = 60`
- `GEN_CAP_RUN = 300`
- `generated_default_lifetime = end_of_turn`
- `generated_in_hand_cap = 5`

Safe range:
- `GEN_CAP_PER_SOURCE_TURN` in [2, 12]
- `GEN_CAP_COMBAT` in [20, 120]
- `GEN_CAP_RUN` in [100, 600]
- `generated_in_hand_cap` in [3, 8]

Failure behavior:
- Over-cap create requests are deterministically rejected newest-first with `ERR_GENERATION_CAP_REACHED`.
- Missing lifetime metadata defaults to `end_of_turn` and emits `WARN_GENERATED_LIFETIME_DEFAULTED`.
- On expiry, card moves to `exhaust_pile` (if ephemeral) or `out_of_combat_purge` with `INFO_GENERATED_EXPIRED`.

7) Anti-deck-thinning safeguards

A) Cycle floor tax:
`cycle_pool_actual = draw_pile_count + discard_pile_count`
`thin_tax = max(0, MIN_CYCLE_POOL - cycle_pool_actual)`
`draw_after_thin_tax = max(0, draw_effective - thin_tax)`

B) Same-card reentry cap:
`same_card_reentries_this_turn(card_instance_id) <= REENTRY_CAP_PER_CARD_TURN`

C) Tutor/search cap:
`search_to_hand_count_this_turn <= TUTOR_CAP_TURN`

MVP defaults:
- `MIN_CYCLE_POOL = 8`
- `REENTRY_CAP_PER_CARD_TURN = 2`
- `TUTOR_CAP_TURN = 6`

Safe range:
- `MIN_CYCLE_POOL` in [6, 12]
- `REENTRY_CAP_PER_CARD_TURN` in [1, 3]
- `TUTOR_CAP_TURN` in [4, 10]

Failure behavior:
- Excess draw/search/reentry effects convert to deterministic no-op with explicit events:
  - `ERR_THINNING_FLOOR_APPLIED`
  - `ERR_REENTRY_CAP_REACHED`
  - `ERR_TUTOR_CAP_REACHED`
- If 3+ thinning safeguards trigger in one turn, emit telemetry marker `WARN_THINNING_ABUSE_PATTERN`.

8) Determinism digest extension for lifecycle

`deck_hash_next = FNV1a64(deck_hash_prev || transition_batch_digest || rng_call_index || shuffle_count_combat || safeguard_counter_digest)`

Used with TSRE/ERP state hash chain for replay verification.

## Edge Cases

1) Draw request while both draw and discard piles are empty
- Result: draw terminates early with `INFO_DRAW_NO_CARDS_AVAILABLE`; no error state.

2) Card targeted/selected in UI but moved by replacement before commit
- Result: TSRE validation re-checks zone; if not in hand, reject intent (`ERR_ZONE_LEGALITY`).

3) Multiple simultaneous transitions for same card in one batch
- Result: deterministic conflict resolution by first valid intent in order; later intents rejected `ERR_DUPLICATE_CARD_INTENT`.

4) Temp card retained indefinitely via repeated grants
- Result: allowed only within combat; end-of-combat purge still removes temp/generated cards from persistent context.

5) Generated-only card appears in master deck import
- Result: content/runtime validator rejects with `ERR_GENERATED_ONLY_PERSISTENCE_VIOLATION`.

6) Hand overflow during generated-card burst
- Result: process in creation order; each overflow card moved per overflow policy with one event per card.

7) Shuffle requested with corrupt duplicate card_instance_id in discard
- Result: fail-fast in debug; in release reject shuffle, emit `ERR_ZONE_REGISTRY_CORRUPT`, force TSRE fail-safe turn end.

8) Card in limbo at combat end (unresolved edge)
- Result: resolve cleanup policy applies in deterministic order:
  - non-temp -> discard
  - temp/generated combat-only -> purge
  - emit `WARN_LIMBO_CLEANUP_APPLIED`.

9) Draw replacement effects (future-support path)
- Result: replacement modifications must emit explicit transformed request before DLS execution; DLS never infers implicit replacement.

10) Replay mismatch only in shuffle order
- Result: determinism mismatch flagged with shuffle trace including pre-shuffle discard ordering and rng indices.

## Dependencies

Hard upstream dependencies:
- Turn State & Rules Engine (phase gates, transition timing, queue ordering, resolve lock)
- Card Data & Definitions (lifecycle fields and validation)
- Effect Resolution Pipeline (effect outcomes that request draw/create/move)
- RNG/Seed service via TSRE integration

Downstream dependents:
- Combat UI/HUD
- Deckbuilder/Inspection UI (combat-state viewer aspects)
- Run Save/Resume
- Telemetry/Debug tooling

Integration compatibility notes:
- DLS must accept TSRE transition batches without reordering.
- DLS must preserve ERP local operation order within the parent resolve item.
- DLS errors must be deterministic code enums, never freeform strings only.

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `HAND_CAP` | int | 10 | 7-12 | Hand-starved turns | Analysis paralysis, UI clutter |
| `DRAW_MAX_PER_EVENT` | int | 20 | 8-40 | Draw cards feel weak | Burst turns/perf spikes |
| `RESHUFFLE_CAP_TURN` | int | 3 | 1-5 | Draw chains fail too early | Loop decks cycle too freely |
| `RESHUFFLE_WARN_THRESHOLD_COMBAT` | int | 12 | 6-20 | Telemetry noise | Late loop detection |
| `EXHAUST_BASE` | int | 4 | 2-6 | Exhaust archetypes underpowered | Deck-thinning abuse |
| `EXHAUST_FRAC_CAP` | float | 0.60 | 0.40-0.75 | Exhaust cards feel constrained | Tiny deterministic loop decks |
| `RETAIN_CAP` | int | 10 | 6-12 | Retain archetypes weak | Sticky-hand stall patterns |
| `GEN_CAP_PER_SOURCE_TURN` | int | 6 | 2-12 | Combo cards feel clipped | Token flood exploits |
| `GEN_CAP_COMBAT` | int | 60 | 20-120 | Build expression suppressed | Long-turn memory/perf pressure |
| `GEN_CAP_RUN` | int | 300 | 100-600 | Run fantasy constrained | Save/state bloat |
| `generated_in_hand_cap` | int | 5 | 3-8 | Generator decks over-clipped | Hand clutter/readability loss |
| `MIN_CYCLE_POOL` | int | 8 | 6-12 | Thin abuse not checked | Legit thin decks over-taxed |
| `REENTRY_CAP_PER_CARD_TURN` | int | 2 | 1-3 | Recursive identity cards feel bad | Same-card replay loops |
| `TUTOR_CAP_TURN` | int | 6 | 4-10 | Search cards feel weak | Deterministic cherry-pick abuse |
| `overflow_policy_temp` | enum | exhaust | discard/exhaust | Temp abuse if discard | Temp fantasy weakened if over-punitive |
| `overflow_policy_normal` | enum | discard | discard/exhaust | Burn pressure if exhaust | Less punishment for overdraw loops |
| `limbo_cleanup_policy` | enum | deterministic_sink | strict_fail/sink | Hard fail frustration if strict | Hidden mistakes if too lenient |

Governance:
- All knob changes are data-configurable and versioned.
- Out-of-range values require replay suite pass + browser perf smoke pass.

## Visual/Audio Requirements

Visual requirements:
- Distinct movement trails per destination:
  - draw (blue)
  - discard (gray)
  - exhaust (amber/ash)
  - retain pulse at TurnEnd (teal lock icon)
  - generated card spawn (violet spark)
- Shuffle event must show explicit "Reshuffle" marker and count increment.
- Limbo state is never hidden in debug mode; optional subtle indicator in player mode.

Audio requirements:
- Unique SFX families: draw, discard, exhaust, shuffle, generate, retain.
- Batch SFX coalescing for high-frequency draw/discard chains.
- Guardrail rejection (generation cap/overflow policy) has soft warning cue, non-modal.

Presentation contract fields:
- `zone_transition_event_id`
- `card_instance_id`
- `from_zone`, `to_zone`
- `reason_code`
- `presentation_hint` (draw/discard/exhaust/retain/generate/shuffle)

## UI Requirements

1) Zone panel
- Always-visible counts: draw, hand, discard, exhaust.
- Tooltip/inspect view lists ordered contents for debug mode; player mode may hide exact draw order unless revealed by mechanics.

2) Hand readability
- Retained cards display retain badge + source (intrinsic/effect).
- Temporary/generated cards display distinct frame tags.

3) Draw/reshuffle messaging
- On reshuffle, show compact inline log entry and optional banner tick.
- On empty draw termination, show "No cards to draw" reason.

4) Overflow feedback
- If hand full, each affected card gets outcome badge: "Overflow -> Discard" or "Overflow -> Exhaust".

5) Explainability hooks
- "Why did this card move?" inspector reveals last transition reason code and source resolve item.

6) Input protection
- During ResolveLock, drag/play interactions disabled with explicit reason text.

## Acceptance Criteria

1) Deterministic zone replay
- Same snapshot/seed/input sequence yields identical zone orderings, shuffle permutations, and deck hash chain.
- Pass threshold: 1000 replay fixtures, 0 divergence.

2) Transition legality enforcement
- All illegal transitions are rejected with stable error codes.
- Pass threshold: 100% transition guard tests pass.

3) Commit/resolve lifecycle correctness
- Every committed play transitions `hand -> limbo -> final destination` exactly once.
- Pass threshold: 0 duplicate or missing terminal transitions across fixture suite.

4) Draw + reshuffle correctness
- Draw requests across empty draw pile deterministically reshuffle and continue correctly.
- Pass threshold: 100% of scripted draw-chain fixtures match expected order.

5) Hand overflow policy correctness
- Overflow behavior follows policy per card flags and logs one event per overflow card.
- Pass threshold: 100% of overflow fixtures pass.

6) Retain behavior correctness
- End-turn retain/non-retain sweep matches flags and preserves deterministic hand order for retained cards.
- Pass threshold: 100% retain fixtures pass.

7) Generated/temp constraints
- Generated and temp cards obey scope limits and never persist into master deck.
- Pass threshold: 0 persistence violations in run-end audits.

8) Performance envelope
- Zone transition batch apply median <= 0.5 ms, P95 <= 2.0 ms on target browsers baseline.

9) UI event completeness
- No zone mutation occurs without corresponding event payload consumed by combat log.
- Pass threshold: 0 silent mutations in instrumentation tests.

## Open Questions

1) Should non-temp overflow policy remain discard in all modes, or exhaust in challenge modifiers?
2) Do we need a player-facing inspect affordance for discard ordering, or debug-only?
3) Should retain have a distinct configurable cap separate from hand cap for future relic-heavy metas?
4) Should generated cards ever support `run_persistent` scope in post-MVP modes?
5) Do ranked/challenge modes require signed shuffle transcripts for anti-cheat verification?
