import json
import subprocess
import tempfile
import unittest
from pathlib import Path


class DeckPowerDistributionTests(unittest.TestCase):
    def _write_deck(self, path: Path, cards: list[str]) -> None:
        path.write_text(json.dumps({"cards": cards}), encoding="utf-8")

    def test_exact_mode_emits_reports_and_order_count(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            deck_path = tmp / "deck.json"
            out_dir = tmp / "out"
            self._write_deck(deck_path, ["strike_01", "defend_01", "scheme_flow"])

            subprocess.run(
                [
                    "python3",
                    "src/tools/balance/deck_order_power_distribution.py",
                    "--deck-json",
                    str(deck_path),
                    "--policy-id",
                    "greedy_value",
                    "--seed-root",
                    "101",
                    "--max-turns",
                    "2",
                    "--mode",
                    "exact",
                    "--max-orders",
                    "20",
                    "--output-dir",
                    str(out_dir),
                ],
                check=True,
            )

            order_runs = out_dir / "order_runs.jsonl"
            summary = out_dir / "distribution_summary.json"
            self.assertTrue(order_runs.exists())
            self.assertTrue(summary.exists())

            data = json.loads(summary.read_text(encoding="utf-8"))
            self.assertEqual(data["total_orders_evaluated"], 6)
            self.assertIn("win_rate", data)
            self.assertIn("p50_turns_completed", data)

    def test_sample_mode_is_deterministic_with_sampler_seed(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            deck_path = tmp / "deck.json"
            out_a = tmp / "out_a"
            out_b = tmp / "out_b"
            self._write_deck(deck_path, [
                "strike_01",
                "strike_02",
                "defend_01",
                "defend_02",
                "scheme_flow",
            ])

            cmd = [
                "python3",
                "src/tools/balance/deck_order_power_distribution.py",
                "--deck-json",
                str(deck_path),
                "--policy-id",
                "random_legal",
                "--seed-root",
                "101",
                "--max-turns",
                "2",
                "--mode",
                "sample",
                "--sample-size",
                "8",
                "--sampler-seed",
                "77",
            ]

            subprocess.run(cmd + ["--output-dir", str(out_a)], check=True)
            subprocess.run(cmd + ["--output-dir", str(out_b)], check=True)

            a = json.loads((out_a / "distribution_summary.json").read_text(encoding="utf-8"))
            b = json.loads((out_b / "distribution_summary.json").read_text(encoding="utf-8"))

            self.assertEqual(a["sampled_order_signatures"], b["sampled_order_signatures"])
            self.assertEqual(a["total_orders_evaluated"], b["total_orders_evaluated"])

    def test_card_search_ranker_outputs_candidate_uplift_table(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp = Path(tmpdir)
            baseline_path = tmp / "baseline_deck.json"
            candidates_path = tmp / "candidates.json"
            out_dir = tmp / "rank"

            self._write_deck(baseline_path, ["strike_01", "defend_01", "defend_02", "scheme_flow"])
            candidates_path.write_text(
                json.dumps({"candidates": ["strike_02", "scheme_flow", "defend_03"]}),
                encoding="utf-8",
            )

            subprocess.run(
                [
                    "python3",
                    "src/tools/balance/card_search_ranker.py",
                    "--baseline-deck-json",
                    str(baseline_path),
                    "--candidates-json",
                    str(candidates_path),
                    "--policy-id",
                    "greedy_value",
                    "--seed-root",
                    "101",
                    "--max-turns",
                    "2",
                    "--mode",
                    "sample",
                    "--sample-size",
                    "8",
                    "--sampler-seed",
                    "9",
                    "--output-dir",
                    str(out_dir),
                ],
                check=True,
            )

            ranking_json = out_dir / "candidate_rankings.json"
            ranking_csv = out_dir / "candidate_rankings.csv"
            self.assertTrue(ranking_json.exists())
            self.assertTrue(ranking_csv.exists())

            data = json.loads(ranking_json.read_text(encoding="utf-8"))
            self.assertIn("baseline", data)
            self.assertIn("candidates", data)
            self.assertEqual(len(data["candidates"]), 3)
            self.assertIn("uplift_mean", data["candidates"][0])
            self.assertIn("downside_risk", data["candidates"][0])


if __name__ == "__main__":
    unittest.main()
