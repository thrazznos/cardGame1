import csv
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from src.tools.balance import report_utils


class BalanceReportMetricsTests(unittest.TestCase):
    def _fixture_rows(self) -> list[dict]:
        return [
            {
                "simulation_id": "s1",
                "scenario_id": "baseline",
                "deck_id": "d1",
                "seed_root": 101,
                "policy_id": "random_legal",
                "policy_runtime_id": "random_legal",
                "enemy_profile_id": "default",
                "result": "player_win",
                "turns_completed": 4,
                "player_hp_end": 22,
                "enemy_hp_end": 0,
                "mana_spent_total": 6,
                "mana_wasted_total": 1,
                "gems_produced_total": 2,
                "gems_consumed_total": 1,
                "advanced_ops_total": 0,
                "stability_ops_total": 1,
                "focus_gate_rejects": 0,
                "card_play_counts": {"strike_01": 2, "scheme_flow": 1},
                "card_effect_value_proxy": {"strike_01": 12.0, "scheme_flow": 0.0},
                "event_count": 12,
                "determinism_hash": "h1",
            },
            {
                "simulation_id": "s2",
                "scenario_id": "baseline",
                "deck_id": "d1",
                "seed_root": 202,
                "policy_id": "greedy_value",
                "policy_runtime_id": "greedy_value",
                "enemy_profile_id": "default",
                "result": "player_win",
                "turns_completed": 3,
                "player_hp_end": 25,
                "enemy_hp_end": 0,
                "mana_spent_total": 5,
                "mana_wasted_total": 0,
                "gems_produced_total": 1,
                "gems_consumed_total": 1,
                "advanced_ops_total": 0,
                "stability_ops_total": 0,
                "focus_gate_rejects": 0,
                "card_play_counts": {"strike_01": 2, "defend_01": 1},
                "card_effect_value_proxy": {"strike_01": 12.0, "defend_01": 5.0},
                "event_count": 10,
                "determinism_hash": "h2",
            },
            {
                "simulation_id": "s3",
                "scenario_id": "baseline",
                "deck_id": "d1",
                "seed_root": 303,
                "policy_id": "sequencing_aware_v1",
                "policy_runtime_id": "sequencing_aware_v1",
                "enemy_profile_id": "default",
                "result": "player_lose",
                "turns_completed": 6,
                "player_hp_end": 0,
                "enemy_hp_end": 5,
                "mana_spent_total": 7,
                "mana_wasted_total": 2,
                "gems_produced_total": 4,
                "gems_consumed_total": 2,
                "advanced_ops_total": 1,
                "stability_ops_total": 1,
                "focus_gate_rejects": 1,
                "card_play_counts": {"scheme_flow": 3, "defend_01": 1},
                "card_effect_value_proxy": {"scheme_flow": 0.0, "defend_01": 5.0},
                "event_count": 16,
                "determinism_hash": "h3",
            },
        ]

    def test_report_utils_summarizes_and_computes_ci(self):
        stats = report_utils.summarize_series([1, 2, 3, 4, 5])
        self.assertEqual(stats["count"], 5)
        self.assertEqual(stats["mean"], 3.0)
        self.assertEqual(stats["p50"], 3)
        self.assertEqual(stats["p95"], 5)

        lower, upper = report_utils.confidence_interval_95([10, 10, 10])
        self.assertEqual(lower, 10.0)
        self.assertEqual(upper, 10.0)

    def test_aggregate_reports_writes_summary_json_and_csvs(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_path = Path(tmpdir)
            input_path = tmpdir_path / "raw.jsonl"
            output_dir = tmpdir_path / "reports"

            with input_path.open("w", encoding="utf-8") as f:
                for row in self._fixture_rows():
                    f.write(json.dumps(row) + "\n")

            cmd = [
                "python3",
                "src/tools/balance/aggregate_reports.py",
                "--input",
                str(input_path),
                "--output-dir",
                str(output_dir),
            ]
            subprocess.run(cmd, check=True)

            summary_path = output_dir / "summary.json"
            card_csv_path = output_dir / "card_metrics.csv"
            policy_csv_path = output_dir / "policy_compare.csv"

            self.assertTrue(summary_path.exists())
            self.assertTrue(card_csv_path.exists())
            self.assertTrue(policy_csv_path.exists())

            summary = json.loads(summary_path.read_text(encoding="utf-8"))
            self.assertIn("summary_kpis", summary)
            self.assertIn("card_outliers_over", summary)
            self.assertIn("card_outliers_under", summary)
            self.assertIn("rarity_curve_health", summary)
            self.assertIn("gem_engine_diagnostics", summary)
            self.assertIn("policy_comparison", summary)
            self.assertIn("confidence_notes", summary)
            self.assertEqual(summary["summary_kpis"]["run_count"], 3)

            with card_csv_path.open("r", encoding="utf-8") as f:
                rows = list(csv.DictReader(f))
            self.assertGreater(len(rows), 0)
            self.assertIn("card_id", rows[0])
            self.assertIn("plays", rows[0])

            with policy_csv_path.open("r", encoding="utf-8") as f:
                rows = list(csv.DictReader(f))
            self.assertGreater(len(rows), 0)
            self.assertIn("policy_runtime_id", rows[0])
            self.assertIn("win_rate", rows[0])

    def test_markdown_renderer_includes_required_sections(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_path = Path(tmpdir)
            input_path = tmpdir_path / "raw.jsonl"
            output_dir = tmpdir_path / "reports"
            output_dir.mkdir(parents=True, exist_ok=True)

            with input_path.open("w", encoding="utf-8") as f:
                for row in self._fixture_rows():
                    f.write(json.dumps(row) + "\n")

            subprocess.run(
                [
                    "python3",
                    "src/tools/balance/aggregate_reports.py",
                    "--input",
                    str(input_path),
                    "--output-dir",
                    str(output_dir),
                ],
                check=True,
            )

            md_path = output_dir / "balance_report.md"
            subprocess.run(
                [
                    "python3",
                    "src/tools/balance/render_markdown_report.py",
                    "--summary-json",
                    str(output_dir / "summary.json"),
                    "--card-csv",
                    str(output_dir / "card_metrics.csv"),
                    "--policy-csv",
                    str(output_dir / "policy_compare.csv"),
                    "--output",
                    str(md_path),
                ],
                check=True,
            )

            body = md_path.read_text(encoding="utf-8")
            self.assertIn("## Set Health Summary", body)
            self.assertIn("## Card Outliers", body)
            self.assertIn("## Rarity Curve Health", body)
            self.assertIn("## Gem Engine Diagnostics", body)
            self.assertIn("## Recommendations", body)


if __name__ == "__main__":
    unittest.main()
