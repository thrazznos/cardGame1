# Determinism Test Harness (Sprint 001)

Goal
- Prove same seed + same inputs => same event order and state hash for implemented combat slice.

Minimum Fixture Set
1) seed_smoke_001
- One encounter, fixed input sequence, 3-5 turns.

Expected Checks
- final_state_hash_match == true
- event_sequence_exact_match == true
- rng_cursor_exact_match == true

Browser Matrix
- Chrome (stable)
- Firefox (stable)

Notes
- Sprint 001 starts with local deterministic assertions.
- Cross-browser capture pipeline is added during E5 execution.
