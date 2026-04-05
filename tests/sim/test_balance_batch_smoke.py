import json
import os
import subprocess
import unittest
from pathlib import Path

from src.tools.godot_test_runner import resolve_godot_executable


class BalanceBatchSmokeTests(unittest.TestCase):
    def _run_batch(self, scenario_path: str) -> tuple[Path, list[dict]]:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/sim/run_balance_batch.gd",
            "--",
            scenario_path,
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        artifact_path = ""
        for line in proc.stdout.splitlines():
            if line.startswith("BALANCE_BATCH_ARTIFACT="):
                artifact_path = line[len("BALANCE_BATCH_ARTIFACT="):]
        self.assertTrue(artifact_path, "missing BALANCE_BATCH_ARTIFACT output")

        artifact = Path(artifact_path)
        self.assertTrue(artifact.exists(), f"missing artifact at {artifact}")

        rows: list[dict] = []
        with artifact.open("r", encoding="utf-8") as f:
            for raw in f:
                raw = raw.strip()
                if not raw:
                    continue
                rows.append(json.loads(raw))
        return artifact, rows

    def test_scenario_packs_have_required_shape(self):
        for relative in [
            "tests/sim/scenarios/baseline_commons_v1.json",
            "tests/sim/scenarios/mixed_rarity_v1.json",
            "tests/sim/scenarios/gem_stress_v1.json",
        ]:
            path = Path(relative)
            self.assertTrue(path.exists(), f"missing scenario pack: {relative}")
            payload = json.loads(path.read_text(encoding="utf-8"))
            self.assertIsInstance(payload.get("scenario_id"), str)
            self.assertIsInstance(payload.get("seeds"), list)
            self.assertIsInstance(payload.get("policies"), list)
            self.assertIsInstance(payload.get("decks"), list)
            self.assertGreater(len(payload.get("seeds", [])), 0)
            self.assertGreater(len(payload.get("policies", [])), 0)
            self.assertGreater(len(payload.get("decks", [])), 0)

    def test_batch_runner_writes_jsonl_artifact(self):
        _, rows = self._run_batch("res://tests/sim/scenarios/baseline_commons_v1.json")
        self.assertGreater(len(rows), 0)

    def test_batch_rows_include_required_report_fields(self):
        _, rows = self._run_batch("res://tests/sim/scenarios/mixed_rarity_v1.json")
        required = {
            "simulation_id",
            "seed_root",
            "policy_id",
            "policy_runtime_id",
            "result",
            "turns_completed",
            "determinism_hash",
        }
        for row in rows:
            self.assertTrue(required.issubset(row.keys()))


if __name__ == "__main__":
    unittest.main()
