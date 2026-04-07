# Sprint 009 Taskboard - Execution

Status: Complete
Sprint: production/sprints/sprint-009.md
Updated: 2026-04-06
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - Polyhedra Graph Generator (S9.M1)
- [x] E1.T1 Define polyhedra edge lists for tetrahedron and octahedron
- [x] E1.T2 Implement graph generator with gem attunement assignment (deterministic from seed)
- [x] E1.T3 Add random node modifications (add/remove node, add shortcut edge)
- [x] E1.T4 Verify 2-3 variable connectivity constraint on generated graphs

## Epic E2 - Gem Stack Persistence and Cap (S9.M2)
- [x] E2.T1 Add 6-slot stack cap to GSM with ERR_STACK_FULL on overflow
- [x] E2.T2 Implement stack snapshot/restore for cross-room persistence
- [x] E2.T3 Add room affinity gem grant at combat start (accumulates freely)
- [x] E2.T4 Stack reset between floors

## Epic E3 - Floor Traversal Controller (S9.M3)
- [x] E3.T1 Floor state machine: floor_start -> room_select -> room_enter -> combat -> room_clear -> (loop or boss)
- [x] E3.T2 Adjacency validation and select-then-commit interaction
- [x] E3.T3 Wire combat slice runner as child of floor controller (not standalone)
- [x] E3.T4 Boss gate logic (unlock after required rooms cleared)

## Epic E4 - Map UI (S9.M4 + S9.M5)
- [x] E4.T1 Graph renderer: nodes with type shapes, attunement colors, cleared state
- [x] E4.T2 Edge rendering with legal-next highlighting
- [x] E4.T3 Gem stack widget on map screen (mirrors combat HUD)
- [ ] E4.T4 Room entry toast with gem grant visual (wired but needs combat integration)
- [x] E4.T5 Current position and cleared-room visual state

## Epic E5 - Validation (S9.M6)
- [x] E5.T1 Graph generator determinism fixture
- [x] E5.T2 Multi-room gem persistence smoke probe
- [x] E5.T3 Full floor traversal integration test
- [x] E5.T4 Verify existing combat probes still pass

## Optional Stretch (Should/Nice)
- [x] O1 Gem slot loss on debt (S9.S1)
- [x] O2 Constraint draft merged with card reward (S9.S2)
- [x] O3 Conduit floor objective (S9.S3)
- [x] O4 Cube projection for late floors (included in graph generator)
- [ ] O5 Route preview ghost on hover (S9.N2)
- [ ] O6 Gem affinity weight in reward draft (S9.N3)

## Outcome Notes
- Sprint 009 wraps the existing combat slice in a navigable gem-attuned graph.
- Success means fighting through a floor of rooms feels meaningfully different from fighting encounters in sequence.
- The map IS a sequencing puzzle — room order creates gem stack consequences.
