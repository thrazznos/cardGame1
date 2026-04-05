# Systems Index: Dungeon Steward

> **Status**: Draft
> **Created**: 2026-04-04
> **Last Updated**: 2026-04-05
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Dungeon Steward is a browser-first roguelite deckbuilder centered on order-sensitive card sequencing, compounding value, and light meta progression through a hub investment layer. This system map prioritizes deterministic combat logic, readable tactical UI, and run-to-run variation while protecting the anti-pillars (no grindy power creep, no bloated complexity, no passive dead turns). The design order is dependency-first and MVP-first to validate core fun within a 6-8 week scope.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Card Data & Definitions (inferred) | Core | MVP | Approved | design/gdd/card-data-definitions.md | — |
| 2 | Turn State & Rules Engine (inferred) | Core | MVP | Approved | design/gdd/systems/turn-state-rules-engine.md | — |
| 3 | RNG/Seed & Run Generation Control (inferred) | Core | MVP | Approved | design/gdd/systems/rng-seed-run-generation.md | — |
| 4 | Profile Progression Save (inferred) | Persistence | MVP | Approved | design/gdd/systems/profile-progression-save.md | — |
| 5 | Effect Resolution Pipeline (inferred) | Gameplay | MVP | Approved | design/gdd/systems/effect-resolution-pipeline.md | Card Data & Definitions, Turn State & Rules Engine |
| 6 | Deck Lifecycle System | Gameplay | MVP | Approved | design/gdd/systems/deck-lifecycle.md | Turn State & Rules Engine, Card Data & Definitions, Effect Resolution Pipeline |
| 7 | Mana & Resource Economy | Economy | MVP | Approved | design/gdd/systems/mana-resource-economy.md | Turn State & Rules Engine, Effect Resolution Pipeline |
| 8 | Enemy Encounter System (inferred) | Gameplay | MVP | Approved | design/gdd/systems/enemy-encounters.md | Turn State & Rules Engine, Card Data & Definitions, RNG/Seed & Run Generation Control |
| 9 | Combat Balance Model (inferred) | Gameplay | MVP | Approved | design/gdd/systems/combat-balance-model.md | Effect Resolution Pipeline, Enemy Encounter System, Mana & Resource Economy |
| 10 | Unlock & Option Gating (inferred) | Progression | MVP | Approved | design/gdd/systems/unlock-option-gating.md | Profile Progression Save, Card Data & Definitions |
| 11 | Relics/Passive Modifiers | Gameplay | MVP | Approved | design/gdd/systems/relics-passive-modifiers.md | Effect Resolution Pipeline, Unlock & Option Gating |
| 12 | Reward Draft System | Economy | MVP | Approved | design/gdd/systems/reward-draft.md | Card Data & Definitions, Unlock & Option Gating, RNG/Seed & Run Generation Control |
| 13 | Map/Pathing System | Gameplay | MVP | Approved | design/gdd/systems/map-pathing.md | RNG/Seed & Run Generation Control, Enemy Encounter System, Reward Draft System |
| 14 | Meta-Hub Investment System | Progression | MVP | Approved | design/gdd/systems/meta-hub-investment.md | Profile Progression Save, Unlock & Option Gating, Reward Draft System |
| 15 | Run Save/Resume System (inferred) | Persistence | Vertical Slice | Approved | design/gdd/systems/run-save-resume.md | Turn State & Rules Engine, Deck Lifecycle System, Map/Pathing System, Reward Draft System, Relics/Passive Modifiers |
| 16 | Combat UI/HUD (inferred) | UI | MVP | Approved | design/gdd/systems/combat-ui-hud.md | Turn State & Rules Engine, Deck Lifecycle System, Mana & Resource Economy, Enemy Encounter System, Relics/Passive Modifiers, Effect Resolution Pipeline |
| 17 | Map & Node UI (inferred) | UI | MVP | Approved | design/gdd/systems/map-node-ui.md | Map/Pathing System, Reward Draft System |
| 18 | Hub UI (inferred) | UI | MVP | Approved | design/gdd/systems/hub-ui.md | Meta-Hub Investment System, Profile Progression Save |
| 19 | Deckbuilder/Inspection UI (inferred) | UI | MVP | Approved | design/gdd/systems/deck-inspection-ui.md | Card Data & Definitions, Deck Lifecycle System, Relics/Passive Modifiers |
| 20 | Audio Feedback System (inferred) | Audio | Vertical Slice | Approved | design/gdd/systems/audio-feedback.md | Combat, Map, Reward, Hub events |
| 21 | Onboarding & Tooltips System (inferred) | Meta | Vertical Slice | Approved | design/gdd/systems/onboarding-tooltips.md | Combat UI/HUD, Map & Node UI, Hub UI, Turn State & Rules Engine |
| 22 | Telemetry/Debug Hooks (inferred) | Meta | Alpha | Not Started | design/gdd/systems/telemetry-debug-hooks.md | Combat, Map, Reward, Meta-Hub systems |

---

## Categories

| Category | Description | Typical Systems |
|----------|-------------|-----------------|
| **Core** | Foundation systems everything depends on | Rules engine, card schema, RNG/seed control |
| **Gameplay** | The systems that make the game fun | Deck lifecycle, effects pipeline, enemies, map, relics |
| **Progression** | How options grow over time | Unlock gating, hub investment |
| **Economy** | Resource creation and consumption | Mana ramp, rewards drafting |
| **Persistence** | Save state and continuity | Profile progression save, run resume |
| **UI** | Player-facing information displays | Combat HUD, map UI, hub UI, deck inspection |
| **Audio** | Sound and music systems | Combat and reward feedback cues |
| **Meta** | Systems outside the core game loop | Onboarding/tooltips, telemetry/debug |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable prototype | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice / demo | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha milestone | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release | Design as needed |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. Card Data & Definitions — canonical card schema used by almost all gameplay systems.
2. Turn State & Rules Engine — authoritative structure for phases, timing windows, and deterministic order.
3. RNG/Seed & Run Generation Control — ensures reproducible map/reward/run generation.
4. Profile Progression Save — persistent meta state for unlocks and hub changes.

### Core Layer (depends on foundation)

1. Effect Resolution Pipeline — depends on: Card Data & Definitions, Turn State & Rules Engine.
2. Deck Lifecycle System — depends on: Turn State & Rules Engine, Card Data & Definitions, Effect Resolution Pipeline.
3. Mana & Resource Economy — depends on: Turn State & Rules Engine, Effect Resolution Pipeline.
4. Enemy Encounter System — depends on: Turn State & Rules Engine, Card Data & Definitions, RNG/Seed & Run Generation Control.
5. Combat Balance Model — depends on: Effect Resolution Pipeline, Enemy Encounter System, Mana & Resource Economy.
6. Unlock & Option Gating — depends on: Profile Progression Save, Card Data & Definitions.

### Feature Layer (depends on core)

1. Relics/Passive Modifiers — depends on: Effect Resolution Pipeline, Unlock & Option Gating.
2. Reward Draft System — depends on: Card Data & Definitions, Unlock & Option Gating, RNG/Seed & Run Generation Control.
3. Map/Pathing System — depends on: RNG/Seed & Run Generation Control, Enemy Encounter System, Reward Draft System.
4. Meta-Hub Investment System — depends on: Profile Progression Save, Unlock & Option Gating, Reward Draft System.
5. Run Save/Resume System — depends on: Turn State & Rules Engine, Deck Lifecycle System, Map/Pathing System, Reward Draft System, Relics/Passive Modifiers.

### Presentation Layer (depends on features)

1. Combat UI/HUD — depends on: Turn State & Rules Engine, Deck Lifecycle System, Mana & Resource Economy, Enemy Encounter System, Relics/Passive Modifiers, Effect Resolution Pipeline.
2. Map & Node UI — depends on: Map/Pathing System, Reward Draft System.
3. Hub UI — depends on: Meta-Hub Investment System, Profile Progression Save.
4. Deckbuilder/Inspection UI — depends on: Card Data & Definitions, Deck Lifecycle System, Relics/Passive Modifiers.
5. Audio Feedback System — depends on: combat/map/reward/hub event outputs.

### Polish Layer (depends on everything)

1. Onboarding & Tooltips System — depends on: Combat UI/HUD, Map & Node UI, Hub UI, Turn State & Rules Engine.
2. Telemetry/Debug Hooks — depends on: run-wide outputs from combat/map/reward/hub systems.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Card Data & Definitions | MVP | Foundation | game-designer, systems-designer | M |
| 2 | Turn State & Rules Engine | MVP | Foundation | game-designer, gameplay-programmer | M |
| 3 | Effect Resolution Pipeline | MVP | Core | game-designer, gameplay-programmer | L |
| 4 | Deck Lifecycle System | MVP | Core | game-designer | M |
| 5 | Mana & Resource Economy | MVP | Core | economy-designer, game-designer | M |
| 6 | Enemy Encounter System | MVP | Core | game-designer | M |
| 7 | Combat Balance Model | MVP | Core | balance-check, game-designer | M |
| 8 | Unlock & Option Gating | MVP | Core | systems-designer | S |
| 9 | Reward Draft System | MVP | Feature | game-designer | M |
| 10 | Relics/Passive Modifiers | MVP | Feature | game-designer | M |
| 11 | Map/Pathing System | MVP | Feature | level-designer, game-designer | M |
| 12 | Meta-Hub Investment System | MVP | Feature | systems-designer, economy-designer | L |
| 13 | Combat UI/HUD | MVP | Presentation | ux-designer, ui-programmer | M |
| 14 | Map & Node UI | MVP | Presentation | ux-designer | S |
| 15 | Hub UI | MVP | Presentation | ux-designer | S |
| 16 | Deckbuilder/Inspection UI | MVP | Presentation | ux-designer | S |
| 17 | Onboarding & Tooltips System | Vertical Slice | Polish | ux-designer, game-designer | S |
| 18 | Audio Feedback System | Vertical Slice | Presentation | sound-designer | S |
| 19 | Run Save/Resume System | Vertical Slice | Feature | gameplay-programmer | M |
| 20 | Telemetry/Debug Hooks | Alpha | Polish | analytics-engineer | S |

---

## Circular Dependencies

- None found in current decomposition.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Effect Resolution Pipeline | Technical | Order-dependent triggers can desync or create ambiguous outcomes | Prototype deterministic test harness early with fixture-based combat cases |
| Meta-Hub Investment System | Design / Scope | Could drift into grindy power creep or management bloat | Keep light-meta constraints; option unlocks over raw stats; enforce anti-pillars |
| Combat UI/HUD | Design | Complex sequencing may become unreadable in browser UI | Early clickable mock + playtest readability; prioritize queue/intent visualization |
| Combat Balance Model | Design | Compounding value can snowball into broken metas | Define guardrails, cap extreme loops, run balancing simulations regularly |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 22 |
| Design docs started | 21 |
| Design docs reviewed | 21 |
| Design docs approved | 21 |
| MVP systems designed | 18/18 |
| Vertical Slice systems designed | 3/3 |

---

## Next Steps

- [ ] Review and approve this systems enumeration
- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the highest-risk system early (`/prototype effect-resolution-pipeline`)
