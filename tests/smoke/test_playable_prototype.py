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

    def _run_keyboard_hotkey_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_keyboard_hotkey_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("KEYBOARD_HOTKEY_PROBE="):
                probe_line = line[len("KEYBOARD_HOTKEY_PROBE="):]
        self.assertTrue(probe_line, "missing KEYBOARD_HOTKEY_PROBE output")
        return json.loads(probe_line)

    def _run_card_style_toggle_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_card_style_toggle_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("CARD_STYLE_TOGGLE_PROBE="):
                probe_line = line[len("CARD_STYLE_TOGGLE_PROBE="):]
        self.assertTrue(probe_line, "missing CARD_STYLE_TOGGLE_PROBE output")
        return json.loads(probe_line)

    def _run_encounter_toast_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_encounter_toast_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("ENCOUNTER_TOAST_PROBE="):
                probe_line = line[len("ENCOUNTER_TOAST_PROBE="):]
        self.assertTrue(probe_line, "missing ENCOUNTER_TOAST_PROBE output")
        return json.loads(probe_line)

    def _run_gsm_core_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_gsm_core_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("GSM_CORE_PROBE="):
                probe_line = line[len("GSM_CORE_PROBE="):]
        self.assertTrue(probe_line, "missing GSM_CORE_PROBE output")
        return json.loads(probe_line)

    def _run_gsm_integration_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_gsm_integration_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("GSM_INTEGRATION_PROBE="):
                probe_line = line[len("GSM_INTEGRATION_PROBE="):]
        self.assertTrue(probe_line, "missing GSM_INTEGRATION_PROBE output")
        return json.loads(probe_line)

    def _run_reward_pool_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_reward_pool_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("REWARD_POOL_PROBE="):
                probe_line = line[len("REWARD_POOL_PROBE="):]
        self.assertTrue(probe_line, "missing REWARD_POOL_PROBE output")
        return json.loads(probe_line)

    def _run_hybrid_payoff_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_hybrid_payoff_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("HYBRID_PAYOFF_PROBE="):
                probe_line = line[len("HYBRID_PAYOFF_PROBE="):]
        self.assertTrue(probe_line, "missing HYBRID_PAYOFF_PROBE output")
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
        self.assertTrue(report.get("encounter_intro_flavor"))
        self.assertNotEqual(report.get("encounter_title"), baseline.get("encounter_title"))
        self.assertNotEqual(report.get("encounter_intent_style"), baseline.get("encounter_intent_style"))
        self.assertNotEqual(report.get("encounter_intro_flavor"), baseline.get("encounter_intro_flavor"))

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
        self.assertIn("Add to deck", probe.get("reward_strike_text", ""))
        self.assertIn("permanently add", probe.get("reward_strike_tooltip", ""))

    def test_missing_art_uses_non_crashing_placeholder_state(self):
        probe = self._run_art_fallback_probe()
        self.assertTrue(probe.get("visible"))
        self.assertFalse(probe.get("has_texture"))
        self.assertIn("Missing art asset", probe.get("tooltip", ""))

    def test_hud_theme_contrast_ratios_meet_minimum_readability(self):
        probe = self._run_hud_contrast_probe()
        self.assertTrue(probe.get("ok"), msg=f"contrast failures: {probe.get('failures', [])}")

    def test_keyboard_hotkeys_map_to_hand_reward_and_pass_actions(self):
        probe = self._run_keyboard_hotkey_probe()
        self.assertTrue(probe.get("has_unhandled_input"))
        self.assertEqual(probe.get("played_card_id"), "defend_01")
        self.assertEqual(probe.get("pass_calls"), 1)
        self.assertEqual(probe.get("reward_pick_index"), 1)
        self.assertEqual(probe.get("reward_continue_calls"), 1)
        self.assertIn("1=Strike", probe.get("hand_hotkey_label", ""))
        self.assertIn("2=Defend", probe.get("hand_hotkey_label", ""))
        self.assertIn("Enter=End Turn", probe.get("hand_hotkey_label", ""))

    def test_card_style_toggle_switches_palette_and_label(self):
        probe = self._run_card_style_toggle_probe()
        self.assertEqual(probe.get("style_after_first_toggle"), "alt")
        self.assertEqual(probe.get("style_after_second_toggle"), "classic")
        self.assertNotEqual(probe.get("classic_bg_color"), probe.get("alt_bg_color"))
        self.assertEqual(probe.get("classic_bg_color"), probe.get("classic_again_bg_color"))
        self.assertIn("Style: Classic", probe.get("classic_label", ""))
        self.assertIn("Style: Alt", probe.get("alt_label", ""))
        self.assertIn("V toggle", probe.get("alt_label", ""))

    def test_encounter_toast_persists_until_enter_and_blocks_pass(self):
        probe = self._run_encounter_toast_probe()
        self.assertTrue(probe.get("visible_immediately"))
        self.assertTrue(probe.get("visible_after_delay"))
        self.assertFalse(probe.get("visible_after_enter"))
        self.assertEqual(probe.get("pass_calls"), 0)

    def test_gsm_core_supports_lifo_and_focus_gate(self):
        probe = self._run_gsm_core_probe()
        self.assertTrue(probe.get("consume_top_ok"))
        self.assertEqual(probe.get("consume_top_gem"), "Sapphire")
        self.assertEqual(probe.get("consume_top_reject_reason"), "ERR_STACK_TOP_MISMATCH")
        self.assertEqual(probe.get("advanced_without_focus_reason"), "ERR_FOCUS_REQUIRED")
        self.assertTrue(probe.get("advanced_with_focus_ok"))
        self.assertEqual(probe.get("advanced_with_focus_gem"), "Ruby")
        self.assertEqual(probe.get("final_stack"), ["Sapphire"])

    def test_gsm_runner_integration_resolves_focus_gated_cards(self):
        probe = self._run_gsm_integration_probe()
        self.assertEqual(probe.get("focus_gate_reason"), "ERR_FOCUS_REQUIRED")
        self.assertEqual(probe.get("focus_after_focus_card"), 1)
        self.assertEqual(probe.get("focus_after_advanced_consume"), 0)
        self.assertEqual(probe.get("stack_after_advanced_consume"), ["Sapphire"])
        self.assertEqual(probe.get("vm_stack_top"), ["Sapphire"])
        self.assertIn("FOCUS", probe.get("zones_text", ""))
        self.assertIn("Gem Top", probe.get("zones_text", ""))
        self.assertIn("Sapphire", probe.get("zones_text", ""))
        self.assertIn("Consumed Ruby", probe.get("advanced_event_line", ""))
        self.assertIn("Produce 1 Ruby", probe.get("gem_producer_button_text", ""))

    def test_reward_pool_keeps_gsm_cards_opt_in(self):
        probe = self._run_reward_pool_probe()
        self.assertFalse(probe.get("normal_has_gsm"))
        self.assertTrue(probe.get("gsm_all_are_gsm"))

    def test_hybrid_cards_resolve_combat_and_gem_effects_together(self):
        probe = self._run_hybrid_payoff_probe()
        self.assertEqual(probe.get("enemy_hp_after"), 15)
        self.assertEqual(probe.get("player_block_after"), 7)
        self.assertEqual(probe.get("focus_after"), 1)
        self.assertEqual(probe.get("stack_after"), ["Ruby"])
        self.assertEqual(probe.get("resolve_count_ruby_strike"), 2)
        self.assertEqual(probe.get("resolve_count_sapphire_guard"), 2)
        self.assertEqual(probe.get("resolve_count_focus_guard"), 2)
        self.assertEqual(probe.get("resolve_count_sapphire_burst"), 2)
        self.assertIn("Hybrid", probe.get("hybrid_button_text", ""))
        self.assertIn("Produce 1 Ruby", probe.get("hybrid_button_text", ""))


if __name__ == "__main__":
    unittest.main()
