import json
import os
import subprocess
import tempfile
import unittest

from src.tools.godot_test_runner import resolve_godot_executable


class BalanceSimSmokeTests(unittest.TestCase):
    def _run_sim(self, payload: dict) -> dict:
        fd, tmp = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        try:
            with open(tmp, "w", encoding="utf-8") as f:
                json.dump(payload, f)

            cmd = [
                resolve_godot_executable(),
                "--headless",
                "--path",
                ".",
                "-s",
                "res://tests/sim/run_balance_sim.gd",
                "--",
                tmp,
            ]
            proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
            for line in proc.stdout.splitlines():
                if line.startswith("BALANCE_SIM_REPORT="):
                    return json.loads(line[len("BALANCE_SIM_REPORT="):])
            self.fail("missing BALANCE_SIM_REPORT output")
        finally:
            os.remove(tmp)

    def _base_payload(self, policy_id: str) -> dict:
        return {
            "simulation_id": f"sim_{policy_id}",
            "seed_root": 13371337,
            "deck_list": [
                "strike_01",
                "strike_02",
                "defend_01",
                "defend_02",
                "scheme_flow",
                "strike_03",
            ],
            "enemy_profile_id": "default",
            "policy_id": policy_id,
            "balance_profile_id": "default",
            "max_turns": 8,
        }

    def test_single_run_emits_balance_report(self):
        report = self._run_sim(self._base_payload("random_legal"))
        self.assertEqual(report["simulation_id"], "sim_random_legal")
        self.assertIn(report["result"], ["player_win", "player_lose", "timeout", "in_progress"])
        self.assertGreaterEqual(report["turns_completed"], 1)
        self.assertIn("determinism_hash", report)

    def test_single_run_is_deterministic_for_same_seed_and_input(self):
        payload = self._base_payload("random_legal")
        first = self._run_sim(payload)
        second = self._run_sim(payload)

        self.assertEqual(first["result"], second["result"])
        self.assertEqual(first["turns_completed"], second["turns_completed"])
        self.assertEqual(first["event_count"], second["event_count"])
        self.assertEqual(first["card_play_counts"], second["card_play_counts"])
        self.assertEqual(first["determinism_hash"], second["determinism_hash"])

    def test_balance_report_uses_card_catalog_effect_values(self):
        strike_plus = self._run_sim(
            {
                "simulation_id": "strike_plus_probe",
                "seed_root": 111,
                "deck_list": ["strike_plus"] * 6,
                "enemy_profile_id": "default",
                "policy_id": "random_legal",
                "balance_profile_id": "default",
                "max_turns": 2,
            }
        )
        strike_precise = self._run_sim(
            {
                "simulation_id": "strike_precise_probe",
                "seed_root": 222,
                "deck_list": ["strike_precise"] * 6,
                "enemy_profile_id": "default",
                "policy_id": "random_legal",
                "balance_profile_id": "default",
                "max_turns": 2,
            }
        )

        strike_plus_avg = strike_plus["card_effect_value_proxy"]["strike_plus"] / strike_plus["card_play_counts"]["strike_plus"]
        strike_precise_avg = strike_precise["card_effect_value_proxy"]["strike_precise"] / strike_precise["card_play_counts"]["strike_precise"]

        self.assertEqual(strike_plus_avg, 7.0)
        self.assertEqual(strike_precise_avg, 7.0)

    def test_balance_report_exposes_authored_card_sim_metadata(self):
        strike_plus = self._run_sim(
            {
                "simulation_id": "strike_plus_metadata_probe",
                "seed_root": 111,
                "deck_list": ["strike_plus"] * 6,
                "enemy_profile_id": "default",
                "policy_id": "random_legal",
                "balance_profile_id": "default",
                "max_turns": 2,
            }
        )
        strike_precise = self._run_sim(
            {
                "simulation_id": "strike_precise_metadata_probe",
                "seed_root": 222,
                "deck_list": ["strike_precise"] * 6,
                "enemy_profile_id": "default",
                "policy_id": "random_legal",
                "balance_profile_id": "default",
                "max_turns": 2,
            }
        )

        self.assertEqual(
            strike_plus["card_sim_metadata"]["strike_plus"]["report_role"],
            "attack_upgrade",
        )
        self.assertEqual(
            strike_precise["card_sim_metadata"]["strike_precise"]["report_role"],
            "attack_draw",
        )

    def test_greedy_value_policy_reports_runtime_policy_id(self):
        report = self._run_sim(self._base_payload("greedy_value"))
        self.assertEqual(report.get("policy_runtime_id"), "greedy_value")

    def test_sequencing_aware_policy_reports_runtime_policy_id(self):
        report = self._run_sim(self._base_payload("sequencing_aware_v1"))
        self.assertEqual(report.get("policy_runtime_id"), "sequencing_aware_v1")


if __name__ == "__main__":
    unittest.main()
