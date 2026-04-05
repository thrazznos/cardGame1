# Dungeon Steward Core Combat Loop Prototype Plan (Godot Web)

Status: Draft for pre-production gate
Owner: Combat Systems + Gameplay Engineering
Target engine/runtime: Godot 4.6 Web export (browser-first)
Timebox: 10 working days
Related approved specs: TSRE, ERP, CUI, EES, MRE, DLS, ADR-0001, ADR-0002

## 1) Objective

Validate that the MVP combat core loop is buildable, playable, deterministic, and inspectable in browser runtime:

Player turn -> intent selection -> validation -> commit -> deterministic resolve -> enemy intent/reply -> next turn or combat end.

The prototype must prove three things with data:
1. Rules integrity: legal/illegal actions, queue ordering, and effect resolution behave per approved GDD/ADR contracts.
2. Runtime viability: web build remains responsive under normal and bursty resolve chains.
3. Debuggability: logs/replay instrumentation can explain outcomes and isolate first divergence.

## 2) Scope (in prototype)

1) Single encounter vertical slice
- 1 player deck list (fixed 20-card prototype deck)
- 2 enemy archetypes + 1 encounter composition (2 enemies max on board)
- 1 relic/passive stub (simple deterministic trigger)

2) Combat state flow
- CombatInit -> TurnStart -> PlayerPhase -> ResolvePhase -> EnemyPhase -> TurnEnd -> CombatEnd
- ResolveLock input gating active during queue drain
- Pass turn action implemented

3) Card play + resolution
- Play intent submit, target selection, legality checks, commit, queue insertion
- Core effects only: damage, block/shield gain, draw, status apply (1 stackable status), simple trigger generation
- Zone transitions: hand -> resolve/limbo -> discard/exhaust (as authored)

4) Enemy behavior slice
- Deterministic intent reveal + resolve
- fixed_cycle or weighted_policy (seeded) behavior mode only

5) UI/HUD slice (functional, not final art)
- Hand, AP/mana display, phase banner, resolve lock indicator
- Enemy intent strip
- Queue panel (ordered items)
- Combat log panel with reason codes

6) Determinism + replay hooks
- Seeded run start
- Event stream with order keys and pre/post state hashes
- Exportable replay trace for a single combat

7) Browser target validation
- Test in Chrome and Firefox desktop web builds
- Performance/latency/memory observations captured

## 3) Out of Scope (prototype exclusions)

- Full run meta loop (map traversal, rewards draft, hub progression)
- Content breadth balancing (many cards/enemies/relics)
- Final UX polish, animation polish, VFX/SFX polish
- Mobile browser support, controller support, accessibility completeness
- Netcode/cloud save/multi-tab recovery hardening
- Full tutorial/onboarding flow
- Production anti-cheat and exploit hardening beyond basic deterministic contracts

## 4) Success Metrics (must be measurable)

A. Functional correctness
- >= 95% pass rate on prototype combat test cases (script below), with zero critical blockers.
- 0 occurrences of illegal state transitions during scripted tests.
- 0 silent action failures (all rejects/fizzles emit reason code event).

B. Determinism/replay
- 50 repeated runs of same seed + scripted inputs produce identical final state hash and event count.
- First-mismatch locator available when divergence occurs (event index + reason code + hash delta).
- 100% authoritative RNG calls tagged with stream_key + draw_index.

C. Browser performance
- Median frame time <= 16.7 ms during normal turns on reference machine.
- P95 frame time <= 33 ms during heavy resolve turns (burst chain case).
- Time-to-interactive from page load <= 8 s on reference machine/network.
- No browser tab crash/OOM in 30-minute soak run.

D. Input/UI clarity
- ResolveLock prevents gameplay mutations 100% while still allowing hover/inspect.
- Queue panel order matches authoritative order key for 100% resolved actions in test script.
- At least 90% of tester-reported "why did this happen" questions answerable directly from in-game log + debug trace.

E. Stability
- 0 data-corrupting prototype defects (state desync requiring restart) in final 3-day test window.

## 5) Test Script (execution checklist)

Test setup (all cases)
- Build web export in release-with-debug-overlay mode.
- Use fixed prototype content pack v0.
- Use seeds: 1001, 1002, 1003.
- Run each case in Chrome and Firefox.
- Capture trace file and summary metrics after each run.

Case T01: Basic legal turn flow
1. Start combat.
2. Play one legal non-targeted card.
3. End/pass turn.
Expected:
- Phase flow valid.
- AP spent at commit.
- Card transitions to correct zone.
- Enemy intent reveals then resolves.

Case T02: Illegal action rejection
1. Attempt play with insufficient AP.
2. Attempt target-required card with invalid target.
Expected:
- No state mutation except rejection event.
- Reason code visible in UI and trace.

Case T03: Queue ordering determinism
1. Play two cards with different timing/speed classes.
2. Trigger at least one generated trigger.
Expected:
- Resolve order matches comparator chain.
- Queue panel and log order match authoritative event stream.

Case T04: Status + stack policy
1. Apply stackable status twice.
2. Advance turn to tick/expire logic boundary.
Expected:
- Stack and duration follow authored policy.
- Clamp/refresh behavior logged when applicable.

Case T05: Enemy deterministic behavior
1. Run same seed twice with identical player inputs.
Expected:
- Enemy intents and outcomes identical (including RNG draw indices).

Case T06: Replay parity
1. Export trace from one run.
2. Replay through deterministic harness.
Expected:
- Final hash and event count match exactly.
- If mismatch forced (debug toggle), first divergence reported.

Case T07: ResolveLock and input gating
1. During queue drain, spam card clicks/end-turn.
Expected:
- No mutating input accepted during ResolveLock.
- Inspection still functional.

Case T08: Performance burst
1. Execute pre-authored heavy chain turn (high trigger density).
2. Continue combat for 10 turns.
Expected:
- Meets p95 frame-time target.
- No lockup/crash.

Case T09: 30-minute soak
1. Loop encounters continuously with seeded resets.
Expected:
- No crash/OOM.
- No accumulating input lag trend beyond 15% from baseline.

## 6) Instrumentation and Data Capture

Required runtime events (minimum)
- IntentCaptured, IntentRejected, IntentCommitted
- QueueItemEnqueued, QueueItemResolved
- EffectApplied, EffectFizzled, EffectRejected
- EnemyIntentGenerated, EnemyIntentRevealed, EnemyActionResolved
- StateTransition (from_state -> to_state)
- RNGDraw(stream_key, draw_index, value, callsite)
- DeterminismCheckpoint(event_index, pre_hash, post_hash)
- Error/Warning events with codes

Per-combat summary payload
- seed_root, content_version, build_version
- total_turns, total_events, total_rng_draws
- final_state_hash
- reject_count by reason_code
- avg_frame_ms, p95_frame_ms, peak_memory_mb
- resolve_lock_duration_ms (avg/p95)

Debug overlay counters (live)
- Current phase/sub-state
- Queue length
- Event index
- RNG cursor per stream (combat.*)
- Last rejection reason
- Last determinism checkpoint hash

Trace artifacts
- /artifacts/core-loop/{timestamp}_{browser}_{seed}.jsonl (event log)
- /artifacts/core-loop/{timestamp}_{browser}_{seed}_summary.json
- Optional replay diff report on mismatch

## 7) Exit Criteria (go/no-go to start production build)

Go only if all are true:
1. Functional correctness metric met (>=95% pass, 0 critical blockers).
2. Determinism metric met (50/50 parity for scripted repeat runs).
3. Browser performance thresholds met on reference machine for both test browsers.
4. No crash/OOM in soak and no unresolved state corruption defects.
5. Instrumentation complete enough to diagnose first divergence and legality failures without attaching an external debugger.
6. Open defects are only P2/P3 polish or non-core content issues.

No-go triggers:
- Any reproducible determinism divergence without first-mismatch visibility.
- Any core loop dead-end (cannot progress turn/combat) at severity P0/P1.
- Browser runtime instability preventing 30-minute soak completion.

## 8) Deliverables at Prototype End

- Playable Godot Web build URL/local package
- Test execution sheet with pass/fail by case and browser
- Determinism parity report (50-run batch)
- Performance summary report (normal + burst + soak)
- Defect list with severity and owner
- Recommendation: proceed / proceed-with-conditions / hold
