import argparse
import csv
import json
from pathlib import Path


def _read_csv(path: Path) -> list[dict]:
    with path.open("r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def _fmt_pct(value: float) -> str:
    return f"{value * 100:.1f}%"


def render_markdown(summary: dict, card_rows: list[dict], policy_rows: list[dict]) -> str:
    kpis = summary.get("summary_kpis", {})
    gem_diag = summary.get("gem_engine_diagnostics", {})
    over = summary.get("card_outliers_over", [])
    under = summary.get("card_outliers_under", [])

    lines: list[str] = []
    lines.append("# Balance Simulation Report")
    lines.append("")

    lines.append("## Set Health Summary")
    lines.append(f"- Runs: {kpis.get('run_count', 0)}")
    lines.append(f"- Wins: {kpis.get('wins', 0)}")
    lines.append(f"- Win Rate: {_fmt_pct(float(kpis.get('win_rate', 0.0)))}")
    lines.append("")

    lines.append("## Card Outliers")
    lines.append("Top overperformers (avg proxy/play):")
    for row in over:
        lines.append(f"- {row.get('card_id', '-')}: {row.get('avg_value_proxy_per_play', 0)}")
    lines.append("Top underperformers (avg proxy/play):")
    for row in under:
        lines.append(f"- {row.get('card_id', '-')}: {row.get('avg_value_proxy_per_play', 0)}")
    lines.append("")

    lines.append("## Rarity Curve Health")
    rarity = summary.get("rarity_curve_health", {})
    lines.append(f"- Status: {rarity.get('status', 'unknown')}")
    lines.append(f"- Note: {rarity.get('note', '')}")
    lines.append("")

    lines.append("## Gem Engine Diagnostics")
    lines.append(f"- Gems Produced: {gem_diag.get('gems_produced_total', 0)}")
    lines.append(f"- Gems Consumed: {gem_diag.get('gems_consumed_total', 0)}")
    lines.append(f"- Advanced Ops: {gem_diag.get('advanced_ops_total', 0)}")
    lines.append(f"- Stability Ops: {gem_diag.get('stability_ops_total', 0)}")
    lines.append(f"- FOCUS Gate Reject Rate: {_fmt_pct(float(gem_diag.get('focus_gate_reject_rate', 0.0)))}")
    lines.append("")

    lines.append("## Recommendations")
    if float(kpis.get("win_rate", 0.0)) < 0.4:
        lines.append("- Overall win rate is low; review common-card base floors and enemy pressure.")
    else:
        lines.append("- Overall win rate is in a playable band for early simulation samples.")

    if float(gem_diag.get("focus_gate_reject_rate", 0.0)) > 0.2:
        lines.append("- High FOCUS gate reject rate; consider adding more FOCUS enablers.")
    else:
        lines.append("- FOCUS gate reject pressure is acceptable in this sample.")

    if policy_rows:
        lines.append("- Compare policy deltas in policy_compare.csv for sequencing skill signal.")
    if card_rows:
        lines.append("- Inspect top/bottom card outliers for next tuning pass.")

    lines.append("")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Render markdown balance report from aggregate outputs.")
    parser.add_argument("--summary-json", required=True)
    parser.add_argument("--card-csv", required=True)
    parser.add_argument("--policy-csv", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    summary = json.loads(Path(args.summary_json).read_text(encoding="utf-8"))
    card_rows = _read_csv(Path(args.card_csv))
    policy_rows = _read_csv(Path(args.policy_csv))

    body = render_markdown(summary, card_rows, policy_rows)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(body, encoding="utf-8")

    print("BALANCE_REPORT_MARKDOWN=" + str(output_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
