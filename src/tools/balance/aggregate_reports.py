import argparse
import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

try:
    from src.tools.balance import report_utils
except ModuleNotFoundError:
    ROOT = Path(__file__).resolve().parents[3]
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from src.tools.balance import report_utils


def load_jsonl(path: Path) -> list[dict]:
    rows: list[dict] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))
    return rows


def build_card_metrics(rows: list[dict]) -> list[dict]:
    agg: dict[str, dict] = defaultdict(lambda: {"plays": 0, "total_value_proxy": 0.0, "run_appearances": 0})

    for row in rows:
        per_run_cards = set()
        counts = row.get("card_play_counts", {}) or {}
        values = row.get("card_effect_value_proxy", {}) or {}
        for card_id, play_count in counts.items():
            card_key = str(card_id)
            agg[card_key]["plays"] += int(play_count)
            per_run_cards.add(card_key)
        for card_id, total_value in values.items():
            card_key = str(card_id)
            agg[card_key]["total_value_proxy"] += float(total_value)
            per_run_cards.add(card_key)
        for card_key in per_run_cards:
            agg[card_key]["run_appearances"] += 1

    out: list[dict] = []
    for card_id in sorted(agg.keys()):
        row = agg[card_id]
        plays = int(row["plays"])
        total_value = float(row["total_value_proxy"])
        avg_value = 0.0 if plays <= 0 else total_value / plays
        out.append(
            {
                "card_id": card_id,
                "plays": plays,
                "run_appearances": int(row["run_appearances"]),
                "total_value_proxy": round(total_value, 4),
                "avg_value_proxy_per_play": round(avg_value, 4),
            }
        )
    return out


def build_policy_compare(rows: list[dict]) -> list[dict]:
    grouped: dict[str, list[dict]] = defaultdict(list)
    for row in rows:
        key = str(row.get("policy_runtime_id", row.get("policy_id", "unknown")))
        grouped[key].append(row)

    out: list[dict] = []
    for policy_id in sorted(grouped.keys()):
        bucket = grouped[policy_id]
        run_count = len(bucket)
        wins = sum(1 for r in bucket if str(r.get("result", "")) == "player_win")
        turns = [float(r.get("turns_completed", 0)) for r in bucket]
        win_ci_low, win_ci_high = report_utils.proportion_confidence_interval_95(wins, run_count)
        out.append(
            {
                "policy_runtime_id": policy_id,
                "run_count": run_count,
                "wins": wins,
                "win_rate": round(wins / run_count if run_count else 0.0, 4),
                "win_rate_ci95_lower": round(win_ci_low, 4),
                "win_rate_ci95_upper": round(win_ci_high, 4),
                "mean_turns": round(report_utils.mean(turns), 4),
                "p95_turns": round(report_utils.percentile(turns, 95), 4),
            }
        )
    return out


def build_summary(rows: list[dict], card_metrics: list[dict], policy_compare: list[dict]) -> dict:
    run_count = len(rows)
    wins = sum(1 for row in rows if str(row.get("result", "")) == "player_win")

    turns = [float(r.get("turns_completed", 0)) for r in rows]
    mana_spent = [float(r.get("mana_spent_total", 0)) for r in rows]
    mana_wasted = [float(r.get("mana_wasted_total", 0)) for r in rows]
    event_counts = [float(r.get("event_count", 0)) for r in rows]

    gems_produced_total = sum(float(r.get("gems_produced_total", 0)) for r in rows)
    gems_consumed_total = sum(float(r.get("gems_consumed_total", 0)) for r in rows)
    advanced_ops_total = sum(float(r.get("advanced_ops_total", 0)) for r in rows)
    stability_ops_total = sum(float(r.get("stability_ops_total", 0)) for r in rows)
    focus_gate_rejects = sum(float(r.get("focus_gate_rejects", 0)) for r in rows)

    outliers_sorted = sorted(card_metrics, key=lambda x: float(x["avg_value_proxy_per_play"]))
    card_outliers_under = outliers_sorted[:3]
    card_outliers_over = list(reversed(outliers_sorted[-3:]))

    win_ci_low, win_ci_high = report_utils.proportion_confidence_interval_95(wins, run_count)

    summary = {
        "summary_kpis": {
            "run_count": run_count,
            "wins": wins,
            "win_rate": round(wins / run_count if run_count else 0.0, 4),
            "win_rate_ci95_lower": round(win_ci_low, 4),
            "win_rate_ci95_upper": round(win_ci_high, 4),
            "turns_completed": report_utils.summarize_series(turns),
            "mana_spent_total": report_utils.summarize_series(mana_spent),
            "mana_wasted_total": report_utils.summarize_series(mana_wasted),
            "event_count": report_utils.summarize_series(event_counts),
        },
        "card_outliers_over": card_outliers_over,
        "card_outliers_under": card_outliers_under,
        "rarity_curve_health": {
            "status": "not_modeled_yet",
            "note": "Rarity-annotated card metadata wiring lands in M4.",
        },
        "gem_engine_diagnostics": {
            "gems_produced_total": gems_produced_total,
            "gems_consumed_total": gems_consumed_total,
            "advanced_ops_total": advanced_ops_total,
            "stability_ops_total": stability_ops_total,
            "focus_gate_rejects": focus_gate_rejects,
            "focus_gate_reject_rate": round(focus_gate_rejects / run_count if run_count else 0.0, 4),
        },
        "policy_comparison": policy_compare,
        "confidence_notes": {
            "run_count": run_count,
            "guidance": "Interpret win-rate and outliers cautiously below 100 runs.",
        },
    }
    return summary


def write_csv(path: Path, rows: list[dict], fieldnames: list[str]) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def generate_reports(input_path: Path, output_dir: Path) -> dict:
    rows = load_jsonl(input_path)
    output_dir.mkdir(parents=True, exist_ok=True)

    card_metrics = build_card_metrics(rows)
    policy_compare = build_policy_compare(rows)
    summary = build_summary(rows, card_metrics, policy_compare)

    summary_path = output_dir / "summary.json"
    card_csv_path = output_dir / "card_metrics.csv"
    policy_csv_path = output_dir / "policy_compare.csv"

    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")
    write_csv(
        card_csv_path,
        card_metrics,
        ["card_id", "plays", "run_appearances", "total_value_proxy", "avg_value_proxy_per_play"],
    )
    write_csv(
        policy_csv_path,
        policy_compare,
        [
            "policy_runtime_id",
            "run_count",
            "wins",
            "win_rate",
            "win_rate_ci95_lower",
            "win_rate_ci95_upper",
            "mean_turns",
            "p95_turns",
        ],
    )

    return {
        "summary_json": str(summary_path),
        "card_metrics_csv": str(card_csv_path),
        "policy_compare_csv": str(policy_csv_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Aggregate raw simulator JSONL into report files.")
    parser.add_argument("--input", required=True, help="Path to raw JSONL file")
    parser.add_argument("--output-dir", required=True, help="Directory for generated report files")
    args = parser.parse_args()

    outputs = generate_reports(Path(args.input), Path(args.output_dir))
    print("BALANCE_REPORT_SUMMARY=" + outputs["summary_json"])
    print("BALANCE_REPORT_CARD_CSV=" + outputs["card_metrics_csv"])
    print("BALANCE_REPORT_POLICY_CSV=" + outputs["policy_compare_csv"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
