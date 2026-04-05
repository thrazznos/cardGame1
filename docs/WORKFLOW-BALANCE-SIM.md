# Balance Simulator Workflow

This workflow runs deterministic combat simulations for card balance tuning and generates machine + human-readable reports.

## Prerequisites

- Godot executable available as `godot4`/`godot`, or set `GODOT_BIN`.
- Python 3.12 available as `python3`.
- Run commands from repository root.

## One-command pipeline

Use the pipeline runner to execute:
1) batch simulation
2) report aggregation
3) markdown rendering

Command:

```bash
python3 src/tools/balance/run_pipeline.py \
  --scenario res://tests/sim/scenarios/baseline_commons_v1.json \
  --output-dir artifacts/balance/reports/baseline_commons_v1
```

Outputs:
- `summary.json`
- `card_metrics.csv`
- `policy_compare.csv`
- `balance_report.md`

The runner also emits `BALANCE_PIPELINE_*` lines with exact paths.

## Running seed sweeps (100 / 1000 / 10000)

Edit the target scenario file `tests/sim/scenarios/*.json` and set `seeds` to the desired cardinality.

Examples:
- 100-run sweep: 100 seeds x 1 deck x 1 policy
- 1000-run sweep: 100 seeds x 2 decks x 5 policies
- 10000-run sweep: 250 seeds x 4 decks x 10 policies

Tip: Keep deterministic ordering in scenario JSON to make diffs/re-runs easy to compare.

## How to add a new card to scenario testing

1) Pick scenario file under `tests/sim/scenarios/`.
2) Add card id(s) to a deck’s `cards` list.
3) Optionally add a new deck entry for A/B comparisons.
4) Re-run pipeline and compare `card_metrics.csv` + markdown outliers.

Example deck block:

```json
{
  "deck_id": "my_test_deck",
  "cards": [
    "strike_01",
    "defend_01",
    "my_new_card_id"
  ]
}
```

## Report interpretation guide

## summary.json

Primary fields:
- `summary_kpis`: run count, win rate, turn distributions, mana usage distributions.
- `gem_engine_diagnostics`: produced/consumed counts, advanced/stability usage, FOCUS reject rate.
- `guardrails`: hard-fail and warning checks.

Guardrail interpretation:
- Hard fail (`status=fail`) blocks trust in the run for balance decisions.
  - `determinism_drift_count > 0` means same scenario/deck/seed/policy produced multiple hashes.
  - `unresolved_selector_ambiguity_count > 0` means selector ambiguity leaked through.
- Warnings (`status=warn`) mean tunable concerns, not invalid data.

## card_metrics.csv

Use for per-card triage:
- `plays`: volume signal.
- `avg_value_proxy_per_play`: rough floor/ceiling proxy.

Typical use:
- High plays + low value proxy: candidate buff or role clarification.
- Low plays + high value proxy: check if card is too conditional or too narrow.

## policy_compare.csv

Use to measure sequencing skill delta:
- Compare win rate and turn pace across `random_legal`, `greedy_value`, `sequencing_aware_v1`.
- Healthy signal: sequencing-aware should outperform random and often greedy on combo-oriented sets.

## balance_report.md

Designer-facing summary optimized for quick review:
- Set Health Summary
- Card Outliers
- Rarity Curve Health
- Gem Engine Diagnostics
- Guardrails
- Recommendations

## Recommended balancing loop

1) Modify card(s) or scenario deck composition.
2) Run one-command pipeline.
3) Read guardrails first.
4) Review outliers and policy delta.
5) Apply tuning adjustments.
6) Repeat with larger seed sweep before locking values.
