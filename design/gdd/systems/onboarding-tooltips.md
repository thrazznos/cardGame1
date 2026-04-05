# Onboarding & Tooltips System

> Status: Approved
> Author: Nathan + Hermes agents
> Last Updated: 2026-04-05
> Implements Pillars: Readable Tactical Clarity; Sequencing Mastery Over Raw Stats; High Run Variety, Low Grind
> Upstream References: design/gdd/systems/combat-ui-hud.md, design/gdd/systems/map-node-ui.md, design/gdd/systems/hub-ui.md, design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems-index.md

## Overview

Onboarding & Tooltips System (OTS) is the guided-learning and contextual explanation layer for first playable onboarding across hub, map, and combat.

OTS does not author gameplay rules or progression legality. It listens to authoritative state/events from TSRE, Combat UI/HUD (CUI), Map & Node UI (MNUI), and Hub UI (HUI), then selects deterministic instructional prompts, callouts, and tooltip content.

Primary objective:
- Teach first-run players enough to complete one full loop (hub -> map -> first combat -> reward/map return) without confusion, while avoiding interruption fatigue.

MVP/Vertical-slice responsibilities:
- Deliver deterministic step-by-step onboarding beats for first playable.
- Provide contextual tooltips tied to legal actions and rejection reasons.
- Enforce anti-spam behavior (cooldowns, dedupe, suppression, frequency caps).
- Provide accessibility-complete guidance surfaces (keyboard/controller/touch + screen-reader-compatible text contracts).
- Emit measurable telemetry to prove comprehension and friction reduction.

Non-goals (vertical slice):
- Full adaptive tutoring/ML personalization.
- Narrative-heavy tutorial scripting engine.
- Mid-combat branching dialogs.
- Explaining every advanced edge-case in first session.

## Player Fantasy

The player should feel supported, not lectured:
- “I always know what to do next.”
- “If something is blocked, I understand why.”
- “Tips appear when needed and get out of the way quickly.”
- “By the end of first combat, I understand turn flow, resources, and basic path choice.”

Emotional outcome:
- Confidence through timely guidance.
- Trust through deterministic, consistent explanations.
- Agency through skippable, non-intrusive onboarding.

## Detailed Design

### Vertical Slice Scope

First playable OTS covers these critical beats only:
1) Hub Entry
- Identify currency strip, one inspectable investment tile, and “start run” CTA.

2) Map Entry
- Identify current node, legal next nodes, and branch selection/commit behavior.

3) Combat Entry
- Identify phase/turn banner, hand, resource HUD, enemy intent strip, and end turn/pass action.

4) First card play
- Teach card select -> target (if needed) -> commit -> resolve lock explanation.

5) Illegal action explanation
- Demonstrate deterministic “why blocked” tooltip at least once (insufficient resource, wrong phase, invalid target, or resolve lock).

6) Post-combat transition
- Explain reward/map return handoff and next-step objective.

Anything outside these beats is deferred to contextual tooltips (not scripted tutorial gating).

### Core Rules

1) Authority boundary rule
- OTS is read-only with respect to gameplay.
- OTS may highlight UI controls and request focus, but cannot mutate TSRE/MNUI/HUI state.

2) Deterministic trigger rule
- Tutorial prompts are event-driven from authoritative state transitions, never animation timing.
- Given same snapshot/event stream and same player input sequence, OTS prompt order must be identical.

3) Single active blocking tutorial rule
- At most one blocking tutorial modal/callout can be active at a time.
- Non-blocking tooltips may coexist but must respect anti-spam caps.

4) Explainability parity rule
- Any OTS “why?” explanation must reuse upstream reason_code mappings from TSRE/CUI/MNUI/HUI.
- OTS cannot invent conflicting explanation text.

5) Progressive disclosure rule
- First-play onboarding uses short imperative prompts.
- Advanced detail is optional via “More info” or inspect action.

6) Player control rule
- Every onboarding step supports: continue, dismiss/close, and global “reduce tips” mode.
- Full skip onboarding is allowed from pause/options and persists in profile.

7) Resume safety rule
- Save/load or refresh restores tutorial progress deterministically without replaying completed required steps.

8) Accessibility parity rule
- Every onboarding instruction must be available in text, focusable via keyboard/controller, and screen-reader readable.

9) Performance rule
- OTS rendering and decision evaluation must stay within browser UI budgets and never delay authoritative input handling.

10) Non-spoiler rule
- OTS cannot reveal hidden map/reward/combat info beyond current reveal policy.

### Deterministic Trigger Policy (Canonical)

Trigger key:
- `trigger_key = (run_id, profile_id, onboarding_track_id, step_id, trigger_version)`

Event cursor:
- OTS consumes ordered authoritative events with monotonic index:
- `event_cursor_index`

Step eligibility:
- `eligible(step) = prereqs_complete(step) && context_guard(step) && !completed(step) && !suppressed(step)`

Step selection order:
- Deterministic ascending tuple:
  1. `track_priority`
  2. `step_priority`
  3. `first_eligible_event_index`
  4. `step_id` lexical tie-break

Trigger fire condition:
- A step can fire only when all are true:
  - `eligible(step)=true`
  - `current_state_version >= step.min_state_version`
  - `cooldown_elapsed(step)=true`
  - `active_blocking_step == null` (for blocking type)

Completion semantics:
- `completed(step)=true` on explicit completion event (example: card committed, node committed, panel opened) or explicit skip.
- Completion is persisted with `completion_event_id` and timestamp.

Idempotency:
- Each fire attempt carries `onboarding_event_id`.
- Duplicate fire attempts with same key are ignored.

No wall-clock dependency:
- OTS logic cannot rely on frame count, animation completion, or non-authoritative timers for ordering.
- Optional display delays are cosmetic only and cannot reorder logical step progression.

### Anti-Spam and Fatigue Control

Global caps:
- `max_blocking_prompts_per_min = 3`
- `max_nonblocking_prompts_per_min = 8`
- `max_repeated_reason_tooltip_per_reason_per_min = 2`

Cooldowns:
- `blocking_prompt_cooldown_ms = 12000`
- `nonblocking_prompt_cooldown_ms = 4000`
- `same_anchor_reprompt_cooldown_ms = 10000`

Dedupe window:
- `dedupe_window_ms = 1500`
- Same prompt key fired within dedupe window is dropped.

Escalation/suppression policy:
- First rejection: show full reason tooltip.
- Second identical rejection (within 30s): short reminder copy.
- Third+ identical rejection (within 30s): suppress visual prompt, allow optional “Why?” on demand.

Context suppression:
- Suppress all non-critical prompts during:
  - TSRE resolve_lock active,
  - MNUI CommitPending/TravelTransition,
  - HUI PurchasePending/PendingUnknownConnectivity,
  - any full-screen error/reconcile state.

Input-spam resilience:
- If user spam-clicks blocked action, show at most one hint every 2s per anchor.
- No modal stacking from spam.

Player preference override:
- “Reduced Tips” mode lowers non-blocking frequency by 50%.
- “Tutorial Off” disables scripted onboarding and leaves only on-demand tooltips.

### Onboarding Tracks and Steps

Track A: Hub First Entry
- A1 Welcome + objective summary (blocking, once per profile).
- A2 Currency strip highlight (non-blocking).
- A3 Investment inspect prompt (non-blocking, completes on inspect).
- A4 Start run CTA prompt (blocking until acknowledged or skipped).

Track B: Map First Entry
- B1 Current node and legal-next concept (blocking once).
- B2 Node inspect panel callout (non-blocking).
- B3 Commit path explanation (blocking on first legal selection).

Track C: Combat First Entry
- C1 Turn/phase banner + enemy intent callout (blocking once).
- C2 Resource HUD and hand basics (non-blocking).
- C3 Play first card guidance (blocking until first committed play or skip).
- C4 ResolveLock explanation (non-blocking when first lock observed).
- C5 End turn/pass guidance (blocking only if idle timeout reached and legal pass exists).

Track D: Contextual Tooltips (always available)
- D1 Illegal action reason tooltip.
- D2 “Why first?” queue ordering explanation entry-point.
- D3 “Why this number?” damage/resource breakdown entry-point.
- D4 Map lock reason tooltip.
- D5 Hub lock/affordability reason tooltip.

### States and Transitions

OTS macro states:
- OnboardingInit
- AwaitAuthoritativeSnapshot
- OnboardingActive
- StepPresentingBlocking
- StepPresentingNonBlocking
- StepAwaitCompletion
- StepCooldown
- OnboardingSuppressed
- OnboardingCompletedCorePath
- OnboardingDisabledByPreference
- OnboardingErrorRecover

Primary transitions:
- OnboardingInit -> AwaitAuthoritativeSnapshot
- AwaitAuthoritativeSnapshot -> OnboardingActive
- OnboardingActive -> StepPresentingBlocking (eligible blocking step)
- OnboardingActive -> StepPresentingNonBlocking (eligible non-blocking step)
- StepPresenting* -> StepAwaitCompletion
- StepAwaitCompletion -> StepCooldown (completion or dismiss)
- StepCooldown -> OnboardingActive (cooldown elapsed)
- Any state -> OnboardingSuppressed (critical gameplay state or reconcile)
- OnboardingSuppressed -> OnboardingActive (suppression guard cleared)
- OnboardingActive -> OnboardingCompletedCorePath (all core steps complete)
- Any state -> OnboardingDisabledByPreference (player setting)
- Any state -> OnboardingErrorRecover (contract mismatch/unmapped critical step)

Invalid transitions:
- StepPresentingBlocking -> StepPresentingBlocking (without resolving current).
- OnboardingSuppressed -> StepPresentingBlocking (while suppression guard true).
- OnboardingDisabledByPreference -> StepPresenting* (unless setting re-enabled).

State guards:
- GuardAuthoritativeDataReady
- GuardStepEligibilityDeterministic
- GuardSpamCapsNotExceeded
- GuardAccessibilityPayloadComplete
- GuardReasonMappingAvailable

### System Interaction Contracts

1) TSRE (hard upstream)
Consumed:
- `get_phase_state()`
- `get_legal_actions(state)`
- `get_event_log_slice(from_index)`
- rejection/ordering reason codes

Used for:
- combat onboarding triggers and illegal-action explanations.

2) Combat UI/HUD (hard upstream)
Consumed:
- UI anchor IDs (hand slot, resource HUD, phase banner, queue panel)
- focus events and inspect interactions
- resolve_lock display state

Produced:
- highlight/focus requests with deterministic anchor keys only.

3) Map & Node UI (hard upstream)
Consumed:
- current node, legal destinations, commit pending state, lock reasons
- node inspect/select/commit UI events

Used for:
- first map navigation onboarding and lock reason tooltips.

4) Hub UI (hard upstream)
Consumed:
- affordability/lock reasons, tile states, purchase pending/reconnect states
- inspect/confirm interactions

Used for:
- first hub orientation and purchase explanation tooltips.

5) Profile Save / progression flags (hard upstream)
Consumed:
- tutorial preference flags (`tutorial_mode`, `reduced_tips`)
- completed steps set and version

Produced:
- deterministic step completion events and updated onboarding progress snapshot.

6) Telemetry/Debug hooks (hard for vertical slice validation)
Produced:
- prompt_shown, prompt_dismissed, prompt_completed, prompt_suppressed, reason_tooltip_requested
- completion time and drop-off markers per step
- anti-spam suppression counters

### Data Model (Vertical Slice)

`OnboardingProgressSnapshot`
- `profile_id`
- `run_id?`
- `onboarding_version`
- `tutorial_mode` (`full`, `reduced`, `off`)
- `completed_step_ids[]`
- `suppressed_step_ids[]`
- `last_prompt_timestamps_by_key`
- `event_cursor_index`
- `core_path_complete` bool

`OnboardingStepDef`
- `step_id`
- `track_id`
- `blocking` bool
- `priority`
- `anchor_key`
- `trigger_conditions[]`
- `completion_conditions[]`
- `cooldown_ms`
- `max_shows`
- `copy_key_title`
- `copy_key_body`
- `a11y_label_key`

`OnboardingPromptEvent`
- `onboarding_event_id`
- `step_id`
- `anchor_key`
- `shown_at_ms`
- `dismiss_reason`
- `completion_event_ref?`

## Formulas

Notation:
- `I(condition)` in {0,1}
- `clamp(x,a,b)=min(max(x,a),b)`

1) Step eligibility score (selection only)

`eligibility_score(step) = 100*I(prereqs_complete) + 50*I(context_guard) + 20*I(!cooldown_active) - 40*I(recently_dismissed)`

Use:
- Only for deterministic sorting among already-eligible candidates.

2) Prompt budget gate

`blocking_budget_ok = shown_blocking_last_60s < max_blocking_prompts_per_min`
`nonblocking_budget_ok = shown_nonblocking_last_60s < max_nonblocking_prompts_per_min`

3) Repeat suppression threshold

`repeat_count_30s(step_or_reason) = count(events in last 30s with same key)`

Policy:
- show full if count=0
- short if count=1
- suppress if count>=2

4) Idle nudge trigger (combat pass guidance)

`idle_nudge_allowed = idle_ms >= idle_nudge_threshold_ms && legal_pass_exists && !resolve_lock`

MVP default:
- `idle_nudge_threshold_ms = 10000`

5) Tooltip latency budget checks

`prompt_render_latency_ms_p95 <= OTS_PROMPT_P95_MS`
`event_to_prompt_latency_ms_p95 <= OTS_EVENT_TO_PROMPT_P95_MS`

MVP defaults:
- `OTS_PROMPT_P95_MS = 60`
- `OTS_EVENT_TO_PROMPT_P95_MS = 120`

6) Onboarding completion funnel metrics

`core_completion_rate = profiles_completed_core_path / profiles_started_core_path`
`step_dropoff_rate(step) = 1 - (profiles_completed_step / profiles_started_step)`

7) Reason clarity success metric

`reason_retry_reduction = 1 - (repeated_same_invalid_attempts_after_tooltip / repeated_same_invalid_attempts_baseline)`

Vertical slice target:
- `reason_retry_reduction >= 0.35`

## Edge Cases

1) Player skips tutorial at first prompt
- Core scripted steps disabled immediately; contextual on-demand tooltips remain available.

2) Save/load during blocking step
- Resume restores same step state and anchor; no duplicate completion write.

3) Anchor not present (responsive layout or hidden panel)
- Fallback to nearest valid parent anchor and include deterministic fallback badge in debug.

4) Reason code unmapped
- Dev: show `UNMAPPED_REASON(code)`.
- Release: show generic deterministic fallback copy and emit telemetry error.

5) Rapid state churn (combat resolve burst)
- Suppress non-critical prompts until stable input-ready state resumes.

6) Map commit pending then node flow transition
- Defer map tutorial prompts until return to MapInteractive.

7) Hub reconnect reconcile active
- Defer purchase guidance prompts; show single non-spam status hint only.

8) Controller-only input path
- All tutorial actions reachable by focus navigation and confirm/cancel bindings.

9) Screen reader mode active
- Prompt auto-focuses accessible heading, reads concise body once, then does not re-read unless re-focused.

10) Multi-device profile handoff
- Completion state merges by step_id and onboarding_version; completed steps do not replay.

11) Conflicting eligible blocking steps across tracks
- Resolve with deterministic sort tuple; lower-priority step waits.

12) Player repeatedly dismisses same blocking step
- After max dismiss count, convert to non-blocking reminder and allow forward progress; mark `deferred_teach` telemetry.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Turn State & Rules Engine | Upstream authority | Hard | Supplies phase/legality/events/reason codes used for combat onboarding triggers and tooltips. |
| Combat UI/HUD | Upstream presentation | Hard | Supplies stable anchor keys, focus events, and explainability entry points for combat prompts. |
| Map & Node UI | Upstream presentation | Hard | Supplies map state/legality/lock reasons and anchor keys for route onboarding. |
| Hub UI | Upstream presentation | Hard | Supplies investment states, lock/affordability reasons, and safe anchor IDs. |
| Profile Progression Save | Upstream persistence | Hard | Persists onboarding preferences and completed-step ledger deterministically. |
| Telemetry/Debug Hooks | Adjacent validation | Hard (VS) | Captures comprehension, spam suppression, and latency metrics for acceptance gates. |
| Localization pipeline | Upstream content | Hard-adjacent | Provides complete copy keys for prompts, reason text, and accessibility labels. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `max_blocking_prompts_per_min` | int | 3 | 1-5 | Missed required instruction | Interruptive fatigue |
| `max_nonblocking_prompts_per_min` | int | 8 | 4-12 | Weak contextual guidance | Tooltip noise |
| `blocking_prompt_cooldown_ms` | int | 12000 | 6000-20000 | Repetition fatigue | Late help arrival |
| `nonblocking_prompt_cooldown_ms` | int | 4000 | 1500-8000 | Clutter/strobe feel | Stale help |
| `dedupe_window_ms` | int | 1500 | 500-3000 | Duplicate spam | Legit prompt drops |
| `idle_nudge_threshold_ms` | int | 10000 | 5000-20000 | Premature nagging | Missed stuck-player rescue |
| `max_dismiss_before_demote` | int | 2 | 1-4 | Steps become optional too quickly | Blocking frustration |
| `reduced_tips_multiplier` | float | 0.5 | 0.25-0.75 | Still noisy | Too little support |
| `OTS_PROMPT_P95_MS` | int | 60 | 40-120 | Strict budget false alarms | Sluggish prompt response |

Governance:
- Knob changes must not break deterministic trigger ordering or anti-spam guarantees.
- Any cap/cooldown changes require telemetry A/B sanity pass in first-play cohort.

## Accessibility Requirements

1) Input parity
- All onboarding interactions support mouse, keyboard, controller, and touch.
- No instruction may require hover-only behavior.

2) Focus management
- Blocking prompts trap focus within prompt until close/continue.
- On close, focus returns to originating anchor deterministically.

3) Screen reader support
- Every prompt has concise title/body `aria` equivalents from copy keys.
- Live-region announcements are rate-limited and deduped.

4) Visual clarity
- Highlighting uses shape/outline/motion + text, not color alone.
- Minimum contrast for tutorial overlays meets WCAG AA for text and interactive controls.

5) Motion sensitivity
- Reduced motion mode swaps animated spotlight sweeps for static outlines/fades.
- No critical information conveyed only by motion.

6) Text scaling/localization
- Prompt layouts support 200% text scale without clipping critical actions.
- Long localized strings wrap with scroll-safe body region.

7) Cognitive load control
- One primary instruction per blocking prompt.
- Optional “More info” for depth without blocking progression.

## Visual/Audio Requirements

Visual:
- Distinct tutorial anchor highlight style separate from standard hover/focus states.
- Clear prompt type badges: Required, Tip, Why blocked, Advanced.
- Persistent progress indicator for core onboarding track completion.

Audio:
- Soft cue on blocking prompt open, softer cue on completion.
- Deny/reason tooltip cues are subtle and rate-limited.
- Audio cues remain informative when reduced motion is enabled.

## UI Requirements

1) Prompt container
- Supports title, body, primary action, secondary dismiss, optional more-info link.

2) Anchor linkage
- Every prompt references exactly one `anchor_key`; fallback anchor behavior is deterministic.

3) Explainability entry points
- “Why?” affordance available near blocked interactions in combat/map/hub contexts.

4) Preference controls
- Settings include: Full Tutorial, Reduced Tips, Off.
- Preference change applies immediately and persists.

5) Progress visibility
- Core onboarding completion shown in lightweight checklist panel (optional collapse).

6) Error handling
- Contract mismatch or missing anchor enters safe fallback with non-blocking generic guidance.

## Acceptance Criteria

1) Deterministic trigger replay
- Given identical event stream + profile state + input sequence, OTS emits identical ordered prompt events.
- Pass threshold: 500 replay fixtures, 0 ordering divergences.

2) Core path completion
- New profiles complete core onboarding path at or above target rate.
- Pass threshold: `core_completion_rate >= 0.85` in first-play telemetry cohort (N >= 500).

3) Time-to-first-combat-action comprehension
- Players perform first legal card commit without external help within target time.
- Pass threshold: median <= 90s from combat entry.

4) Anti-spam compliance
- Prompt frequency never exceeds configured caps in stress tests (input spam, repeated rejects, rapid state churn).
- Pass threshold: 100% automated stress suite compliance.

5) Rejection clarity improvement
- Repeated identical illegal attempts decrease after reason tooltip exposure.
- Pass threshold: `reason_retry_reduction >= 0.35` versus baseline cohort.

6) Accessibility conformance
- Keyboard/controller/screen-reader acceptance test suite passes all critical onboarding flows.
- Pass threshold: 100% pass on defined critical-path scenarios; WCAG AA contrast checks pass.

7) Resume integrity
- Save/load/refresh during any onboarding state restores step progress without duplicate required prompts.
- Pass threshold: 100% pass across Init, Active, Blocking, Cooldown, Suppressed states.

8) Performance budget
- OTS meets render and event-to-prompt latency budgets on target browser matrix.
- Pass threshold: `prompt_render_latency_ms_p95 <= 60` and `event_to_prompt_latency_ms_p95 <= 120` on Chrome/Firefox stable baseline hardware.

9) Reason mapping completeness
- All production reason codes used by OTS entry points map to localized copy keys.
- Pass threshold: 100% mapped in release build; any unmapped code fails CI content gate.

10) Non-spoiler compliance
- OTS never displays hidden-info fields beyond current reveal policies from map/hub/combat systems.
- Pass threshold: 0 spoiler leaks in contract audit fixtures.
