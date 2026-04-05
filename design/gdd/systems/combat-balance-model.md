# Combat Balance Model

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-04
> **Implements Pillars**: Sequencing Mastery Over Raw Stats; Compounding Value Every Turn; Readable Tactical Clarity; High Run Variety, Low Grind
> **Upstream References**: design/gdd/game-concept.md, design/gdd/systems/turn-state-rules-engine.md, design/gdd/systems/effect-resolution-pipeline.md, design/gdd/systems/mana-resource-economy.md, design/gdd/systems/enemy-encounters.md, design/gdd/card-data-definitions.md

## Overview

Combat Balance Model (CBM) is the meta-system that defines balance targets and tuning governance for combat in Dungeon Steward. CBM does not execute combat logic at runtime. Instead, it sets measurable envelopes and constraints that TSRE, ERP, MRE, EES, and Card Data content must satisfy.

CBM governs:
- encounter pacing targets (turns-to-win, turns-to-loss pressure, damage volatility),
- economy pace targets (spend velocity, refund/conversion prevalence, wasted mana),
- difficulty progression by floor/tier/encounter type,
- archetype viability bands (minimum and maximum expected win-rate spread),
- tuning workflow, validation fixtures, and release gates.

Design intent:
- Ensure a full run remains within 30-45 minutes for target-skill players.
- Reward sequencing skill over stat creep or grind.
- Keep outcomes deterministic and explainable while preserving variety.

Non-goals (MVP):
- Real-time adaptive difficulty that changes mid-combat.
- Hidden rubber-banding unreflected in event logs.
- Balancing through undocumented one-off overrides.

## Player Fantasy

Balance should make players feel:
- "My choices and sequencing matter more than raw luck or grind."
- "Hard fights feel fair because I can see what went wrong and improve."
- "Different deck lines are viable; I am not forced into one solved meta."

Emotional outcome:
- Tension without randomness abuse.
- Mastery through repeatable optimization.
- Confidence that system rules are consistent across runs.

## Detailed Design

### Core Rules

1) CBM is policy, not simulation authority
- Runtime authority remains with TSRE/ERP/MRE/EES.
- CBM provides target ranges and pass/fail thresholds consumed by balancing tools and CI fixtures.

2) Deterministic balance evaluation
- All balance validation uses deterministic replay fixtures (seed + snapshot + input script).
- KPI calculations must be reproducible byte-for-byte from authoritative event logs.

3) Multi-layer pacing envelopes
- Balance is evaluated at three layers:
  - Turn Layer (single-turn burst/survival windows)
  - Encounter Layer (normal/elite/boss pacing)
  - Run Layer (30-45 minute session pacing and attrition profile)

4) Hard vs soft constraints
- Hard constraints: violation is release-blocking (for example deterministic drift, infinite loops, illegal contract usage).
- Soft constraints: warning-tier and tracked over test windows (for example archetype spread slightly outside target band).

5) Skill-first balance objective
- Primary objective is decision leverage: correct sequencing should materially outperform random legal play at equal deck quality.
- Baseline target: expert-policy simulation must outperform random-policy simulation by configured margin in each encounter tier.

6) Contract compliance is mandatory
- Card costs and sequencing keys must follow Card Data schema (`base_cost`, `cost_type`, `speed_class`, `timing_window`, `effects[]`).
- Resource pacing must respect MRE rules (commit-time spend, refund caps, gain caps, overcharge expiry).
- Enemy pressure must respect EES telegraphing and deterministic intent contracts.
- Resolution pacing must respect ERP anti-loop caps and deterministic order semantics.

7) Browser-first performance envelope
- Balance simulations and runtime telemetry checks must assume browser constraints and TSRE guardrails.
- No balance target may require breaking existing per-turn resolve/item caps.

8) Explainability-first
- Any balance intervention (knob changes, profile swaps) must map to named reason tags and changelog entry.
- No undocumented silent tuning in shipped builds.

### Balance Data Model and Contracts

Balance Profile (`balance_profile_id`) minimum schema:
- `profile_version`
- `target_skill_band` (`new`, `core`, `expert`)
- `run_pacing_targets`
- `encounter_pacing_targets`
- `economy_targets`
- `difficulty_scalars`
- `archetype_viability_targets`
- `guardrail_limits`
- `metric_eval_window`

Encounter pacing target block:
- `ttv_target_turns` (time-to-victory)
- `ttd_floor_turns` (minimum turns before expected defeat under poor lines)
- `incoming_damage_band`
- `burst_window_cap`
- `stall_turn_threshold`

Economy target block:
- `avg_mana_spend_turn`
- `wasted_mana_rate`
- `refund_share_cap`
- `conversion_share_cap`
- `cost_reduction_uptime_cap`

Archetype viability block:
- `min_win_rate`, `max_win_rate`
- `max_delta_vs_global`
- `sample_floor`
- `confidence_floor`

Contract policy:
- CBM may only tune through exposed knobs from TSRE/ERP/MRE/EES/content weights.
- CBM cannot introduce fields that violate upstream schemas.

### States and Transitions

CBM lifecycle states (tooling and governance state):
- BaselineDefined
- InstrumentationActive
- DataIngested
- ModelFit
- TuningProposed
- SimulationValidated
- PlaytestValidated
- ApprovedForRelease
- PostReleaseObserved

Primary transitions:
- BaselineDefined -> InstrumentationActive (metrics schema approved)
- InstrumentationActive -> DataIngested (minimum sample reached)
- DataIngested -> ModelFit (clean deterministic replay set available)
- ModelFit -> TuningProposed (drift/imbalance detected)
- TuningProposed -> SimulationValidated (fixtures pass)
- SimulationValidated -> PlaytestValidated (human readability/fairness check)
- PlaytestValidated -> ApprovedForRelease (release gate pass)
- ApprovedForRelease -> PostReleaseObserved (live telemetry window)
- PostReleaseObserved -> TuningProposed (if drift threshold breached)

Illegal transitions:
- BaselineDefined -> ApprovedForRelease (skip validation)
- TuningProposed -> ApprovedForRelease (skip simulation/playtest)
- SimulationValidated -> ApprovedForRelease (skip playtest)

### Interactions with Other Systems

1) Turn State & Rules Engine (hard)
- CBM consumes TSRE metrics:
  - turn count, queue depth, action-cap hits, resolve-budget hits, phase durations.
- CBM tunes only allowed TSRE knobs (`AP_base`, `AP_max`, action cap, resolve budget safe ranges).

2) Effect Resolution Pipeline (hard)
- CBM consumes ERP metrics:
  - per-item op counts, replacement/cap hits, clamp frequencies, fizzle rates.
- CBM constrains burst and loop potential by setting acceptable guardrail hit rates.

3) Mana & Resource Economy (hard)
- CBM consumes MRE ledger-derived metrics:
  - spend/gain/refund/conversion rates, wasted mana, cap-hit frequencies.
- CBM tuning respects commit-time spend and explicit refund semantics.

4) Enemy Encounter System (hard)
- CBM consumes EES telemetry:
  - intent pressure profiles, telegraph certainty usage, reinforcement frequency, enrage activation turns.
- CBM sets encounter-type pacing envelopes used to adjust threat budgets/scalars safely.

5) Card Data & Definitions (hard)
- CBM consumes card-level aggregates:
  - play rate, pick rate, win contribution, sequencing leverage, dead-draw incidence.
- Card tuning must remain schema-compliant (no hidden runtime exceptions).

6) Deck Lifecycle System (adjacent)
- CBM tracks draw consistency and hand clog metrics that influence pacing and agency.
- CBM does not directly mutate zone rules.

7) Combat UI/HUD and Telemetry (downstream)
- CBM requires reason-coded metric outputs and readable summaries for designers/QA.
- Balance patches must expose player-facing patch-note categories (economy, enemy pressure, card pacing).

## Formulas

Notation:
- `clamp(x,a,b) = min(max(x,a),b)`
- All KPI calculations use deterministic integer/fixed-point source values.

1) Encounter Time-to-Victory (TTV)

`TTV_encounter = turns_until_enemy_team_hp_zero`

Target bands (core skill):
- Normal: `4 <= TTV <= 7`
- Elite: `6 <= TTV <= 10`
- Boss: `8 <= TTV <= 14`

Failure behavior:
- Outside band for >= `TTV_BREACH_RATE_MAX` share of fixtures flags pacing breach.
- MVP default: `TTV_BREACH_RATE_MAX = 0.10`.

2) Encounter Time-to-Defeat Floor (TTD_floor)

`TTD_floor = turns_until_player_hp_zero under low-synergy legal baseline policy`

Targets:
- Normal >= 3
- Elite >= 4
- Boss >= 5

Rationale: prevents unavoidable spike losses while preserving pressure.

3) Resource Velocity Score

`RVS = (mana_spent_total + overcharge_spent_total + substitute_spend_equivalent) / turns_player_active`

Target (core skill):
- `RVS_target = 2.3` with acceptable band `[1.8, 2.9]`

Linked constraints:
- `wasted_mana_rate <= 0.28`
- `refund_share = refunds_total / mana_spent_total <= 0.22`

4) Burst Volatility Index

`BVI = p95(player_damage_taken_per_turn) / max(1, median(player_damage_taken_per_turn))`

Target band:
- Normal/Elite: `BVI <= 2.8`
- Boss: `BVI <= 3.4`

Too high indicates unfair spike patterns; too low indicates flat/boring pacing.

5) Sequencing Skill Delta

`SSD = win_rate(expert_policy) - win_rate(random_legal_policy)`

Minimum targets by encounter type:
- Normal >= 0.20
- Elite >= 0.25
- Boss >= 0.18

Interpretation: sequencing mastery must produce meaningful gain.

6) Archetype Spread Constraint

For each archetype `a` with sufficient samples:
`delta_a = win_rate(a) - global_win_rate`

Constraint:
`ARCH_MIN_DELTA <= delta_a <= ARCH_MAX_DELTA`

MVP defaults:
- `ARCH_MIN_DELTA = -0.08`
- `ARCH_MAX_DELTA = +0.08`

7) Run Duration Estimate

`run_minutes_est = Σ(encounter_turns_i * sec_per_turn_est + transition_sec_i + reward_sec_i) / 60`

MVP target band:
- `30 <= run_minutes_est <= 45` at core skill profile.

8) Determinism Compliance Rate

`DCR = deterministic_replay_passes / total_replay_runs`

Release requirement:
- `DCR = 1.0` for gated fixture suite.

## Edge Cases

All rows below are mandatory QA fixtures with fixed seeds and explicit telemetry assertions.

| ID | Scenario | Expected Balance Result | Deterministic Replay Metric | Browser/Perf Telemetry Check | Exploit Prevention Check |
|---|---|---|---|---|---|
| CBM-EC-001 | Encounter appears healthy in aggregate but has extreme first-turn lethality | Fails opener fairness gate even if average TTV passes | `first_turn_state_hash_match=100%` across reruns | `long_task_ms_max` variance cannot change opener outcome | No input spam can alter opener ordering |
| CBM-EC-002 | High win rate driven by a low-frequency exploit line | Contribution decomposition flags and fails exploit concentration threshold | `line_replay_parity=100%` for flagged line seeds | `queue_depth`/`cap_hit_rate` correlated with exploit signature | No repeated submit or timing abuse can increase exploit trigger rate |
| CBM-EC-003 | Low-sample archetype appears overpowered | Tagged provisional; no live nerf until confidence floor met | `metric_snapshot_match=100%` | Sample metadata (`n`, confidence) emitted per segment | Prevents manipulation via tiny sample spike |
| CBM-EC-004 | Cross-system knob conflict (refund down + enemy damage up) | Combined run fails if TTD floor is breached in any tier | `combined_fixture_hash_match=100%` | Cross-browser outcome parity required for combined profile | No hidden override can bypass conflict gate |
| CBM-EC-005 | Deterministic replay mismatch only on one browser | Release-block on affected profile; divergence triaged by first mismatch index | `cross_browser_hash_match=100%` | Browser-tagged divergence dashboard populated | No browser-specific balance advantage ships |
| CBM-EC-006 | Boss TTV passes but readability degrades due to mutation/fizzle spam | Fails readability gate despite numeric pass | `reason_code_seq_match=100%` | `events_per_turn` and `fizzle_rate` tracked vs threshold | Prevents “opaque but strong” exploit patterns |
| CBM-EC-007 | Action-cap/resolve-budget caps frequently force early turns | Counted as pacing failure and tuning regression | `failsafe_turn_end_replay_match=100%` | `ERR_TURN_CPU_BUDGET` and budget-cap rate segmented by tier | No lag-induced forced-end advantage |
| CBM-EC-008 | Nerf fixes expert outlier but collapses new/core success | Fails skill-band protection if new/core floor violated | `skill_band_fixture_match=100%` | KPI drift by skill band and perf tier visible | Prevents exploit by overfitting expert-only telemetry |
| CBM-EC-009 | Save/resume on same seed and script | Restored path matches uninterrupted path exactly | `checkpoint_hash_match=100%` | Resume latency recorded, outcome invariant | No save-scum reroll on same seed |
| CBM-EC-010 | Background tab throttling during heavy chain | Identical winner/turn count/final HP tuple vs foreground | `background_vs_foreground_hash_match=100%` | `tab_visibility_state` segmented drift report | No slowdown-to-survive exploit |
| CBM-EC-011 | Long-task injection (>200ms stalls) mid resolve | Identical deterministic outcomes; only wall-clock changes | `stall_fixture_hash_match=100%` | `long_task_bucket` vs KPI drift <= thresholds | No stall-induced RNG/order manipulation |
| CBM-EC-012 | Queue hard-limit saturation | Deterministic reject of newest enqueue; no reorder | `overflow_decision_match=100%` | `queue_depth_p99`, overflow counts emitted | No overflow reorder exploit |

## Dependencies

Hard upstream dependencies:
- Turn State & Rules Engine (phase/order/per-turn caps metrics)
- Effect Resolution Pipeline (operation-level outcome metrics)
- Mana & Resource Economy (resource ledger and economy counters)
- Enemy Encounter System (intent pressure and scaling telemetry)
- Card Data & Definitions (content taxonomy and card-level analytics keys)

Hard-adjacent dependencies:
- Deck Lifecycle System (draw/hand-flow pacing metrics)
- RNG/Seed service (replay reproducibility)

Downstream dependents:
- Content tuning pipeline (cards/enemies/relics)
- Difficulty profiles
- Patch notes and balance dashboards
- QA replay suite and regression gates

Integration contract (MVP analytics-level):
- `collect_balance_frame(combat_id, turn_index)`
  - output: normalized metrics frame keyed by deterministic IDs.
- `evaluate_balance_profile(balance_profile_id, fixture_bundle_id)`
  - output: pass/fail + breached constraints + confidence stats.
- `propose_tuning_delta(balance_profile_id, knob_changes[])`
  - output: projected KPI movement with uncertainty band.

## Tuning Knobs

| Knob | System Owner | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---|---:|---|---|---|
| `AP_base` | TSRE/MRE | int | 3 | 2-4 | Slow, low-agency turns | Burst-heavy openers |
| `AP_max` | TSRE/MRE | int | 6 | 4-8 | Late turns feel capped | Combo bloat, long turns |
| `ACT_base` | TSRE | int | 12 | 8-16 | Inputs feel constrained | Spam/rope turns |
| `RES_base` | TSRE/ERP | int | 128 | 96-192 | Legit chains clipped | Browser/perf risk |
| `REFUND_CAP_PER_TURN` | MRE | int | 6 | 3-12 | Rebate archetypes weak | Pseudo-infinite turns |
| `NET_MANA_GAIN_CAP_TURN` | MRE | int | 12 | 8-20 | Compounding feels muted | Loop exploit window |
| `B_floor_ramp` | EES | int | 12 | 8-18 | Flat progression | Late-floor walls |
| `S_floor_mult` | EES | float | 0.035 | 0.02-0.06 | Weak enemy scaling | Stat inflation spikes |
| `ENRAGE_START_TURN` | EES | int | 12 | 8-16 | Stall metas persist | Excess anti-control punishment |
| `damage_op_cap` | ERP | int | 9999 | 1999-19999 | Big effects feel flat | Lethal spikes + volatility |
| `status_stacks_cap_default` | ERP | int | 99 | 20-999 | Synergy suppression | Runaway scaling |
| `weight_base` distributions | Card Data | float | 1.0 | 0.1-5.0 | Build options narrow | Dominant card spam |

Governance:
- Multi-knob changes require interaction simulation, not isolated A/B reads.
- Any out-of-safe-range change requires explicit design waiver and replay/perf signoff.

## Visual/Audio Requirements

Visual requirements (balance-facing surfaces):
- Designer dashboard heatmaps for TTV/TTD bands by encounter type and floor.
- Spike timeline view showing damage/resource deltas per turn with cap-hit markers.
- Archetype spread chart with confidence intervals and sample counts.
- Determinism compliance panel (pass/fail by browser target).

Audio requirements (player-facing balance cues):
- Distinct warning mix for high-threat telegraphed burst turns (no false alarms).
- Guardrail/cap-hit SFX should remain subtle and non-fatiguing during long chain turns.
- Boss pressure escalation cue must be audible but not masking core action clarity.

Presentation data contract:
- `balance_event_id`, `category`, `severity`, `metric_key`, `value`, `target_band`, `reason_code`, `source_system`.

## UI Requirements

1) Internal Balance Console (dev/QA)
- Shows profile selection, fixture bundle, pass/fail summary, and breached constraints.
- Supports drill-down from run-level KPI -> encounter -> turn -> event stream.

2) KPI Comparison View
- Side-by-side baseline vs candidate tuning with absolute and percentage deltas.
- Highlights regressions against protected goals (session length, fairness floors, determinism).

3) Exploit Detector Panel
- Flags abnormal loop signatures (refund/conversion concentration, repeated replacement caps).
- Links directly to deterministic replay ID and seed.

4) Player-Facing Patch Notes Mapping
- Every shipped knob change maps to human-readable categories:
  - pacing, economy, enemy pressure, card consistency, bugfix.

5) Accessibility/Readability QA hooks
- UI validates that major balance-impact events have readable reason strings.
- No release if key reason code coverage is incomplete.

## Acceptance Criteria

1) Session pacing
- Core-skill full-run estimate remains within 30-45 minutes across approved fixture set.

2) Deterministic replay gates (release blocking)
- Nightly corpus minimum: 50,000 seeded combat replays.
- `final_state_hash_match_rate = 100%`.
- `event_sequence_exact_match_rate = 100%`.
- `rng_cursor_exact_match_rate = 100%` for non-corrupt fixtures.
- Any divergence in ranked-critical fixtures is P0.

3) Browser parity
- Supported matrix: Chrome Stable and Firefox Stable on baseline hardware profile.
- Per archetype/matchup win-rate drift by browser: `abs(delta) <= 0.5pp`.
- Median turn-count drift by browser: `<= 0.2 turns`.
- eDPT drift by browser: `<= 1.0%`.

4) Performance-related balance invariance
- Under synthetic long-task injection and background-tab throttling, deterministic fixtures must preserve winner, turn count, and final HP tuple.
- Forced fail-safe events (`ERR_TURN_CPU_BUDGET`, `ERR_RESOLVE_BUDGET_EXHAUSTED`) <= 0.1% in non-loop fixtures.
- Degrade mode toggles must not change authoritative outcome metrics.

5) Encounter/economy/skill compliance
- >= 90% of encounters fall inside TTV target bands per type.
- 100% satisfy TTD floor constraints for baseline policy.
- `RVS` remains inside target band; `wasted_mana_rate`, `refund_share`, and gain-cap hit rates stay inside configured limits.
- `SSD` meets minimum thresholds for normal/elite/boss fixtures.

6) Archetype viability
- No supported archetype exceeds ±8 percentage points from global win rate after confidence floor.
- No skill band (`new`, `core`, `expert`) violates declared minimum win-rate floor after candidate tuning.

7) Readability/fairness/exploit prevention
- No telegraph-breaking enemy behavior without reason event.
- No hidden balance override outside documented profile config.
- Duplicate commit acceptance count = 0.
- Queue overflow reorder incidents = 0.
- Same-seed save/resume reroll incidents = 0.

8) Guardrail health
- Anti-loop and cap systems prevent non-terminating turns in all exploit regression fixtures.
- Frequent cap-forced early turns are treated as pacing failures and must remain below threshold.

9) Telemetry completeness
- Required combat-balance telemetry fields present in >= 99.9% of completed combats.
- Missing deterministic core fields (`seed_id`, `rng_cursor_final`, `state_hash_final`) < 0.01%.

10) Release governance
- Every balance patch includes:
  - knob diff,
  - KPI impact summary,
  - replay fixture pass report,
  - browser parity report,
  - perf-drift report,
  - explicit waiver list (if any).

## QA Instrumentation Plan

### 1) Event Schema

Emit canonical `combat_balance_event` envelope.

Required identity fields:
- `combat_id`, `build_id`, `ruleset_version`, `content_version`, `balance_profile_id`, `mode`.

Required environment fields:
- `browser_family`, `browser_version`, `device_perf_tier`, `tab_visibility_state`.

Required deterministic fields:
- `seed_id`, `turn_index`, `resolve_item_index`, `order_key`,
- `rng_cursor_before`, `rng_cursor_after`,
- `state_hash_before`, `state_hash_after`,
- `reason_code`.

Required balance fields:
- `hp_player`, `hp_enemy`,
- `shield_player`, `shield_enemy`,
- `resource_player`, `resource_enemy`,
- `damage_dealt_this_item`, `healing_done_this_item`,
- `queue_depth`, `caps_triggered[]`,
- `ttv_projection`, `ttd_projection`, `archetype_tag`.

Required performance fields:
- `resolve_step_cpu_ms`, `turn_cpu_ms`, `long_task_ms_max`, `degrade_mode_on`.

### 2) Deterministic Replay Metrics

Per replay store:
- `replay_hash_match` (bool)
- `replay_event_seq_match` (bool)
- `replay_rng_cursor_match` (bool)
- `first_divergence_turn`
- `first_divergence_resolve_item`
- `first_divergence_reason_code`

Dashboards:
- Divergence rate by `build_id`, `browser_family`, `device_perf_tier`, and fixture bundle.
- Top divergence fixtures with direct seed links.
- Heatmap for divergence density by turn index and queue depth.

Alerts:
- Hash-match < 100% on nightly rolling window.
- Any ranked-critical fixture divergence.
- Any browser-specific deterministic failure cluster.

### 3) Browser Performance-Related Balance Telemetry

Derived KPI segments:
- `kpi_drift_by_perf_tier` (win-rate, TTV, eDPT, turn count)
- `kpi_drift_by_long_task_bucket` (0, 1-50ms, 51-200ms, >200ms)
- `background_tab_bias`
- `degrade_mode_bias`

Alert thresholds:
- Win-rate drift low-tier vs baseline > 1.0pp over >= 5,000 combats.
- TTV drift > 0.3 turns.
- eDPT drift > 1.0%.
- Non-zero deterministic outcome drift in synthetic stall fixtures.

### 4) Exploit Instrumentation

Track and alert on:
- duplicate submit attempts and accepted duplicate count,
- resolve-lock mutation attempts,
- queue overflow rejects and reorder anomalies,
- loop-cap hits per source and per turn,
- same-seed save/resume attempts,
- local clock/timezone changes during active combat.

Daily anti-abuse report:
- top sessions by spam rate,
- correlation of abnormal performance signatures with outcome deltas,
- suspected seed-reroll patterns.

### 5) QA Cadence and Gates

Per PR:
- 2,000 deterministic replays,
- 200 cross-browser parity fixtures,
- exploit regression subset must pass 100%.

Nightly:
- 50,000 replay corpus,
- synthetic long-task and background-tab perturbation suite,
- drift segmentation by browser and perf tier.

Pre-release:
- 200,000 replay soak,
- pinned browser matrix certification,
- manual triage of top divergence and drift buckets.

Triage workflow on failure:
1) Auto-file issue with seed, fixture id, build id, and first divergence marker.
2) Classify root cause: deterministic defect, content-tuning defect, perf-induced skew, exploit path.
3) Apply release block for deterministic critical failures and perf-induced winner drift breaches.
4) Require fix + regression fixture + backfilled replay evidence.

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Should CBM target separate pacing bands for "new" vs "core" skill in MVP, or only core? | Combat Design | Sprint 2 | Open |
| What minimum sample size/confidence is required before shipping archetype nerfs/buffs? | Data + Design | Sprint 2 | Open |
| Should boss encounters intentionally exceed 45-minute run pace in rare challenge seeds, or stay hard-capped? | Design Director | Pre-alpha | Open |
| How much of balance telemetry (for example cap hits, mutation rates) should be surfaced to players vs kept internal? | UX + Design | Vertical Slice | Open |
| Do we need profile-specific balance presets for accessibility modes while preserving deterministic replay categories? | Systems + UX | Vertical Slice | Open |
| Should exploit detector thresholds be static or percentile-based per content season? | Live Ops/Design (future) | Alpha planning | Open |