# Gem-Graph Map System — Design Decisions

> **Status**: Draft — decisions captured, full GDD pending
> **Date**: 2026-04-06
> **Source**: Socratic design session, Sprint 008 boundary

## Core Concept

The map is a sequencing puzzle that mirrors combat. Each floor is a small graph of gem-attuned rooms where visit ORDER matters because the gem stack persists between rooms.

## Locked Decisions

### 1. Graph Topology — Polyhedra Projections

Floor graphs are 2D projections of regular polyhedra with randomized node modifications.

Base shapes:
- **Tetrahedron** (4 nodes) — small, tight, early floors
- **Octahedron** (6 nodes) — mid complexity
- **Cube** (8 nodes) — full complexity, late floors
- **Dodecahedron face** (5 nodes) — alternative mid shape

Random modifications per floor: add/remove a node, add a shortcut edge. Preserves geometric readability while adding variety.

### 2. Gem Stack Persistence — Full + Floor Gem

- Gem stack carries fully between all rooms on a floor
- Each room's gem affinity (Ruby/Sapphire/neutral) grants 1 free gem of that color at combat start
- Stack resets between floors
- This is the load-bearing mechanic that makes room order matter

### 3. Floor Objective System — Player-Drafted Constraints

Between floors, the player drafts which constraint to add (like drafting cards):
- **Persistence** is always on (base layer)
- Player chooses ONE additional objective per floor: Circuit, Seal, or Conduit
- Better constraints = better rewards
- After floor 3+, allow pairing (e.g., Circuit + gem gates)

### 4. Visibility — Full Graph

- Entire graph, all attunements, all objectives visible from floor start
- The puzzle is pure planning, no fog of war
- No room revisits (cleared rooms are muted)
- Hub/junction nodes can be traversed without triggering encounters

### 5. Debt Spiral — Gem Slot Loss

- If a player depletes their gem stack completely and can't afford a gem gate: they LOSE a gem slot (permanent stack capacity reduction for the rest of the run)
- A starting relic on easy difficulty masks this penalty (acts as a buffer before actual slot loss)
- Gem gates are always optional (free path to boss exists), so this punishes greed, not routing failure

### 6. Variant Exclusivity

- Floors 1-3: persistence + ONE objective type (mutually exclusive)
- Floors 4+: allow pairing if the player opted in via constraint drafting
- Constraint combinations are the player's choice, not random

## Four Floor Objective Variants

### Circuit
- Target gem color sequence visible from floor entry (e.g., R-S-R-S)
- Visiting correct-color room advances tracker
- Wrong color triggers penalty node insertion
- Generator must verify sequence is achievable

### Seal
- 3 mandatory seal nodes with explicit gem costs
- All 3 must be cleared to reach boss gate
- Remaining nodes are optional prep rooms
- Generator must verify solvability

### Conduit
- Optional pattern template revealed at floor entry
- Match perfectly = pre-boss reward (relic or stack bonus)
- Miss = standard boss fight (no penalty)
- Lowest friction variant, good for introductory floors

### Persistent Stack (Gem Gates)
- Premium rooms (elites, strong events) have gem entry costs
- Combat gem decisions have direct map consequences
- Gates are optional bypasses, never mandatory
- Free path to boss always exists

### 7. Routing Density — 2-3 Variable Connectivity

- Outer nodes connect to 2 neighbors (commit points — once you go, options narrow)
- Inner nodes connect to 3 neighbors (decision points — real routing choices)
- Creates natural bottlenecks and shortcuts within the polyhedra projection

### 8. Gem Stack Capacity — 6 Slots

- Player starts with 6 gem slots (stack max = 6)
- Slot loss from debt reduces this permanently within the run
- The cap IS the natural snowball limiter for affinity gem accumulation
- Losing 1 slot = 17% capacity hit; losing 2 = 33% (brutal, run-defining)

### 9. Affinity Gem Accumulation — Free Stacking

- Room affinity gems accumulate freely across rooms
- 3 Ruby rooms in a row = 3 free Rubies banked before next combat
- Stack cap (6 slots) limits this naturally — banking affinity gems costs combat headroom
- Deliberate color routing is a real strategic commitment

### 10. Constraint Draft — Merged with Card Draft

- After beating a boss, the card reward draft and floor constraint draft are ONE screen
- Each reward card comes with a constraint attached: "Heavy Guard + Circuit rules" vs "Quick Slash + Seal rules"
- One decision, two consequences (deck improvement + floor difficulty)
- Players agonize over card-they-want vs constraint-they-can-handle

### 11. Room Entry Transition — Toast + Immediate Combat

- Brief toast showing room name, affinity, and gem granted
- Combat starts after ~1-second auto-dismiss
- Fast, maintains momentum, no menu tax between rooms
- Gem grant appears in the toast as a visual element

## Open Questions

| Question | Notes |
|----------|-------|
| Does gem slot loss carry between floors or only within a floor? | Within-run seems right |
| How does the reward draft weight gems after persistence is active? | Game-designer suggests gem_affinity_weight modifier on RDS |
| What polyhedra work best at each floor depth? | Tetra=4, Octa=6, Cube=8 — needs playtesting |
| How are constraint-card pairings generated? | Random? Authored? Weighted by encounter history? |
| What constraints pair well for late-game floors 4+? | Circuit+Gates seems natural, Seal+Conduit may conflict |

## Agent Findings (Archived)

### Level Designer
- Recommends Anchor-and-Orbit (adapted to polyhedra projection)
- 3-4 combat rooms, 1-2 events, 1 rest/shop per floor
- Difficulty scales by visit count, not graph position (except exit-adjacent = hardest)
- No room revisits, full visibility
- Node shape = type, background color = attunement, border = objective status

### UX Designer
- Info hierarchy: current node > gem stack > floor objective > node attunement > cleared path
- Two-step interaction: select then commit (not single-click)
- Route preview ghost on hover showing projected gem stack delta
- Gem stack widget mirrors combat HUD placement/language
- Objective banner persistent but compact, same screen region as stack widget

### Game Designer
- Gem producers gain "banking for the map" dimension
- Consumers face "exit cost" — big payoff now vs. saving for gate
- FOCUS becomes a map tool (transmute for next gate's color)
- Escalating profiles leave more gems banked than burst profiles (emergent map personality per encounter type)
- Need new MPS checkpoint type for Conduit bonus
- RDS run_context_snapshot needs gem_stack_depth_by_color extension
