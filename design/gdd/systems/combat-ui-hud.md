# Combat UI/HUD

> Status: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-04
> Implements Pillars: Readable Tactical Clarity; Sequencing Mastery Over Raw Stats; High Run Variety, Low Grind
> Upstream References: design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/deck-lifecycle.md, design/gdd/systems/mana-resource-economy.md, design/gdd/systems/enemy-encounters.md, design/gdd/systems/relics-passive-modifiers.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/card-data-definitions.md

## Overview

Combat UI/HUD (CUI) is the player-facing presentation and input layer for tactical combat. It does not own combat logic. It renders authoritative state from TSRE/DLS/MRE/EES/RPM/ERP and submits only legal player intents through TSRE contracts.

Primary objective:
- Maximize tactical clarity in a browser-first runtime where turn order, resource use, and trigger chains must remain readable under high event density.

CUI responsibilities:
- Present current phase/sub-state and legal actions.
- Present card hand, zones, resources, enemy intents, and passive effects.
- Present queue/event sequencing in a way players can explain after the fact.
- Provide deterministic explainability surfaces (“Why can’t I play this?”, “Why did this resolve first?”, “Where did this value come from?”).
- Enforce input gating during ResolveLock and any disallowed phase windows.

Non-goals (MVP):
- Animation-authoritative timing or ordering.
- Hidden UI-only state that can diverge from core combat state.
- Player-driven queue reordering after commit.
- Overly cinematic sequencing that obscures causal order.

## Player Fantasy

The player should feel like a precise tactician with complete information confidence:
- “I always know whose turn it is and what will happen next.”
- “I can inspect exactly why my card is legal/illegal right now.”
- “Enemy threats are readable and trustworthy.”
- “Even chain-heavy turns are understandable, not visual noise.”

Emotional outcome:
- Confidence from transparency.
- Mastery through sequence planning.
- Fairness through deterministic, inspectable outcomes.

## Detailed Design

### Core Rules

1) UI is read-only for game state
- CUI never mutates combat state directly.
- All gameplay actions route through TSRE input APIs (`submit_play_intent`, `submit_pass`).

2) Single authoritative event stream
- Queue panel, combat log, tooltips, and recap consume the same ordered event stream from TSRE/ERP/DLS/MRE/EES/RPM.
- No surface may synthesize contradictory ordering.

3) ResolveLock is hard UI-gated
- During TSRE `resolve_lock=true`, card play/end-turn input is disabled.
- Hover/inspection remains enabled.
- Disabled controls must show deterministic reason text key.

4) Intent telegraphing is binding-aware
- Enemy intent strip displays EES `certainty_class` (`exact`, `ranged`, `pattern_only`).
- Any intent mutation/fizzle must appear with explicit mutation badge and reason code.

5) Queue readability is order-key based
- Queue chips use TSRE comparator fields:
  - timing_window
  - speed_class
  - enqueue_sequence_id
  - source_instance_id (debug/advanced inspect)
- “Why First?” popover shows this comparator chain explicitly.

6) AP/mana readability follows MRE shared-budget model
- MVP shows AP-as-mana budget as one authoritative value (`current/max`) with optional advanced breakdown for overcharge/momentum.
- Card affordance and on-hover cost preview must match commit-time affordability semantics.

7) Hand/zone visibility follows DLS policy
- Hand is always fully visible.
- Draw pile order remains hidden unless explicitly revealed by mechanics.
- Draw/discard/exhaust counts always visible.
- Transition animations are cosmetic only; event log remains source of truth.

8) Explainability hooks are mandatory
- Every rejected input, no-op, fizzle, cap-drop, mutation, clamp, and retarget outcome must map to:
  - reason_code,
  - readable text key,
  - source system tag,
  - event/log reference.
- “Unknown reason” is disallowed in production mappings.

9) Browser-first performance policy
- CUI must remain legible under bursty resolve chains via deterministic batching/coalescing rules.
- Coalescing can reduce visual spam but cannot hide causality or ordering.

10) Accessibility by default
- All critical states use icon + text/shape, not color alone.
- Numeric values always visible for resources and key threat previews.
- Reduced-motion mode keeps event order markers intact.

11) Deterministic preview policy
- Preview/order panels use same scheduler and legality outputs as authoritative backend APIs.
- If mismatch detected in debug mode (preview vs first resolved item), raise determinism warning badge.

12) Progressive disclosure
- Base HUD shows essential tactical info only.
- Expanded panels provide deeper breakdowns (source IDs, comparator tie-breaks, ledger details) without blocking core play.

### Information Architecture (MVP)

Persistent combat HUD regions:
1. Top center: Phase banner + ResolveLock indicator + turn index.
2. Top right: Enemy Intent Strip (ordered by enemy slot/index).
3. Left rail: Queue/Resolve Stack panel (collapsed/expanded states).
4. Right rail: Combat Log (filtered + searchable in debug).
5. Bottom center: Hand + card interaction layer.
6. Bottom left: Resource HUD (mana/AP shared budget, overcharge, momentum).
7. Bottom right: Deck Zones (draw/discard/exhaust counts + inspect).
8. Upper-left or portrait-adjacent: Relic/Passive bar with trigger outcomes.
9. Contextual overlays: Targeting reticle, legality reasons, “Why?” popovers.

### States and Transitions

HUD macro states:
- CombatHUDInit
- AwaitAuthoritativeSnapshot
- PlayerInputReady
- TargetSelection
- IntentPreview
- IntentSubmitPending
- ResolvePlayback
- EnemyIntentReview
- TurnSettlementView
- CombatResultView

Primary transitions:
- CombatHUDInit -> AwaitAuthoritativeSnapshot
- AwaitAuthoritativeSnapshot -> PlayerInputReady (phase PlayerPhase.AwaitInput)
- PlayerInputReady -> TargetSelection (selected card requires target)
- PlayerInputReady -> IntentPreview (selected playable card)
- IntentPreview -> IntentSubmitPending (submit_play_intent)
- IntentSubmitPending -> ResolvePlayback (commit accepted)
- IntentSubmitPending -> PlayerInputReady (rejected)
- ResolvePlayback -> PlayerInputReady (queue drained and player actions remain)
- ResolvePlayback -> EnemyIntentReview (enemy phase gate)
- EnemyIntentReview -> ResolvePlayback (enemy actions resolving)
- ResolvePlayback -> TurnSettlementView (turn end)
- TurnSettlementView -> PlayerInputReady (next turn)
- Any active state -> CombatResultView (combat end)

Illegal transitions (must be blocked in UI state machine):
- ResolvePlayback -> TargetSelection via click input.
- CombatResultView -> IntentSubmitPending.
- AwaitAuthoritativeSnapshot -> IntentPreview (no authoritative state).

State guards:
- GuardPhaseAllowsInput (TSRE phase/sub-state).
- GuardNotResolveLocked.
- GuardCardInHandAndLegal (TSRE legal action list).
- GuardTargetingComplete for target-requiring plays.

### System Interaction Contracts

1) TSRE (hard upstream)
- Consumed:
  - `get_phase_state()`
  - `get_legal_actions(state)`
  - queue preview/projection output
  - `get_event_log_slice(from_index)`
- Produced:
  - `submit_play_intent(intent)`
  - `submit_pass(actor_id)`
- UI constraints:
  - No enqueue or ordering mutation outside TSRE API.
  - Respect TSRE reason codes verbatim for legality feedback.

2) DLS (hard upstream)
- Consumed:
  - zone counts and transition events
  - card instance metadata for retain/temp/generated tags
- UI constraints:
  - Draw order hidden by default.
  - Limbo visibility shown in debug and optional subtle player indicator.

3) MRE (hard upstream)
- Consumed:
  - `get_resource_snapshot(actor_id)`
  - affordability preview and payment plan breakdown
  - ledger events (spend/refund/conversion/cap)
- UI constraints:
  - Commit feedback must show paid source decomposition (example: `2 overcharge + 1 mana`).

4) EES (hard upstream)
- Consumed:
  - `get_revealed_intents_view()`
  - certainty class and mutation reasons
- UI constraints:
  - Telegraph mismatch must always display explicit mutation/fizzle indicator.

5) RPM (hard upstream)
- Consumed:
  - relic passive trigger attempt/outcome events
  - cooldown/suppression state
- UI constraints:
  - Every passive attempt appears in log with applied/blocked/fizzled/cap-dropped outcome.

6) ERP (hard upstream)
- Consumed:
  - resolve stage markers (S0-S7)
  - operation outcomes (applied/blocked/fizzled/partial), clamp reasons
- UI constraints:
  - Stage strip and outcome badges must match ERP event order.

7) Telemetry/Debug (soft MVP, hard VS)
- CUI emits interaction and readability telemetry:
  - hover inspect usage,
  - collapsed/expanded panel usage,
  - repeated rejection reason frequency,
  - “Why?” popover invocation count,
  - frame-time degradation mode activations.

### Explainability Model (Deterministic Hooks)

Required explainability surfaces:
1. Why illegal?
- Inputs: legal action rejection code + current resource/phase/target state.
- Output: deterministic text block with primary cause and supporting fields.

2. Why first?
- Inputs: two queue items or selected item + comparator chain.
- Output: ordered comparator explanation (`timing_window`, `speed_class`, `enqueue_sequence`, `source_id`).

3. Why this number?
- Inputs: ERP magnitude breakdown + MRE/DLS/RPM modifiers + clamps.
- Output: compact equation line + clamp/refund/cap notices.

4. Why target changed/fizzled?
- Inputs: invalid-target policy result + live target validity at apply.
- Output: retarget/fizzle explanation with policy label.

5. Why intent changed?
- Inputs: EES intent mutation event.
- Output: mutation reason + certainty class before/after.

Reason mapping contract:
- `reason_code -> ui_text_key -> localized string`
- Missing mapping fallback is not permitted in production; dev fallback shows `UNMAPPED_REASON(reason_code)` badge.

### Formulas

1) Visible queue window sizing

`queue_visible_count = clamp(Q_base + Q_scale * hud_zoom_factor, Q_min, Q_max)`

MVP defaults:
- `Q_base = 6`
- `Q_scale = 2`
- `Q_min = 4`
- `Q_max = 12`

Failure behavior:
- If panel space constrained, keep first `Q_min` entries and show deterministic overflow chip `+N pending`.

2) Event coalescing threshold (visual only)

`coalesce_enabled = (events_in_last_500ms >= E_coalesce_threshold)`

MVP defaults:
- `E_coalesce_threshold = 10`
- `coalesce_window_ms = 500`
- `coalesce_max_bucket = 8` events per reason/outcome bucket

Rules:
- Coalescing cannot combine different order indices.
- Coalesced entry must expose expand-to-raw list.

3) Resource urgency indicator

`mana_ratio = mana_current / max(1, mana_max)`

Urgency states:
- `healthy` if `mana_ratio > 0.5`
- `tight` if `0 < mana_ratio <= 0.5`
- `empty` if `mana_current = 0`

MVP uses this only for display emphasis; never for logic.

4) Threat preview aggregation (enemy strip)

`threat_total_exact = sum(exact_damage_i)`
`threat_total_low = sum(range_min_i)`
`threat_total_high = sum(range_max_i)`

Display policy:
- If all exact: show single exact total.
- If mixed certainty: show range band and certainty chip.

5) Hand layout fan spacing

`card_spacing_px = clamp((hand_region_width - card_width) / max(1, hand_count - 1), S_min, S_max)`

MVP defaults:
- `S_min = 28px`
- `S_max = 96px`

Failure behavior:
- If below `S_min`, switch to compressed overlap + hover raise mode.

6) Log retention budgets

`log_rows_kept_runtime = clamp(L_base + floor(turn_index * L_ramp), L_min, L_max)`

MVP defaults:
- `L_base = 300`
- `L_ramp = 10`
- `L_min = 200`
- `L_max = 1200`

Failure behavior:
- Oldest rows evicted from in-memory view only; authoritative event index remains continuous for backfill.

7) UI step budget (browser target)

`hud_update_ms_p95 <= HUD_P95_BUDGET_MS`
`input_to_feedback_ms_p95 <= INPUT_FEEDBACK_P95_MS`

MVP defaults:
- `HUD_P95_BUDGET_MS = 4.0`
- `INPUT_FEEDBACK_P95_MS = 80`

Failure behavior:
- Enter degraded mode: reduce non-critical animations, enable coalescing, shorten particle/audio fan-out.

8) Explainability completeness score (QA metric)

`explainability_coverage = mapped_reason_events / total_reason_events`

MVP threshold:
- `explainability_coverage >= 0.999` (target 1.0 in production)

Failure behavior:
- Build gate warning at < 1.0 in release candidate pipelines.

## Edge Cases

1) Preview says playable but commit rejects
- UI must show immediate commit-time recompute reason (state changed between hover and commit).

2) Enemy telegraph exact value changes before resolve
- Must show mutation badge + reason; no silent value swap.

3) Target dies during queue
- Pending item displays retarget/fizzle outcome according to policy.

4) Chain-heavy turn floods log
- Coalesce visually but preserve per-event inspect path and order index continuity.

5) Resource clamps/refunds occur in same resolve item
- Show ordered chips matching ledger event order, not merged net-only value.

6) Card moved out of hand before submit due to external event
- Intent submit rejected with zone legality reason; card interaction resets safely.

7) Simultaneous lethal outcomes
- Result screen references ordered event cause chain (no extra actor-priority narrative).

8) Draw pile hidden-information leak risk
- No accidental top-card reveal through animation timing, hover, or log text unless mechanic grants reveal entitlement.

9) ResolveLock click spam
- Inputs are ignored/idempotently rejected with one rate-limited UI hint, not repeated modal spam.

10) Determinism mismatch detected in debug replay
- Show non-player-facing debug badge with event index and hash fragment; gameplay flow remains controlled by TSRE release policy.

11) Mobile/narrow viewport overflow
- Panels collapse to prioritized stack (phase/resources/hand/enemy intents first) while preserving essential legality and telegraph info.

12) Unmapped reason code arrives (dev only)
- Display explicit unmapped token and log telemetry; never silent empty tooltip.

13) Action pending exceeds network soft-timeout
- If `pending_submit_age_ms >= 2500`, show non-blocking status near submit source: "Waiting for server...".
- Keep initiating control disabled until ack/reject or hard-timeout recovery.

14) Snapshot version drift while input is active
- If authoritative snapshot version differs for >250 ms, show sync warning banner and cancel target confirmation until versions align.

15) Checksum mismatch on authoritative replay tick
- Enter hard-resync path: clear local pending intents, fetch latest snapshot, rebind HUD to authoritative state.
- Never show phantom damage/heal numbers that cannot be traced to authoritative events.

16) Exploit attempt via macro/key-repeat submit spam
- Repeated submits of same logical action inside dedupe window are idempotently dropped.
- UI emits at most one rate-limited hint every 2s: "Action already pending."

17) Cross-input race (mouse click + hotkey same frame)
- Canonicalize by earliest timestamp; only one action_id generated.
- Losing input path is canceled silently; no double cost preview commit.

18) Reduced-motion toggled during active resolve chain
- New events must switch to reduced-motion presentation immediately.
- In-flight non-critical animations may snap/fade to completion within 100 ms without changing event order markers.

## Dependencies

Hard upstream dependencies:
- Turn State & Rules Engine (phase state, legal actions, queue ordering, event stream)
- Deck Lifecycle System (zones/transitions/instance metadata)
- Mana & Resource Economy (resource snapshot, affordability, ledger)
- Enemy Encounter System (revealed intents/mutations/certainty)
- Relics/Passive Modifiers (passive triggers/cooldowns/outcomes)
- Effect Resolution Pipeline (resolve stages, operation outcomes, clamps/fizzles)

Hard-adjacent dependencies:
- Card Data & Definitions (card cost/type/targeting/lifecycle UI fields)

Downstream dependents:
- Onboarding & Tooltips System
- Telemetry/Debug Hooks
- Accessibility QA guidelines and localization pipelines

MVP integration contract summary:
- CUI reads only authoritative snapshots/events.
- CUI writes only `submit_play_intent` and `submit_pass`.
- CUI keeps local ephemeral state for selection/hover/scroll; this state must be discardable and reconstructible from authoritative stream.

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `Q_base` | int | 6 | 4-8 | Queue context too short | UI clutter |
| `Q_max` | int | 12 | 8-16 | Hidden pending complexity | Overload on small screens |
| `E_coalesce_threshold` | int | 10 | 6-20 | Event spam/noise | Important detail appears too collapsed |
| `coalesce_window_ms` | int | 500 | 250-1000 | Limited benefit | Delayed readability |
| `L_base` | int | 300 | 200-500 | Short forensic history | Memory/render overhead |
| `L_max` | int | 1200 | 600-2000 | Hard to diagnose long turns | Browser memory spikes |
| `HUD_P95_BUDGET_MS` | float | 4.0 | 2.5-6.0 | Over-aggressive degradation | Frame hitch risk |
| `INPUT_FEEDBACK_P95_MS` | int | 80 | 50-120 | Tough on low-end systems | Sluggish perceived responsiveness |
| `S_min` | int px | 28 | 20-40 | Hand unreadable overlap | Wasted horizontal space |
| `intent_strip_rows_max` | int | 2 | 1-3 | Hidden enemy info | Vertical clutter |
| `show_advanced_debug_fields` | bool | false | true/false | Less debugging context | Player-facing noise if accidentally enabled |
| `reduced_motion_default` | bool | false | true/false | Less spectacle | Motion discomfort for some users |

Governance:
- Knob changes are data-configurable and versioned.
- Out-of-range values require readability playtest signoff plus perf smoke pass.

## Visual/Audio Requirements

Visual requirements:
- Deterministic order chips for queue/intents (`pre/main/post`, `fast/normal/slow`, sequence).
- Strong phase banner with ResolveLock state.
- Resource HUD with numeric `current/max` and separate overcharge/momentum markers.
- Enemy intents with certainty badge and mutation flash state.
- Hand card states: playable, unaffordable, illegal-target, retained, temp/generated tags.
- Zone transition indicators: draw/discard/exhaust/limbo, with limbo visible in debug mode.
- Passive trigger pulses with outcome icon set (applied/blocked/fizzled/cap-dropped).
- Outcome badges on affected units: Applied/Blocked/Fizzled/Partial.

Audio requirements:
- Distinct SFX groups: commit, reject, resolve impact, fizzle, cap-hit warning, intent reveal/mutation, passive trigger.
- Batched chain sounds for high event density.
- Non-modal warning cues for guardrails/rejections.
- Reduced-motion/degraded mode also reduces non-critical audio chatter.
- Confirm cue onset <= 75 ms from input-to-feedback event.
- Reject/desync cues must be perceptibly distinct from confirm cues and rate-limited to <= 1 cue per 2 seconds when persistent.

Desync and error messaging visual standards:
- Sync warning banner text: "Syncing combat state..." with icon + text (not color-only).
- Hard resync banner text: "Connection hiccup. Resyncing combat state...".
- Reject toasts must include plain-language outcome and next action, optional code token.
- Messaging surfaces must never block core HUD unless mismatch is unrecoverable.

Reduced-motion standards:
- Camera shake amplitude forced to 0 in Reduced Motion mode.
- Full-screen flash effects disabled in Reduced Motion mode.
- Motion-heavy travel replaced by fade/pop transitions <= 120 ms.
- Critical outcomes remain identifiable using text/icon/audio without motion.

Presentation event minimum contract:
- `presentation_event_id`
- `order_index_ref`
- `source_system` (TSRE/ERP/DLS/MRE/EES/RPM)
- `reason_code`
- `outcome_flag`
- `vfx_event_id?`
- `sfx_event_id?`

## UI Requirements

1) Phase/Turn Header
- Show phase, sub-state, turn index, active actor, ResolveLock.
- Tooltip explains phase transitions and why input may be disabled.

2) Resource HUD
- Show shared AP/mana budget (`current/max`) plus overcharge and momentum.
- Hover on card shows effective cost and payment plan preview.
- Rejections include deterministic reason details.

3) Hand Interaction Layer
- Card hover: rules text, cost, legality, expected target requirements.
- Card select: targeting overlay if required.
- Illegal play reason appears inline and in log.

4) Zone Panel
- Always-visible counts for draw/hand/discard/exhaust.
- Inspect list for discard/exhaust; draw list hidden unless reveal entitlement active.

5) Enemy Intent Strip
- Ordered enemy intents with certainty and threat preview.
- Multi-turn telegraph (if present) shown ghosted/provisional per EES rules.

6) Queue/Resolve Stack Panel
- Show pending and active resolve items.
- Expand active item into ERP stage progression (S0-S7).
- “Why First?” popover available per item.

7) Combat Log
- Append-only ordered rows with reason text.
- Filters: outcomes, source system, actor, turn.
- Expand row for debug details (IDs, comparator keys, deltas).

8) Relic/Passive Bar
- Show relic states, cooldown, suppression, and last trigger outcome.
- Click/hover explains trigger condition and most recent reason.

9) End Turn and Pass Controls
- Clearly enabled/disabled states with reasons.
- Confirm optional in settings; no ambiguous pass when legal actions still exist.

10) Explainability Overlays
- Why illegal?
- Why first?
- Why this number?
- Why changed/fizzled?

11) Accessibility
- Colorblind-safe iconography and text labels.
- Keyboard focus traversal for hand, intents, queue, and logs.
- Screen-reader compatible concise reason strings for key events.
- Reduced-motion toggle available in-combat settings and applied without combat restart.

12) Desync and error messaging surfaces
- Recoverable rejects render as toast near action region and mirrored in combat log.
- Sync drift renders as top-center warning banner; hard-resync renders elevated banner state.
- Blocking modal reserved only for unrecoverable mismatch or reconnect failure >10s.
- Message copy standard: [what happened] + [what player can do now] + optional `(CODE)`.

13) Exploit-resistant interaction gating
- Every submit carries `action_id` + authoritative `snapshot_version`.
- Controls in `IntentSubmitPending` block all equivalent submits across mouse/touch/keyboard/gamepad.
- Logical-action dedupe window default 180 ms (safe range 120-300 ms).
- Cross-input same-frame collisions resolve to one canonical submit by timestamp.

14) Debug Overlay (dev/QA)
- State hash fragment and event index.
- Preview-vs-resolve mismatch indicators.
- Queue size, coalescing status, degraded mode status.
- Pending-age, version-drift, and dedupe-drop counters visible for QA scripts.

## Acceptance Criteria

1) Authoritative state compliance
- No direct UI state mutation path changes gameplay state.
- All gameplay actions route through TSRE APIs only.

2) Queue/order explainability
- 100% of resolved items expose comparator-based “Why First?” explanation.
- No queue item displayed without order chips in debug builds.

3) Rejection clarity
- 100% of rejected play/pass actions present mapped reason text.
- Zero `unknown reason` strings in production fixtures.

4) Telegraph integrity
- Enemy telegraph mutation/fizzle fixtures always show explicit UI indication and matching log event.

5) Resource accuracy
- Hover cost preview equals commit charge unless state changed in-between; mismatch path must show recompute explanation.

6) Zone clarity
- Draw/discard/exhaust counts remain accurate under all DLS transition fixtures.
- Hidden draw order is never leaked without reveal entitlement.

7) Passive visibility
- All RPM trigger attempts appear with one deterministic outcome label.

8) Performance envelope
- On target browsers (Chrome Stable, Firefox Stable), HUD update P95 <= 4 ms and input feedback P95 <= 80 ms during 95th percentile combat chains.

9) Determinism aid
- Debug replay mode surfaces mismatch markers with event reference when backend flags mismatch.

10) Accessibility baseline
- Critical tactical states are distinguishable without color-only cues.

11) Browser resilience
- Tab throttling/frame drops do not reorder or drop authoritative event rows; UI catches up without causality inversion.

12) Desync warning SLA
- If snapshot drift persists >250 ms, sync warning banner appears within 100 ms of threshold crossing.

13) Hard-resync recovery SLA
- On checksum mismatch or unresolved drift >1500 ms, HUD enters hard-resync and restores interactable authoritative state within 1.0 s after snapshot receipt.

14) Pending submit messaging
- If submit remains pending >=2500 ms, UI displays "Waiting for server..." status and keeps source action disabled until resolution.

15) Duplicate-submit resistance
- Under scripted double-click/macro tests (>=20 submits/sec), exactly one authoritative commit occurs per legal action window.

16) Cross-input race safety
- Simultaneous mouse+hotkey submits for same action generate exactly one action_id and one resource spend event.

17) Reduced-motion compliance
- With Reduced Motion enabled: camera shake amplitude is 0, full-screen flashes absent, and critical outcomes still identifiable via non-motion channel.

18) Messaging quality standard
- 100% reject/desync messages follow copy format with clear next-step guidance; zero blame-language strings in localization fixtures.

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should MVP show one unified resource bar (AP-as-mana only) or dual-labeled AP/mana terminology for onboarding clarity? | UX + Systems | Sprint 2 | Open |
| How much of queue internals (`source_instance_id`, hash refs) should be available outside debug mode? | Design Director | Sprint 2 | Open |
| Should “Why this number?” be always-inline on hover or opt-in via advanced tooltip to reduce clutter? | UX | Sprint 2 | Open |
| Default panel layout for narrow screens: fixed priority stack vs user-customizable docking? | UI Engineering | Sprint 3 | Open |
| Should passive trigger spam collapse more aggressively in casual mode while preserving full detail in ranked/challenge? | Systems + UX | Pre-alpha | Open |
