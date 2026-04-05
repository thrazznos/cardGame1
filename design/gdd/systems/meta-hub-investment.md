# Meta-Hub Investment System

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats; Readable Tactical Clarity
> **Upstream References**: design/gdd/systems/unlock-option-gating.md, design/gdd/systems/reward-draft.md, design/gdd/game-concept.md

## Overview

Meta-Hub Investment System (MHIS) is the between-run progression layer that lets players spend persistent hub resources to unlock new strategic options and lightly bias future reward ecosystems.

MHIS exists to deliver long-term account growth without turning the game into mandatory power grind.

MVP contract:
- Core run viability is never hard-gated behind hub progression.
- Hub progression primarily expands options (new unlock keys, mode toggles, archetype branches).
- Any reward-pool influence is soft, bounded, deterministic, and replay-verifiable.
- All profile state transitions are browser-first deterministic and idempotent under save/retry conditions.

Out of scope (MVP):
- Real-time base-building minigames.
- Timed construction queues.
- Prestige/reset loops.
- Permanent uncapped power-stat inflation.

## Player Fantasy

The player fantasy is:
- “My runs feed a living strategic hub that reflects my playstyle.”
- “I gain more buildcraft options over time, not just bigger numbers.”
- “I can choose where to invest and see predictable effects in future runs.”
- “I never feel locked out of core fun because I didn’t grind enough.”

The player should feel long-term agency and expression, not obligation.

## Detailed Design

### Design Goals (Optional)

1) Preserve low-grind baseline
- New profile can fully engage core loop before any hub investment.
- Hub progression broadens choices, difficulty toggles, and reward ecology rather than baseline survival stats.

2) Deterministic profile progression
- Investments, unlock effects, and hub modifiers resolve identically for identical inputs.
- Save/reload, retry, and duplicate event delivery do not create divergent state.

3) Explainable effects
- Every investment has explicit effect payload, unlock linkage, and UI-facing summary.
- If an investment cannot be purchased or applied, reason is explicit.

4) Clean integration
- Unlock operations route through Unlock & Option Gating (UOG) `unlock_key` contract.
- Reward ecosystem influence routes through Reward Draft System (RDS) `A_hub` multiplier path.

### Core Rules

1) MHIS is between-run only in MVP
- Investments can be purchased only at hub phase (outside active combat/map node flow).
- Mid-run purchases are not allowed in MVP.

2) Core viability non-gating rule (hard)
- No investment is required to access base run loop.
- `base_set` and baseline mode are always available via UOG policy.

3) Investment effect classes (MVP)
- `unlock_grant`: grants one or more UOG `unlock_key`s.
- `reward_bias`: applies bounded hub weight modifiers consumed by RDS (`A_hub`).
- `mode_option_unlock`: enables optional challenge/mutator choices (still subject to UOG mode gating).
- `cosmetic_or_info` (optional): purely UX/cosmetic unlocks with no mechanical impact.

4) No permanent raw-stat escalation
- MHIS cannot grant uncapped permanent damage/hp/mana multipliers.
- Any mechanical advantage must be option-space or bounded weighting influence.

5) Deterministic purchase semantics
- Purchase request includes `purchase_event_id` for idempotency.
- Replayed identical purchase event must produce identical post-state and no duplicate spending.

6) Effect activation timing
- Unlock grants become effective at deterministic checkpoint: immediately after successful hub purchase commit.
- Reward bias effects apply on next run generation snapshot (not retroactively to an active run).

7) Versioned policy data
- Investment definitions are versioned content.
- Profile stores applied policy version for migration/replay safety.

8) Bounded reward influence
- Combined hub modifier effect is clamped and cannot force guaranteed specific-card outcomes.
- Hub bias may tilt probabilities but never bypass UOG legality filters.

### Investment Taxonomy and Content Contract (Optional)

Investment definition shape (`HubInvestmentDef`):
- `investment_id` (stable string)
- `name_loc_key`
- `description_loc_key`
- `category` (`unlock`, `bias`, `mode`, `cosmetic`)
- `cost_currency_id` (MVP default: `hub_shard`)
- `cost_amount`
- `prereq_unlock_keys[]`
- `prereq_investments[]`
- `effect_payload`
- `repeatable` (bool; MVP default false)
- `max_rank` (MVP default 1)
- `ui_priority`
- `content_version`

Effect payload examples:
- Unlock grant:
  - `grant_unlock_keys: ["meta.archetype_chain_pack_1"]`
- Reward bias:
  - `tag_biases: [{ tag:"archetype.chain", scalar:+0.10 }, { tag:"rarity.rare", scalar:-0.05 }]`
  - `global_bias_cap: 1.20`
- Mode unlock:
  - `grant_unlock_keys: ["mode.hardcore_toggle"]`

Authoring constraints:
- `investment_id` immutable after ship.
- All referenced unlock keys must exist in UOG catalog.
- Bias tags must map to existing RDS/card pool tag vocab.
- Circular prerequisite chains are validation errors.

### Resource Economy (Optional)

MVP persistent hub currency:
- `hub_shard` (account-level scalar).

Earning policy (high-level, data-authored):
- Run completion grants deterministic base payout by outcome tier.
- Optional bonuses may come from boss clear or first-clear milestones.
- No daily caps or time-gated energy mechanics in MVP.

Spending policy:
- Purchases are atomic: either full cost is deducted and effect applies, or no change.
- Cannot spend below zero.

### States and Transitions

Per-investment state machine:
- Hidden (optional; if author chooses concealed content)
- VisibleLocked (shown but unmet prerequisites)
- Available (prereqs met, affordable maybe true/false)
- PurchasedPendingCommit (transient internal)
- Active (effect applied)

Primary transitions:
- Hidden -> VisibleLocked (visibility condition met)
- VisibleLocked -> Available (all prerequisites satisfied)
- Available -> PurchasedPendingCommit (purchase event accepted)
- PurchasedPendingCommit -> Active (transaction committed, profile updated)

Invalid transitions:
- Active -> Available via normal play (no regression in MVP)
- Active -> Active with additional spend when `repeatable=false`

Profile-level progression states:
- HubUninitialized
- HubReady
- HubTransactionInFlight
- HubReady (post-commit)
- HubReadOnlyFallback (save/profile failure mode)

Transition guardrails:
- Only one transaction lock per profile at a time.
- Duplicate `purchase_event_id` returns prior committed result.

### Data Model and API Contracts (Optional)

Read snapshot:
- `GetHubProfileState(profile_id) -> HubProfileSnapshot`
- Snapshot fields:
  - `profile_id`
  - `version`
  - `currency_balances: map<string,int>`
  - `investments_owned: map<investment_id,rank>`
  - `granted_unlock_keys: set<string>`
  - `reward_bias_profile: map<tag,float>`
  - `policy_version`
  - `last_commit_seq`

Purchase request:
- `PurchaseHubInvestment(profile_id, investment_id, purchase_event_id, expected_commit_seq) -> HubPurchaseResult`
- Canonical event identity mapping:
  - `purchase_event_id` is serialized as ProgressEvent.`event_id` when writing through shared profile persistence.

Purchase result:
- `accepted` (bool)
- `reason_codes[]`
- `new_snapshot`
- `unlock_deltas[]`
- `reward_bias_delta`
- `commit_seq`

Preview request:
- `PreviewHubInvestment(profile_id, investment_id) -> HubInvestmentPreview`
- Includes affordability, prerequisite status, and projected effect summary.

Downstream export to run start:
- `BuildRunHubModifiers(profile_id, policy_version) -> RunHubModifierSnapshot`
- Output consumed by RDS as `A_hub` inputs and by pre-run option UI.

### Profile Save Contract Integration (Canonical)

MHIS now targets the canonical profile persistence contract defined in:
- `design/gdd/systems/profile-progression-save.md`
- QA migration checklist: `design/gdd/systems/profile-save-contract-migration.md`

Required persistence semantics:
- Read: `GetProfileProgressSnapshot(profile_id)`
- Write: `ApplyProfileEvents(profile_id, events[], expected_base_seq|null)`
- Optional reconcile/idempotency lookup: `GetEventCommitStatus(profile_id, event_id)`

Integration mapping rules:
- MHIS `purchase_event_id` is the persistence `event_id` for `HUB_INVESTMENT_PURCHASED`.
- `expected_commit_seq` maps to persistence `expected_base_seq`.
- Duplicate event handling returns duplicate classification with original commit outcome.
- Stale sequence returns `ERR_EXPECTED_SEQ_CONFLICT` and triggers snapshot rebase.

Hard guarantees:
- Atomic purchase event commit (currency deduction + ownership + unlock grant apply together).
- Integrity/tamper failures reject commit and preserve prior authoritative state.
- Migration failure forces read-only fallback via snapshot flags (`read_only_fallback`, `fallback_reason_code`).

Run boundary policy (canonical):
- Active run uses run-start bound profile view.
- Mid-run profile updates do not alter current run reward weighting.
- New modifiers apply next run only.

### Interactions with Other Systems

1) Unlock & Option Gating (hard upstream/downstream)
- MHIS grants unlock keys; UOG remains authority for eligibility evaluation.
- Hub UI lock explanations should reuse UOG reason/hint patterns when relevant.

2) Reward Draft System (hard downstream)
- MHIS provides bounded hub bias profile consumed as `A_hub` in reward formulas.
- RDS still performs eligibility-first filtering; MHIS never bypasses unlock legality.

3) Profile Progression Save (hard upstream)
- Supplies canonical snapshot/commit/reconcile APIs with idempotency, atomicity, conflict handling, and integrity checks.

4) Map/Pathing and Run Generation (soft-adjacent)
- May consume unlocked mode options/challenge flags enabled by MHIS via UOG.

5) Hub UI (hard downstream)
- Presents investment tree/list, affordability, prerequisites, previews, and commit results.

6) Telemetry/Debug systems (soft in MVP)
- Consume purchase outcomes, failure reasons, and pacing metrics.

## Formulas

Notation:
- `I(condition)` is indicator in {0,1}
- `clamp(x,a,b)=min(max(x,a),b)`

1) Affordability

`affordable(i) = I(balance[currency_i] >= cost_i)`

2) Purchase validity

`can_purchase(i) = I(state_i in {Available}) * affordable(i) * prereq_pass(i) * repeat_rule_pass(i)`

3) Atomic currency update (on successful purchase)

`balance' = balance - cost_i`

Constraint:
- `balance' >= 0`

4) Unlock grant projection

For each granted key `k` in investment `i`:

`unlock_flags'[k] = true`

No unlock regression:
- If already true, remains true.

5) Hub reward bias aggregation

For a candidate reward item `c` with tags `T(c)`:

`bias_sum(c) = Σ bias_profile[t] for t in T(c) if t exists`

`A_hub(c) = clamp(1 + bias_sum(c), A_hub_min, A_hub_max)`

MVP defaults:
- `A_hub_min = 0.80`
- `A_hub_max = 1.20`

RDS alignment:
- RDS card formula already includes `A_hub` term; MHIS supplies this scalar deterministically per candidate.
- If no matching bias tags, `A_hub(c)=1.0`.

6) Investment pacing health metric (policy KPI)

`optional_unlocks_per_5_runs = newly_unlocked_optional_keys / completed_runs_window`

Target (MVP guidance):
- 1 to 3 optional unlocks per 5 completed runs, without reducing new-profile core access.

## Edge Cases

1) Duplicate purchase submission (double-click / retry)
- Idempotency by `purchase_event_id` returns original commit result.

2) Concurrent purchases on same profile
- Serialized by profile lock.
- Second request evaluates against post-first committed state.

3) Purchase accepted but downstream UI disconnect
- Commit remains authoritative in profile save.
- On reconnect/reload, Hub UI reads snapshot and reflects owned state.

4) Unknown investment_id at runtime
- Reject purchase with `ERR_HUB_INVESTMENT_UNKNOWN`.
- Emit telemetry and keep state unchanged.

5) Investment references unknown unlock key
- Content validation hard fail pre-ship.
- Runtime defensive path: skip effect, mark error, do not spend currency.

6) Insufficient funds race condition
- Re-check affordability inside transaction lock before commit.

7) Policy version mismatch (profile older than content)
- Attempt deterministic migration.
- On failure, enter HubReadOnlyFallback.

8) Bias stack exceeds clamp bounds
- Clamp at formula stage; do not error.

9) Mid-run hub modification attempt via external tool/dev command
- Allowed only in dev mode with explicit warning.
- Production behavior: defer effect to next run snapshot.

10) Lost ack after commit (offline/reconnect)
- Purchase may have committed even if caller did not receive response; resolve by `GetEventCommitStatus(event_id)` or refreshed snapshot commit_seq.

11) Stale `expected_base_seq` from delayed client
- Commit rejects with `ERR_EXPECTED_SEQ_CONFLICT`; client must reload state before reattempt.

12) Partial write/fault injection during purchase commit
- After recovery, profile contains either full pre-purchase or full post-purchase state, never mixed currency/ownership.

13) Integrity/tamper rejection
- Snapshot or payload integrity failure yields rejection/read-only escalation; no currency or ownership mutation applies.

14) Multi-device simultaneous purchase race
- One device may commit first; conflicting device must rebase and cannot double-spend or duplicate unlock grants.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Profile Progression Save | Upstream state provider | Hard | Persists hub currency/ownership/unlocks with canonical snapshot/commit APIs, idempotency by `event_id`, `expected_base_seq` conflict handling, and atomicity. |
| Unlock & Option Gating | Upstream/downstream eligibility authority | Hard | Consumes unlock grants from MHIS; evaluates all final eligibility by `unlock_key` with reason codes/hints. |
| Reward Draft System | Downstream consumer | Hard | Consumes `RunHubModifierSnapshot` and applies `A_hub` scalar in deterministic reward weighting. |
| Card Data & Definitions | Adjacent data vocabulary | Soft in MVP | Provides tag vocabulary that reward bias references (`pool_tags`, rarity tags, archetype tags). |
| Hub UI | Downstream presentation | Hard | Displays investments, prerequisites, affordability, and deterministic purchase outcomes. |
| Telemetry/Debug Hooks | Downstream observability | Soft in MVP | Records purchase funnel, pacing, errors, and lock reasons. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `run_completion_base_payout` | int | 10 | 5-25 | Progress feels stalled | Unlock cadence too fast, trivial choices |
| `boss_bonus_payout` | int | 10 | 0-30 | Boss clears feel unrewarding | Snowball pacing too steep |
| `A_hub_min` | float | 0.80 | 0.70-0.95 | Negative bias too punitive | Bias has no meaningful downside shaping |
| `A_hub_max` | float | 1.20 | 1.05-1.35 | Bias feels irrelevant | Hub over-determines rewards |
| `max_bias_tags_per_profile` | int | 6 | 2-12 | Expression too narrow | Authoring complexity/exploit risk |
| `investment_cost_curve` | enum | gentle_step | flat-gentle-steep | Too many purchases immediately | Grind pressure emerges |
| `unlock_visibility_default` | bool | true | false/true | Hidden options feel absent | Too much locked clutter |
| `optional_unlock_target_per_5_runs` | int range | 1-3 | 0-5 | No long-term motivation | Overload and loss of strategic commitment |

Governance constraints:
- Any tuning change must preserve `core_access_ratio(profile_new)=1.0` from UOG policy.
- Any proposal enabling mandatory stat grind is blocked for MVP.

## Visual/Audio Requirements

Visual:
- Hub screen clearly separates categories: Unlocks, Reward Bias, Mode Options, Cosmetic.
- Each investment tile shows state badge: Locked, Available, Owned.
- Preview panel shows exact deterministic effect summary (grants, biases, prerequisites).
- Newly acquired investments receive one-time highlight.

Audio:
- Positive confirm cue on successful purchase.
- Gentle denied cue for insufficient funds or locked prerequisites.
- Distinct but subtle “new unlock available” cue after run return.

## UI Requirements

1) Deterministic and explainable states
- Same profile snapshot must render identical investment states and ordering.
- Locked entries must show why (missing prereq, insufficient currency, hidden condition).

2) Purchase safety UX
- Confirm dialog for purchases with clear cost/effect summary.
- Prevent accidental repeat submission (button lock until response).
- On duplicate submit, UI resolves using idempotent result without double animation spam.

3) Effect transparency
- Show which unlock keys or option families are affected.
- Show reward-bias effects as bounded ranges (for example: “Chain-tag rewards slightly more likely”).

4) Integration clarity
- If an investment unlocks a mode toggle, that toggle UI should display “New” indicator in pre-run setup.

5) Browser-first reliability
- UI must handle refresh/reconnect by reloading authoritative snapshot and reconciling local optimistic state.

## Acceptance Criteria

1) Low-grind baseline integrity
- New profile can play full core loop without any hub purchases.

2) UOG alignment
- Unlock-grant investments correctly change UOG eligibility on next eligibility query after commit.
- No unknown `unlock_key` references pass content validation.

3) RDS alignment
- Hub bias modifiers feed `A_hub` deterministically.
- Reward generation with identical seed + snapshots yields identical offers including hub effects.

4) Deterministic state transitions
- Duplicate purchase events are idempotent and do not double-spend.
- Concurrent purchase requests resolve deterministically by seq-conflict semantics.

5) Save-failure resilience
- If profile save integrity/migration fails, system enters read-only fallback without crashing core play.

6) Atomic purchase commit
- Currency deduction, ownership grant, and unlock grant apply all-or-nothing under fault injection testing.

7) Reconnect reconciliation
- Lost-ack purchases resolve deterministically via `event_id` status lookup and `commit_seq` refresh.

8) Multi-device race safety
- Simultaneous purchases from different devices never result in negative currency or duplicate ownership.

9) No hard power creep
- MVP content audit confirms zero uncapped permanent combat stat multipliers from MHIS.

10) Performance
- Hub state evaluation for 200 investments renders in <= 3 ms on target desktop browser hardware (excluding UI draw).
- Single purchase commit round-trip processing (excluding storage I/O latency) <= 2 ms server/runtime logic budget.

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `mhis_purchase_attempt_total{investment_id}`
- `mhis_purchase_success_total{investment_id}`
- `mhis_purchase_fail_total{reason}`
- `mhis_currency_balance_histogram{currency_id}`
- `mhis_unlocks_granted_total{unlock_key}`
- `mhis_bias_profile_size_histogram`
- `mhis_readonly_fallback_total`

Derived health metrics:
- Optional unlocks earned per 5 runs.
- Time-to-first-noncore-unlock median.
- Purchase regret proxy (investments never interacting with selected run options over N runs).

Debug commands (dev only):
- Grant currency
- Revoke currency (bounded, non-negative)
- Force-purchase by ID (with audit flag)
- Dump hub snapshot + derived `A_hub` vectors for current profile

## Open Questions

1) Should MVP include mutually exclusive investment branches (meaningful commitment), or keep all branches combinable?
2) Should reward bias investments be visible as exact numeric scalars in player UI, or abstract “slight/moderate” language only?
3) What run-outcome payout table best supports low-grind pacing across first 10 runs?
4) Should first purchase be scripted/tutorialized, or entirely freeform?
5) After Profile Progression Save GDD exists, which provisional fields should remain canonical vs moved into separate hub-save subdocument?