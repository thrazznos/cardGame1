# Audio Feedback System

> Status: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-05
> Implements Pillar: Readable Tactical Clarity; High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats
> Upstream References: docs/architecture/ADR-0001-runtime-determinism-and-ui-boundary.md, design/gdd/systems/combat-ui-hud.md, design/gdd/systems/map-node-ui.md, design/gdd/systems/reward-draft.md, design/gdd/systems/hub-ui.md, design/gdd/systems/map-pathing.md, design/gdd/systems/meta-hub-investment.md

## Overview

Audio Feedback System (AFS) is the browser-first, event-driven audio presentation layer for player-facing feedback.

AFS does not own gameplay logic, legality, timing windows, RNG, or progression state. It consumes authoritative ordered events from gameplay systems and emits deterministic audio cues (SFX/UI stingers/ambience transitions) that improve readability, pace, and confidence.

MVP/Vertical Slice scope:
- Combat feedback cues aligned to TSRE/ERP/MRE/EES/RPM event outcomes.
- Map traversal and node checkpoint cues aligned to MPS/MNUI events.
- Reward panel and reward selection cues aligned to RDS events.
- Hub purchase/lock/reconcile cues aligned to MHIS/HUI events.
- Browser-safe performance and accessibility defaults with deterministic suppression/coalescing.

Non-goals (MVP):
- Rhythm gameplay or timing-accuracy mechanics.
- Audio-authoritative sequencing.
- Procedural music systems that affect gameplay.
- Spatialized 3D audio complexity beyond lightweight stereo pan for polish.

## Player Fantasy

The player should feel informed and in control:
- “I hear instantly whether an action was accepted, rejected, or altered.”
- “Busy turns still sound readable, not chaotic.”
- “Map, reward, and hub interactions have clear state changes and consequences.”
- “Even with reduced motion, I still understand what just happened.”

Emotional outcome:
- Trust through consistent sonic semantics.
- Momentum from fast confirmation and clear transitions.
- Reduced cognitive load in chain-heavy combat and menu-heavy progression flows.

## Detailed Design

### Core Rules

1) Authoritative event boundary
- AFS triggers only from authoritative event stream/snapshots.
- AFS never mutates gameplay state.
- Missing or delayed audio must never block gameplay progression.

2) Deterministic mapping contract
- Every triggerable gameplay event class maps to exactly one `audio_cue_key` policy group.
- Mapping uses stable metadata: `source_system`, `event_type`, `outcome_flag`, `reason_code`, and context tags.
- Mapping priority and fallback behavior are data-authored and versioned.

3) Ordered playback policy
- AFS preserves event order semantics using the same ordering metadata consumed by UI (`order_index` or checkpoint sequence equivalents).
- Audio may coalesce burst events but cannot invert perceived causality (for example, reject sound after commit success for same action).

4) Domain context channels
- Separate cue buses: `combat`, `map`, `reward`, `hub`, `global_ui`, `error_sync`.
- Domain-local priorities resolve first; global bus ducking applies second.

5) Critical cue guarantee
- Critical cues (illegal action, desync/reconnect, lethal resolution, purchase accepted/rejected) bypass non-critical suppression windows unless hard-muted by user settings.
- Critical cues always require visual equivalent for accessibility.

6) Browser-first latency targets
- Input-to-confirm/reject cue onset target <= 75 ms p95 on supported desktop browsers.
- Authoritative event-to-cue onset target <= 100 ms p95 for non-input events.

7) Performance degradation policy
- If audio update budget is exceeded, AFS degrades deterministically:
  1. reduce non-critical one-shots,
  2. increase coalescing window,
  3. disable decorative layers,
  4. preserve only critical + high-priority informational cues.

8) Accessibility baseline
- No gameplay-critical information may exist in audio only.
- Provide separate volume controls (Master/Music/SFX/UI).
- Reduced Motion mode automatically enables Reduced Audio Chatter profile (lower repetition and shorter tails for non-critical cues).
- Hearing comfort cap and dynamic range compression toggle available.

9) Idempotency and dedupe
- Duplicate authoritative events with same `(source_system, domain_event_id, outcome_flag)` produce at most one cue in dedupe window.
- Replayed network acknowledgments must not double-fire success stingers.

10) Explainability linkage
- Each emitted cue stores `audio_emit_trace` linking to source event IDs for QA replay and mismatch audits.

### Event Binding Matrix (Vertical Slice Contract)

AFS consumes these event families and emits cue groups:

1) Combat events (TSRE/ERP/MRE/EES/RPM via CUI)
- `combat.intent.commit.accepted` -> `sfx.combat.commit_ok`
- `combat.intent.commit.rejected` -> `sfx.combat.commit_reject` (reason-coded variants)
- `combat.resolve.item_applied` -> `sfx.combat.resolve_hit` or `resolve_buff`
- `combat.resolve.item_fizzled` -> `sfx.combat.resolve_fizzle`
- `combat.resolve.cap_clamp` -> `sfx.combat.cap_warning`
- `combat.enemy_intent.revealed` -> `sfx.combat.intent_reveal`
- `combat.enemy_intent.mutated` -> `sfx.combat.intent_mutate`
- `combat.passive.trigger.applied` -> `sfx.combat.passive_proc`
- `combat.passive.trigger.blocked` -> `sfx.combat.passive_blocked`
- `combat.turn.start`/`combat.turn.end` -> `sfx.combat.turn_start`/`turn_end`
- `combat.result.victory`/`defeat` -> `stinger.combat.victory`/`defeat`

2) Map events (MPS/MNUI)
- `map.node.inspect` -> `sfx.map.inspect_soft`
- `map.path.select.legal` -> `sfx.map.select_legal`
- `map.path.commit.accepted` -> `sfx.map.commit_ok`
- `map.path.commit.rejected` -> `sfx.map.commit_reject`
- `checkpoint.node_enter` -> `sfx.map.node_enter`
- `checkpoint.node_resolve` -> `sfx.map.node_resolve`
- `checkpoint.reward_request` -> `stinger.map.to_reward`
- `map.act.complete` -> `stinger.map.act_complete`

3) Reward events (RDS/reward UI)
- `reward.draft.presented` -> `stinger.reward.panel_open`
- `reward.entry.hover` -> `sfx.reward.inspect_soft`
- `reward.selection.committed` -> `sfx.reward.pick_confirm`
- `reward.selection.rejected` -> `sfx.reward.pick_reject`
- `reward.panel.closed` -> `sfx.reward.panel_close`
- `reward.fallback_pool.used` (debug/telemetry audible off by default) -> `sfx.reward.debug_notice` (dev only)

4) Hub events (MHIS/HUI)
- `hub.investment.inspect` -> `sfx.hub.inspect_soft`
- `hub.purchase.submit` -> `sfx.hub.submit`
- `hub.purchase.accepted` -> `stinger.hub.purchase_success`
- `hub.purchase.rejected` -> `sfx.hub.purchase_reject`
- `hub.offline.readonly_enter` -> `sfx.hub.offline_enter`
- `hub.reconcile.resolved` -> `sfx.hub.reconcile_ok`
- `hub.reconcile.conflict` -> `sfx.hub.reconcile_conflict`

5) Global reliability events
- `sync.warning` -> `sfx.global.sync_warning`
- `sync.resync.start` -> `sfx.global.resync_start`
- `sync.resync.complete` -> `sfx.global.resync_ok`
- `ui.error.unmapped_reason` (dev only) -> `sfx.global.debug_unmapped`

### Data Model and Runtime Contracts

Audio trigger input contract (`AudioTriggerEvent`):
- `audio_trigger_id` (unique within session)
- `source_system` (`TSRE`,`ERP`,`MRE`,`EES`,`RPM`,`MPS`,`RDS`,`MHIS`,`UI`)
- `domain` (`combat`,`map`,`reward`,`hub`,`global`)
- `domain_event_id` (authoritative event identifier)
- `event_type`
- `outcome_flag` (`applied`,`blocked`,`fizzled`,`accepted`,`rejected`,`info`)
- `reason_code?`
- `order_index?` (combat ordered streams)
- `checkpoint_seq?` (map/reward/hub progression checkpoints)
- `intensity_scalar` [0,1]
- `timestamp_ms`

Audio emit output contract (`AudioEmitRecord`):
- `emit_id`
- `audio_cue_key`
- `bus`
- `priority_tier` (`critical`,`high`,`normal`,`low`)
- `gain_db_applied`
- `pitch_cents_applied`
- `dedupe_applied` bool
- `coalesced_count`
- `source_ref` (`domain_event_id`, `order_index/checkpoint_seq`)

Hard contract rules:
- If `domain_event_id` repeats inside dedupe horizon with same `audio_cue_key`, suppress duplicate.
- If ordering metadata missing, cue plays with `normal` priority and logs `WARN_AUDIO_NO_ORDER_REF` (dev telemetry).
- AFS failure must never propagate exception to gameplay loop.

### States and Transitions

AFS runtime states:
- AudioInit
- BankPreload
- Ready
- ActiveDomainCombat
- ActiveDomainMap
- ActiveDomainReward
- ActiveDomainHub
- Degraded
- MutedBySettings
- AudioRecover

Primary transitions:
- AudioInit -> BankPreload
- BankPreload -> Ready (minimum critical bank loaded)
- Ready -> ActiveDomainCombat / Map / Reward / Hub (context focus event)
- Any ActiveDomain* -> Degraded (budget breach or browser suspend pressure)
- Degraded -> ActiveDomain* (budget recovered for grace interval)
- Any state -> MutedBySettings (master mute)
- MutedBySettings -> prior domain state (unmute)
- Any state -> AudioRecover (device/context loss)
- AudioRecover -> Ready (context restored)

Invalid transitions:
- AudioInit -> ActiveDomain* (without critical bank load)
- MutedBySettings -> cue playback (except silent telemetry)

State guards:
- GuardAudioContextReady
- GuardCriticalBankAvailable
- GuardUserConsentAndSettingsValid
- GuardSourceEventMonotonicWhenRequired

### Interactions with Other Systems

1) Combat UI/HUD + TSRE/ERP/MRE/EES/RPM (hard upstream)
- Supplies ordered combat event stream and reason/outcome taxonomy.
- AFS maps cue families by event type/outcome and preserves order semantics.

2) Map/Pathing + Map Node UI (hard upstream)
- Supplies traversal commit outcomes and checkpoints (`checkpoint.node_enter`, `checkpoint.node_resolve`, `checkpoint.reward_request`).
- AFS emits transition cues only on authoritative acceptance/checkpoint arrival.

3) Reward Draft + Reward UI (hard upstream)
- Supplies draft presentation, selection commit, and close events.
- AFS does not infer reward outcomes from hover-only state.

4) Meta-Hub Investment + Hub UI (hard upstream)
- Supplies purchase accepted/rejected/offline/reconcile events with idempotent IDs.
- AFS dedupes duplicate acks for same purchase event.

5) Settings/UI Accessibility (hard upstream/downstream)
- Supplies user audio preferences, reduced-motion/reduced-chatter toggles.
- AFS exposes current output mode for UI status display.

6) Telemetry/Debug (soft MVP, hard VS validation)
- Consumes `AudioEmitRecord` stream and budget/skip counters.
- Supports replay verification that identical source event traces produce identical cue-key sequences.

## Formulas

Notation:
- `clamp(x,a,b)=min(max(x,a),b)`
- dB operations use linear mix internally, displayed as dB.

1) Effective cue gain

`gain_db = clamp(base_gain_db(cue) + bus_gain_db(bus) + user_sfx_gain_db + context_gain_db(domain) + intensity_gain_db(intensity_scalar) - ducking_db, G_min, G_max)`

MVP defaults:
- `G_min = -36 dB`
- `G_max = +3 dB`
- `ducking_db` range `0..9 dB`

2) Deterministic pitch variance

`pitch_cents = clamp(pitch_base_cents(cue) + hash16(domain_event_id) mod (2*P_span+1) - P_span, -P_cap, P_cap)`

MVP defaults:
- `P_span = 8`
- `P_cap = 12`

Policy:
- Critical cues set `P_span=0` (no variance).

3) Dedupe horizon

`dedupe_hit = I(now_ms - last_emit_ms(cue_key, domain_event_id) <= dedupe_window_ms(priority_tier))`

MVP defaults:
- critical: `50 ms`
- high: `120 ms`
- normal: `200 ms`
- low: `350 ms`

4) Burst coalescing

`coalesce_enabled = (events_same_family_in_window >= C_threshold)`
`coalesced_count = min(events_same_family_in_window, C_max_bucket)`

MVP defaults:
- `coalesce_window_ms = 300`
- `C_threshold = 4`
- `C_max_bucket = 10`

Rule:
- Never coalesce across different `outcome_flag` for same family when one is reject/error.

5) Voice budget allocator

`voices_allocated(bus) = clamp(round(V_total * weight_bus(bus)), V_bus_min, V_bus_max)`

MVP defaults:
- `V_total = 24`
- weights: combat 0.45, map 0.15, reward 0.15, hub 0.10, global_ui 0.10, error_sync 0.05
- `V_bus_min = 1`, `V_bus_max = 14`

6) Degraded mode trigger

`degraded = I(audio_update_ms_p95 > AUDIO_P95_BUDGET_MS OR dropped_voice_rate_10s > DROP_RATE_THRESHOLD)`

MVP defaults:
- `AUDIO_P95_BUDGET_MS = 1.2`
- `DROP_RATE_THRESHOLD = 0.08`

7) Input feedback SLA

`input_audio_latency_ms = cue_onset_ms - input_commit_or_reject_event_ms`

Acceptance target:
- `p95(input_audio_latency_ms) <= 75`

## Edge Cases

1) Commit accepted then immediate reject from stale duplicate
- Play accepted cue once, suppress stale reject if same action id classified duplicate.

2) Combat burst flood (multi-trigger chain)
- Coalesce non-critical hits, keep distinct reject/fizzle/cap-warning cues.

3) Late/out-of-order network ack in hub
- Use commit sequence and event ID to classify stale events; no retroactive success stinger.

4) Map transition skipped due to resume checkpoint
- On resume, play neutral re-entry cue only; do not replay historical traversal cues.

5) Reward panel restored from save
- Do not replay panel-open stinger if panel was already open pre-save; only play on first presentation event.

6) Audio context suspended by browser/tab background
- Queue no backlog replay spam on restore; emit single `resync_ok` cue if state changed materially.

7) User sets SFX to 0 while critical errors occur
- Respect mute; ensure visual equivalents remain present.

8) Missing cue asset key in release
- Fallback to safe generic cue in same family and emit telemetry `ERR_AUDIO_CUE_MISSING`.

9) Repeated illegal input spam
- Reject cue rate-limited by priority dedupe windows and UI cooldown policies.

10) Device sample-rate mismatch
- Resample via WebAudio pipeline; keep pitch/gain calculations stable and bounded.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Combat UI/HUD + TSRE/ERP/MRE/EES/RPM | Upstream authority | Hard | Supplies ordered combat event stream and reason/outcome metadata used for cue mapping. |
| Map/Pathing + Map Node UI | Upstream authority | Hard | Supplies traversal selection results and checkpoints for map/handoff cues. |
| Reward Draft + Reward UI | Upstream authority | Hard | Supplies reward panel lifecycle and commit outcomes. |
| Meta-Hub Investment + Hub UI | Upstream authority | Hard | Supplies purchase/reconcile/offline outcomes with idempotent event identity. |
| Settings/Accessibility UI | Upstream controls | Hard | Supplies user mix settings, mute, reduced-motion/reduced-chatter toggles. |
| Browser Audio Runtime (WebAudio) | Platform runtime | Hard | Provides audio context, decode/playback, suspend/resume behavior. |
| Telemetry/Debug | Adjacent | Soft MVP / Hard VS validation | Receives emit traces, dedupe/coalesce stats, and budget health metrics. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `AUDIO_P95_BUDGET_MS` | float | 1.2 | 0.8-2.0 | Aggressive degradation | CPU spikes, crackle/dropouts |
| `V_total` | int | 24 | 12-40 | Cues get stolen | Browser CPU/memory pressure |
| `coalesce_window_ms` | int | 300 | 150-600 | Noise during bursts | Over-flattened feedback |
| `C_threshold` | int | 4 | 3-8 | Too chatty | Loss of detail |
| `ducking_db_max` | float | 9 | 4-12 | Muddy layering | Over-pumping audibly |
| `critical_gain_bias_db` | float | +2 | 0-4 | Critical cues missed | Harsh mix imbalance |
| `dedupe_window_normal_ms` | int | 200 | 100-400 | Spam repeats | Legit repeats suppressed |
| `reject_rate_limit_ms` | int | 600 | 300-1200 | Annoying reject spam | Weak failure feedback |
| `reduced_chatter_scalar` | float | 0.7 | 0.4-1.0 | Feedback too sparse | Reduced mode not helpful |
| `stream_preload_kb` | int | 1024 | 512-4096 | Decode hitches | High memory use |
| `max_simultaneous_stingers` | int | 1 | 1-2 | Missed transitions | Stinger pileup |

Governance:
- Knob changes are data-driven, versioned, and replay-audited against deterministic cue-key sequence tests.
- Any mix/perf change requires browser smoke pass and accessibility regression checks.

## Visual/Audio Requirements

Audio content requirements:
- Distinct sonic identities for: confirm, reject, fizzle, mutation, checkpoint, reward open/pick, hub purchase success/reject, sync warning/resync.
- Cue duration targets:
  - critical UI cues: 80-250 ms
  - transition stingers: 400-1400 ms
- Peak safety target: default mix not exceeding -1 dBTP on master bus.
- Loudness consistency target (SFX bus integrated): -20 to -14 LUFS short-term equivalent guidance.

Browser/runtime requirements:
- Decode strategy: preload critical short cues, stream/lazy-load non-critical tails.
- Supported output: stereo first; mono fold-down safe.
- Resume policy after autoplay/user-gesture constraints: fail gracefully with visible “audio disabled” state.

Visual parity requirements:
- Every critical cue has matching visual badge/banner/icon state.
- Audio-only warnings are prohibited for legality, desync, or purchase outcomes.

Reduced motion/chatter requirements:
- Enabling Reduced Motion implies Reduced Audio Chatter preset by default (user can override).
- Repeated ambient UI ticks should be suppressed in reduced mode.

## UI Requirements

1) Settings surface
- Controls: Master, Music, SFX, UI sliders; mute toggle; reduced chatter toggle; dynamic range compression toggle.
- Per-control changes reflected within one interaction frame and persisted per profile.

2) Status and diagnostics
- If audio context unavailable/suspended, show non-blocking status indicator.
- In debug mode, expose current cue key, bus, and source event reference.

3) Domain-aware mixing
- Combat domain prioritizes informational combat cues.
- Map/Reward/Hub domains emphasize transition and confirmation cues, with combat bus attenuated when inactive.

4) Accessibility controls
- Provide “critical cues boost” toggle (+dB bias for critical tier).
- Provide “repetitive cue reduction” toggle for sensory comfort.

5) Input feedback fidelity
- Confirm/reject cues tied to authoritative action outcome events, not raw click alone.

## Acceptance Criteria

1) Deterministic mapping coverage
- 100% of vertical-slice event classes for combat/map/reward/hub have mapped `audio_cue_key` or explicit `silent_by_policy` entries.

2) Event-order fidelity
- Replay of identical authoritative event traces yields identical emitted cue-key sequence and dedupe/coalesce decisions.

3) Performance budgets
- `audio_update_ms_p95 <= 1.2 ms` and no sustained dropped-voice rate above 8% on target desktop browser spec.

4) Latency
- `p95(input_audio_latency_ms) <= 75` for commit/reject cues in combat, map commit, reward pick, and hub purchase flows.

5) Accessibility parity
- All critical outcomes represented visually and audibly (unless user mutes); no color-only or audio-only critical communication.

6) Save/resume integrity
- Resume during combat/map/reward/hub does not replay historical one-shot cues incorrectly; only current-state re-entry cues may play.

7) Idempotent safety
- Duplicate acks/retries in hub and map flows do not produce duplicate success stingers.

8) Degraded mode behavior
- Under forced perf stress, critical cues remain intact while non-critical chatter reduces deterministically.

## Open Questions

1) Should vertical slice include optional lightweight adaptive music transitions between combat/map/hub, or defer to post-VS?
2) Do we want per-reason-code reject cue variants in MVP, or one shared reject cue with UI text doing most differentiation?
3) Should reward fallback/debug cues remain entirely silent in release builds or be surfaced behind an accessibility/debug toggle?
4) Is haptic mirroring for critical cues required in VS browser scope (gamepad vibration where available), or deferred?
5) Should `AudioTriggerEvent` include explicit `snapshot_version_token` for stronger replay diagnostics, or rely on `domain_event_id` + order metadata?