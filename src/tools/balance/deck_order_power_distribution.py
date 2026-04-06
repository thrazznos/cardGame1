import argparse
import itertools
import json
import math
import os
import random
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

try:
    from src.tools.balance import report_utils
    from src.tools.godot_test_runner import resolve_godot_executable
except ModuleNotFoundError:
    ROOT = Path(__file__).resolve().parents[3]
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from src.tools.balance import report_utils
    from src.tools.godot_test_runner import resolve_godot_executable


def _read_deck(path: Path) -> list[str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    cards = payload.get("cards", [])
    if not isinstance(cards, list) or not cards:
        raise ValueError("deck json must include non-empty 'cards' array")
    return [str(c) for c in cards]


def _total_unique_permutations(cards: list[str]) -> int:
    counts = Counter(cards)
    numerator = math.factorial(len(cards))
    denom = 1
    for v in counts.values():
        denom *= math.factorial(v)
    return numerator // denom


def _generate_exact_orders(cards: list[str], max_orders: int) -> list[tuple[str, ...]]:
    total_unique = _total_unique_permutations(cards)
    if total_unique > max_orders:
        raise ValueError(
            f"exact mode requires {total_unique} unique orders, exceeds max-orders={max_orders}. "
            "Use sample mode or increase max-orders."
        )

    out: list[tuple[str, ...]] = []
    counter = Counter(cards)
    current: list[str] = []

    def rec() -> None:
        if len(current) == len(cards):
            out.append(tuple(current))
            return
        for card_id in sorted(counter.keys()):
            if counter[card_id] <= 0:
                continue
            counter[card_id] -= 1
            current.append(card_id)
            rec()
            current.pop()
            counter[card_id] += 1

    rec()
    return out


def _generate_sample_orders(cards: list[str], sample_size: int, sampler_seed: int) -> list[tuple[str, ...]]:
    rng = random.Random(sampler_seed)
    unique: set[tuple[str, ...]] = set()
    attempts = 0
    attempt_cap = max(200, sample_size * 50)

    while len(unique) < sample_size and attempts < attempt_cap:
        deck = cards.copy()
        rng.shuffle(deck)
        unique.add(tuple(deck))
        attempts += 1

    return sorted(unique)


def _run_single(deck_order: tuple[str, ...], policy_id: str, seed_root: int, max_turns: int) -> dict:
    payload = {
        "simulation_id": "deck_order_probe",
        "seed_root": seed_root,
        "deck_list": list(deck_order),
        "enemy_profile_id": "default",
        "policy_id": policy_id,
        "balance_profile_id": "order_distribution",
        "max_turns": max_turns,
    }

    fd, payload_path = tempfile.mkstemp(suffix=".json")
    os.close(fd)
    try:
        with open(payload_path, "w", encoding="utf-8") as f:
            json.dump(payload, f)

        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/sim/run_balance_sim.gd",
            "--",
            payload_path,
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
        for line in proc.stdout.splitlines():
            if line.startswith("BALANCE_SIM_REPORT="):
                return json.loads(line[len("BALANCE_SIM_REPORT=") :])
        raise RuntimeError("missing BALANCE_SIM_REPORT output")
    finally:
        os.remove(payload_path)


def _build_summary(rows: list[dict], sampled_signatures: list[str], mode: str) -> dict:
    run_count = len(rows)
    wins = sum(1 for r in rows if str(r.get("result", "")) == "player_win")
    turns = [float(r.get("turns_completed", 0)) for r in rows]

    return {
        "mode": mode,
        "total_orders_evaluated": run_count,
        "wins": wins,
        "win_rate": round(wins / run_count if run_count else 0.0, 4),
        "mean_turns_completed": round(report_utils.mean(turns), 4),
        "p50_turns_completed": round(report_utils.percentile(turns, 50), 4),
        "p95_turns_completed": round(report_utils.percentile(turns, 95), 4),
        "sampled_order_signatures": sampled_signatures,
    }


def run_distribution(
    deck_cards: list[str],
    policy_id: str,
    seed_root: int,
    max_turns: int,
    mode: str,
    sample_size: int,
    sampler_seed: int,
    max_orders: int,
    output_dir: Path,
) -> dict:
    if mode == "exact":
        orders = _generate_exact_orders(deck_cards, max_orders=max_orders)
    else:
        orders = _generate_sample_orders(deck_cards, sample_size=sample_size, sampler_seed=sampler_seed)

    output_dir.mkdir(parents=True, exist_ok=True)
    order_runs_path = output_dir / "order_runs.jsonl"

    rows: list[dict] = []
    signatures: list[str] = []
    with order_runs_path.open("w", encoding="utf-8") as f:
        for i, order in enumerate(orders):
            signature = "|".join(order)
            signatures.append(signature)
            report = _run_single(order, policy_id=policy_id, seed_root=seed_root, max_turns=max_turns)
            row = {
                "order_index": i,
                "order_signature": signature,
                "deck_list": list(order),
                "result": report.get("result"),
                "turns_completed": report.get("turns_completed"),
                "determinism_hash": report.get("determinism_hash"),
                "policy_runtime_id": report.get("policy_runtime_id"),
            }
            rows.append(row)
            f.write(json.dumps(row) + "\n")

    summary = _build_summary(rows, sampled_signatures=signatures, mode=mode)
    summary_path = output_dir / "distribution_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

    return {
        "order_runs_jsonl": str(order_runs_path),
        "distribution_summary_json": str(summary_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate deck power distribution across deck orderings.")
    parser.add_argument("--deck-json", required=True)
    parser.add_argument("--policy-id", default="greedy_value")
    parser.add_argument("--seed-root", type=int, default=101)
    parser.add_argument("--max-turns", type=int, default=2)
    parser.add_argument("--mode", choices=["exact", "sample"], default="sample")
    parser.add_argument("--sample-size", type=int, default=64)
    parser.add_argument("--sampler-seed", type=int, default=7)
    parser.add_argument("--max-orders", type=int, default=720)
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    deck_cards = _read_deck(Path(args.deck_json))
    outputs = run_distribution(
        deck_cards=deck_cards,
        policy_id=args.policy_id,
        seed_root=args.seed_root,
        max_turns=args.max_turns,
        mode=args.mode,
        sample_size=args.sample_size,
        sampler_seed=args.sampler_seed,
        max_orders=args.max_orders,
        output_dir=Path(args.output_dir),
    )

    print("DECK_POWER_ORDER_RUNS=" + outputs["order_runs_jsonl"])
    print("DECK_POWER_SUMMARY=" + outputs["distribution_summary_json"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
