# Deck Power Distribution + Card Search Implementation Plan

> For Hermes: use strict TDD and implement in small commits from this plan.

Goal: add hard balancing scenarios where the starter deck fails, then quantify how win power changes as cards are added and deck order varies, producing a searchable power distribution for card tuning.

Architecture:
- Keep Godot combat simulation as source of truth.
- Extend scenario packs to express progression ladders (starter -> upgraded decks).
- Add a Python deck-order evaluator that runs many ordered deck variants through the existing simulation runner.
- Emit compact metrics used for candidate card search/ranking.

Tech stack: Godot headless scripts, Python 3.12 stdlib, unittest, JSON/CSV/Markdown.

---

## Problem framing

Current issue:
- Existing scenarios are too easy and always win.

Needed capability:
1) Include at least one "floor" scenario where the starter deck fails by construction.
2) Include progression scenarios where adding cards shifts win rate from near-zero toward partial and then strong viability.
3) Measure deck power as a distribution across deck orders, not just one fixed order.
4) Support future card search by ranking candidate additions by marginal power uplift.

---

## Deliverables

1) Hard scenario ladder pack:
- Starter fails.
- Mid-upgrade sometimes wins.
- Strong-upgrade wins frequently.

2) Order-distribution evaluator:
- Exact permutation mode for small decks.
- Sampled permutation mode for large decks.
- Outputs per-order run data + aggregate distribution summary.

3) Card-search-ready outputs:
- Marginal uplift table for candidate card additions.
- Rank by expected uplift and downside risk.

4) Docs/workflow update:
- How to run progression and order-distribution analysis.

---

## Canonical file map

Create:
- tests/sim/scenarios/power_ladder_v1.json
- src/tools/balance/deck_order_power_distribution.py
- src/tools/balance/card_search_ranker.py
- tests/sim/test_deck_power_distribution.py

Modify:
- tests/sim/test_balance_batch_smoke.py
- docs/WORKFLOW-BALANCE-SIM.md

Optional later (if needed):
- tests/sim/run_balance_batch.gd (scenario schema expansion hooks)

---

## Metrics to produce

Per order run:
- result (win/loss/timeout)
- turns_completed
- determinism_hash

Per deck aggregate:
- win_rate
- p10/p50/p90 win proxy (binary or score)
- mean turns
- loss_rate
- volatility index (stddev over binary win signal)

Card search aggregates:
- candidate_card_id
- baseline_win_rate
- candidate_win_rate
- uplift_mean
- uplift_p10
- uplift_p90
- downside_risk (probability candidate performs below baseline)

---

## Implementation tasks

### Task A: Hard ladder scenario pack
Objective: add scenario pack with starter fail floor and upgrade tiers.

Files:
- Create `tests/sim/scenarios/power_ladder_v1.json`
- Modify `tests/sim/test_balance_batch_smoke.py`

TDD steps:
1) Add failing test asserting scenario exists and has 3 ladder decks (`starter_floor`, `upgrade_mid`, `upgrade_high`).
2) Add failing behavioral test: run pipeline for this scenario and assert at least one deck has zero wins and at least one deck has non-zero wins.
3) Create scenario to satisfy tests.
4) Re-run tests and commit.

Commit message:
`test(sim): add hard power ladder scenario pack`

### Task B: Deck order power distribution tool
Objective: compute win distribution across order variants for a deck.

Files:
- Create `src/tools/balance/deck_order_power_distribution.py`
- Create `tests/sim/test_deck_power_distribution.py`

CLI:
- `--deck-json <path>` (list of card ids)
- `--policy-id <id>`
- `--seed-root <int>`
- `--max-turns <int>`
- `--mode exact|sample`
- `--sample-size <int>`
- `--max-orders <int>`
- `--output-dir <path>`

TDD steps:
1) RED: tests for exact mode on tiny deck (<=7 unique permutations) and sample mode reproducibility.
2) GREEN: implement permutation generation and deterministic sampler.
3) RED: tests for report files (`order_runs.jsonl`, `distribution_summary.json`).
4) GREEN: implement run orchestration via existing `run_balance_sim.gd` subprocess calls.
5) Run tests and commit.

Commit message:
`feat(balance): add deck order power distribution evaluator`

### Task C: Candidate card search ranker
Objective: rank candidate cards by uplift over baseline deck.

Files:
- Create `src/tools/balance/card_search_ranker.py`
- Modify `tests/sim/test_deck_power_distribution.py`

Inputs:
- baseline deck
- candidate card pool
- evaluation mode (exact/sample)
- per-candidate insertion strategy (append or replace index)

Outputs:
- `candidate_rankings.csv`
- `candidate_rankings.json`

TDD steps:
1) RED: test ranking file shape + deterministic ordering tie-break.
2) GREEN: implement baseline + candidate evaluation loop.
3) RED: test includes downside_risk and uplift quantiles.
4) GREEN: implement metrics.
5) Run tests and commit.

Commit message:
`feat(balance): add candidate card power uplift ranker`

### Task D: Workflow docs
Objective: document practical tuning loop for ladder + distribution + search.

Files:
- Modify `docs/WORKFLOW-BALANCE-SIM.md`

Must include:
- how to run power ladder
- how to run order distribution
- how to run candidate search
- how to interpret uplift and volatility

Commit message:
`docs(balance): add deck power distribution and card search workflow`

---

## Validation commands

- `python3 -m unittest tests.sim.test_balance_batch_smoke -v`
- `python3 -m unittest tests.sim.test_deck_power_distribution -v`
- `python3 -m unittest tests.sim.test_balance_report_metrics -v`
- `python3 -m unittest tests/determinism/test_fixture_compare.py -v`
- `python3 -m unittest tests/smoke/test_playable_prototype.py -v`

---

## Iteration checkpoints for user updates

Checkpoint 1:
- hard ladder scenario committed
- report proving starter floor fails

Checkpoint 2:
- order distribution tool committed
- one example deck distribution shared

Checkpoint 3:
- card search ranker committed
- first candidate ranking table shared

---

## Notes

- For combinatorics, use exact permutations only when total unique order count <= `max_orders`; otherwise switch to deterministic sampling.
- Keep outputs machine-readable first; markdown summaries remain optional for this phase.
- Prefer deterministic tie-breakers everywhere (card id lexical order, fixed seed for sampling).
