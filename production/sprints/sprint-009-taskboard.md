# Sprint 009 Taskboard - Execution

Status: Planned
Sprint: production/sprints/sprint-009.md
Updated: 2026-04-06
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - Polyhedra Graph Generator (S9.M1)
- [ ] E1.T1 Define polyhedra edge lists for tetrahedron and octahedron
- [ ] E1.T2 Implement graph generator with gem attunement assignment (deterministic from seed)
- [ ] E1.T3 Add random node modifications (add/remove node, add shortcut edge)
- [ ] E1.T4 Verify 2-3 variable connectivity constraint on generated graphs

## Epic E2 - Gem Stack Persistence and Cap (S9.M2)
- [ ] E2.T1 Add 6-slot stack cap to GSM with ERR_STACK_FULL on overflow
- [ ] E2.T2 Implement stack snapshot/restore for cross-room persistence
- [ ] E2.T3 Add room affinity gem grant at combat start (accumulates freely)
- [ ] E2.T4 Stack reset between floors

## Epic E3 - Floor Traversal Controller (S9.M3)
- [ ] E3.T1 Floor state machine: floor_start -> room_select -> room_enter -> combat -> room_clear -> (loop or boss)
- [ ] E3.T2 Adjacency validation and select-then-commit interaction
- [ ] E3.T3 Wire combat slice runner as child of floor controller (not standalone)
- [ ] E3.T4 Boss gate logic (unlock after required rooms cleared)

## Epic E4 - Map UI (S9.M4 + S9.M5)
- [ ] E4.T1 Graph renderer: nodes with type shapes, attunement colors, cleared state
- [ ] E4.T2 Edge rendering with legal-next highlighting
- [ ] E4.T3 Gem stack widget on map screen (mirrors combat HUD)
- [ ] E4.T4 Room entry toast with gem grant visual
- [ ] E4.T5 Current position and cleared-room visual state

## Epic E5 - Validation (S9.M6)
- [ ] E5.T1 Graph generator determinism fixture
- [ ] E5.T2 Multi-room gem persistence smoke probe
- [ ] E5.T3 Full floor traversal integration test
- [ ] E5.T4 Verify existing combat probes still pass

## Optional Stretch (Should/Nice)
- [ ] O1 Gem slot loss on debt (S9.S1)
- [ ] O2 Constraint draft merged with card reward (S9.S2)
- [ ] O3 Conduit floor objective (S9.S3)
- [ ] O4 Cube projection for late floors (S9.N1)
- [ ] O5 Route preview ghost on hover (S9.N2)
- [ ] O6 Gem affinity weight in reward draft (S9.N3)

## Outcome Notes
- Sprint 009 wraps the existing combat slice in a navigable gem-attuned graph.
- Success means fighting through a floor of rooms feels meaningfully different from fighting encounters in sequence.
- The map IS a sequencing puzzle — room order creates gem stack consequences.
