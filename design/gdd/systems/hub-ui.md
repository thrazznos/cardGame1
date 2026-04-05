# Hub UI

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Readable Tactical Clarity; High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats
> **Upstream References**: design/gdd/systems/meta-hub-investment.md, design/gdd/systems/unlock-option-gating.md, design/gdd/systems/reward-draft.md, design/gdd/systems-index.md

## Overview

Hub UI (HUI) is the browser-first presentation and interaction layer for between-run progression investments.

HUI does not own progression logic, unlock legality, reward bias math, or profile persistence. It renders authoritative profile + investment state from Meta-Hub Investment System (MHIS) and Profile Progression Save, and submits explicit purchase intents with deterministic idempotency keys.

MVP responsibilities:
- Show current hub currency and owned investments with deterministic ordering.
- Show investment availability, affordability, and prerequisite reasons.
- Provide explainable unlock previews and reward-bias effect summaries.
- Execute safe purchase flows with duplicate-click/retry protection.
- Survive browser offline/reconnect/refresh without corrupting state or misleading ownership.
- Preserve low-grind clarity by emphasizing option unlocks over permanent power inflation.

Non-goals (MVP):
- Mid-run purchases.
- Real-time base construction mechanics.
- Hidden client-side progression mutations.
- “Mystery” purchases with opaque outcomes.

## Player Fantasy

The player fantasy is:
- “My runs feed a meaningful hub that grows my strategy options.”
- “I can tell exactly what I can afford, what it does, and why it is locked.”
- “Purchases always feel safe and trustworthy, even if my browser disconnects.”
- “The system adds choice variety, not mandatory grind.”

Emotional outcomes:
- Confidence from deterministic, explainable state.
- Agency through clear investment planning.
- Trust that no action is lost or doubled during connectivity issues.

## Detailed Design

### Design Goals (Optional)

1) Deterministic clarity first
- Same authoritative snapshot must render identical tile order, state badges, and preview content.
- Client optimistic effects are visually separated and reconciled strictly against authority.

2) Low-grind readability
- UI language prioritizes option unlocks, mode options, and reward shaping.
- Avoid framing investments as mandatory baseline power gates.

3) Transaction safety under web conditions
- Duplicate clicks, retries, tab refreshes, and reconnects must not double-spend.
- Pending intent state is recoverable and explainable.

4) Fast planning
- User can answer at a glance: what is owned, what is buyable now, what unlocks next.

5) Accessibility and parity
- Mouse, keyboard, and controller pathways support all core purchase/inspect actions.

### Information Architecture (Optional)

Primary screen regions:
1. Top bar:
- Hub title and category tabs.
- Currency strip (`hub_shard` in MVP) with authoritative/refresh status.
- Connection/status indicator: Online, Reconnecting, Offline-ReadOnly.

2. Investment catalog panel (center/left):
- Deterministically sorted tiles/cards.
- Grouping by category: Unlock, Reward Bias, Mode Option, Cosmetic/Info.
- Filter chips: All, Available, Locked, Owned, Affordable.

3. Detail/preview panel (right):
- Investment name, cost, prerequisites, effect summary.
- Unlock deltas (`unlock_key` families), bias summary bounds, and mode implications.
- Reason list for any disabled purchase state.

4. Action bar (bottom/right):
- Purchase button + confirm affordance.
- Pending transaction state + retry/reconcile controls (if needed).
- Last transaction result with commit sequence token.

5. Overlay layers:
- Confirm purchase dialog.
- Connection loss/reconnect reconciliation banner.
- Error/reason modal for unexpected contract failures.

Responsive behavior:
- Narrow widths collapse detail panel into slide-up drawer.
- Filters collapse to horizontal scroll chips.
- Currency + connection state remain persistently visible.

### Core Rules

1) Authority boundary rule
- HUI renders authoritative state from MHIS/Profile snapshot.
- HUI never decides unlock legality or applies purchases locally as final truth.

2) Deterministic ordering rule
- Investment render order is stable by deterministic key:
  - `ui_priority` ascending,
  - then category stable order,
  - then `investment_id` lexical.
- Same snapshot -> same visual order and focus order.

3) Explainability rule
- Every non-buyable tile must expose reason(s):
  - insufficient currency,
  - unmet prereq investment,
  - unmet prereq unlock key,
  - already owned,
  - hidden by reveal policy.
- Unknown reason fallback is disallowed in production mappings.

4) Purchase safety rule
- Purchase flow requires explicit confirm step in MVP.
- On submit, client attaches idempotent `purchase_event_id`.
- While pending, submit for that investment is disabled.

5) Idempotent result handling rule
- Duplicate response/replay for same `purchase_event_id` must map to one visible outcome.
- UI must avoid repeated spend animations or duplicate toasts for same commit.

6) Offline/reconnect integrity rule
- Offline: switch to read-only mode; no fake local commits.
- Reconnect: fetch authoritative snapshot and reconcile all pending intents by event ID.
- Any unresolved pending purchase after timeout enters “Needs Reconcile” state until snapshot confirms outcome.

7) Run-boundary communication rule
- Purchases affecting reward bias are tagged as “applies next run snapshot.”
- UI must never imply active run has changed.

8) Low-grind messaging rule
- Investment copy and labels must avoid mandatory language (“required”, “must buy”).
- Core baseline access reminder is visible in help tooltip.

9) Browser persistence rule
- Ephemeral client state (filters, selection, pending-intent ledger) is safe to discard and reconstruct from authoritative state + local pending queue metadata.

10) Accessibility rule
- State encoding uses icon + text + shape, not color alone.
- Keyboard/controller focus path supports inspect, preview, confirm, cancel.

### Investment Presentation and Preview Model (Optional)

Tile state model:
- Hidden (optional content policy).
- Locked (visible, unmet prereqs).
- AvailableUnaffordable.
- AvailableAffordable.
- PendingCommit.
- Owned.

Required tile fields:
- Name, category icon, cost, state badge.
- Compact effect headline.
- Lock reason chip(s) when not buyable.

Preview panel required fields:
- Full effect summary from MHIS `effect_payload` projection.
- Prerequisite checklist with pass/fail status.
- “After purchase” delta list:
  - unlock keys granted,
  - reward bias tag changes (bounded language),
  - mode option toggles.
- Scope note:
  - Immediate in profile,
  - next-run for run-generation modifiers.

Reward bias display policy:
- Show directional effect and bounded strength tier (Slight/Moderate/Strong within cap).
- Optional advanced toggle can show exact scalar deltas in debug/advanced mode.

### Interaction Flows (Optional)

Flow A: Inspect investment
1) Hover/focus/select tile.
2) Detail panel loads authoritative preview.
3) Locked reasons/prereq checklist displayed immediately.

Flow B: Purchase success (online)
1) Player selects buyable investment.
2) Confirm dialog shows cost and effect deltas.
3) Submit `PurchaseHubInvestment(... purchase_event_id ...)`.
4) Tile enters PendingCommit state.
5) On accepted result, snapshot updates:
   - currency decremented,
   - ownership badge becomes Owned,
   - unlock/new indicators emitted.

Flow C: Duplicate click/retry
1) User rapidly submits same purchase.
2) UI keeps single pending intent and suppresses duplicate calls in debounce window.
3) If duplicate response arrives anyway, reconcile via `purchase_event_id` and show one outcome.

Flow D: Offline during pending
1) Submit sent, connection drops.
2) UI marks intent as PendingUnknown and blocks new purchases.
3) On reconnect, fetch snapshot and resolve:
   - if owned/currency changed as expected -> mark success,
   - else if unchanged and no commit -> mark failed/retry eligible,
   - else show conflict banner + reload action.

Flow E: Browser refresh/reopen
1) On load, UI requests fresh snapshot.
2) Local pending-intent metadata is compared to snapshot commit sequence + owned set.
3) Intent rows resolve to Success/Failed/Unknown needing support telemetry.

### States and Transitions

HUI macro states:
- HubUiInit
- AwaitSnapshot
- HubInteractive
- InvestmentInspect
- ConfirmDialogOpen
- PurchasePending
- PendingUnknownConnectivity
- ReconcileOnReconnect
- HubReadOnlyOffline
- HubReadOnlyFallback
- HubUiErrorRecover

Primary transitions:
- HubUiInit -> AwaitSnapshot
- AwaitSnapshot -> HubInteractive (valid snapshot)
- HubInteractive -> InvestmentInspect (focus/select tile)
- InvestmentInspect -> ConfirmDialogOpen (buy action)
- ConfirmDialogOpen -> PurchasePending (submit accepted locally)
- PurchasePending -> HubInteractive (commit result success/reject)
- PurchasePending -> PendingUnknownConnectivity (connection loss before final ack)
- PendingUnknownConnectivity -> ReconcileOnReconnect (network restored)
- ReconcileOnReconnect -> HubInteractive (resolved)
- Any online state -> HubReadOnlyOffline (offline detected)
- Any state -> HubReadOnlyFallback (profile migration/save failure flag from backend)
- Any state -> HubUiErrorRecover (contract mismatch / invalid payload)

Invalid transitions:
- HubReadOnlyOffline -> PurchasePending (purchases blocked).
- HubReadOnlyFallback -> PurchasePending.
- ConfirmDialogOpen -> PurchasePending without valid `purchase_event_id` generated.

State guards:
- GuardHasAuthoritativeSnapshot
- GuardInvestmentVisible
- GuardPurchaseAllowedByState
- GuardConnectionOnlineForSubmit
- GuardReasonMappingsComplete

### Data Model and API Contracts (Optional)

Consumed snapshot (read):
- `HubProfileSnapshot`
  - `profile_id`
  - `version`
  - `currency_balances`
  - `investments_owned`
  - `granted_unlock_keys`
  - `reward_bias_profile`
  - `policy_version`
  - `last_commit_seq`

Consumed content catalog:
- `HubInvestmentDef[]` (versioned)
  - includes `investment_id`, cost, prereqs, effect payload, `ui_priority`, category.

Submit contract:
- `PurchaseHubInvestment(profile_id, investment_id, purchase_event_id, expected_commit_seq)`

Result contract:
- `HubPurchaseResult`
  - `accepted`
  - `reason_codes[]`
  - `new_snapshot`
  - `unlock_deltas[]`
  - `reward_bias_delta`
  - `commit_seq`

Preview contract:
- `PreviewHubInvestment(profile_id, investment_id)`
  - affordability
  - prerequisite status
  - projected effect summary

Client local ephemeral structures:
- `pending_intents: map<purchase_event_id, PendingIntentState>`
- `ui_filters`
- `focus_state`
- `last_seen_commit_seq`

### Profile Save Contract Integration (Canonical)

HUI now targets the canonical profile persistence contract defined in:
- `design/gdd/systems/profile-progression-save.md`
- QA migration checklist: `design/gdd/systems/profile-save-contract-migration.md`

Required persistence semantics:
- Read: `GetProfileProgressSnapshot(profile_id)`
- Write: `ApplyProfileEvents(profile_id, events[], expected_base_seq|null)` (via MHIS)
- Optional reconcile/idempotency lookup: `GetEventCommitStatus(profile_id, event_id)`

Integration mapping and behavior:
- HUI `purchase_event_id` is persistence `event_id` through MHIS.
- `expected_commit_seq` maps to `expected_base_seq` for conflict detection.
- Duplicate submit/replay returns deterministic duplicate classification for same `event_id`.
- `ERR_EXPECTED_SEQ_CONFLICT` forces snapshot refresh and UI rebase before retry.
- Snapshot flags `read_only_fallback` and `fallback_reason_code` control read-only fallback UX.

Offline/cache policy:
- Cached snapshot may be used for read display only.
- Cached data is always marked stale and never used as write authority.

Run-boundary policy (canonical):
- Hub reward-bias effects apply to next run generation snapshot only.
- Current run behavior is unchanged by hub purchases.

### Interactions with Other Systems

1) Meta-Hub Investment System (hard upstream)
- Provides authoritative investment eligibility, preview, purchase results, reason codes, and commit sequence.
- HUI mirrors MHIS state machine and reason taxonomy.

2) Profile Progression Save (hard upstream)
- Persists currency and ownership via canonical snapshot/commit/reconcile APIs with idempotency, atomicity, and seq conflict handling.
- Drives `read_only_fallback` and `fallback_reason_code` flags used by HUI read-only fallback behavior.

3) Unlock & Option Gating (adjacent via MHIS)
- Unlock key grants are surfaced by HUI, but legality authority remains UOG.
- HUI messaging for lock/unlock reasons aligns with UOG wording where shared.

4) Reward Draft System (adjacent via MHIS)
- HUI displays bounded “future reward shaping” copy tied to MHIS/RDS `A_hub` behavior.

5) Pre-run setup / mode selection UI (downstream)
- New mode options unlocked in hub should display “New” indicators in setup UI.

6) Telemetry/Debug Hooks (soft MVP, required for validation)
- Tracks transaction funnel, failure reasons, reconnect reconciliation outcomes, and low-grind pacing indicators.

## Formulas

Notation:
- `I(condition)` in {0,1}
- `clamp(x,a,b)=min(max(x,a),b)`

1) Tile affordability indicator

`affordable(i) = I(balance[currency_i] >= cost_i)`

2) Display state derivation (simplified)

`state(i) =`
- `Owned` if `owned_rank(i) >= 1`
- else `PendingCommit` if `exists pending_intent for i`
- else `Locked` if `!prereq_pass(i)`
- else `AvailableAffordable` if `affordable(i)=1`
- else `AvailableUnaffordable`

3) Deterministic ordering key

`sort_key(i) = (ui_priority_i, category_order_i, investment_id_i)`

4) Reconnect reconciliation outcome

For pending intent `p` on investment `i`:
- `resolved_success = I(owned(i)=true OR commit_seq >= p.expected_seq_and_matches_event)`
- `resolved_fail = I(owned(i)=false AND currency unchanged_for_p AND backend_reject_found)`
- Else `resolved_unknown` requiring manual retry/reload path.

5) Submit debounce guard

`submit_allowed = !purchase_pending_global && (now_ms - last_submit_ms) >= submit_debounce_ms`

MVP default:
- `submit_debounce_ms = 200`

6) Connection freshness indicator

`stale_snapshot = I(now_ms - snapshot_received_at_ms > snapshot_stale_threshold_ms)`

MVP default:
- `snapshot_stale_threshold_ms = 5000`

7) Performance UI budget checks

`hub_state_eval_ms_p95 <= HUB_STATE_EVAL_BUDGET_MS`
`input_to_feedback_ms_p95 <= HUB_INPUT_FEEDBACK_BUDGET_MS`

MVP defaults:
- `HUB_STATE_EVAL_BUDGET_MS = 3.0`
- `HUB_INPUT_FEEDBACK_BUDGET_MS = 80`

## Edge Cases

1) Double-click on purchase button
- Single `purchase_event_id` tracked; additional clicks ignored while pending.

2) Same purchase retried after timeout
- Reuses or links to same idempotency identity and resolves by authoritative result.

3) Submit accepted, ack lost, tab refreshed
- On reload, snapshot reconciliation resolves ownership/currency accurately.

4) Client offline before submit
- Purchase disabled with explicit offline reason.

5) Client offline after submit
- Intent marked PendingUnknown; reconcile on reconnect.

6) Snapshot/content version mismatch
- Show non-destructive warning and trigger snapshot refetch; no purchases until aligned.

7) Investment removed/unknown in content after update
- Tile shown as deprecated/unknown content state; purchases blocked safely.

8) Currency display stale due to delayed snapshot
- Show stale badge and last-update timestamp; prevent misleading “affordable” call-to-action until refreshed.

9) Reason code unmapped in localization
- Dev: explicit `UNMAPPED_REASON(code)` token.
- Release: generic deterministic fallback copy + telemetry.

10) Concurrent purchase from second device
- Local commit attempt may reject due to changed balance/ownership; UI surfaces updated reasons after refetch.

11) Migration read-only fallback entered mid-session
- Immediately disable purchase actions, preserve browsing/preview.

12) Browser storage cleared (losing pending cache)
- Safe recovery from authoritative snapshot only; no phantom purchases applied.

13) Pending request outcome expired from lookup retention
- If `GetMutationOutcome` returns unknown, UI resolves by authoritative snapshot + deterministic retry/reconcile path (never local commit).

14) Snapshot integrity/tamper failure surfaced by backend
- Enter read-only fallback state, invalidate optimistic assumptions, and require clean snapshot refresh.

15) Atomicity violation detection test (fault injection)
- UI never renders mixed state where currency changed but ownership did not (or vice versa); either pre or post snapshot only.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Meta-Hub Investment System | Upstream authority | Hard | Provides snapshots, preview, purchase validation/results, reason codes, commit sequence. |
| Profile Progression Save | Upstream persistence | Hard | Guarantees canonical snapshot/commit/reconcile semantics with idempotent request_id handling, seq conflict detection, and atomic writes for hub fields. |
| Unlock & Option Gating | Adjacent (via MHIS) | Hard-adjacent | Unlock grants and lock reason semantics align with UOG key taxonomy. |
| Reward Draft System | Adjacent (via MHIS) | Hard-adjacent | HUI communicates bounded future reward-bias effects tied to `A_hub` model. |
| Pre-run Setup UI | Downstream consumer | Soft MVP | Displays “newly unlocked” mode options granted by hub purchases. |
| Telemetry/Debug | Adjacent | Soft MVP | Receives funnel/reconnect/error metrics and determinism diagnostics. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `submit_debounce_ms` | int | 200 | 100-400 | Duplicate requests slip through | UI feels laggy |
| `snapshot_stale_threshold_ms` | int | 5000 | 2000-10000 | Frequent stale warnings | Stale affordability misleads |
| `pending_reconcile_timeout_ms` | int | 12000 | 5000-30000 | Premature failure messaging | Long uncertainty periods |
| `max_visible_reason_chips` | int | 3 | 1-6 | Missing lock clarity | UI clutter |
| `new_unlock_badge_duration_ms` | int | 8000 | 3000-20000 | Missed discovery | Visual noise persists |
| `hub_catalog_page_size` | int | 30 | 12-60 | Excess pagination friction | Heavy render cost |
| `show_exact_bias_numbers` | bool | false | false/true | Less expert transparency | Over-optimization behavior |
| `offline_readonly_banner_persist` | bool | true | false/true | Users miss state mode | Excessive banner fatigue |

Governance constraints:
- Knob changes cannot weaken idempotent safety or offline read-only protections.
- Messaging/tuning changes must preserve low-grind framing and non-mandatory progression principles from MHIS.

## Visual/Audio Requirements

Visual:
- Distinct tile badges: Locked, Available, Pending, Owned, Offline.
- Currency display includes icon, numeric value, and freshness indicator.
- Pending intent visuals are subtle but unambiguous (spinner + event token in advanced view).
- Lock reasons are concise and scannable.
- Reconnect reconciliation banner states: Reconnecting, Reconciling, Resolved.
- Deterministic ordering with stable focus ring and keyboard navigation cues.

Audio:
- Purchase confirm success cue.
- Soft deny cue for unaffordable/locked/offline attempts.
- Reconnect resolved cue (subtle, optional).
- Rate-limit repetitive deny/error cues to avoid spam during unstable connection.

## UI Requirements

1) Currency and status clarity
- Always visible current hub currency.
- Always visible connectivity + stale snapshot state.

2) Investment discoverability
- Filterable catalog with deterministic sorting.
- Owned and newly unlocked investments are immediately identifiable.

3) Explainable lock/affordability states
- Every disabled buy action has visible reason text/chips.
- Preview panel includes prereq checklist with pass/fail icons.

4) Safe purchase flow
- Confirmation step includes cost, effect deltas, and scope timing.
- Pending state blocks duplicate submits for that investment.

5) Offline/reconnect resilience
- Offline mode explicitly read-only.
- Reconnect automatically reconciles pending intents and refreshes authoritative snapshot.

6) Deterministic rendering
- Same snapshot + content version => identical ordering, state badges, and summary text selection.

7) Accessibility and input parity
- Full keyboard/controller support for browse/inspect/purchase.
- Non-color-only state encoding and readable text contrast.

8) Error containment
- Contract mismatch or unknown payload never crashes UI; enters recover state with retry.

## Acceptance Criteria

1) Deterministic render fidelity
- Given identical `HubProfileSnapshot` + content version, render ordering and state badges are identical across reloads and target browsers.

2) Purchase idempotency UX correctness
- Repeated submit attempts for same logical purchase result in at most one committed spend and one owned transition.

3) Reason explainability coverage
- 100% of disabled purchases expose deterministic player-facing reason messaging from reason code map.

4) Offline safety
- While offline, no purchase submit is allowed; UI remains browse/inspect capable.

5) Reconnect reconciliation
- Pending intents created before disconnect resolve to success/failure/unknown deterministically after reconnect snapshot.

6) Conflict handling correctness
- Stale `expected_seq` responses force UI refresh/rebase and never display silent overwrite success.

7) Low-grind communication integrity
- UI copy audit confirms no implication that core run access requires hub investment.

8) Run-boundary correctness
- Purchases that influence reward bias are labeled next-run only; no active-run implication appears.

9) Tamper/integrity containment
- Integrity rejection paths always disable purchase actions until authoritative state is refreshed.

10) Atomicity visibility
- Under persistence fault-injection scenarios, UI only presents coherent pre or post commit snapshots.

11) Performance
- Hub state evaluation for 200 investments <= 3 ms p95 (excluding draw).
- Input-to-feedback <= 80 ms p95 on target desktop browsers.

12) Read-only fallback behavior
- If backend flags migration/save fallback mode, purchases are disabled and explanatory banner is shown without blocking hub browsing.

## Telemetry & Debug Hooks (Optional)

Counters:
- `hub_ui_open_total`
- `hub_ui_purchase_click_total{investment_id}`
- `hub_ui_purchase_confirm_total{investment_id}`
- `hub_ui_purchase_submit_total{investment_id}`
- `hub_ui_purchase_result_total{investment_id, outcome}`
- `hub_ui_purchase_fail_reason_total{reason_code}`
- `hub_ui_offline_enter_total`
- `hub_ui_reconnect_reconcile_total{outcome}`
- `hub_ui_snapshot_stale_total`
- `hub_ui_readonly_fallback_total`

Durations/histograms:
- `hub_ui_purchase_pending_ms`
- `hub_ui_reconcile_duration_ms`
- `hub_ui_state_eval_ms`
- `hub_ui_input_feedback_ms`

Derived health metrics:
- Purchase completion rate by category.
- PendingUnknown resolution rate after reconnect.
- Median time from hub open to first successful purchase.
- Optional unlock discovery rate after run completion.

Debug features (non-release):
- Show `purchase_event_id`, `commit_seq`, snapshot version.
- Force network drop simulation for reconnect testing.
- Reason-code mapping validator overlay.
- Determinism hash display for ordered tile list.

## Open Questions

1) Should MVP expose exact reward-bias scalar numbers in standard UI, or keep tiered language only?
2) Should confirm dialog be skippable after first successful purchase (with settings toggle), or always required?
3) Should hidden investments exist in MVP, or should all locked items be visible for planning clarity?
4) What is the preferred UX when a pending intent remains unresolved beyond timeout (auto-retry vs manual retry only)?
5) Once Profile Progression Save GDD is finalized, which reconciliation fields are canonical for UI (`last_commit_seq`, event journal query, both)?
6) Should hub UI provide a lightweight “path to next unlock” planner panel in MVP or defer to post-MVP?