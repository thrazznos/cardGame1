import argparse
import csv
import json
import sys
from pathlib import Path

try:
    from src.tools.balance.deck_order_power_distribution import run_distribution
except ModuleNotFoundError:
    ROOT = Path(__file__).resolve().parents[3]
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from src.tools.balance.deck_order_power_distribution import run_distribution


def _read_cards(path: Path, key: str) -> list[str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    arr = payload.get(key, [])
    if not isinstance(arr, list) or not arr:
        raise ValueError(f"{path} must include non-empty '{key}' array")
    return [str(x) for x in arr]


def _load_summary(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_csv(path: Path, rows: list[dict]) -> None:
    fieldnames = [
        "candidate_card_id",
        "baseline_win_rate",
        "candidate_win_rate",
        "uplift_mean",
        "downside_risk",
        "baseline_orders",
        "candidate_orders",
    ]
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        for row in rows:
            w.writerow(row)


def rank_candidates(
    baseline_cards: list[str],
    candidates: list[str],
    policy_id: str,
    seed_root: int,
    max_turns: int,
    mode: str,
    sample_size: int,
    sampler_seed: int,
    max_orders: int,
    output_dir: Path,
) -> dict:
    output_dir.mkdir(parents=True, exist_ok=True)

    baseline_dir = output_dir / "baseline"
    baseline_outputs = run_distribution(
        deck_cards=baseline_cards,
        policy_id=policy_id,
        seed_root=seed_root,
        max_turns=max_turns,
        mode=mode,
        sample_size=sample_size,
        sampler_seed=sampler_seed,
        max_orders=max_orders,
        output_dir=baseline_dir,
    )
    baseline_summary = _load_summary(Path(baseline_outputs["distribution_summary_json"]))
    baseline_win_rate = float(baseline_summary.get("win_rate", 0.0))

    rows: list[dict] = []
    candidate_entries: list[dict] = []
    for index, candidate in enumerate(candidates):
        candidate_cards = baseline_cards + [candidate]
        candidate_dir = output_dir / f"candidate_{index}_{candidate}"
        candidate_outputs = run_distribution(
            deck_cards=candidate_cards,
            policy_id=policy_id,
            seed_root=seed_root,
            max_turns=max_turns,
            mode=mode,
            sample_size=sample_size,
            sampler_seed=sampler_seed + index + 1,
            max_orders=max_orders,
            output_dir=candidate_dir,
        )
        candidate_summary = _load_summary(Path(candidate_outputs["distribution_summary_json"]))
        candidate_win_rate = float(candidate_summary.get("win_rate", 0.0))

        uplift = candidate_win_rate - baseline_win_rate
        downside_risk = max(0.0, baseline_win_rate - candidate_win_rate)

        entry = {
            "candidate_card_id": candidate,
            "baseline_win_rate": round(baseline_win_rate, 4),
            "candidate_win_rate": round(candidate_win_rate, 4),
            "uplift_mean": round(uplift, 4),
            "downside_risk": round(downside_risk, 4),
            "baseline_orders": int(baseline_summary.get("total_orders_evaluated", 0)),
            "candidate_orders": int(candidate_summary.get("total_orders_evaluated", 0)),
        }
        rows.append(entry)
        candidate_entries.append(entry)

    rows_sorted = sorted(rows, key=lambda r: (-float(r["uplift_mean"]), str(r["candidate_card_id"])))

    ranking_json = {
        "baseline": {
            "win_rate": round(baseline_win_rate, 4),
            "orders": int(baseline_summary.get("total_orders_evaluated", 0)),
        },
        "candidates": rows_sorted,
    }

    ranking_json_path = output_dir / "candidate_rankings.json"
    ranking_csv_path = output_dir / "candidate_rankings.csv"

    ranking_json_path.write_text(json.dumps(ranking_json, indent=2, sort_keys=True), encoding="utf-8")
    _write_csv(ranking_csv_path, rows_sorted)

    return {
        "ranking_json": str(ranking_json_path),
        "ranking_csv": str(ranking_csv_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Rank candidate cards by deck power uplift.")
    parser.add_argument("--baseline-deck-json", required=True)
    parser.add_argument("--candidates-json", required=True)
    parser.add_argument("--policy-id", default="greedy_value")
    parser.add_argument("--seed-root", type=int, default=101)
    parser.add_argument("--max-turns", type=int, default=2)
    parser.add_argument("--mode", choices=["exact", "sample"], default="sample")
    parser.add_argument("--sample-size", type=int, default=64)
    parser.add_argument("--sampler-seed", type=int, default=7)
    parser.add_argument("--max-orders", type=int, default=720)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    baseline_cards = _read_cards(Path(args.baseline_deck_json), "cards")
    candidates = _read_cards(Path(args.candidates_json), "candidates")

    outputs = rank_candidates(
        baseline_cards=baseline_cards,
        candidates=candidates,
        policy_id=args.policy_id,
        seed_root=args.seed_root,
        max_turns=args.max_turns,
        mode=args.mode,
        sample_size=args.sample_size,
        sampler_seed=args.sampler_seed,
        max_orders=args.max_orders,
        output_dir=Path(args.output_dir),
    )

    print("CARD_SEARCH_RANKINGS_JSON=" + outputs["ranking_json"])
    print("CARD_SEARCH_RANKINGS_CSV=" + outputs["ranking_csv"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
