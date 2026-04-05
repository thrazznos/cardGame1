import json
import subprocess
import unittest

from src.tools.godot_test_runner import resolve_godot_executable


class PlayablePrototypeSmokeTests(unittest.TestCase):
    def _run_fixture(self, fixture_path: str) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/determinism/run_fixture.gd",
            "--",
            fixture_path,
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        report_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("DETERMINISM_REPORT="):
                report_line = line[len("DETERMINISM_REPORT="):]
        self.assertTrue(report_line, "missing DETERMINISM_REPORT output")
        return json.loads(report_line)

    def test_seed_smoke_001_reports_playable_player_win(self):
        report = self._run_fixture("res://tests/determinism/fixtures/seed_smoke_001.json")
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["fixture_id"], "seed_smoke_001")
        self.assertEqual(report["combat_result"], "player_win")
        self.assertEqual(report["reward_checkpoint_count"], 1)
        self.assertEqual(report["reward_state"], "presented")
        self.assertEqual(len(report["reward_offer_card_ids"]), 3)
        self.assertGreater(report["turns_completed"], 0)

    def test_seed_smoke_002_reports_playable_player_win(self):
        report = self._run_fixture("res://tests/determinism/fixtures/seed_smoke_002.json")
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["fixture_id"], "seed_smoke_002")
        self.assertEqual(report["combat_result"], "player_win")
        self.assertEqual(report["reward_checkpoint_count"], 1)
        self.assertEqual(report["reward_state"], "presented")
        self.assertEqual(len(report["reward_offer_card_ids"]), 3)
        self.assertGreater(report["turns_completed"], 0)

    def test_seed_reward_001_applies_reward_once(self):
        report = self._run_fixture("res://tests/determinism/fixtures/seed_reward_001.json")
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["fixture_id"], "seed_reward_001")
        self.assertEqual(report["combat_result"], "player_win")
        self.assertEqual(report["reward_commit_count"], 1)
        self.assertEqual(report["reward_state"], "applied")
        self.assertTrue(report["reward_selected_card_id"])
        self.assertEqual(report["run_master_deck_size"], 11)

    def test_seed_continue_001_starts_next_encounter_with_rewarded_card_available(self):
        report = self._run_fixture("res://tests/determinism/fixtures/seed_continue_001.json")
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["fixture_id"], "seed_continue_001")
        self.assertEqual(report["encounter_index"], 2)
        self.assertEqual(report["combat_result"], "in_progress")
        self.assertEqual(report["reward_state"], "none")
        self.assertEqual(report["run_master_deck_size"], 11)
        self.assertTrue(report["reward_selected_card_id"])
        self.assertIn(report["reward_selected_card_id"], report["hand"])

    def test_seed_second_reward_001_presents_a_new_reward_after_second_encounter(self):
        report = self._run_fixture("res://tests/determinism/fixtures/seed_second_reward_001.json")
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["fixture_id"], "seed_second_reward_001")
        self.assertEqual(report["encounter_index"], 2)
        self.assertEqual(report["combat_result"], "player_win")
        self.assertEqual(report["reward_state"], "presented")
        self.assertEqual(report["reward_checkpoint_count"], 2)
        self.assertEqual(report["reward_commit_count"], 1)
        self.assertEqual(report["run_master_deck_size"], 11)
        self.assertEqual(report["reward_selected_card_id"], "")
        self.assertEqual(len(report["reward_offer_card_ids"]), 3)


if __name__ == "__main__":
    unittest.main()
