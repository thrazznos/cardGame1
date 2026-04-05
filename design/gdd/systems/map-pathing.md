# Map/Pathing System

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: High Run Variety, Low Grind; Readable Tactical Clarity; Sequencing Mastery Over Raw Stats
> **Upstream References**: design/gdd/systems/reward-draft.md, design/gdd/systems/enemy-encounters.md, design/gdd/systems/unlock-option-gating.md, design/gdd/card-data-definitions.md

## Overview

Map/Pathing System (MPS) is the authoritative run-progression graph generator and traversal controller for Dungeon Steward MVP.

MPS is responsible for:
- Deterministic map graph generation (layers, nodes, directed edges, branch structure).
- Node content assignment (combat, elite, event, rest, shop, boss gate/boss).
- Path choice legality (what can be selected now, adjacency validation, lock rules).
- Forward visibility and telegraphing (what the player can see now vs later).
- Traversal checkpoints that trigger encounter setup and reward generation.

Design intent:
- Deliver meaningful route planning each run without forcing grind-heavy “correct” routes.
- Keep choices legible: risk/reward should be readable from map UI.
- Make progression deterministic and replay-verifiable from seed + state.

Out of scope (MVP):
- Free-roam overworld navigation.
- Fog-of-war exploration with hidden tactical movement.
- Live-ops map mutation outside authored deterministic rule sets.

## Player Fantasy

The player fantasy is:
- “I can read upcoming risks and rewards and choose my line intentionally.”
- “Each run’s map feels fresh, but not random nonsense.”
- “My sequencing skill matters: I can route toward what my deck needs now.”
- “When a path is blocked or risky, I understand why.”

The map should feel like strategic routing, not hallway autopilot.

## Detailed Design

### Design Goals (Optional)

1) High variety, bounded structure
- Maps should produce distinct route patterns run-to-run while preserving predictable progression milestones (elite pressure, recovery windows, boss arrival).

2) Readable clarity
- Node identity, upcoming threats, and legal next choices are visible and stable.

3) Sequencing mastery
- Route value depends on run context (deck/relic state, current HP/resources), rewarding planning over pure stat checks.

4) Deterministic replayability
- Same seed + same profile/run snapshot + same commits -> identical graph, encounters, rewards, and traversal outcomes.

### Core Rules

1) Graph is layered and acyclic (MVP)
- Map is generated as ordered layers `L0..L_last`.
- Directed edges only connect from layer `k` to `k+1`.
- No backward traversal in MVP.

2) One committed move per traversal step
- Player may select only a legal outgoing edge from the current node.
- Commit point is path-confirm action, not animation completion.
- Commit is idempotent by `(run_id, node_instance_id, commit_event_id)`.

3) Node types are explicit and data-authored
- MVP node types: `combat`, `elite`, `event`, `rest`, `shop`, `boss_gate`, `boss`.
- Each type has authored generation quotas/weights by layer band.

4) Mandatory progression constraints
- Exactly one reachable `boss` node exists at final layer.
- At least one reachable path from start to boss is guaranteed.
- Required milestone bands (elite/rest/shop opportunities) must satisfy authored min/max bounds.

5) Traversal checkpoints are deterministic
- MPS emits deterministic checkpoint events:
  - `checkpoint.node_enter`
  - `checkpoint.node_resolve`
  - `checkpoint.reward_request` (if node grants rewards)
- Reward Draft System only triggers from checkpoint events, never from animation timing.

6) Encounter assignment is deterministic and deferred to node-entry boundary
- For encounter nodes (`combat`, `elite`, `boss`), MPS requests an encounter using deterministic context at `node_enter`.
- Encounter selection uses node seed slice + encounter pool policy; no frame-time rolls.

7) Visibility/telegraph policy is tiered
- Immediate legal next nodes are fully visible.
- Forward nodes beyond one step show authored preview level:
  - `full`: type + risk class + reward hint
  - `partial`: type silhouette + risk band only
  - `hidden`: locked placeholder until adjacency reached
- Boss node and final approach lane are always visible from run start.

8) Locking never creates soft-lock states
- Dynamic locks/unlocks may change future options, but current node must always retain at least one legal exit unless run is complete/failed.

9) Deterministic RNG isolation
- MPS never uses ambient runtime random APIs.
- Graph generation, node typing, and encounter-pool picks use indexed deterministic RNG streams.
- MPS RNG streams are isolated from combat and reward streams.

10) Save/resume is authoritative
- Open traversal state restores exact current node, revealed visibility state, pending checkpoints, and RNG cursors.
- Resume never rerolls map structure or already-committed node outcomes.

### Map Topology and Generation Policy (Optional)

MVP topology profile (default):
- Layers: 9 (start + 7 traversal + boss).
- Nodes per middle layer: 2-4 (authored by layer band).
- Outgoing edges per node: 1-2.
- Incoming edges per non-start node: 1-3.
- Branch merge allowed; branch split allowed; cross-layer skips disallowed.

Authored layer-band intent:
- Early band: onboarding variance, lower elite density.
- Mid band: highest branch tension (risk/reward divergence).
- Late band: convergence toward boss approach with at least one recovery option if feasible.

### States and Transitions

Run map states:
- MapUninitialized
- MapGenerated
- AwaitNodeSelection
- TransitionCommitted
- NodeEntered
- NodeResolving
- NodeResolved
- AwaitRewardResolution (optional)
- ActComplete

Primary transitions:
- MapUninitialized -> MapGenerated (run start/load)
- MapGenerated -> AwaitNodeSelection
- AwaitNodeSelection -> TransitionCommitted (legal edge confirmed)
- TransitionCommitted -> NodeEntered
- NodeEntered -> NodeResolving (node content execution starts)
- NodeResolving -> NodeResolved
- NodeResolved -> AwaitRewardResolution (if reward checkpoint exists)
- AwaitRewardResolution -> AwaitNodeSelection (next step)
- NodeResolved -> ActComplete (if boss resolved)

Invalid transitions (hard reject):
- AwaitNodeSelection -> NodeEntered (without commit)
- TransitionCommitted -> AwaitNodeSelection (without rollback event)
- ActComplete -> AwaitNodeSelection

### Data Model and API Contracts (Optional)

Generation request:
- `MapGenerateRequest`
  - `run_id`
  - `profile_id`
  - `act_index`
  - `difficulty_tier`
  - `map_profile_id`
  - `seed_context`
  - `unlock_context_snapshot`

Generation result:
- `MapGenerateResult`
  - `map_instance_id`
  - `nodes[]` (`node_instance_id`, `layer_index`, `node_type`, `preview_payload_ref`)
  - `edges[]` (`edge_id`, `from_node_id`, `to_node_id`, `edge_flags`)
  - `start_node_id`
  - `boss_node_id`
  - `rng_cursor_start`
  - `rng_cursor_end`
  - `map_trace_id`

Traversal commit:
- `CommitPathChoice(run_id, from_node_id, to_node_id, commit_event_id)`
- Response:
  - `accepted` bool
  - `reject_reason_code?`
  - `new_current_node_id`
  - `checkpoint_events[]`

Encounter request contract (to Enemy Encounter System):
- `BuildEncounterRequest`
  - `run_id`, `node_instance_id`, `node_type`, `act_index`, `threat_band`, `encounter_pool_tags[]`, `rng_cursor`

Reward checkpoint contract (to Reward Draft System):
- `RewardDraftRequest` produced only from `checkpoint.reward_request` with:
  - `reward_checkpoint_id`
  - `node_type`
  - `run_context_snapshot`
  - `reward_history_digest`

### RNG Contract Binding (Canonical)

MPS is bound to RNG/Seed & Run Generation Control canonical API and run determinism manifest.

Required API usage:
- Indexed draw (trace/debug):
  - `DrawU32At(stream_key, draw_index) -> uint32`
- Cursor-consuming draw (runtime):
  - `DrawU32Next(stream_key) -> uint32`

Required stream keys:
- `map.layout`
- `map.node_type`
- `map.encounter_pick`
- `map.event_variant`

Contract requirements:
- MPS persists/restores per-stream cursor heads through run save snapshots.
- MPS pins `map_profile_version` and dependent pool versions through run determinism manifest.
- MPS logs stream/index pairs in generation and traversal checkpoint traces.

### Interactions with Other Systems

1) Enemy Encounter System (hard downstream)
- MPS selects encounter context and triggers encounter build at node entry.
- EES owns encounter composition/intent behavior after handoff.

2) Reward Draft System (hard downstream)
- MPS emits deterministic reward checkpoints from node resolution.
- RDS consumes `node_type` and checkpoint context for channel bundle generation.

3) Unlock & Option Gating (hard upstream/adjacent)
- MPS filters map options/events gated by unlock keys or mode constraints.
- Ineligible optional branches may be hidden or shown disabled per UI policy.

4) Card Data / Relics / Deck state (adjacent runtime context)
- MPS may consume summarized run-state signals for risk/reward hinting only (not direct combat resolution).

5) Run Save/Resume (hard downstream)
- Persists map graph, current node, reveal state, lock states, and RNG cursors.

6) Map & Node UI (hard downstream)
- Renders authoritative nodes/edges, legal selections, previews, and lock reasons.

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a), b)`
- Boolean gates are represented as {0,1}

1) Node count by layer

`N_layer(k) = clamp(N_base(k) + delta_seed(k) + delta_profile(k), N_min(k), N_max(k))`

MVP defaults:
- Early layers `N_min=2, N_max=3`
- Mid layers `N_min=3, N_max=4`
- Late layers `N_min=2, N_max=3`

2) Node type assignment weight

For candidate node type `t` at layer `k`:

`W_type(t,k) = base_weight(t,k) * A_quota(t,k) * A_unlock(t) * A_run_context(t) * A_variety_recent(t)`

Where:
- `A_quota(t,k)` is 0 if min/max quota would be violated, else 1
- `A_unlock(t)` from UOG/context compatibility, binary {0,1}
- `A_run_context(t)` clamp [0.75, 1.25]
- `A_variety_recent(t)` clamp [0.6, 1.2]

3) Encounter threat band selection at node entry

`threat_band = clamp(B_node_base + B_act + B_path_depth + B_modifier, B_min, B_max)`

MPS passes `threat_band` and pool tags to EES; EES applies final composition formulas.

4) Path score for preview ordering (UI aid only, non-binding)

`preview_score(path_i) = reward_hint_i * R_w - risk_hint_i * K_w + recovery_hint_i * H_w`

MVP defaults:
- `R_w = 1.0`, `K_w = 1.0`, `H_w = 0.6`

This score is for readable ordering/highlighting only and does not alter legal path set.

5) Deterministic weighted selection (shared pattern)

Given eligible candidates `C`:
- `bucket_i = max(0, floor(W_i * WEIGHT_SCALE))`
- `roll = DrawU32At(stream_key, draw_index) mod Σ(bucket)`
- pick first cumulative bucket > `roll`

MVP default:
- `WEIGHT_SCALE = 1000`

6) Determinism digest extension (map)

`map_hash_next = FNV1a64(map_hash_prev || map_instance_id || current_node_id || chosen_edge_id || checkpoint_id || rng_call_index)`

Used with combat/reward hash chains for replay validation.

## Edge Cases

1) Save/Resume Integrity
- Mid-transition save: save after node selection but before travel animation completes restores exactly one committed destination and does not reopen prior node rewards.
- Mid-reward save: resume returns to reward UI state for that node; node cannot be re-entered for duplicate rewards.
- App kill during autosave: loader falls back to last valid checkpoint and never produces null current-node state.
- Version mismatch: old map schema migrates or hard-fails with safe message; no invisible nodes or soft-lock.
- Seed consistency: reloading same save reconstructs identical graph, node types, and lock states.

2) Unreachable-node prevention
- Generator rejects layouts where mandatory layer targets (including boss gate) have zero reachable inbound paths.
- Any path terminating before required milestone is invalid unless explicitly optional by profile.
- One-way lock trap is disallowed unless destination is final node.
- Dynamic lock/unlock cannot remove all legal exits from current node.

3) Input/navigation robustness
- Double click/tap commits once.
- Rapid input during pan/zoom cannot select hidden or non-adjacent nodes.
- Controller focus restores to current node and nearest legal edge after resume.
- Hover/selection states clear on act regeneration.

4) Exploit resistance
- Reloading pre-choice save cannot alter already committed RNG decisions.
- Re-entering completed node is rejected by authority guard.
- Non-adjacent destination spoofing is rejected by adjacency validation.
- Transition spam cannot queue multiple node advances.
- Force-close after reveal but before commit does not reroll already revealed options.

5) Accessibility/readability
- Available vs locked must be distinguishable without color alone.
- Small-screen mode preserves minimum tap target sizes.
- Localization expansion cannot overlap lock-reason labels.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| RNG/Seed & Run Generation Control | Upstream | Hard | Supplies indexed deterministic draws and persisted stream cursors for map generation/traversal events. |
| Enemy Encounter System | Downstream consumer | Hard | Consumes node-entry encounter request context and returns deterministic encounter instance. |
| Reward Draft System | Downstream consumer | Hard | Consumes deterministic reward checkpoint events and node context for offers. |
| Unlock & Option Gating | Upstream eligibility | Hard-adjacent | Supplies unlock/mode eligibility for gated nodes/options and visibility states. |
| Run Save/Resume | Persistence | Hard | Stores and restores map instance, current node, reveal state, commits, and RNG cursors exactly. |
| Map & Node UI | Presentation | Hard | Displays authoritative graph state, legal choices, previews, and reason codes. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `layers_total` | int | 9 | 7-12 | Runs feel too short/simple | Runs drag, pacing fatigue |
| `nodes_per_layer_mid` | int range | 3-4 | 2-5 | Low branch variety | Choice overload/readability loss |
| `elite_min_per_act` | int | 1 | 0-3 | Risk/reward too flat | Difficulty spikes |
| `rest_min_per_act` | int | 1 | 0-3 | Recovery starvation | Tension collapses |
| `shop_min_per_act` | int | 1 | 0-2 | Economy options thin | Economy overcontrol |
| `preview_depth_steps` | int | 1 | 1-2 | Poor route planning clarity | Over-solvable maps |
| `A_variety_recent_floor` | float | 0.6 | 0.4-0.9 | Repeated node patterns | Loss of route coherence |
| `A_run_context_cap` | float | 1.25 | 1.0-1.5 | Route context irrelevant | Forced routing metas |
| `commit_debounce_ms` | int | 150 | 50-300 | Double-commit risk | Input feels sluggish |
| `WEIGHT_SCALE` | int | 1000 | 100-10000 | Coarse buckets | Overflow/perf pressure |

Governance:
- Knob changes must preserve deterministic replay equivalence for fixed seed/version and uphold low-grind baseline path viability.

## Visual/Audio Requirements

Visual:
- Node icons with clear type identity (`combat`, `elite`, `event`, `rest`, `shop`, `boss`).
- Legal edges highlighted; illegal edges visibly disabled with reason affordance.
- Risk/reward preview chips per node according to visibility policy.
- Current node and committed destination states are visually distinct.

Audio:
- Distinct cues for node hover, path commit, invalid selection, node arrival, and act completion.
- Elite/boss route nodes use stronger anticipation stingers.
- Repeated invalid input cues are rate-limited.

## UI Requirements

1) Stable deterministic map presentation
- Node and edge layout does not reshuffle within an act.
- Revealed information persists exactly after save/load.

2) Choice clarity
- UI clearly indicates legal next nodes from current position.
- Disabled/gated nodes expose concise lock reason text.

3) Telegraph readability
- Preview level (`full`, `partial`, `hidden`) is visually explicit.
- Risk bands and reward hints use icon + text patterns, not color only.

4) Commit safety
- Confirmed path shows immediate committed state; second commit attempts are ignored/rejected deterministically.

5) Integration transparency
- At node resolve, UI transitions cleanly to encounter or reward flow via checkpoint events.

## Acceptance Criteria

1) Deterministic generation
- Same seed + profile snapshot + mode context + map profile version yields byte-identical node graph and node type assignment.

2) Reachability safety
- 100% of generated maps in validation runs have at least one legal path start->boss and satisfy mandatory quota constraints.

3) Checkpoint correctness
- Node-entry and node-resolve checkpoints fire exactly once per committed node traversal.
- Reward checkpoints align with Reward Draft contract and never double-fire.

4) Encounter alignment
- Encounter nodes always produce deterministic, valid encounter requests consumable by EES.

5) Save/resume integrity
- Save/load during selection, transition, node resolve, and reward states restores exact progression with no rerolls and no duplicate claim paths.

6) Input/authority safety
- Non-adjacent/path-spoof commits are rejected with deterministic reason code.

7) Readability
- In usability test pass, players can correctly identify legal next choices and boss route from map UI without debug overlays.

8) Performance
- Map generation and validation for one act completes within 6 ms on target desktop browser hardware (excluding UI render).

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `mps_map_generate_calls_total`
- `mps_generation_reject_count{reason}`
- `mps_branch_factor_histogram`
- `mps_node_type_count{type}`
- `mps_checkpoint_emit_total{checkpoint}`
- `mps_invalid_commit_total{reason}`
- `mps_resume_restore_mismatch_total`

Debug tools (dev only):
- Dump map generation trace with candidate weights, filters, and RNG indices.
- Replay map construction from `(seed, map_profile_version, act_index)`.
- Force visibility profile (`full/partial/hidden`) for UI verification.
- Validate current map reachability and quota constraints in-editor.

## Open Questions

1) Should MVP include optional one-time path reroute consumable per act, or keep path commits strictly final?
2) Should preview depth remain fixed at 1 step or scale to 2 in higher difficulty tiers?
3) Do we need a dedicated `treasure` node type in MVP, or keep treasure bundled into event/reward contexts?
4) Should some event nodes be allowed to dynamically alter future edges in MVP, or defer dynamic topology mutation post-MVP?
5) Should map streams remain root-only keys or move to scoped keys by `(act_index, layer_index)` for denser replay diagnostics?