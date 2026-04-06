# Gem Stack Machine

> Status: Implemented (Sprint 004 MVP pilot)
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-05
> Implements Pillars: Sequencing Mastery Over Raw Stats; Readable Tactical Clarity; Compounding Value Every Turn
> Upstream References: design/gdd/card-data-definitions.md, design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/systems/deck-lifecycle.md, design/gdd/systems/mana-resource-economy.md

## Overview

Gem Stack Machine (GSM) is the central combo logic for card sequencing in Dungeon Steward. Cards create and consume an ordered gem stack, and player mastery comes from planning stack state 1-3 plays ahead.

The system is intentionally asymmetric:
- Producer cards should usually deliver immediate baseline value plus gem setup.
- Consumer cards can range from stable hybrid effects to high-risk all-in payoffs.
- Higher rarity cards can shift toward gem-dependent or fully gem-dependent outcomes with stronger spikes.

Design goals:
1) Keep baseline turns readable and satisfying.
2) Reward sequencing foresight and execution.
3) Preserve expansion flexibility without eroding clarity.

## Player Fantasy

The player should feel like a precise combo engineer:
- "I can build a sequence, not just play raw stats."
- "My setup cards still do enough now, but great planning unlocks huge turns later."
- "Risky gem payoffs feel earned, not random."

Emotional target:
- Tactical confidence from visible stack state.
- High satisfaction from planned combo conversions.
- Distinct deck identity through sequencing style.

## Detailed Design

### Core Rules

1) The gem stack is an ordered LIFO structure.
2) Default consume behavior is top-only.
3) Non-top stack access is classified as Advanced and requires FOCUS.
4) Operation family taxonomy is fixed to exactly four families:
   - Production
   - Consumption
   - Advanced
   - Stability
5) Every stack mutation must emit deterministic, reason-coded events.
6) Equal inputs under equal seed/state must produce equal stack transitions.

### Operation Families

#### 1) Production
Purpose: add gems while preserving immediate play value.

Examples:
- Produce(gem, n)
- ProduceSequence([gem_a, gem_b, gem_c])

Policy:
- Common producers target roughly 75% base value + 25% gem setup value.
- Production resolves atomically and in declared push order.

#### 2) Consumption
Purpose: convert stack state into payoff effects.

Examples:
- ConsumeTop(pattern, n)
- ConsumeExactTop(sequence)
- ConsumeAllTopWhile(pattern)

Policy:
- Default selectors are top-only.
- Failure behavior is card-defined (fallback, partial, or fizzle).
- Common/Uncommon mostly hybrid; Rare+ may include all-in consumers.

#### 3) Advanced
Purpose: specialized stack access/manipulation beyond top-only behavior.

Examples:
- Addressed consume:
  - ConsumeFromBottom(k)
  - ConsumeFromTopOffset(k)
  - ConsumeFirstMatch(pattern)
- Transform/payoff tools:
  - Transmute(a -> b)
  - Compress(rule)
  - Burst(pattern)

Policy:
- Non-top addressing requires FOCUS.
- Advanced selectors must define stable tie-breakers.
- Rare+ cards may allocate most or all value budget to Advanced gem effects.

#### 4) Stability
Purpose: preserve, lock, and inspect stack state for future planning.

Examples:
- PeekTop
- PeekN(n)
- ReserveTop(n)
- LockTopUntil(end_of_turn)

Policy:
- Stability should reduce ambiguity, not create hidden state.
- Reservation/lock visibility must be reflected in UI and event logs.

### Value Budget & Rarity Policy

Global philosophy:
- Producers avoid "dead setup" feel.
- Consumers permit larger variance and deliberate risk.
- Rarity increases spike budget and gem dependence.

Recommended split by rarity:
- Common:
  - Producers: ~75/25 (base/gem)
  - Consumers: mostly hybrid, reliable floor
- Uncommon:
  - Producers: ~70/30
  - Consumers: hybrid + conditional spikes
- Rare:
  - Producers: ~50/50
  - Consumers/Advanced: high gem dependence
- Legendary:
  - Producers: optional hybrid
  - Consumers/Advanced: can be ~0/100 (fully conditional, high payoff)

Card-level metadata guidance:
- value_mode: stable | hybrid | all_in
- base_floor_pct
- gem_payoff_pct
- fail_policy: fallback | partial | fizzle
- rarity_spike_budget: low | mid | high

### FOCUS Gate

FOCUS is the access gate for non-top Advanced behavior.

Contract:
1) If non-top selector is requested without FOCUS, reject deterministically.
2) FOCUS generation/spend/duration is managed by card/effect/relic rules.
3) Cards may require persistent FOCUS or consume FOCUS on use.

Sprint 004 MVP implementation note:
- Live runtime currently models FOCUS as spendable charges (`0..n`) rather than a pure boolean flag.
- In the shipped pilot, advanced offset consume spends 1 charge on success.
- This preserves the intended access-gate behavior while leaving room for later binary/charge design consolidation if desired.

### States and Transitions

#### Runtime State Components
- GemStack: ordered list of gem tokens.
- FocusState: current FOCUS value/flag(s).
- LockState: reserved/locked segments and expiration scope.

#### Operation Lifecycle
1) Preview
2) Validate (cost + selector legality + FOCUS gate)
3) Commit
4) Resolve
5) Emit Event / Update UI

Illegal transitions (must reject):
- Resolve without successful Commit
- Non-top Advanced selector without FOCUS
- Selector addressing invalid index under strict mode

### Interactions with Other Systems

1) Card Data & Definitions (hard)
- Provides operation family, selector params, fail policy, and metadata tags.

2) Turn State & Rules Engine (hard)
- Determines when operations can be committed/resolved.
- Enforces phase legality and resolve locking.

3) Effect Resolution Pipeline (hard)
- Executes operation semantics and deterministic ordering.
- Emits reason-coded outcomes and mutation records.

4) Deck Lifecycle System (adjacent hard)
- Governs card flow; GSM governs gem-stack flow.
- Combined sequencing should remain auditable in one timeline.

5) Mana & Resource Economy (hard)
- Pays card costs and supports FOCUS gating economy hooks where applicable.

6) Combat UI/HUD (hard downstream)
- Must display top gems, lock states, and FOCUS-dependent affordances.

## Formulas

Notation:
- clamp(x, a, b) = min(max(x, a), b)

### 1) Producer Value Envelope

producer_total_value = base_value + gem_setup_value

Target by rarity (guideline):
- Common: base_value / producer_total_value ≈ 0.75
- Uncommon: ≈ 0.70
- Rare: ≈ 0.50

### 2) Consumer Expected Value

consumer_ev = P(match) * payoff_hit + (1 - P(match)) * payoff_fail

Design targets:
- Hybrid cards: payoff_fail retains ~60-80% of baseline expected power.
- All-in cards: payoff_fail can be ~0-35% of expected power if payoff_hit is high.

### 3) Advanced Access Tax via FOCUS

advanced_legal = has_focus AND selector_is_valid

If not advanced_legal:
- resolve_result = reject(reason_code = ERR_FOCUS_REQUIRED or ERR_SELECTOR_INVALID)

### 4) Rarity Spike Budget

spike_index = payoff_hit / baseline_same_cost_value

Guideline bands:
- Common: 1.0-1.3
- Uncommon: 1.1-1.6
- Rare: 1.3-2.1
- Legendary: 1.6-2.8

## Edge Cases

1) Empty stack consume
- Behavior: deterministic fail path by card fail_policy.

2) Partial pattern match for exact consumes
- Behavior: fails exact requirement; fallback only if card defines it.

3) Non-top selector tie ambiguity
- Behavior: enforce deterministic first-valid rule; no random tie resolution.

4) Lock/Reserve conflicts with consume
- Behavior: lock policy priority is explicit and logged.

5) FOCUS expires between preview and commit
- Behavior: revalidate at commit; reject if no longer legal.

6) Burst on zero matches
- Behavior: no-op with reason code (or card-defined fallback).

## Dependencies

| System | Direction | Type | Contract |
|---|---|---|---|
| Card Data & Definitions | Upstream | Hard | Operation family, selectors, fail policy, rarity metadata |
| Turn State & Rules Engine | Upstream | Hard | Commit windows, legality, resolve ordering |
| Effect Resolution Pipeline | Peer/Executor | Hard | Deterministic operation execution + logs |
| Deck Lifecycle System | Peer | Hard-adjacent | Parallel state machine coordination |
| Mana & Resource Economy | Upstream/Peer | Hard | Cost payment and FOCUS-gate interactions |
| Combat UI/HUD | Downstream | Hard | Stack readability, FOCUS/readability surfacing |

## Tuning Knobs

| Knob | Default | Safe Range | Notes |
|---|---:|---:|---|
| common_producer_base_pct | 0.75 | 0.65-0.85 | Keeps setup cards feeling useful now |
| hybrid_fail_floor_pct | 0.65 | 0.55-0.80 | Prevents too many dead turns |
| all_in_fail_floor_pct | 0.20 | 0.00-0.35 | Controls risk appetite |
| rare_spike_index_cap | 2.1 | 1.8-2.4 | Guards runaway burst lines |
| legendary_spike_index_cap | 2.8 | 2.2-3.2 | High spectacle without total collapse |
| focus_gate_density | medium | low-high | Fraction of Advanced cards requiring FOCUS |
| non_top_access_rate | low | very_low-medium | Preserve top-only mastery as default |

## Visual/Audio Requirements

- Distinct gem iconography and color coding (Ruby/Sapphire baseline).
- Stack top emphasis in HUD.
- Clear lock/reserve overlays.
- Audio cues:
  - Produce (soft constructive cue)
  - Consume hit (strong confirm cue)
  - Consume fail (soft deny cue)
  - Advanced + FOCUS success (distinct premium cue)

## UI Requirements

1) Always-visible top-of-stack window (at least top 3).
2) Peek actions should surface deterministic selector previews.
3) Advanced selectors show targeting intent before commit.
4) FOCUS state visible near card hand/cost context.
5) Recent log lines explain consumed gems and reason codes.

## Acceptance Criteria

1) A Common producer card delivers useful baseline impact even when gem setup is ignored.
2) Top-only consume is default across non-Advanced cards.
3) Non-top Advanced consumes fail without FOCUS and succeed with FOCUS.
4) Same seed + same inputs produce identical stack logs and outcomes.
5) Hybrid consumer fail states do not feel fully dead in common gameplay.
6) Rare/Legendary all-in cards can produce higher spikes while staying inside guardrail caps.
7) HUD/log readability answers "what gem was consumed and why" without debugger use.

## Open Questions

1) Should FOCUS be binary (present/absent) or stacked (N charges)?
2) Should Reserve/Lock persist only this turn or be extensible to next-turn effects in MVP?
3) Is the initial gem taxonomy limited to 2 gems (Ruby/Sapphire) or 3+ in first content wave?

---

## Appendix A: 20-Card Mini Set (v1)

### Commons (8)

1) Ember Jab
- Family: Production | Cost: 1 | value_mode: stable
- Deal 4. Produce 1 Ruby.

2) Ward Polish
- Family: Production | Cost: 1 | value_mode: stable
- Gain 5 Block. Produce 1 Sapphire.

3) Kindling Step
- Family: Production | Cost: 1 | value_mode: hybrid
- Deal 3. If top gem is Ruby, Produce 1 Ruby.

4) Coolant Step
- Family: Production | Cost: 1 | value_mode: hybrid
- Gain 4 Block. If top gem is Sapphire, Produce 1 Sapphire.

5) Split Cut
- Family: Consumption | Cost: 1 | value_mode: hybrid
- Deal 5. Consume top Ruby: +3 damage.

6) Shell Brace
- Family: Consumption | Cost: 1 | value_mode: hybrid
- Gain 6 Block. Consume top Sapphire: +4 Block.

7) Read the Grain
- Family: Stability | Cost: 0 | value_mode: stable
- Peek top 2 gems. Draw 1.

8) Top Clamp
- Family: Stability | Cost: 1 | value_mode: stable
- Reserve top 1 gem until end of turn. Gain 3 Block.

### Uncommons (6)

9) Twin Chisel
- Family: Consumption | Cost: 1 | value_mode: hybrid
- Consume exact top [Ruby, Sapphire]: Deal 11. Else: Deal 4.

10) Cut and Coat
- Family: Production | Cost: 1 | value_mode: stable
- Deal 4 and Gain 4 Block. Produce 1 chosen gem.

11) Prism Shift
- Family: Advanced | Cost: 1 | value_mode: hybrid
- Transmute top gem (Ruby <-> Sapphire). Draw 1.

12) Vault Focus
- Family: Stability | Cost: 1 | value_mode: enabler
- Gain FOCUS. Peek top 3.

13) Offset Scalpel
- Family: Advanced | Cost: 1 | value_mode: hybrid
- [FOCUS] ConsumeFromTopOffset(1): Deal 9. Without FOCUS: Deal 3.

14) Seam Pull
- Family: Advanced | Cost: 1 | value_mode: hybrid
- [FOCUS] ConsumeFirstMatch(Sapphire): Gain 10 Block.

### Rares (4)

15) Pressure Burst
- Family: Advanced | Cost: 2 | value_mode: all_in
- [FOCUS] Burst(Ruby): Consume all Rubies, deal 4 each.

16) Deep Hook
- Family: Advanced | Cost: 1 | value_mode: all_in
- [FOCUS] ConsumeFromBottom(1): Gain 2 Energy and Draw 1.

17) Facet Engine
- Family: Consumption | Cost: 1 | value_mode: all_in
- Consume top gem: Ruby -> Deal 10, Sapphire -> Gain 12 Block. No gem: no effect.

18) Lattice Surge
- Family: Production | Cost: 2 | value_mode: hybrid
- Produce [Ruby, Sapphire]. If both are consumed this turn, gain 1 Energy.

### Legendaries (2)

19) Master Sequence
- Family: Consumption | Cost: 2 | value_mode: all_in
- Consume exact top [Ruby, Sapphire, Ruby]: Deal 26 and apply Vulnerable 2. Else: fizzle.

20) Crown of Focus
- Family: Stability | Cost: 2 | value_mode: capstone
- Gain 2 FOCUS. This turn, your Advanced cards ignore one non-top targeting restriction.
