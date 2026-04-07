# Sprint 009 -- 2026-07-13 to 2026-07-24

## Sprint Goal
Build the gem-graph map MVP: polyhedra-projected floor graphs with gem stack persistence, room affinity gems, and multi-room floor traversal wrapping the existing combat slice. Turn "play encounters in sequence" into "navigate a gem-attuned graph where room order matters."

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S9.M1 | Polyhedra graph generator | gameplay-programmer | 1.5 | design/gdd/systems/gem-graph-map-decisions.md | Data-driven generator produces tetrahedron (4-node) and octahedron (6-node) floor graphs with gem attunements, 2-3 variable connectivity, and random node modifications. Deterministic from seed. |
| S9.M2 | Gem stack cap and persistence | gameplay-programmer | 1.0 | S9.M1, existing GSM | GSM enforces 6-slot max. Stack persists between rooms on a floor via snapshot/restore. Stack resets between floors. Room affinity grants 1 free gem at combat start (accumulates freely). |
| S9.M3 | Floor traversal controller | gameplay-programmer | 1.5 | S9.M1, S9.M2 | Player navigates the graph room-by-room with select-then-commit interaction. Adjacency validation, cleared-room tracking, and boss gate at exit node. Combat slice launches for combat rooms. |
| S9.M4 | Map UI — graph display and navigation | ui-programmer | 1.5 | S9.M1, S9.M3 | Full graph visible from floor start. Nodes show type (shape), gem attunement (color + icon), and cleared state. Current node highlighted. Legal next nodes selectable. Gem stack widget mirrors combat HUD. |
| S9.M5 | Room entry toast and gem grant | ui-programmer + gameplay-programmer | 0.5 | S9.M2, S9.M3 | Brief toast shows room name, affinity, and gem granted. Combat starts after ~1s auto-dismiss. Existing encounter toast pattern extended. |
| S9.M6 | Smoke tests and determinism coverage | qa-tester | 1.0 | S9.M1-M5 | Graph generator determinism verified. Floor traversal produces correct gem stack state across rooms. Multi-room flow completes without hangs or state corruption. |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S9.S1 | Gem slot loss on debt | gameplay-programmer + game-designer | 0.75 | S9.M2 | Depleting gem stack at a gem gate permanently reduces stack cap by 1 for the rest of the run. Easy-mode starting relic masks the first slot loss. |
| S9.S2 | Constraint draft merged with card reward | gameplay-programmer + ui-programmer | 1.0 | S9.M3, existing reward draft | After boss clear, reward cards each carry an attached floor constraint (Circuit/Seal/Conduit tag). Picking a card also selects the next floor's objective. |
| S9.S3 | Conduit floor objective (simplest variant) | gameplay-programmer | 0.75 | S9.S2, S9.M3 | Conduit pattern template shown at floor entry. Matching the pattern earns a pre-boss bonus. Missing it means standard boss. Objective banner visible on map UI. |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S9.N1 | Cube projection (8-node) for late floors | gameplay-programmer | 0.5 | S9.M1 | Generator supports cube topology for floors 4+. Edge pruning maintains 2-3 connectivity target. |
| S9.N2 | Route preview ghost on hover | ui-programmer | 0.5 | S9.M4 | Hovering an adjacent node shows projected gem stack delta in the info panel. |
| S9.N3 | Gem affinity weight in reward draft | gameplay-programmer | 0.5 | S9.S2, S9.M2 | RDS run_context_snapshot includes gem_stack_depth_by_color. Soft weight modifier [0.85, 1.15] on gem-affinity-tagged cards. |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Combat pressure profiles are complete | Sprint 008 delivered all 4 profiles with validation. Map wraps the combat slice — no combat rework needed. | 0 days |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Polyhedra graph generation is more complex than estimated | Medium | Medium | Start with tetrahedron (4 nodes) as minimum viable floor. Octahedron and cube are stretch. |
| Gem persistence creates subtle state bugs across room transitions | Medium | High | Snapshot/restore pattern with hash verification. Determinism fixture covers multi-room flow. |
| Map UI scope creep (polish, animation, layout) | High | Medium | Ship functional graph with basic node rendering first. Polish is Sprint 010. |
| Constraint draft merged with card reward is a UX risk | Medium | Medium | If too confusing, fall back to separate draft screens. Ship S9.S2 late so we can cut if needed. |

## Dependencies on External Factors
- Existing combat slice runner must support being launched from a floor controller (not just standalone scene)
- GSM must support stack cap and snapshot/restore without breaking existing combat determinism

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Player can navigate a gem-attuned polyhedra graph, enter rooms, and fight encounters
- [ ] Gem stack persists between rooms with correct accumulation and cap
- [ ] Room affinity grants free gems at combat start
- [ ] Map UI shows full graph with attunements, current position, and cleared rooms
- [ ] Determinism verified across multi-room floor traversal
- [ ] Existing combat probes and determinism fixtures still pass
- [ ] Design docs updated for any contract changes to GSM or MPS
