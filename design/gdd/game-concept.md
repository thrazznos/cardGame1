# Game Concept: Dungeon Steward

*Created: 2026-04-04*
*Status: Draft*

---

## Elevator Pitch

> It’s a browser-first fantasy roguelite deckbuilder where you sequence cards to build compounding combat value through a dungeon run, then reinvest loot into a small hub that reshapes future card pools and run conditions.
>
> The core promise is “engine-building in combat”: each turn rewards precise ordering and combo timing, so players feel like they are constructing a strategy machine in real time.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Single-player roguelite deckbuilder with light meta-hub management |
| **Platform** | Browser (desktop-first Web export) |
| **Target Audience** | Mid-core and hardcore strategy/buildcraft players who enjoy optimization loops |
| **Player Count** | Single-player |
| **Session Length** | 30-45 minutes per full run |
| **Monetization** | Premium/one-time (TBD), no F2P grind assumptions |
| **Estimated Scope** | Small (6-8 week MVP) |
| **Comparable Titles** | Slay the Spire, Monster Train, Across the Obelisk (single-player buildcraft angle) |

---

## Core Fantasy

You are a tactical steward of a frontier dungeon outpost, turning fragile starting tools into a precise value engine. Every combat decision—especially card order—creates momentum, and every run contributes strategic options for the next one. The emotional promise is incremental mastery: not just getting stronger, but feeling smarter with each run.

---

## Unique Hook

A deckbuilder where *between-run hub investment changes future card and event ecosystems*, and *within-run card sequencing is a first-class tactical resource*. 

“And also” test: It’s like Slay the Spire, **and also** your hub development choices alter what the dungeon can offer and how your sequencing strategies evolve from run to run.

---

## Player Experience Analysis (MDA Framework)

The MDA (Mechanics-Dynamics-Aesthetics) framework ensures we design from the
player's emotional experience backward to the systems that create it.

### Target Aesthetics (What the player FEELS)
Rank the following aesthetic goals for this game (1 = primary, mark N/A if not
relevant). These come from the MDA framework's 8 aesthetic categories:

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 6 | Crisp pixel art readability, clear VFX for combo/timing triggers |
| **Fantasy** (make-believe, role-playing) | 4 | Fantasy dungeon crawl identity + steward role over a recovering outpost |
| **Narrative** (drama, story arc) | 7 | Lightweight flavor text/events, intentionally not story-heavy |
| **Challenge** (obstacle course, mastery) | 1 | Sequencing decisions, pathing tradeoffs, boss scaling pressure |
| **Fellowship** (social connection) | N/A | Single-player focus in MVP |
| **Discovery** (exploration, secrets) | 5 | Branching map, evolving pool interactions, event/relic discovery |
| **Expression** (self-expression, creativity) | 2 | High buildcraft variety and combo route experimentation |
| **Submission** (relaxation, comfort zone) | 8 | Not a primary target; the game is strategic and mentally active |

### Key Dynamics (Emergent player behaviors)
- Players reorder hands and sequence turns to maximize ramp and trigger windows.
- Players trade short-term safety for long-term compounding value.
- Players plan routes around deck state and boss expectations.
- Players experiment with archetypes and converge on personalized “engine styles.”
- Players make hub investments that bias future runs toward preferred strategy patterns.

### Core Mechanics (Systems we build)
1. Turn-based card combat with explicit order-sensitive interactions.
2. Mana ramp system tied to specific card classes and sequencing outcomes.
3. Branching dungeon map with visible risk/reward paths.
4. Run rewards (cards/relics/resources) with constrained draft choices.
5. Lightweight hub investment layer that modifies future pool probabilities/modifiers.

---

## Player Motivation Profile

Understanding WHY players play helps us make every design decision. Based on
Self-Determination Theory (SDT) and the Player Experience of Need Satisfaction
(PENS) model.

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | Branching pathing, card/relic picks, and sequencing alternatives each turn | Core |
| **Competence** (mastery, skill growth) | Players improve through combo literacy, ordering precision, and encounter planning | Core |
| **Relatedness** (connection, belonging) | Light connection to world via hub stewardship fantasy; no social systems in MVP | Minimal |

### Player Type Appeal (Bartle Taxonomy)

Which player types does this game primarily serve?

- [x] **Achievers** (goal completion, collection, progression) — How: Beat runs, unlock options, optimize outcomes.
- [x] **Explorers** (discovery, understanding systems, finding secrets) — How: Discover synergies, event outcomes, and route strategies.
- [ ] **Socializers** (relationships, cooperation, community) — How: Not a core target in MVP.
- [ ] **Killers/Competitors** (domination, PvP, leaderboards) — How: No PvP/competitive ladder in MVP.

### Flow State Design

Flow occurs when challenge matches skill. How does this game maintain flow?

- **Onboarding curve**: First run introduces only a small, legible card subset and 1-2 simple sequencing synergies.
- **Difficulty scaling**: Enemies and elites escalate by floor; bosses test specific sequencing competencies.
- **Feedback clarity**: Combat log + visual queue highlights explain why combos succeeded/failed.
- **Recovery from failure**: Fast restart, short pre-run setup, educational death recap showing key decision losses.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Draw hand, evaluate order, play cards to ramp mana and trigger sequencing effects, then defend/convert value before enemy action. The repeated pleasure is seeing small optimizations stack immediately.

### Short-Term (5-15 minutes)
Clear 2-3 encounters, choose one reward package, and decide next branch on the map. This is where “one more node” momentum appears through tactical and strategic tradeoffs.

### Session-Level (30-120 minutes)
A full run (target 30-45 minutes): progress through dungeon branches, face elites/boss, then return to hub to reinvest run loot into future-run option shaping.

### Long-Term Progression
Primarily knowledge and option growth (light meta): unlock new strategic possibilities rather than raw permanent power spikes. Players grow by skill plus wider build palette.

### Retention Hooks
- **Curiosity**: Unseen cards/relic interactions, unexplored map events, unopened archetype lines.
- **Investment**: Hub choices that set up future run identities.
- **Social**: Optional future sharing of builds/seeds (post-MVP), not required for loop.
- **Mastery**: Better sequencing lines, cleaner elite clears, improved consistency across runs.

---

## Game Pillars

Design pillars are non-negotiable principles that guide EVERY decision. When
two design choices conflict, pillars break the tie. Keep to 3-5 pillars.

### Pillar 1: Sequencing Mastery Over Raw Stats
Winning should come from intelligent card order and timing, not stat inflation.

*Design test*: If choosing between a plain +damage relic and a relic enabling order-based combo depth, choose combo depth.

### Pillar 2: Compounding Value Every Turn
Each turn should offer opportunities to create incremental advantage that snowballs through good planning.

*Design test*: If a mechanic creates static repetitive turns with little compounding potential, reject or redesign it.

### Pillar 3: Readable Tactical Clarity
Complexity is welcome, confusion is not. The game must make cause-and-effect understandable.

*Design test*: If players cannot explain why an interaction happened from UI feedback, simplify or improve visualization.

### Pillar 4: High Run Variety, Low Grind
Replayability should come from meaningful variation and strategy expression, not mandatory grind.

*Design test*: If progression requires repetitive farming for baseline viability, reduce power gating and shift to option unlocks.

### Anti-Pillars (What This Game Is NOT)

- **NOT heavy narrative gating**: Long story lockouts would compromise quick strategic iteration and replay rhythm.
- **NOT mandatory meta power grind**: Permanent stat creep would undermine skill-driven mastery.
- **NOT bloated card text complexity**: Excessive wording harms readability and tactical clarity.
- **NOT long dead turns/passivity**: Turn flow must stay active and decision-rich.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Slay the Spire | Tight encounter pacing, map branching, deckbuilder clarity | Add hub investments that shape future pool ecology | Validates demand for strategic roguelite deck combat |
| Monster Train | Layered buildcraft and explosive synergy moments | Keep single-lane readability and order-centric interactions | Shows high replay value from combo expression |
| Civilization / City Builders | Incremental compounding and planning satisfaction | Compress compounding loop into run + light hub cycle | Aligns with target player’s compounding-value motivation |

**Non-game inspirations**: Dungeon-crawl pulp fantasy tone, tabletop engine-building mindset, minimalist pixel UI readability from retro tactics titles.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-40 |
| **Gaming experience** | Mid-core to hardcore strategy players |
| **Time availability** | 30-45 minute focused sessions |
| **Platform preference** | Desktop browser |
| **Current games they play** | Slay the Spire, Civilization, strategy/city-builder titles |
| **What they're looking for** | Skillful buildcraft, compounding strategy, high replayability |
| **What would turn them away** | Excessive narrative interruption, grindy progression, low readability |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | **Godot 4** — best fit for solo first project, fast 2D iteration, strong Web export path, lower overhead than Unity/Unreal for this scope |
| **Key Technical Challenges** | Order-sensitive resolution system, deterministic combat state handling, browser performance/UI clarity |
| **Art Style** | Pixel art 2D fantasy |
| **Art Pipeline Complexity** | Medium (custom 2D + UI-heavy card content) |
| **Audio Needs** | Moderate (combat feedback + ambient loop + cue stingers) |
| **Networking** | None (single-player MVP) |
| **Content Volume** | MVP: 1 biome, 3-4 enemy families, 1 boss, ~80 cards, ~30 relics, 5-8 hours initial mastery depth |
| **Procedural Systems** | Procedural map branching + weighted reward/event pools influenced by hub investments |

---

## Risks and Open Questions

### Design Risks
- Core sequencing may feel opaque without excellent feedback.
- Hub layer may feel either too weak (irrelevant) or too strong (grindy) if tuning drifts.

### Technical Risks
- Browser UI complexity for drag/play order interactions may create input friction.
- Deterministic trigger ordering bugs can produce hard-to-debug edge cases.

### Market Risks
- Deckbuilder space is crowded with established titles.
- “Generic fantasy” theming may reduce immediate differentiation unless hook is clearly communicated.

### Scope Risks
- Card/relic content count can balloon beyond solo 6-8 week limits.
- Hub system could expand into a full management game if boundaries are not enforced.

### Open Questions
- How much hub influence feels meaningful without becoming mandatory grind? (Answer via A/B prototype tuning.)
- What level of order-combo complexity remains readable for first-time players? (Answer via onboarding prototype + playtests.)

---

## MVP Definition

**Core hypothesis**: Players find the order-sensitive card combat loop engaging enough to sustain 30-45 minute sessions with repeat runs.

**Required for MVP**:
1. Deterministic turn-based card combat with several order-based synergies.
2. Branching dungeon map with encounter/reward cadence.
3. Lightweight post-run hub investment that alters future pool weights/modifiers.

**Explicitly NOT in MVP** (defer to later):
- Deep narrative campaign and branching dialogue system.
- Multiple biomes/factions beyond one polished vertical path.

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 biome, 1 boss, limited card/relic set | Core combat + map + light hub | 6-8 weeks |
| **Vertical Slice** | 1 polished full run arc | Improved onboarding, tuning pass, better UX juice | +4-6 weeks |
| **Alpha** | 2-3 biomes, expanded archetypes | Content breadth, balancing, broader events | +8-12 weeks |
| **Full Vision** | Complete content plan and polish | Full progression depth, richer art/audio, QoL suite | +4-8 months |

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Fill in CLAUDE.md technology stack based on engine choice (`/setup-engine`)
- [ ] Create game pillars document (`/design-review` to validate)
- [ ] Decompose concept into systems (`/map-systems` — maps dependencies, assigns priorities, guides per-system GDD writing)
- [ ] Create first architecture decision record (`/architecture-decision`)
- [ ] Prototype core loop (`/prototype order-sensitive card sequencing`)
- [ ] Validate core loop with playtest (`/playtest-report`)
- [ ] Plan first milestone (`/sprint-plan new`)
