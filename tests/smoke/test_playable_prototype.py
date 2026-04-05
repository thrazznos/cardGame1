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

    def _run_draw_log_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_draw_log_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("DRAW_LOG_PROBE="):
                probe_line = line[len("DRAW_LOG_PROBE="):]
        self.assertTrue(probe_line, "missing DRAW_LOG_PROBE output")
        return json.loads(probe_line)

    def _run_card_identity_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_card_identity_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("CARD_IDENTITY_PROBE="):
                probe_line = line[len("CARD_IDENTITY_PROBE="):]
        self.assertTrue(probe_line, "missing CARD_IDENTITY_PROBE output")
        return json.loads(probe_line)

    def _run_art_fallback_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_art_fallback_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("ART_FALLBACK_PROBE="):
                probe_line = line[len("ART_FALLBACK_PROBE="):]
        self.assertTrue(probe_line, "missing ART_FALLBACK_PROBE output")
        return json.loads(probe_line)

    def _run_hud_contrast_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_hud_contrast_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("HUD_CONTRAST_PROBE="):
                probe_line = line[len("HUD_CONTRAST_PROBE="):]
        self.assertTrue(probe_line, "missing HUD_CONTRAST_PROBE output")
        return json.loads(probe_line)

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

        baseline = self._run_fixture("res://tests/determinism/fixtures/seed_smoke_001.json")
        self.assertTrue(report.get("encounter_title"))
        self.assertTrue(report.get("encounter_intent_style"))
        self.assertNotEqual(report.get("encounter_title"), baseline.get("encounter_title"))
        self.assertNotEqual(report.get("encounter_intent_style"), baseline.get("encounter_intent_style"))

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

    def test_draw_effect_event_log_includes_drawn_card_id(self):
        probe = self._run_draw_log_probe()
        self.assertTrue(probe.get("ok"))
        self.assertEqual(probe.get("drawn_card"), "strike_probe")
        self.assertIn("Drew: strike_probe.", probe.get("effect_resolve_line", ""))

    def test_card_identity_markers_render_for_core_card_types(self):
        probe = self._run_card_identity_probe()
        self.assertIn("[ATK]", probe.get("strike_text", ""))
        self.assertIn("[DEF]", probe.get("defend_text", ""))
        self.assertIn("[UTL]", probe.get("utility_text", ""))
        self.assertIn("Attack card", probe.get("strike_tooltip", ""))
        self.assertIn("Defense card", probe.get("defend_tooltip", ""))
        self.assertIn("Utility card", probe.get("utility_tooltip", ""))

    def test_missing_art_uses_non_crashing_placeholder_state(self):
        probe = self._run_art_fallback_probe()
        self.assertTrue(probe.get("visible"))
        self.assertFalse(probe.get("has_texture"))
        self.assertIn("Missing art asset", probe.get("tooltip", ""))

    def test_hud_theme_contrast_ratios_meet_minimum_readability(self):
        probe = self._run_hud_contrast_probe()
        self.assertTrue(probe.get("ok"), msg=f"contrast failures: {probe.get('failures', [])}")


if __name__ == "__main__":
    unittest.main()
