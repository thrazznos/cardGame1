# Card Balance Simulator Implementation Plan

> For Hermes: Use subagent-driven-development skill to implement this plan task-by-task.

Goal: Build a deterministic simulator pipeline that evaluates card sets (especially Gem Stack Machine cards) and outputs actionable balance reports with statistical summaries.

Architecture: Reuse existing headless Godot combat runtime for simulation truth, add deterministic policy-driven run orchestration, then aggregate JSON/JSONL artifacts in Python into designer-facing markdown and CSV reports. Keep runtime logic authoritative; analytics layer is pure post-processing.

Tech Stack: Godot 4.6 headless scripts (GDScript), Python 3.12 (stdlib only), unittest, JSON/CSV/Markdown artifacts.

---

## Scope and non-goals

In scope (MVP):
- Single-run deterministic simulation harness.
- Batch execution over seeds/decks/enemy profiles.
- Policy pluggability (random_legal, greedy_value, sequencing_aware_v1).
- Balance report generation with mean/p50/p95 and confidence intervals.
- Gem-stack-specific diagnostics and card outlier detection.

Out of scope (MVP):
- Real-time UI dashboard.
- ML-based policy training.
- Remote/distributed execution.

---

## Canonical file map

Create:
- tests/sim/run_balance_sim.gd
- tests/sim/run_balance_batch.gd
- tests/sim/policies/policy_random_legal.gd
- tests/sim/policies/policy_greedy_value.gd
- tests/sim/policies/policy_sequencing_aware_v1.gd
- tests/sim/scenarios/baseline_commons_v1.json
- tests/sim/scenarios/mixed_rarity_v1.json
- tests/sim/scenarios/gem_stress_v1.json
- src/tools/balance/aggregate_reports.py
- src/tools/balance/render_markdown_report.py
- src/tools/balance/report_utils.py
- tests/sim/test_balance_sim_smoke.py
- tests/sim/test_balance_batch_smoke.py
- tests/sim/test_balance_report_metrics.py

Modify:
- src/tools/godot_test_runner.py (only if helper hooks are needed for invoking new scripts)

Artifact outputs:
- artifacts/balance/raw/*.jsonl
- artifacts/balance/reports/*.json
- artifacts/balance/reports/*.csv
- artifacts/balance/reports/*.md

---

## Data contracts

### Simulation input schema (JSON)
- simulation_id: string
- seed_root: int
- deck_list: string[]
- enemy_profile_id: string
- policy_id: string
- balance_profile_id: string
- max_turns: int

### Per-run output schema (JSON line)
- simulation_id, seed_root, policy_id, enemy_profile_id
- result: win|loss|timeout
- turns_completed
- player_hp_end, enemy_hp_end
- mana_spent_total, mana_wasted_total
- gems_produced_total, gems_consumed_total
- advanced_ops_total, stability_ops_total
- focus_gate_rejects
- card_play_counts: {card_id: int}
- card_effect_value_proxy: {card_id: float}
- event_count
- determinism_hash

### Aggregate report schema
- summary_kpis
- card_outliers_over
- card_outliers_under
- rarity_curve_health
- gem_engine_diagnostics
- policy_comparison
- confidence_notes

---

## Implementation tasks

### Task 1: Create simulator directories and placeholders
Objective: Establish stable file structure before behavior.

Files:
- Create: tests/sim/, src/tools/balance/
- Create: empty target files listed in canonical file map

Step 1: Create directories and placeholder files.
Step 2: Run `python3 -m unittest -v` and confirm no import-side breakages.
Step 3: Commit.

Suggested commit:
`chore(sim): scaffold balance simulator file structure`

### Task 2: Implement single-run harness shell
Objective: Add `run_balance_sim.gd` that accepts JSON input and emits one JSON result line.

Files:
- Create: tests/sim/run_balance_sim.gd
- Modify: src/tools/godot_test_runner.py (if helper command wiring is needed)

Step 1: Write failing smoke test in `tests/sim/test_balance_sim_smoke.py` expecting `BALANCE_SIM_REPORT=` output.
Step 2: Run test and verify fail.
Step 3: Implement minimal script that loads combat scene, executes one policy step loop, prints report.
Step 4: Run test and verify pass.
Step 5: Commit.

Suggested commit:
`feat(sim): add single-run balance simulation harness`

### Task 3: Determinism assertion for single-run
Objective: Ensure same input+seed => identical determinism hash.

Files:
- Modify: tests/sim/test_balance_sim_smoke.py
- Modify: tests/sim/run_balance_sim.gd

Step 1: Add failing test that runs same payload twice and compares hash + key fields.
Step 2: Make harness include deterministic hash of canonical report subset.
Step 3: Re-run tests to green.
Step 4: Commit.

Suggested commit:
`test(sim): enforce deterministic single-run output`

### Task 4: Implement policy interface and random policy
Objective: Introduce pluggable policy contract with first policy.

Files:
- Create: tests/sim/policies/policy_random_legal.gd
- Modify: tests/sim/run_balance_sim.gd

Contract:
- `choose_action(view_model: Dictionary) -> Dictionary`

Step 1: Add failing test that policy id `random_legal` is loadable.
Step 2: Implement load/dispatch + random legal selection.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(sim): add policy interface and random_legal policy`

### Task 5: Implement greedy_value policy
Objective: Add deterministic heuristic policy for baseline comparison.

Files:
- Create: tests/sim/policies/policy_greedy_value.gd
- Modify: tests/sim/run_balance_sim.gd

Heuristic v1:
- Prefer legal card with highest immediate value proxy (damage+block weighted).

Step 1: Add failing policy-load test.
Step 2: Implement policy and deterministic tie-breakers.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(sim): add greedy_value policy`

### Task 6: Implement sequencing_aware_v1 policy
Objective: Add gem-stack-aware policy for skill-delta comparisons.

Files:
- Create: tests/sim/policies/policy_sequencing_aware_v1.gd
- Modify: tests/sim/run_balance_sim.gd

Heuristic v1:
- Score actions by projected top-2 stack utility + fallback floor.
- Prefer FOCUS-gated advanced only when legal and expected value exceeds hybrid fallback threshold.

Step 1: Add failing load/invocation test.
Step 2: Implement policy with stable tie-break order.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(sim): add sequencing_aware_v1 policy`

### Task 7: Implement batch runner
Objective: Execute matrix jobs (seed x scenario x policy) and write JSONL.

Files:
- Create: tests/sim/run_balance_batch.gd
- Create: tests/sim/test_balance_batch_smoke.py

Step 1: Add failing smoke test expecting raw JSONL artifact.
Step 2: Implement batch loop with deterministic job ordering.
Step 3: Output `artifacts/balance/raw/<timestamp>_batch.jsonl`.
Step 4: Pass tests.
Step 5: Commit.

Suggested commit:
`feat(sim): add batch simulation runner`

### Task 8: Add scenario packs
Objective: Seed realistic test matrices for balancing sessions.

Files:
- Create: tests/sim/scenarios/baseline_commons_v1.json
- Create: tests/sim/scenarios/mixed_rarity_v1.json
- Create: tests/sim/scenarios/gem_stress_v1.json

Step 1: Add schema validation test for scenarios.
Step 2: Author scenario files with deck lists/policies/seeds.
Step 3: Run tests.
Step 4: Commit.

Suggested commit:
`test(sim): add baseline scenario packs`

### Task 9: Build report utility functions
Objective: Add Python utilities for parsing, grouping, and percentile stats.

Files:
- Create: src/tools/balance/report_utils.py
- Create: tests/sim/test_balance_report_metrics.py

Step 1: Write failing unit tests for mean/p50/p95 and simple CI estimate.
Step 2: Implement utilities using stdlib.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(balance): add report utility stats helpers`

### Task 10: Implement aggregate report generator
Objective: Convert raw JSONL into normalized summary JSON/CSV.

Files:
- Create: src/tools/balance/aggregate_reports.py
- Modify: tests/sim/test_balance_report_metrics.py

Outputs:
- `summary.json`
- `card_metrics.csv`
- `policy_compare.csv`

Step 1: Add failing integration test over fixture JSONL.
Step 2: Implement aggregator with:
- TTV/TTD style metrics
- gem family usage rates
- card outlier lists
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(balance): aggregate raw sim artifacts into KPI reports`

### Task 11: Implement markdown report rendering
Objective: Produce designer-readable report narrative.

Files:
- Create: src/tools/balance/render_markdown_report.py
- Modify: tests/sim/test_balance_report_metrics.py

Sections:
- Set Health Summary
- Card Outliers
- Rarity Curve Health
- Gem Engine Diagnostics
- Recommendations

Step 1: Add failing test that markdown file includes required headings.
Step 2: Implement renderer.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(balance): render human-readable markdown balance report`

### Task 12: Add end-to-end command scripts
Objective: One-command local run for designers.

Files:
- Modify/Create: scripts optional under src/tools/balance/ (or documented commands only)
- Modify: docs/plans/2026-04-05-card-balance-simulator.md (usage block)

Command target:
1) run batch
2) aggregate
3) render markdown

Step 1: Add smoke test for command chain on tiny scenario.
Step 2: Implement command chain.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`chore(balance): add one-command local simulation pipeline`

### Task 13: Guardrails and thresholds
Objective: Encode hard-fail and warn thresholds from CBM + GSM docs.

Files:
- Modify: src/tools/balance/aggregate_reports.py
- Modify: src/tools/balance/render_markdown_report.py
- Modify: tests/sim/test_balance_report_metrics.py

Hard-fail examples:
- determinism drift > 0
- unresolved selector ambiguity > 0

Warn examples:
- producer baseline split out-of-band
- rare spike index above cap

Step 1: Add failing threshold tests.
Step 2: Implement flags in outputs.
Step 3: Pass tests.
Step 4: Commit.

Suggested commit:
`feat(balance): enforce simulator guardrails and threshold flags`

### Task 14: Documentation and handoff
Objective: Add operator docs for design sessions.

Files:
- Create: docs/WORKFLOW-BALANCE-SIM.md
- Modify: README.md (link section)

Must document:
- how to add a new card to scenarios
- how to run 100/1000/10000 seed sweeps
- how to interpret outlier and confidence sections

Step 1: Write docs.
Step 2: Verify commands from clean checkout.
Step 3: Commit.

Suggested commit:
`docs(balance): add simulator workflow and reporting guide`

---

## Test commands

Single suite checks:
- `python3 -m unittest tests.sim.test_balance_sim_smoke -v`
- `python3 -m unittest tests.sim.test_balance_batch_smoke -v`
- `python3 -m unittest tests.sim.test_balance_report_metrics -v`

Full relevant checks:
- `python3 -m unittest tests/smoke/test_playable_prototype.py -v`
- `python3 -m unittest tests/determinism/test_fixture_compare.py -v`

---

## Milestones

M1 (single-run deterministic): Tasks 1-4
M2 (batch + policies): Tasks 5-8
M3 (metrics + reports): Tasks 9-11
M4 (guardrails + docs): Tasks 12-14

---

## Initial success criteria

1) 1,000-run batch completes without nondeterministic hash drift.
2) Report includes per-card outlier table and gem-engine diagnostics.
3) Producer cards can be audited against target base/gem value split bands.
4) Policy comparison shows measurable sequencing skill delta.
5) Designers can run full pipeline from command line in one pass.
