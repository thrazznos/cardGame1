# Gem Stack Machine

> Status: Draft
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-05
> Implements Pillars: Sequencing Mastery Over Raw Stats; Readable Tactical Clarity; Compounding Value Every Turn
> Related Systems: design/gdd/card-data-definitions.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/systems/deck-lifecycle.md, design/gdd/systems/mana-resource-economy.md

## Overview

Gem Stack Machine (GSM) is the central card-combo mechanic for Dungeon Steward. Cards interact with an ordered gem stack to create and cash out sequencing lines. The default skill expression is planning around top-of-stack state over 1-3 future plays.

Design intent:
- Keep baseline gameplay readable and deterministic.
- Reward sequencing foresight over brute stat checks.
- Preserve an expansion lane for specialist cards without breaking core clarity.

## Core Rules

1) The gem stack is an ordered LIFO structure.
2) Default consume behavior is top-only.
3) Any non-top interaction is an exception and must be explicitly declared as an Advanced operation.
4) Advanced non-top interaction requires FOCUS state.
5) All operations must emit deterministic event records with pre/post stack snapshots (or equivalent hash-safe representation).

## Canonical Operation Families

The operation family taxonomy is exactly:

1. Production
2. Consumption
3. Advanced
4. Stability

No additional operation family names should be introduced without a schema/version update.

### 1) Production

Adds gems to the stack.

Examples:
- Produce(gem, n)
- ProduceSequence([gem_a, gem_b, gem_c])

Rules:
- New gems are pushed in declared order.
- Production resolves atomically per operation.

### 2) Consumption

Removes gems from the stack for payoff effects.

Examples:
- ConsumeTop(pattern, n)
- ConsumeExactTop(sequence)
- ConsumeAllTopWhile(pattern)

Rules:
- Baseline is top-only LIFO.
- If pattern does not match and card has no fallback clause, consumption fails gracefully with reason code.

### 3) Advanced

Specialized manipulation beyond default top-only behavior.

Examples:
- Addressed consume:
  - ConsumeFromBottom(k)
  - ConsumeFromTopOffset(k)
  - ConsumeFirstMatch(pattern)
- Stack transformation:
  - Transmute(a -> b)
  - Compress(rule)
  - Burst(pattern)

Rules:
- Requires FOCUS state for non-top addressing.
- Must be explicitly keyworded/telegraphed in card text and preview.
- Must preserve deterministic target selection (no ambiguous ties).

### 4) Stability

Operations that preserve, protect, or inspect stack state to support planning.

Examples:
- PeekTop
- PeekN(n)
- ReserveTop(n)
- LockTopUntil(end_of_turn)

Rules:
- Stability operations should improve readability and strategic planning, not add hidden state.
- Any reservation/lock must be visible in HUD/log.

## FOCUS Gate (Advanced Access Contract)

FOCUS is the gate for non-top access Advanced effects.

Contract:
- If a card requests non-top addressing and actor lacks FOCUS, operation rejects with deterministic reason code.
- FOCUS acquisition/spend/expiry behavior is defined by card/relic/effect rules in upstream systems.
- Advanced cards may consume FOCUS on use or require persistent FOCUS state, depending on card data.

## Determinism and Readability Contracts

For each stack-affecting operation, runtime must log:
- operation_id
- family (Production/Consumption/Advanced/Stability)
- selector/targeting details (if any)
- pre_stack_state_ref
- post_stack_state_ref
- reason_code (success/reject/fallback)
- order key reference

Constraints:
- Same seed + same input sequence => identical stack transitions and outcomes.
- Advanced selectors must define stable tie-breakers.
- UI preview should reflect intended selector before commit when possible.

## Data Model Notes (MVP)

Recommended card-operation payload shape:
- family: enum {production, consumption, advanced, stability}
- op_id: string
- params: dictionary
- focus_required: bool
- fallback_policy: enum {reject, downgrade, substitute}

Gem selector payload examples:
- selector: {mode: "top", n: 2}
- selector: {mode: "from_bottom", k: 1}
- selector: {mode: "from_top_offset", k: 2}
- selector: {mode: "first_match", pattern: "ruby"}

## Open Extension Lane

The family taxonomy remains fixed, but new primitives can be added inside existing families. Future extensions should prefer:
- adding a new operation primitive under an existing family,
- not creating a new family,
- and keeping FOCUS as the default gate for non-top addressing unless explicitly redesigned.

## Initial Acceptance Criteria

1) A default non-advanced consume card can only consume from stack top.
2) A non-top Advanced consume rejects without FOCUS.
3) The same Advanced consume succeeds with FOCUS and targets deterministically.
4) Event log/HUD can explain what was consumed and why.
5) No hidden stack mutations occur outside logged operations.
