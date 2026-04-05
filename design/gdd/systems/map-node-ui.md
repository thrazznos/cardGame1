# Map & Node UI

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Readable Tactical Clarity; High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats
> **Upstream References**: design/gdd/systems/map-pathing.md, design/gdd/systems/reward-draft.md, design/gdd/systems/unlock-option-gating.md

## Overview

Map & Node UI (MNUI) is the player-facing navigation and interaction layer for run progression between combats.

MNUI does not author path legality, rewards, or encounter logic. It renders authoritative state from Map/Pathing System (MPS), presents deterministic previews, captures player branch choice, and transitions the player into node resolution flows.

MNUI responsibilities:
- Render node graph, edges, and current run position with high readability in browser.
- Communicate node state clearly (current, legal next, locked, hidden, completed, boss route).
- Provide inspectable node previews without violating deterministic reveal policy.
- Gate interactions so only legal MPS actions can be committed.
- Transition cleanly into encounter/event/reward flows triggered by MPS checkpoints.
- Preserve exact view/interaction state across save/load when applicable.

Non-goals (MVP):
- Free camera exploration beyond authored pan/zoom constraints.
- UI-authored reroutes that override MPS traversal legality.
- Hidden client-only rerolls or speculative reward generation.
- Topology mutation authored by UI itself.

## Player Fantasy

The player should feel like a deliberate route planner:
- “I can quickly read what is available now and what is likely ahead.”
- “When I choose a branch, I know why it is legal and what tradeoff I’m making.”
- “The map is clean and trustworthy; no surprises from unclear UI behavior.”
- “I can inspect enough detail to plan, without visual overload.”

Emotional outcome:
- Confidence in navigation clarity.
- Ownership of sequencing decisions.
- Fairness from deterministic, explainable map behavior.

## Detailed Design

### Design Goals (Optional)

1) Deterministic trust
- UI always reflects MPS authority exactly; no misleading local state.

2) Readability first in browser
- Legibility must hold on standard desktop and constrained laptop resolutions.

3) Low-friction planning
- Core map actions should be understandable within one glance + one inspect action.

4) Input safety
- Rapid clicking/tapping/controller navigation should never create double commits or illegal traversal.

5) Preview usefulness without spoilers
- Forward information depth follows MPS visibility policy (`full`, `partial`, `hidden`) and never leaks hidden details.

### Information Architecture (Optional)

Primary map screen regions:
1. Top bar: act label, progress marker (layer index), run seed/debug token (debug-only), back/settings.
2. Center canvas: node graph and edges with current-node anchor.
3. Right info panel: selected/hovered node details, risk class, reward hint chips, lock reason text.
4. Bottom controls: zoom in/out/reset, recenter-to-current, confirm path (if explicit confirm mode enabled).
5. Context overlays: legend, tutorial callouts, accessibility toggles.
6. Transition mask layer: commit travel and node-enter handoff visuals.

Responsive collapse (narrow width):
- Info panel becomes slide-up sheet.
- Legend collapses into icon button.
- Zoom controls become compact vertical stack.

### Core Rules

1) Authority rule
- MNUI must render only authoritative node/edge legality from MPS snapshot.
- Client-side prediction may improve responsiveness visually but cannot alter legal action set.

2) Legal selection rule
- A node is selectable for traversal only if it is a legal outgoing destination from current node per MPS.
- Non-adjacent selection attempts are rejected and show deterministic reason feedback.

3) Commit idempotency rule
- Path commit is idempotent by commit event ID contract from MPS.
- UI must disable repeated submit while commit is pending and handle duplicate-ack safely.

4) Visibility contract rule
- Node preview depth follows MPS reveal policy:
  - `full`: type + risk class + reward hint.
  - `partial`: silhouette + risk band.
  - `hidden`: placeholder only.
- UI never requests or displays data beyond allowed reveal tier.

5) Node state clarity rule
- Every node renders one primary state and optional secondary badge:
  - Primary: hidden, locked, available, current, completed, boss.
  - Secondary badges: elite, shop, rest, reward-rich, gate condition.

6) Lock explainability rule
- Locked or disabled nodes expose concise reason text key from MPS/UOG reason code map.
- Reason display must be available by hover/focus and tap/click on disabled nodes.

7) Deterministic ordering rule
- Node/edge draw order, focus order, and inspect panel field order are stable and deterministic.
- Same map snapshot must produce identical visual ordering across sessions/platforms.

8) Save/resume continuity rule
- On load, map graph, reveal states, selected node, focused element, and camera anchor restore deterministically from saved UI/runtime state contracts.
- Resume must not reopen already resolved node choices.

9) Enter-node handoff rule
- On successful commit, MNUI transitions to node-enter flow only after authoritative acceptance.
- Encounter/reward transitions are triggered by MPS checkpoints, not animation completion.

10) Accessibility rule
- Legal vs illegal vs locked distinctions must use icon/shape/text cues, not color alone.
- Keyboard/controller navigation parity is required for all core map actions.

11) Performance rule
- Graph redraw and pan/zoom interactions must stay responsive under browser target budgets.
- Expensive visual effects are optional and must degrade gracefully.

12) Anti-exploit input rule
- UI must not expose hidden node metadata via DOM/tooltips/debug in release mode.
- Spam input cannot queue multiple path commits.

### Node and Edge Presentation Model (Optional)

Node visual semantics:
- `current`: strongest ring + pulse, always centered by recenter action.
- `available_next`: highlighted border and active edge glow from current node.
- `completed`: muted fill with completion check marker.
- `locked`: muted with lock icon + reason affordance.
- `hidden`: generic placeholder icon without node type identity.
- `boss`: unique crown/skull motif and persistent visibility lane.

Edge visual semantics:
- `legal_now`: bright/high-contrast line.
- `reachable_future`: normal contrast line.
- `illegal_from_current`: dimmed line.
- `blocked_by_lock`: dim + lock interruption marker.

Preview chip policy (from MPS/RDS aligned hints):
- Risk chip: `low`, `mid`, `high`, `unknown`.
- Reward hint chips: channel-level hints only (example: `card`, `relic`, `option`, `shop access`, `recovery`).
- No exact reward contents are shown before checkpoint generation by RDS.

### Interaction Flows (Optional)

Flow A: Inspect node
1) Hover/focus/tap node.
2) Info panel updates with allowed preview fields.
3) If locked/hidden, show reason tier and what unlocks visibility (if allowed).

Flow B: Choose branch and commit
1) Select legal adjacent node.
2) UI enters SelectedPending state with highlighted route.
3) Commit via click/tap confirm or explicit confirm button (configurable).
4) Submit `CommitPathChoice` to MPS with commit ID.
5) On accept: lock controls, play transition, await checkpoint.
6) On reject: clear pending state, show reason code mapping.

Flow C: Enter node resolution
1) Receive `checkpoint.node_enter`.
2) Show short transition with node identity.
3) Route to encounter/event/rest/shop/reward UI as dictated by node type and checkpoints.
4) Return to map on node resolution completion when applicable.

Flow D: Resume mid-map
1) Load authoritative map + traversal snapshot.
2) Reconstruct revealed nodes, current node, and completed path markers.
3) Restore camera anchor and focus target safely.

### States and Transitions

MNUI macro states:
- MapUIInit
- AwaitMapSnapshot
- MapInteractive
- NodeInspect
- PathSelected
- CommitPending
- TravelTransition
- AwaitNodeEntryCheckpoint
- InNodeFlow
- ReturnFromNodeFlow
- MapActComplete
- MapUIErrorRecover

Primary transitions:
- MapUIInit -> AwaitMapSnapshot
- AwaitMapSnapshot -> MapInteractive (snapshot valid)
- MapInteractive -> NodeInspect (hover/focus/select)
- NodeInspect -> PathSelected (legal adjacent node selected)
- PathSelected -> CommitPending (commit action)
- CommitPending -> TravelTransition (commit accepted)
- CommitPending -> MapInteractive (commit rejected)
- TravelTransition -> AwaitNodeEntryCheckpoint
- AwaitNodeEntryCheckpoint -> InNodeFlow (`checkpoint.node_enter`)
- InNodeFlow -> ReturnFromNodeFlow (`checkpoint.node_resolve` complete)
- ReturnFromNodeFlow -> MapInteractive (next selection available)
- ReturnFromNodeFlow -> MapActComplete (boss resolved)
- Any state -> MapUIErrorRecover (snapshot mismatch/fatal contract error)

Invalid transitions (hard block):
- MapInteractive -> TravelTransition without accepted commit.
- CommitPending -> CommitPending with new destination (no multi-queue).
- InNodeFlow -> PathSelected (map input disabled during node flow).
- MapActComplete -> MapInteractive (unless new act initialization event).

State guards:
- GuardHasValidSnapshot
- GuardDestinationIsLegalAdjacent
- GuardCommitNotPending
- GuardCheckpointOrderValid
- GuardNodeFlowClosedBeforeMapInput

### Data Model and API Contracts (Optional)

Consumed map snapshot (read model):
- `MapUiSnapshot`
  - `run_id`
  - `map_instance_id`
  - `act_index`
  - `current_node_id`
  - `nodes[]` with display-safe reveal payload by node
  - `edges[]` with legality/lock flags
  - `visibility_profile`
  - `current_legal_destinations[]`
  - `map_state` (selection/resolution phase)
  - `version_token`

Selection/commit request:
- `CommitPathChoice(run_id, from_node_id, to_node_id, commit_event_id)`
- Response:
  - `accepted` bool
  - `reject_reason_code?`
  - `new_current_node_id?`
  - `checkpoint_events[]`

UI event contracts:
- `ui.map.node_inspect(node_id, reveal_tier, timestamp)`
- `ui.map.path_select(from_node_id, to_node_id)`
- `ui.map.path_commit_attempt(commit_event_id)`
- `ui.map.path_commit_result(accepted, reason_code?)`

Reward hint contract alignment:
- MNUI may display only authored `reward_hint_tags[]` from MPS preview payload.
- Exact offers/content remain unknown until RDS checkpoint generation.

### Run-Control Contract Binding (Canonical)

MNUI binds to approved RNG/Seed + Map/Pathing run-control contracts.

Required guarantees consumed by UI:
- Snapshot includes deterministic ordering keys (or canonical sort contract) for nodes/edges.
- Map/reveal policy versions are pinned in run determinism manifest and exposed to UI.
- `commit_event_id` is idempotent and duplicate-safe.
- `checkpoint.node_enter` and `checkpoint.node_resolve` are monotonic for the committed node.

### Interactions with Other Systems

1) Map/Pathing System (hard upstream)
- Provides authoritative map graph, legal adjacency, reveal tiers, lock states, reason codes, and traversal checkpoints.
- MNUI must not override path legality.

2) Reward Draft System (adjacent downstream flow)
- MNUI shows only reward hints pre-node.
- After `checkpoint.reward_request`, reward UI consumes RDS outputs; map view waits until reward flow closes.

3) Unlock & Option Gating (upstream via MPS payload)
- Lock reasons and eligibility display derive from gated state supplied through MPS/UOG integration.

4) Enemy Encounter System / Node Content UIs (downstream handoff)
- MNUI hands off on node entry based on node type.
- Returns to map only after node resolution contract.

5) Save/Resume System (hard upstream/downstream)
- Persists map UI-relevant state: current node, reveal status, selected/focused node, and camera anchor/zoom (if allowed).

6) Input Platform Layer (hard upstream)
- Provides mouse/keyboard/controller/touch abstraction with deterministic action mapping and debounce policy.

7) Telemetry/Debug Systems (soft MVP, hard for validation)
- Collects usability and determinism signals for map interaction and failure analysis.

## Formulas

1) Node screen position (layout normalization)

`x_screen = map_origin_x + layer_index * layer_spacing_px + lane_offset_px(node_lane)`
`y_screen = map_origin_y + lane_index * lane_spacing_px + jitter_px(seed_key, node_id)`

Rules:
- `jitter_px` is deterministic and bounded for readability; never changes node connectivity meaning.

MVP defaults:
- `layer_spacing_px = 220`
- `lane_spacing_px = 140`
- `|jitter_px| <= 18`

2) Zoom level clamp

`zoom_next = clamp(zoom_current + zoom_input_delta * zoom_step, zoom_min, zoom_max)`

MVP defaults:
- `zoom_step = 0.1`
- `zoom_min = 0.75`
- `zoom_max = 1.5`

3) Node clickable radius scaling

`hit_radius_px = clamp(base_hit_radius_px * (1 / zoom_current), hit_radius_min, hit_radius_max)`

MVP defaults:
- `base_hit_radius_px = 36`
- `hit_radius_min = 28`
- `hit_radius_max = 52`

4) Edge emphasis alpha

`alpha_edge = A_base * A_state * A_focus`

Where:
- `A_state` mapping: legal_now=1.0, reachable_future=0.65, illegal=0.25, blocked=0.2
- `A_focus` mapping: hovered-path=1.15 (clamped), non-focus=1.0

Final clamp:
- `alpha_edge = clamp(alpha_edge, 0.15, 1.0)`

5) Commit debounce guard

`commit_allowed = (now_ms - last_commit_attempt_ms) >= commit_debounce_ms && !commit_pending`

MVP default:
- `commit_debounce_ms = 150`

6) Preview panel priority score (display only)

`inspect_priority = P_state + P_risk + P_reward_hint`

Example default mapping:
- `P_state`: current=4, selected=3, legal_next=2, others=1
- `P_risk`: high=3, mid=2, low=1, unknown=0
- `P_reward_hint`: relic=2, card=1, option=1, none=0

Usage:
- Sorts inspect recents/history in UI only; does not alter gameplay legality.

7) Performance budget checks

`map_frame_update_ms_p95 <= MAP_UI_P95_BUDGET_MS`
`input_to_highlight_ms_p95 <= MAP_INPUT_FEEDBACK_P95_MS`

MVP defaults:
- `MAP_UI_P95_BUDGET_MS = 4.0`
- `MAP_INPUT_FEEDBACK_P95_MS = 80`

## Edge Cases

1) Double click / rapid tap on legal node
- Exactly one commit request is sent while pending; duplicates are dropped or idempotently ignored.

2) Selecting non-adjacent node via direct click/hotkey
- Hard reject with reason code; no temporary path animation.

3) Save during CommitPending or TravelTransition
- Resume restores committed destination and pending checkpoint state without reopening branch choice.

4) Save during reward panel opened from node
- Resume returns to reward flow; map interaction remains disabled until reward flow closes.

5) Lock state changes after inspect but before commit
- Commit uses latest authoritative legality; stale UI selection is rejected with updated reason.

6) Hidden node receives accidental focus via keyboard navigation
- Focus skips hidden placeholders unless they are interactable by policy.

7) Small viewport overlap
- Node labels/chips prioritize current + legal-next + boss lane; others collapse into icon-only with tooltip.

8) Localization expansion overflows lock reason text
- Reason text wraps/truncates with expandable tooltip; no overlap over critical controls.

9) Lost/late checkpoint events
- UI enters recover state and requests fresh snapshot; does not unlock map input on uncertain node flow status.

10) Browser tab background throttling during transition
- On refocus, reconcile with authoritative state before accepting new map input.

11) Attempted DOM inspection exploit for hidden data
- Release build strips hidden-node metadata and debug payloads from client state.

12) Controller disconnect/reconnect mid-selection
- Preserve selected node if valid; otherwise reset to current node focus.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Map/Pathing System | Upstream authority | Hard | Supplies graph, legality, reveal tiers, lock reasons, traversal checkpoints, and commit validation. |
| Reward Draft System | Adjacent/downstream flow | Hard | Reward content appears only after MPS reward checkpoint; MNUI shows only pre-checkpoint hints. |
| Unlock & Option Gating | Upstream (via MPS) | Hard-adjacent | Supplies eligibility reason semantics exposed in lock/disabled UI messaging. |
| Save/Resume System | Persistence | Hard | Restores map traversal state and required UI continuity fields without reroll/reselection. |
| Encounter/Event/Shop/Rest UIs | Downstream handoff | Hard | Consume node-entry handoff and return control on node resolution completion. |
| Input Abstraction Layer | Upstream | Hard | Ensures parity for mouse/keyboard/controller/touch with deterministic action mapping. |
| Telemetry/Debug | Adjacent | Soft MVP | Captures interaction/readability/determinism diagnostics for validation. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `layer_spacing_px` | int | 220 | 180-280 | Node/edge overlap | Excessive horizontal scrolling |
| `lane_spacing_px` | int | 140 | 110-190 | Visual crowding | Sparse, hard-to-scan map |
| `zoom_min` | float | 0.75 | 0.6-0.9 | Too much detail loss | Less full-map context |
| `zoom_max` | float | 1.5 | 1.2-2.0 | Inspect detail too limited | Pixelation/over-zoom confusion |
| `base_hit_radius_px` | int | 36 | 30-48 | Missed clicks/taps | Accidental selections |
| `commit_debounce_ms` | int | 150 | 75-300 | Duplicate commit risk | Input feels laggy |
| `label_density_level` | enum | medium | low/medium/high | Missing info | Cluttered readability |
| `preview_chip_max_count` | int | 3 | 1-5 | Weak route telegraphing | Chip overload |
| `travel_transition_ms` | int | 350 | 150-700 | Abrupt/no context | Pacing drag |
| `invalid_feedback_cooldown_ms` | int | 800 | 300-2000 | Spam feedback noise | Unclear failures |
| `controller_focus_wrap` | bool | true | true/false | Dead-end focus feel | Accidental focus jumps |

Governance:
- Knob changes must preserve deterministic interpretation of legal options and visibility tiers from MPS.
- Any readability-affecting change requires browser QA pass at target resolutions.

## Visual/Audio Requirements

Visual requirements:
- Clear iconography for node types and state overlays.
- Strong contrast between current node, legal next nodes, and non-legal nodes.
- Edge states visibly differentiated (legal, future, blocked, illegal).
- Preview chips use icon + text abbreviations with tooltip expansion.
- Boss route visibility maintained from run start.
- Transition visuals communicate commit accepted vs rejected outcomes distinctly.

Audio requirements:
- Distinct cues for hover/focus, legal select, commit success, commit reject, node arrival, and act completion.
- Invalid interaction cues are rate-limited.
- Elite/boss node selection uses stronger anticipation cue.
- Audio cues must remain informative with reduced motion mode enabled.

## UI Requirements

1) Graph readability
- Player can identify current node, legal next nodes, and boss lane at a glance.
- Zoom and pan controls are always discoverable.

2) Inspect panel clarity
- Selected node panel shows: node type (if revealed), risk band, reward hints, lock reason (if any), and outgoing options summary.

3) Deterministic focus/navigation
- Keyboard/controller tab/focus order is stable and follows deterministic node ordering.
- Focus returns to current node after major state transitions unless explicit selection persists.

4) Commit UX safety
- Selected destination is clearly marked before commit.
- Commit pending state disables additional path commits and indicates progress.

5) Handoff integration
- On node enter/resolve checkpoints, transitions to downstream UIs are clean and state-safe.
- Returning to map restores expected camera and focus context.

6) Accessibility
- Supports colorblind-safe distinction through shape/icon/text.
- Minimum tap/click targets respected on supported browser form factors.
- Text scales with accessibility size settings without obscuring legal path cues.

7) Debug/QA affordances (non-release)
- Optional overlays for node IDs, layer indices, edge legality flags, and reveal tier.
- Determinism mismatch warnings visible in debug builds only.

## Acceptance Criteria

1) MPS legality fidelity
- 100% of commit attempts accepted/rejected identically to MPS legality rules; no client-authorized illegal traversal.

2) Visibility policy compliance
- UI never reveals data beyond `full/partial/hidden` tier allowed by MPS snapshot across all node states.

3) Deterministic rendering
- Same map snapshot produces identical node ordering, focus ordering, and visible labels across reload/resume on target browsers.

4) Commit idempotency
- Repeated input during pending commit results in exactly one committed traversal event.

5) Reward alignment
- Pre-node UI shows hints only; exact reward offers appear only in RDS flow after reward checkpoint.

6) Save/resume integrity
- Resume during MapInteractive, CommitPending, TravelTransition, and reward/node flow restores correct state without reroll or duplicate traversal.

7) Readability usability
- In playtest validation, users can correctly identify legal next choices and lock reasons without debug overlays.

8) Performance
- Meets p95 map interaction budgets on target desktop browser hardware:
  - `map_frame_update_ms_p95 <= 4.0`
  - `input_to_highlight_ms_p95 <= 80`

9) Accessibility baseline
- Legal/locked/hidden states remain distinguishable without color and with keyboard/controller-only navigation.

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `mnui_map_screen_open_total`
- `mnui_node_inspect_total{state,reveal_tier}`
- `mnui_path_commit_attempt_total`
- `mnui_path_commit_reject_total{reason}`
- `mnui_path_commit_duplicate_drop_total`
- `mnui_focus_navigation_steps_total{input_mode}`
- `mnui_zoom_change_total{direction}`
- `mnui_snapshot_reconcile_total{reason}`
- `mnui_transition_to_node_total{node_type}`

Diagnostics (dev only):
- Show deterministic sort keys for nodes/edges.
- Overlay reveal tier and legality source fields.
- Replay map UI sequence from snapshot + input log.
- Toggle low-vision and reduced-motion presets for QA.

## Open Questions

1) Should MVP require explicit confirm button for every path commit, or allow single-click commit with optional setting?
2) Should map preview panel include projected “next two steps” breadcrumb when visibility depth is only 1, or keep strictly immediate-next information?
3) Should locked but visible nodes show “unlock hint” text in MVP, or reason code only?
4) Should controller navigation prioritize legal-next nodes first or geometric nearest nodes first?
5) Do we need an optional compact minimap mode for ultrawide/low-height browser windows in MVP?