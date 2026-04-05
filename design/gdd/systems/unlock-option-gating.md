# Unlock & Option Gating

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillar**: High Run Variety, Low Grind; Sequencing Mastery Over Raw Stats; Readable Tactical Clarity
> **Upstream References**: design/gdd/card-data-definitions.md, design/gdd/systems/combat-balance-model.md

## Overview

Unlock & Option Gating (UOG) is the progression-layer eligibility service for Dungeon Steward MVP.

Its job is to answer one deterministic question for any content or option:
- Is this eligible right now for this profile, this run context, and this selected mode?

UOG controls:
- Card/relic/reward pool eligibility via `unlock_key` contracts.
- Visibility and selectability of run options (difficulty toggles, mode mutators, challenge flags).
- Eligibility of optional systems that should be unlocked as player-facing variety, not raw stat escalation.

MVP philosophy:
- No mandatory grind wall for core fun.
- Unlocks expand option space and expression, not linear power.
- Gating decisions are deterministic, inspectable, and UI-explainable.

Out of scope (MVP):
- Battle pass style XP tracks.
- Time-gated live-service unlock cadence.
- Monetization-linked unlocks.

## Player Fantasy

The player fantasy is:
- “I can access the core game immediately.”
- “As I play, I unlock new strategic toys and challenge switches, not chores.”
- “If something is locked, I know exactly why and how to unlock it.”

The player should never feel:
- Forced into repetitive farming for base viability.
- Blocked from meaningful buildcraft due to opaque requirements.
- Punished for experimenting with optional mode settings.

## Detailed Design

### Design Goals (Optional)

1) Preserve low-grind pillar
- Core content needed to evaluate game fun is available at start (`base_set` and starter options).
- Unlock progression primarily broadens archetype and challenge variety.

2) Deterministic contracts
- `unlock_key` is a stable lookup token.
- Key evaluation result must be identical for identical inputs.

3) Explainability
- Every lock state has a machine-readable reason code and player-readable hint.

4) Cross-system utility
- Reward Draft, Relics, Map options, and UI all consume one consistent eligibility API.

### Core Rules

1) Every gateable content item has an `unlock_key` (string token).
- Card Data already defines this field for cards.
- Non-card content (relics, mode toggles) follows same contract in their own data definitions.

2) `unlock_key` never stores logic inline.
- Logic is defined in a separate Unlock Catalog.
- Content only references key names.

3) Eligibility is conjunctive by context:
- `eligible = profile_gate AND run_gate AND mode_gate`
- If any required gate fails, item is ineligible.

4) Low-grind baseline policy (MVP hard rule)
- `base_set` cards/options are always eligible on profile creation.
- No required daily/weekly loops for core unlocks.
- No permanent power-stat unlocks in MVP through UOG.

5) Unlocks are account/profile scoped, not per-run permanent mutations.
- Run-scoped gates may temporarily hide/show options during a run, but do not overwrite profile unlock history.

6) Card Data contract alignment
- UOG must support current Card Data usage: `unlock_key` -> binary eligibility multiplier (`A_unlock` in Card Data formulas).
- If `unlock_key` missing or unknown, fail-safe policy applies (defined below).

7) Fail-safe policy (MVP)
- Unknown `unlock_key` in production content validation: hard fail and block publish.
- Unknown `unlock_key` at runtime (corrupt/mismatched build): treat as locked and emit error telemetry.

### Gate Types and Evaluation Model (Optional)

MVP supports these gate dimensions:

1) Profile flag gates
- Check persistent booleans/counters (example: `defeated_boss_1`, `runs_completed >= 3`).

2) Run condition gates
- Check current run context (example: only valid in challenge run, map tier, selected act).

3) Mode option gates
- Check currently selected pre-run options (example: mutator compatibility, tutorial mode restrictions).

Unlock Catalog entry shape (logical contract):
- `unlock_key`
- `gate_type` (`always`, `profile_flag`, `profile_counter`, `run_condition`, `mode_option`, `composite_all`, `composite_any`)
- `params` (typed payload)
- `visible_when_locked` (bool)
- `ui_unlock_hint_key`
- `priority` (for conflict resolution in UI ordering only)

Composite behavior:
- `composite_all`: all child clauses must pass.
- `composite_any`: at least one child clause must pass.

### States and Transitions

Per-key profile projection states:
- UnknownKey
- Locked
- Unlocked
- TemporarilyIneligible (unlocked profile-wise, blocked by current run/mode context)

Primary transitions:
- UnknownKey -> Locked (after catalog load if key defined but requirements unmet)
- Locked -> Unlocked (requirements met)
- Unlocked -> TemporarilyIneligible (run/mode constraints fail in current context)
- TemporarilyIneligible -> Unlocked (context becomes valid)

Invalid transition:
- Unlocked -> Locked by normal play flow (MVP does not support unlock regression).

### Data Model and API Contracts (Optional)

Core request:
- `EligibilityQuery`
  - `profile_id`
  - `content_type` (`card`, `relic`, `mode_option`, `reward_bundle`, ...)
  - `content_id`
  - `unlock_key`
  - `run_context` (nullable outside run)
  - `mode_context` (selected options/mutators)

Core response:
- `EligibilityResult`
  - `eligible` (bool)
  - `profile_gate_pass` (bool)
  - `run_gate_pass` (bool)
  - `mode_gate_pass` (bool)
  - `state` (`locked`, `unlocked`, `temporarily_ineligible`, `unknown_key`)
  - `reason_codes[]`
  - `ui_hint_key`

Batch request for reward generation:
- `EvaluateEligibilityBatch(unlock_keys[], profile_context, run_context, mode_context)`
- Must support deterministic output ordering matching input ordering.

### Profile Save Contract Integration (Canonical)

UOG now targets the canonical profile persistence contract defined in:
- `design/gdd/systems/profile-progression-save.md`
- QA migration checklist: `design/gdd/systems/profile-save-contract-migration.md`

Required persistence semantics for UOG integration:
- Read: `GetProfileProgressSnapshot(profile_id)`
- Write: `ApplyProfileEvents(profile_id, events[], expected_base_seq|null)`
- Optional idempotency lookup: `GetEventCommitStatus(profile_id, event_id)`

Hard requirements:
- Idempotency by `event_id`.
- Concurrency safety by `expected_base_seq` conflict handling (`ERR_EXPECTED_SEQ_CONFLICT`).
- Atomic event commits (no partial unlock/counter apply visible to readers).
- Migration/integrity failures route to read-only fallback where only `base_set` fail-open policy remains.

Consistency window policy (canonical):
- UOG uses run-bound profile view from run start (`bound_commit_seq`) for active-run determinism.
- Mid-run progression writes persist immediately for future runs, but do not alter active-run reward generation.

### Interactions with Other Systems

1) Card Data & Definitions (hard)
- Consumes `unlock_key` from card records.
- Returns binary eligibility used by Card Data reward weighting (`A_unlock` 0/1).

2) Reward Draft System (hard downstream)
- Must call UOG before weighting candidates.
- Ineligible entries removed before probability normalization.

3) Meta-Hub Investment (hard downstream)
- Hub features/options can use same unlock-key contract.
- Must not introduce mandatory stat grind through UOG-controlled gates.

4) Relics/Passive Modifiers (hard downstream)
- Relic availability gated by unlock keys and mode compatibility.

5) UI systems (hard downstream)
- Need lock reason/hint payload for tooltips and disabled controls.

6) Profile Progression Save (hard upstream)
- Provides canonical snapshot, commit, and reconcile APIs with idempotency, seq-conflict handling, and atomicity guarantees.

### Unlock Catalog Governance (Optional)

Authoring rules:
- All unlock keys must be declared exactly once.
- Key names are immutable after ship for save compatibility.
- Deprecated keys map through alias table until migration complete.

Naming convention:
- `base.*` always-open baseline.
- `meta.*` profile progression unlocks.
- `mode.*` mode toggle unlocks.
- `challenge.*` optional challenge switches.

Example keys:
- `base_set` (always)
- `meta.archetype_chain_pack_1` (profile milestone)
- `mode.hardcore_toggle` (profile milestone)
- `challenge.no_healing` (profile + mode compatibility)

## Formulas

1) Eligibility decomposition

`gate_profile = EvalProfile(unlock_key, profile_snapshot)`
`gate_run = EvalRun(unlock_key, run_context)`
`gate_mode = EvalMode(unlock_key, mode_context)`
`eligible = gate_profile * gate_run * gate_mode`

Boolean values represented as {0,1} for interoperability with weighting.

2) Card Data unlock multiplier alignment

`A_unlock(card) = eligible(card.unlock_key)`

Constraint:
- `A_unlock` must be exactly 0 or 1 in MVP.

3) Reward candidate filtering

Given candidate set `C`:
`C_eligible = { c in C | eligible(c.unlock_key)=1 }`

Then Reward Draft normalizes weights over `C_eligible` only.

4) Low-grind unlock pacing guardrail (MVP policy metric)

`core_access_ratio = accessible_core_items / total_core_items`

MVP target:
- `core_access_ratio(profile_new) = 1.0`

Optional variety metric:
`option_growth = unlocked_optional_items_over_time`
- Should trend upward through normal play, without requiring repetitive farm loops.

## Edge Cases

1) Missing `unlock_key` on a card
- Content validation error; publish blocked.

2) Unknown `unlock_key` in runtime data
- Mark ineligible, emit `ERR_UNLOCK_KEY_UNKNOWN_RUNTIME`, show safe lock hint.

3) Profile snapshot unavailable (load failure)
- Fail open only for `base_set`.
- All non-base keys lock with `ERR_PROFILE_UNAVAILABLE_FALLBACK`.

4) Unlock achieved mid-run
- Profile state may update, but active node reward candidate lists do not retroactively reroll.
- New eligibility applies at next deterministic reward-generation checkpoint.

5) Mode option selected but incompatible with other selected option
- Both pass unlock profile checks, but final mode gate fails with `ERR_MODE_OPTION_CONFLICT`.

6) Composite key circular reference (authoring bug)
- Validation hard fail on catalog build.

7) Key renamed without migration
- Treated as unknown at runtime; blocked by content pipeline pre-ship.

8) Stale `expected_base_seq` on unlock write
- Commit rejects with `ERR_EXPECTED_SEQ_CONFLICT`; UOG reloads snapshot and re-evaluates without applying stale write assumptions.

9) Duplicate unlock event replay
- Same `event_id` is classified duplicate (`duplicate_event_ids`); no duplicate progression increment.

10) Partial write/fault injection during unlock mutation
- Reader observes either full pre-state or full post-state only; never mixed unlock/counter state.

11) Snapshot integrity/tamper failure
- Treat non-`base_set` keys as locked-safe, emit telemetry, and surface deterministic fallback reason.

12) Multi-device progression race on same profile
- One commit may win; conflicting writer must rebase from newer snapshot before eligibility is recomputed.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Card Data & Definitions | Upstream data provider | Hard | Provides per-card `unlock_key`; UOG returns eligibility for weighting/filtering. |
| Profile Progression Save | Upstream state provider | Hard | Provides canonical snapshot/commit/reconcile APIs with idempotency, atomicity, and seq-based conflict handling. |
| Reward Draft System | Downstream consumer | Hard | Calls UOG before candidate weighting; must exclude ineligible content. |
| Relics/Passive Modifiers | Downstream consumer | Soft in MVP, Hard post-MVP | Reuses unlock-key eligibility for relic pools. |
| Meta-Hub Investment | Downstream consumer | Soft in MVP, Hard post-MVP | Uses UOG for feature option unlocking. |
| UI (Hub/Map/Deck/Mode screens) | Downstream consumer | Hard | Needs lock state + reason codes + hint keys for readable gating UX. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `base_set_scope` | enum set | full_core_loop | minimal-full | Core loop blocked for new players | No progression sense if everything open |
| `optional_unlock_rate_target` | milestone cadence | 1 every 1-2 runs | 1/1 to 1/4 | Overload from too many unlocks | Progress feels stalled |
| `lock_visibility_default` | bool | true | false/true | Hidden content feels missing/confusing | UI clutter from too many locked items |
| `batch_eval_cache_ttl_sec` | int | 0 (event-driven invalidation) | 0-30 | Extra CPU if no cache | Stale eligibility after unlock |
| `mode_conflict_policy` | enum | strict_block | strict/warn | Invalid mode combos slip through | Too many blocked combinations |
| `unknown_key_runtime_policy` | enum | lock_and_log | lock_and_log/dev_open | Player sees inaccessible content | Risk of accidental bypass in release |

Low-grind governance:
- Knob changes must preserve `core_access_ratio(profile_new)=1.0`.
- Any proposal that lowers new-profile core access is design-review blocked for MVP.

## Visual/Audio Requirements

Visual:
- Locked items show lock badge + concise reason text.
- Temporarily ineligible items show context badge (for example: “Unavailable in current mode”).
- Newly unlocked options get one-time highlight pulse in hub/menu.

Audio:
- Soft positive sting on unlock acquisition.
- Subtle deny click on selecting locked option (non-punitive).
- No spammy repeated sounds during batch list refresh.

## UI Requirements

1) Explainable lock state
- Tooltip includes:
  - status (Locked / Unlocked / Temporarily Ineligible)
  - short reason
  - unlock hint text

2) Deterministic list behavior
- Sorting and grouping do not jump unpredictably after eligibility refresh.
- Locked-visible entries stay in stable order.

3) Mode setup guardrails
- Disabled toggles show conflict reason inline.
- If a selected option becomes invalid due to another selection, UI resolves deterministically (new selection rejected, old retained).

4) Deck/reward transparency
- Cards not eligible by `unlock_key` are absent from candidate offers.
- Optional debug overlay can show filtered-count telemetry (not required for player-facing mode).

## Acceptance Criteria

1) Contract correctness
- 100% of content records with `unlock_key` resolve against Unlock Catalog in CI.

2) Card Data alignment
- Reward generation never offers cards with unmet `unlock_key`.
- `A_unlock` observed as binary {0,1} only.

3) Low-grind baseline
- New profile can access complete core loop content required for fun evaluation without extra runs.

4) Determinism
- Given same profile snapshot + same run/mode context + same content set, eligibility output is identical.

5) Explainability
- Every ineligible result includes at least one reason code and one UI hint key.

6) Save integration safety
- If profile save read or integrity check fails, system remains playable with `base_set` and deterministic lock behavior for non-base keys.

7) Idempotent write handling
- Replayed unlock writes with identical `event_id` produce `duplicate_noop` and never duplicate counters/flags.

8) Concurrency conflict handling
- Writes with stale `expected_base_seq` are rejected with `ERR_EXPECTED_SEQ_CONFLICT`; no stale snapshot overwrite occurs.

9) Atomicity under fault injection
- Unlock writes are all-or-nothing; tests never observe partial writes.

10) Performance
- Batch eligibility evaluation for 500 keys completes within 2 ms on target desktop browser hardware (excluding I/O).

11) Validation safety
- Composite key cycles and unknown key references are caught pre-runtime in content validation.

12) Multi-device race determinism
- Concurrent progression updates from multiple devices converge deterministically by commit order with no unlock regression.

## Telemetry & Debug Hooks (Optional)

Emit counters:
- `uog_eval_calls_total`
- `uog_eval_batch_size_histogram`
- `uog_locked_reason_code_count{reason}`
- `uog_unknown_key_runtime_count`
- `uog_profile_fallback_count`

Debug commands (dev only):
- Force-unlock key
- Force-lock key
- Dump eligibility matrix for current profile/run/mode

## Open Questions

1) Should MVP support per-class/profile-track unlock variants, or global profile only?
2) Should temporarily ineligible-but-unlocked entries be shown by default in reward-previews?
3) Which exact progression milestones should drive first optional archetype unlock cadence?
4) After Profile Progression Save GDD is authored, which provisional fields should be canonical vs removed?
5) Do we need a separate entitlement layer for external demo builds (press/demo profile presets)?
