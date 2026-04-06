# Card Data & Definitions

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Readable Tactical Clarity; Sequencing Mastery Over Raw Stats; High Run Variety, Low Grind

## Overview

Card Data & Definitions is the authoritative schema for all card content in Dungeon Steward. It defines each card’s identity, play cost, sequencing/timing metadata, effect references, targeting rules, rarity/pool eligibility, and UI presentation fields as data (not hardcoded logic). The system’s job is to make card behavior deterministic and readable while enabling rapid content iteration: designers can add or tune cards by editing data assets without rewriting combat code. This balanced schema is MVP-first but extension-friendly, so downstream systems (effect resolution, rewards, unlock gating, and deck inspection UI) can rely on stable contracts now and grow safely later.

Current MVP implementation note:
- Card content is currently authored as repo-tracked JSON assets rather than custom Godot Resource files.
- Primary live files:
  - `data/cards/catalog_v1.json`
  - `data/decks/starter_run_v1.json`
- Runtime access currently flows through `src/core/card/card_catalog.gd` and `src/core/card/card_presenter.gd`.

## Player Fantasy

This system supports the feeling of being both a precision strategist and a buildcraft inventor. Players should trust that card outcomes are consistent and legible—when they choose a sequence, the game resolves it exactly as expected. At the same time, the schema enables broad expressive card variety, so players can discover and assemble unique interaction engines across runs. Even though players never directly see the schema, they feel its quality through reliable combo execution, clear card identity, and meaningful build diversity without rule ambiguity.

## Detailed Design

### Core Rules

1. Card definitions are data assets, never hardcoded in combat logic.
2. Every card has a globally unique `card_id` (stable, immutable).
3. Effects are referenced by `effect_id` plus parameter payload; card data declares intent while Effect Resolution executes behavior.
4. Sequencing metadata is explicit in data (`speed_class`, `timing_window`, `combo_tags`, `chain_flags`) so order-sensitive play is deterministic.
5. Targeting is declarative (`target_mode`, `target_filters`, `max_targets`) and validated before play.
6. Pool eligibility is data-driven (`rarity`, `pool_tags`, `unlock_key`, `exclusion_tags`) for reward drafting and hub-modified pools.
7. UI-facing text/icons are present in data (`name_key`, `rules_text_key`, `icon_key`, `vfx_key`, `sfx_key`) to keep gameplay and presentation decoupled.
8. Versioned schema (`schema_version`) is required for migration safety.

MVP card schema contract:
- Identity: `card_id`, `schema_version`, `archetype`, `rarity`
- Cost: `base_cost`, `cost_type` (mana/other), `cost_mod_flags`
- Play constraints: `play_conditions[]`, `target_mode`, `target_filters[]`, `max_targets`, `invalid_target_policy` (`fizzle` | `retarget_if_possible` | `retarget_random_deterministic`)
- Sequencing: `speed_class` (fast/normal/slow), `timing_window` (pre/main/post), `combo_tags[]`, `chain_flags[]`
- Effects: `effects[]` where each effect has `effect_id`, `params`, `stack_behavior`, `preview_priority`
- Lifecycle tags: `zone_on_play` (discard/exhaust/retain/temp), `ephemeral`, `generated_only`
  - Runtime semantics: `retain` returns played card to hand with retain flag; `temp` consumes to exhaust on play by default unless an effect override is explicitly applied.
- Reward hooks: `pool_tags[]`, `unlock_key`, `weight_base`, `weight_modifiers[]`
  - `weight_modifiers[]` schema (MVP): `{modifier_id, type, value, condition_key?}`
  - Deterministic rule: apply in ascending `modifier_id` order before final weight clamp.
- UI payload: `name_key`, `rules_text_key`, `flavor_key`, `icon_key`, `frame_style`, `vfx_key`, `sfx_key`

Validation rules:
- `card_id` unique and immutable.
- `effects[]` non-empty for playable cards unless explicitly `utility_only=true`.
- `base_cost >= 0`; temp/generated cards may override via flags only.
- All localization keys must resolve.
- All referenced `effect_id` must exist in effect registry.
- Conflicting tags (e.g., `ephemeral` + `retain`) fail validation unless explicitly whitelisted.

Example resource (JSON-like):
```json
{
  "card_id": "iron_chain_opening",
  "schema_version": 1,
  "archetype": "chain",
  "rarity": "common",
  "base_cost": 1,
  "cost_type": "mana",
  "target_mode": "single_enemy",
  "speed_class": "normal",
  "timing_window": "main",
  "combo_tags": ["chain_starter"],
  "effects": [
    {"effect_id": "deal_damage", "params": {"amount": 6}},
    {"effect_id": "grant_chain_charge", "params": {"stacks": 1}}
  ],
  "zone_on_play": "discard",
  "pool_tags": ["starter", "attack"],
  "unlock_key": "base_set",
  "weight_base": 1.0,
  "name_key": "card.iron_chain_opening.name",
  "rules_text_key": "card.iron_chain_opening.rules",
  "icon_key": "icons/cards/iron_chain_opening"
}
```

### States and Transitions

Authoring states:
- Defined -> Validated -> Published

Runtime card-instance states:
- InDrawPile -> InHand -> SelectedTargeting (optional) -> Resolving -> Discarded | Exhausted | Retained | ConsumedTemp

Invalid transitions are blocked by the rules engine (example: `InDrawPile -> Resolving` is illegal).

### Interactions with Other Systems

Provisional contracts (until downstream GDDs are finalized):
- Effect Resolution Pipeline: consumes `effects[]`, sequencing fields, and targeting payload.
- Deck Lifecycle System: consumes lifecycle tags and zone transition instructions.
- Reward Draft System: consumes rarity/pool tags/unlock keys/weights.
- Unlock & Option Gating: consumes `unlock_key` and content flags.
- Deckbuilder/Inspection UI: consumes UI payload plus derived preview fields.
- Enemy Encounter System: may reference enemy-target filters and counter-tags.

Contract policy: Card Data owns field definitions and allowed value sets; downstream systems own runtime interpretation within those constraints.

## Formulas

1) Effective Reward Weight

`effective_weight(card, run_state, hub_state) = weight_base(card) * A_unlock * A_pool * A_hub * A_run * A_duplicates`

Where:
- `A_unlock` = 1 if unlock_key satisfied, else 0
- `A_pool` = 1 if card pool_tags intersect current reward pool and no exclusion_tags conflict, else 0
- `A_hub` = product of hub modifiers affecting matching tags/archetype (default 1.0)
- `A_run` = run-context scalar (e.g., archetype encouragement, streak dampening), clamped [0.5, 1.5] for MVP
- `A_duplicates` = duplicate dampener based on copies already offered/owned this run (default 1.0, floor 0.6)

MVP clamps:
- `weight_base` in [0.1, 5.0]
- `effective_weight` final clamp [0, 10]

2) Normalized Offer Probability

For candidate set `C`:

`P(card_i) = effective_weight_i / Σ(effective_weight_j for j in C)`

If `Σ=0`, fallback to curated safety pool.

3) Validation Score (pass/fail gate)

`validation_pass = id_ok AND schema_ok AND refs_ok AND rules_ok`

Sub-checks:
- `id_ok`: unique immutable `card_id`
- `schema_ok`: required fields present + typed + enum-valid
- `refs_ok`: all `effect_id` and localization keys resolve
- `rules_ok`: no forbidden tag combos unless allowlisted

4) Text Length Safety (UI readability)

`rules_text_overflow = char_count(rules_text_localized) > ui_limit_chars`

MVP default: `ui_limit_chars = 180` (warn at 160, fail at >220 for standard frame).

5) Cost Sanity

`playable_cost = base_cost + Σ(cost_modifiers_runtime)`

Constraint: schema enforces `base_cost >= 0`; runtime layer handles temporary negative-modifier floor policy.

Variable table (MVP defaults):
- `weight_base`: card’s baseline offer weight
- `pool_tags`, `exclusion_tags`: categorical filters
- `unlock_key`: progression gate token
- `ui_limit_chars`: per-frame text budget
- `A_*`: multiplicative scalars, each default 1.0 unless conditions apply

## Edge Cases

1) Duplicate `card_id`
- Behavior: hard validation fail; import blocked.

2) Missing/unknown `effect_id`
- Behavior: hard validation fail; card cannot publish.

3) Conflicting lifecycle tags (`retain` + `ephemeral`)
- Behavior: hard fail unless explicit allowlist rule exists.

4) Invalid targeting contract (e.g., `single_enemy` with `max_targets > 1` or unsupported `invalid_target_policy`)
- Behavior: hard validation fail.

5) Unplayable but draftable card (play conditions impossible)
- Behavior: warn in validator and exclude from reward pools until fixed.

6) Localization key missing
- Behavior: publish blocked for production; in dev, fallback to debug token plus warning.

7) Text overflow for standard card frame
- Behavior: warning at >160 chars, fail at >220 unless alternate frame style declared.

8) Schema version mismatch
- Behavior: migration step required; card held in Defined state until migrated and revalidated.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Effect Resolution Pipeline | Depended on by | Hard | Consumes `effects[]`, `stack_behavior`, `preview_priority`, sequencing metadata (`speed_class`, `timing_window`, `combo_tags`, `chain_flags`), targeting payload, and `invalid_target_policy`. |
| Deck Lifecycle System | Depended on by | Hard | Consumes lifecycle fields (`zone_on_play`, `ephemeral`, `generated_only`) and card instance identity linkage (`card_id`, instance UID at runtime). |
| Enemy Encounter System | Depended on by | Soft | Reads targeting compatibility tags/filters and optional counter-tags for encounter generation constraints. |
| Unlock & Option Gating | Depended on by | Hard | Consumes `unlock_key` and content flags to determine card eligibility. |
| Reward Draft System | Depended on by | Hard | Consumes `rarity`, `pool_tags`, `exclusion_tags`, `weight_base`, `weight_modifiers`, and unlock status for candidate generation and weighting. |
| Deckbuilder/Inspection UI | Depended on by | Hard | Consumes presentation payload (`name_key`, `rules_text_key`, `flavor_key`, `icon_key`, `frame_style`) plus preview metadata. |

Directional notes:
- This system has no upstream dependencies in MVP.
- Card Data is a source-of-truth provider; downstream systems must not redefine schema fields.

Consistency policy:
- Any new runtime field required by a downstream system must be added here first, versioned, and validated before use.

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `weight_base` | float/card | 1.0 | 0.1-5.0 | Card rarely appears | Card dominates rewards |
| `A_run` clamp | global float range | [0.5,1.5] | [0.3,2.0] | Run context feels irrelevant | Context overforces archetypes |
| `A_duplicates` floor | global float | 0.6 | 0.4-0.9 | Repeats feel spammy | Build consistency becomes too random |
| `ui_limit_chars` | int/frame | 180 | 140-220 | Truncated clarity | Verbose unreadable cards |
| `overflow_warn_chars` | int | 160 | 120-200 | Too many warnings/noise | Late readability failures |
| `max_effects_per_card` | int | 3 | 1-5 | Cards feel flat | Text bloat, parser complexity |
| `max_combo_tags` | int | 3 | 1-6 | Synergy depth shallow | Tag soup, opaque interactions |
| `weight_modifiers_cap` | float | 2.0x | 1.2x-3.0x | Hub impact feels weak | Hub becomes pseudo power creep |
| `allowlist_conflict_pairs` | set size | minimal | 0-10 pairs | Fewer creative edge cards | Validation loopholes grow |

Knob interaction notes:
- `weight_base` + `A_run` + `A_duplicates` jointly control reward diversity.
- `max_effects_per_card` and `ui_limit_chars` must be tuned together (raise one -> likely raise/adjust the other).
- `weight_modifiers_cap` should stay conservative to preserve "low grind" pillar.

Design governance:
- All knob changes are data-only and versioned by schema/release notes.
- Any change outside safe range requires playtest signoff.

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

1) Schema Integrity
- 100% of published cards pass required-field/type/enum validation.

2) Identity Safety
- `card_id` uniqueness enforced across all card assets; duplicate import is blocked.

3) Reference Integrity
- 100% of published cards resolve all `effect_id` references and localization keys.

4) Determinism Contract
- Given identical card asset + inputs, exported schema payload is byte-stable between loads (no nondeterministic field ordering/content).

5) Reward Weight Correctness
- For any candidate reward set, normalized probabilities sum to 1.0 ± 0.001.

6) Eligibility Gating
- Cards with unmet `unlock_key` never appear in reward candidates.

7) Conflict Guardrails
- Forbidden tag combinations fail validation unless allowlisted.

8) UI Readability Gate
- Rules text warnings trigger at configured threshold; hard fail at configured max unless alternate frame override exists.

9) Downstream Contract Tests
- Effect pipeline fixture can consume every published card’s `effects[]` payload without schema errors.
- Deck inspection fixture can render every published card using UI payload without missing-key errors.

10) Tooling Throughput
- Validation pass over full MVP card set completes within 1 second in local tooling for iterative design flow.

## Open Questions

[To be designed]
