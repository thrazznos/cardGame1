import json
import subprocess
import unittest
from pathlib import Path

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

    def _run_gameplay_art_visibility_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_gameplay_art_visibility_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("GAMEPLAY_ART_VISIBILITY_PROBE="):
                probe_line = line[len("GAMEPLAY_ART_VISIBILITY_PROBE="):]
        self.assertTrue(probe_line, "missing GAMEPLAY_ART_VISIBILITY_PROBE output")
        return json.loads(probe_line)

    def _run_reward_overlay_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_reward_overlay_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("REWARD_OVERLAY_PROBE="):
                probe_line = line[len("REWARD_OVERLAY_PROBE="):]
        self.assertTrue(probe_line, "missing REWARD_OVERLAY_PROBE output")
        return json.loads(probe_line)

    def _run_combat_stage_event_feed_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_combat_stage_event_feed_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("COMBAT_STAGE_EVENT_FEED_PROBE="):
                probe_line = line[len("COMBAT_STAGE_EVENT_FEED_PROBE="):]
        self.assertTrue(probe_line, "missing COMBAT_STAGE_EVENT_FEED_PROBE output")
        return json.loads(probe_line)

    def _run_combat_stage_reward_hit_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_combat_stage_reward_hit_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("COMBAT_STAGE_REWARD_HIT_PROBE="):
                probe_line = line[len("COMBAT_STAGE_REWARD_HIT_PROBE="):]
        self.assertTrue(probe_line, "missing COMBAT_STAGE_REWARD_HIT_PROBE output")
        return json.loads(probe_line)

    def _run_combat_stage_hand_hit_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_combat_stage_hand_hit_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("COMBAT_STAGE_HAND_HIT_PROBE="):
                probe_line = line[len("COMBAT_STAGE_HAND_HIT_PROBE="):]
        self.assertTrue(probe_line, "missing COMBAT_STAGE_HAND_HIT_PROBE output")
        return json.loads(probe_line)

    def _run_map_hover_cursor_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_map_hover_cursor_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("MAP_HOVER_CURSOR_PROBE="):
                probe_line = line[len("MAP_HOVER_CURSOR_PROBE="):]
        self.assertTrue(probe_line, "missing MAP_HOVER_CURSOR_PROBE output")
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

    def _run_card_hover_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_card_hover_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("CARD_HOVER_PROBE="):
                probe_line = line[len("CARD_HOVER_PROBE="):]
        self.assertTrue(probe_line, "missing CARD_HOVER_PROBE output")
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

    def _run_live_reward_context_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_live_reward_context_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("LIVE_REWARD_CONTEXT_PROBE="):
                probe_line = line[len("LIVE_REWARD_CONTEXT_PROBE="):]
        self.assertTrue(probe_line, "missing LIVE_REWARD_CONTEXT_PROBE output")
        return json.loads(probe_line)

    def _run_gem_gate_block_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_gem_gate_block_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("GEM_GATE_BLOCK_PROBE="):
                probe_line = line[len("GEM_GATE_BLOCK_PROBE="):]
        self.assertTrue(probe_line, "missing GEM_GATE_BLOCK_PROBE output")
        return json.loads(probe_line)

    def _run_event_readability_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_event_readability_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("EVENT_READABILITY_PROBE="):
                probe_line = line[len("EVENT_READABILITY_PROBE="):]
        self.assertTrue(probe_line, "missing EVENT_READABILITY_PROBE output")
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

    def _run_deck_inspection_snapshot_builder_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_deck_inspection_snapshot_builder_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("DECK_INSPECTION_SNAPSHOT_BUILDER_PROBE="):
                probe_line = line[len("DECK_INSPECTION_SNAPSHOT_BUILDER_PROBE="):]
        self.assertTrue(probe_line, "missing DECK_INSPECTION_SNAPSHOT_BUILDER_PROBE output")
        return json.loads(probe_line)

    def _run_deck_inspection_overlay_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_deck_inspection_overlay_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("DECK_INSPECTION_OVERLAY_PROBE="):
                probe_line = line[len("DECK_INSPECTION_OVERLAY_PROBE="):]
        self.assertTrue(probe_line, "missing DECK_INSPECTION_OVERLAY_PROBE output")
        return json.loads(probe_line)

    def _run_combat_deck_overlay_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_combat_deck_overlay_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("COMBAT_DECK_OVERLAY_PROBE="):
                probe_line = line[len("COMBAT_DECK_OVERLAY_PROBE="):]
        self.assertTrue(probe_line, "missing COMBAT_DECK_OVERLAY_PROBE output")
        return json.loads(probe_line)

    def _run_escape_exit_overlay_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_escape_exit_overlay_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("ESCAPE_EXIT_OVERLAY_PROBE="):
                probe_line = line[len("ESCAPE_EXIT_OVERLAY_PROBE="):]
        self.assertTrue(probe_line, "missing ESCAPE_EXIT_OVERLAY_PROBE output")
        return json.loads(probe_line)

    def _run_map_deck_overlay_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_map_deck_overlay_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("MAP_DECK_OVERLAY_PROBE="):
                probe_line = line[len("MAP_DECK_OVERLAY_PROBE="):]
        self.assertTrue(probe_line, "missing MAP_DECK_OVERLAY_PROBE output")
        return json.loads(probe_line)

    def _run_gsm_pilot_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_gsm_pilot_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("GSM_PILOT_PROBE="):
                probe_line = line[len("GSM_PILOT_PROBE="):]
        self.assertTrue(probe_line, "missing GSM_PILOT_PROBE output")
        return json.loads(probe_line)

    def _run_card_catalog_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_card_catalog_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("CARD_CATALOG_PROBE="):
                probe_line = line[len("CARD_CATALOG_PROBE="):]
        self.assertTrue(probe_line, "missing CARD_CATALOG_PROBE output")
        return json.loads(probe_line)

    def _run_card_instance_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_card_instance_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("CARD_INSTANCE_PROBE="):
                probe_line = line[len("CARD_INSTANCE_PROBE="):]
        self.assertTrue(probe_line, "missing CARD_INSTANCE_PROBE output")
        return json.loads(probe_line)

    def _run_card_play_contract_probe(self) -> dict:
        cmd = [
            resolve_godot_executable(),
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/smoke/run_card_play_contract_probe.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        probe_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("CARD_PLAY_CONTRACT_PROBE="):
                probe_line = line[len("CARD_PLAY_CONTRACT_PROBE="):]
        self.assertTrue(probe_line, "missing CARD_PLAY_CONTRACT_PROBE output")
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
        rewarded_runtime_ids = [
            instance_id
            for instance_id, card_id in zip(report["hand"], report["hand_card_ids"])
            if card_id == report["reward_selected_card_id"]
        ]
        self.assertTrue(rewarded_runtime_ids)
        self.assertTrue(
            all(instance_id != report["reward_selected_card_id"] for instance_id in rewarded_runtime_ids)
        )

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

    def test_seed_identity_001_supports_explicit_fixture_instance_payloads(self):
        report = self._run_fixture("res://tests/determinism/fixtures/seed_identity_001.json")
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["fixture_id"], "seed_identity_001")
        self.assertEqual(report["combat_result"], "in_progress")
        self.assertEqual(report["discard"], ["strike_beta"])
        self.assertEqual(report["discard_card_ids"], ["strike"])
        self.assertEqual(report["hand"], ["strike_alpha", "strike_gamma", "strike_delta"])
        self.assertEqual(report["hand_card_ids"], ["strike", "strike", "strike"])

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
        self.assertIn("Reward effect", probe.get("reward_strike_tooltip", ""))

    def test_reward_variants_render_distinct_authored_identities(self):
        probe = self._run_card_identity_probe()
        self.assertNotEqual(probe.get("reward_strike_plus_text"), probe.get("reward_strike_precise_text"))
        self.assertNotEqual(probe.get("reward_defend_plus_text"), probe.get("reward_defend_hold_text"))
        self.assertIn("Strike+", probe.get("reward_strike_plus_text", ""))
        self.assertIn("Precise", probe.get("reward_strike_precise_text", ""))
        self.assertIn("Defend+", probe.get("reward_defend_plus_text", ""))
        self.assertIn("Hold", probe.get("reward_defend_hold_text", ""))

    def test_card_catalog_loads_cleanly_and_resolves_aliases(self):
        probe = self._run_card_catalog_probe()
        self.assertEqual(probe.get("validation_errors"), [])
        self.assertEqual(probe.get("starter_deck_size"), 12)
        self.assertEqual(probe.get("alias_display_name"), "Strike")
        self.assertEqual(probe.get("alias_resolved_id"), "strike")
        self.assertEqual(probe.get("reward_variant_name"), "Strike+")
        self.assertTrue(probe.get("has_effects"))
        self.assertEqual(probe.get("invalid_weight_modifier_errors"), ["ERR_CARD_WEIGHT_MODIFIERS_INVALID:probe_invalid_weight_modifier"])
        self.assertEqual(probe.get("valid_weight_modifier_errors"), [])
        self.assertEqual(probe.get("strike_authored_effect_id"), "deal_damage")
        self.assertEqual(probe.get("strike_authored_effect_params"), {"amount": 6})
        self.assertEqual(probe.get("strike_normalized_effect", {}).get("type"), "deal_damage")
        self.assertEqual(probe.get("strike_normalized_effect", {}).get("amount"), 6)
        self.assertEqual(probe.get("strike_precise_authored_effect_ids"), ["deal_damage", "draw_n"])
        self.assertEqual(
            [effect.get("type") for effect in probe.get("strike_precise_normalized_effects", [])],
            ["deal_damage", "draw_n"],
        )

    def test_card_play_contract_comes_from_authored_data(self):
        probe = self._run_card_play_contract_probe()
        self.assertEqual(probe.get("catalog_base_cost"), 2)
        self.assertEqual(probe.get("catalog_cost_type"), "energy")
        self.assertEqual(probe.get("catalog_target_mode"), "single_enemy")
        self.assertEqual(probe.get("catalog_max_targets"), 1)
        self.assertEqual(probe.get("catalog_invalid_target_policy"), "fizzle")
        self.assertEqual(probe.get("catalog_play_conditions"), [])
        self.assertEqual(probe.get("catalog_combo_tags"), ["probe", "contract"])
        self.assertEqual(probe.get("catalog_chain_flags"), [])
        self.assertEqual(probe.get("catalog_weight_modifiers"), [])
        self.assertEqual(probe.get("catalog_speed_class"), "fast")
        self.assertEqual(probe.get("catalog_timing_window"), "pre")
        self.assertEqual(probe.get("catalog_zone_on_play"), "exhaust")
        self.assertEqual(probe.get("normalized_effect", {}).get("type"), "deal_damage")
        self.assertEqual(probe.get("normalized_effect", {}).get("amount"), 1)
        self.assertEqual(probe.get("retain_probe_zone_on_play"), "retain")
        self.assertEqual(probe.get("temp_probe_zone_on_play"), "temp")
        self.assertEqual(probe.get("stack_probe_target_mode"), "none")
        self.assertEqual(probe.get("stack_probe_max_targets"), 0)
        self.assertEqual(probe.get("stack_probe_invalid_target_policy"), "fizzle")
        self.assertEqual(
            probe.get("stack_probe_play_conditions"),
            [{"condition_id": "stack_top_is", "gem": "Ruby"}],
        )
        self.assertEqual(
            probe.get("discard_probe_play_conditions"),
            [{"condition_id": "discard_at_least", "amount": 2}],
        )
        self.assertFalse(probe.get("low_energy_ok"))
        self.assertEqual(probe.get("low_energy_reason"), "ERR_NOT_ENOUGH_ENERGY")
        self.assertEqual(probe.get("low_energy_hand_after"), ["probe_contract_anchor_runtime"])
        self.assertEqual(probe.get("low_energy_discard"), 0)
        self.assertEqual(probe.get("low_energy_exhaust"), 0)
        self.assertTrue(probe.get("play_ok"))
        self.assertEqual(probe.get("energy_after_play"), 1)
        self.assertEqual(probe.get("enemy_hp_after"), probe.get("enemy_hp_before") - 1)
        self.assertEqual(probe.get("last_resolved_card_id"), "probe_contract_anchor")
        self.assertEqual(probe.get("last_resolved_timing_priority"), 0)
        self.assertEqual(probe.get("last_resolved_speed_priority"), 0)
        self.assertEqual(probe.get("discard_after_play"), 0)
        self.assertEqual(probe.get("exhaust_after_play"), 1)
        self.assertEqual(probe.get("hand_after_play"), [])
        self.assertEqual(probe.get("exhaust_top_instance_id"), "probe_contract_anchor_runtime")
        self.assertEqual(probe.get("exhaust_top_card_id"), "probe_contract_anchor")
        self.assertFalse(probe.get("stack_empty_ok"))
        self.assertEqual(probe.get("stack_empty_reason"), "ERR_STACK_EMPTY")
        self.assertEqual(probe.get("stack_empty_hand_after"), ["probe_stack_top_anchor_runtime"])
        self.assertFalse(probe.get("stack_mismatch_ok"))
        self.assertEqual(probe.get("stack_mismatch_reason"), "ERR_STACK_TOP_MISMATCH")
        self.assertFalse(probe.get("discard_gate_ok"))
        self.assertEqual(probe.get("discard_gate_reason"), "ERR_DISCARD_REQUIRED")
        self.assertEqual(probe.get("discard_gate_hand_after"), ["probe_discard_ready_anchor_runtime"])
        self.assertTrue(probe.get("discard_ready_ok"))
        self.assertEqual(probe.get("discard_ready_energy_after"), 0)
        self.assertEqual(probe.get("discard_ready_block_gain"), 4)
        self.assertEqual(probe.get("discard_ready_last_resolved_card_id"), "probe_discard_ready_anchor")
        self.assertTrue(probe.get("retain_ready_ok"))
        self.assertEqual(probe.get("retain_ready_energy_after"), 0)
        self.assertEqual(probe.get("retain_ready_block_gain"), 3)
        self.assertEqual(probe.get("retain_ready_hand_after"), ["probe_retain_anchor_runtime"])
        self.assertEqual(probe.get("retain_ready_discard_after"), 0)
        self.assertEqual(probe.get("retain_ready_exhaust_after"), 0)
        self.assertTrue(probe.get("temp_ready_ok"))
        self.assertEqual(probe.get("temp_ready_energy_after"), 0)
        self.assertEqual(probe.get("temp_ready_hand_after"), [])
        self.assertEqual(probe.get("temp_ready_exhaust_after"), 1)
        self.assertEqual(probe.get("temp_ready_exhaust_top_instance_id"), "probe_temp_anchor_runtime")
        self.assertEqual(probe.get("temp_ready_exhaust_top_card_id"), "probe_temp_anchor")
        self.assertFalse(probe.get("no_target_attack_ok"))
        self.assertEqual(probe.get("no_target_attack_reason"), "ERR_NO_VALID_TARGETS")
        self.assertTrue(probe.get("targetless_play_ok"))
        self.assertEqual(probe.get("targetless_energy_after"), 0)
        self.assertEqual(probe.get("targetless_hand_after"), ["probe_draw_strike_runtime"])
        self.assertEqual(probe.get("targetless_last_resolved_card_id"), "probe_stack_top_anchor")
        self.assertEqual(probe.get("targetless_last_resolved_effect_type"), "draw_n")
        self.assertEqual(probe.get("targetless_last_resolved_effect_amount"), 1)

    def test_runtime_card_instances_preserve_instance_id_and_card_id(self):
        probe = self._run_card_instance_probe()
        self.assertEqual(probe.get("normalized_instance_id"), "strike_01")
        self.assertEqual(probe.get("normalized_card_id"), "strike")
        self.assertEqual(probe.get("alias_dict_instance_id"), "strike_01")
        self.assertEqual(probe.get("alias_dict_card_id"), "strike")
        self.assertEqual(probe.get("alias_dict_card_id_of"), "strike")
        self.assertEqual(probe.get("inferred_dict_instance_id"), "strike_02")
        self.assertEqual(probe.get("inferred_dict_card_id"), "strike")
        self.assertTrue(probe.get("hand_internal_uses_dictionaries"))
        self.assertTrue(probe.get("draw_internal_uses_dictionaries"))
        self.assertEqual(probe.get("view_hand_first"), "strike_01")
        self.assertTrue(probe.get("raw_string_hand_normalized"))
        self.assertTrue(probe.get("raw_string_draw_normalized"))

    def test_runtime_card_instances_resolve_authored_effects_without_alias_ids(self):
        probe = self._run_card_instance_probe()
        self.assertEqual(probe.get("runtime_view_hand_before_play"), ["combat_runtime_strike_alpha"])
        self.assertEqual(probe.get("runtime_view_hand_after_play"), [])
        self.assertTrue(probe.get("play_ok"))
        self.assertEqual(probe.get("enemy_hp_after"), probe.get("enemy_hp_before") - 6)
        self.assertEqual(probe.get("last_resolved_source_instance_id"), "combat_runtime_strike_alpha")
        self.assertEqual(probe.get("last_resolved_card_id"), "strike")
        self.assertEqual(probe.get("last_resolved_effect_type"), "deal_damage")
        self.assertEqual(probe.get("last_resolved_effect_amount"), 6)
        self.assertEqual(probe.get("discard_top_instance_id"), "combat_runtime_strike_alpha")
        self.assertEqual(probe.get("discard_top_card_id"), "strike")
        self.assertFalse(probe.get("play_by_authored_id_ok"))
        self.assertEqual(probe.get("play_by_authored_id_reason"), "ERR_CARD_NOT_IN_HAND")
        self.assertIn("combat_runtime_strike_alpha", probe.get("effect_resolve_line", ""))

    def test_runtime_card_instances_reject_missing_authored_card_definitions(self):
        probe = self._run_card_instance_probe()
        self.assertFalse(probe.get("invalid_runtime_play_ok"))
        self.assertEqual(probe.get("invalid_runtime_play_reason"), "ERR_CARD_DEFINITION_NOT_FOUND")

    def test_runtime_reward_copies_render_authored_hand_presentation(self):
        probe = self._run_card_instance_probe()
        self.assertEqual(probe.get("reward_copy_view_hand"), ["combat_reward_strike_plus_alpha"])
        self.assertEqual(probe.get("reward_copy_view_hand_card_ids"), ["strike_plus"])
        self.assertIn("1=Strike+", probe.get("reward_copy_hand_hotkey_text", ""))
        self.assertIn("Strike+", probe.get("reward_copy_button_text", ""))
        self.assertIn("[ATK]", probe.get("reward_copy_button_text", ""))
        self.assertIn("deal 7 damage", probe.get("reward_copy_button_tooltip", ""))
        self.assertEqual(probe.get("reward_copy_button_card_id_meta"), "strike_plus")
        self.assertEqual(probe.get("reward_copy_button_instance_id_meta"), "combat_reward_strike_plus_alpha")
        self.assertEqual(probe.get("reward_copy_button_role_tooltip"), "[ATK]")
        self.assertEqual(probe.get("reward_copy_button_art_tooltip"), "Strike+")

    def test_live_materialization_preserves_authored_aliases_and_mints_reward_copy_ids(self):
        probe = self._run_card_instance_probe()
        self.assertEqual(probe.get("bootstrap_alias_instance_id"), "strike_01")
        self.assertEqual(probe.get("bootstrap_alias_card_id"), "strike")
        self.assertEqual(probe.get("bootstrap_reward_card_ids"), ["strike_plus", "strike_plus"])
        self.assertEqual(len(set(probe.get("bootstrap_reward_instance_ids", []))), 2)
        self.assertNotIn("strike_plus", probe.get("bootstrap_reward_instance_ids", []))
        self.assertEqual(
            probe.get("bootstrap_reward_instance_ids"),
            probe.get("bootstrap_reward_instance_ids_repeat"),
        )

    def test_reward_added_runtime_copy_gets_unique_instance_id(self):
        probe = self._run_card_instance_probe()
        self.assertTrue(probe.get("reward_pick_ok"))
        self.assertEqual(probe.get("reward_discard_card_id"), "strike_plus")
        self.assertNotEqual(probe.get("reward_discard_instance_id"), "strike_plus")

    def test_missing_art_uses_non_crashing_placeholder_state(self):
        probe = self._run_art_fallback_probe()
        self.assertTrue(probe.get("visible"))
        self.assertFalse(probe.get("has_texture"))
        self.assertIn("Missing art asset", probe.get("tooltip", ""))

    def test_generated_gameplay_art_surfaces_in_buttons_and_gem_strip(self):
        probe = self._run_gameplay_art_visibility_probe()
        self.assertTrue(probe.get("hand_art_has_texture"))
        self.assertTrue(probe.get("hand_role_icon_has_texture"))
        self.assertTrue(probe.get("reward_art_has_texture"))
        self.assertTrue(probe.get("reward_role_icon_has_texture"))
        self.assertTrue(probe.get("gem_top_1_has_texture"))
        self.assertTrue(probe.get("gem_top_2_has_texture"))
        self.assertTrue(probe.get("focus_icon_has_texture"))
        self.assertEqual(probe.get("focus_value_text"), "1")
        self.assertTrue(probe.get("lock_icon_has_texture"))
        self.assertTrue(probe.get("lock_icon_visible"))
        self.assertIn("FOCUS", probe.get("zones_text", ""))
        self.assertIn("Gem Top", probe.get("zones_text", ""))
        self.assertIn("Sapphire", probe.get("zones_text", ""))

    def test_reward_overlay_presents_and_then_confirms_reward_state_cleanly(self):
        probe = self._run_reward_overlay_probe()
        self.assertTrue(probe.get("presented_overlay_visible"))
        self.assertTrue(probe.get("presented_seal_has_texture"))
        self.assertGreaterEqual(probe.get("presented_visible_reward_count", 0), 3)
        self.assertIn("Victory Reward", probe.get("presented_title", ""))
        self.assertIn("Choose 1 card", probe.get("presented_subtitle", ""))
        self.assertIn("Hotkeys: 1-3 pick reward", probe.get("presented_state_text", ""))
        self.assertFalse(probe.get("presented_continue_visible"))
        self.assertEqual(probe.get("presented_selected_footer"), "Add to deck")
        self.assertTrue(probe.get("applied_overlay_visible"))
        self.assertIn("Checkpoint Complete", probe.get("applied_title", ""))
        self.assertIn("Reward secured", probe.get("applied_subtitle", ""))
        self.assertIn("Reward claimed.", probe.get("applied_state_text", ""))
        self.assertIn("Enter starts next encounter", probe.get("applied_state_text", ""))
        self.assertTrue(probe.get("applied_continue_visible"))
        self.assertEqual(probe.get("applied_selected_footer"), "Chosen")
        self.assertEqual(probe.get("applied_unselected_footer"), "Reward secured")
        self.assertTrue(probe.get("applied_selected_disabled"))
        self.assertTrue(probe.get("applied_unselected_disabled"))

    def test_combat_stage_event_feed_keeps_latest_event_readable_and_toned(self):
        probe = self._run_combat_stage_event_feed_probe()
        self.assertGreaterEqual(probe.get("panel_width", 0), 340)
        self.assertGreaterEqual(probe.get("panel_height", 0), 140)
        self.assertEqual(probe.get("row_count"), 3)
        self.assertEqual(probe.get("latest_tone"), "bad")
        self.assertEqual(probe.get("reward_tone"), "good")
        self.assertEqual(probe.get("resolve_tone"), "neutral")
        self.assertEqual(probe.get("latest_badge"), "#11")
        self.assertEqual(probe.get("reward_badge"), "#10")
        self.assertIn("Can't play Strike", probe.get("latest_text", ""))
        self.assertIn("no living target matches this card", probe.get("latest_text", ""))
        self.assertIn("Reward checkpoint opened", probe.get("reward_text", ""))
        self.assertIn("Strike+", probe.get("reward_text", ""))
        self.assertIn("Resolve Strike", probe.get("resolve_text", ""))
        self.assertIn("Reward selection rejected", probe.get("reward_reject_text", ""))
        self.assertIn("no reward is available", probe.get("reward_reject_text", "").lower())
        self.assertEqual(probe.get("reward_reject_tone"), "bad")
        self.assertLessEqual(probe.get("latest_text_length", 999), 72)
        self.assertLessEqual(probe.get("reward_text_length", 999), 64)
        self.assertTrue(probe.get("latest_is_primary"))
        self.assertFalse(probe.get("reward_is_primary"))

    def test_combat_stage_reward_overlay_hitboxes_match_visible_cards(self):
        probe = self._run_combat_stage_reward_hit_probe()
        self.assertEqual(probe.get("hit_first"), 0)
        self.assertEqual(probe.get("hit_second"), 1)
        self.assertEqual(probe.get("hit_third"), 2)
        self.assertEqual(probe.get("gap_between_cards"), -1)
        self.assertEqual(probe.get("space_above_first"), -1)
        self.assertEqual(probe.get("hover_lift_second"), 1)
        self.assertEqual(probe.get("hover_lift_above_range"), -1)

    def test_combat_stage_hovered_hand_hitboxes_match_visible_card_bounds(self):
        probe = self._run_combat_stage_hand_hit_probe()
        self.assertEqual(probe.get("base_first"), 0)
        self.assertEqual(probe.get("base_second"), 1)
        self.assertEqual(probe.get("base_third"), 2)
        self.assertEqual(probe.get("hovered_extension_hit"), 1)
        self.assertEqual(probe.get("hovered_above_miss"), -1)

    def test_map_hover_cursor_resets_when_state_changes(self):
        probe = self._run_map_hover_cursor_probe()
        self.assertEqual(probe.get("refresh_hovered_node"), -1)
        self.assertEqual(probe.get("refresh_cursor"), 0)
        self.assertEqual(probe.get("show_event_hovered_node"), -1)
        self.assertEqual(probe.get("show_event_cursor"), 0)
        self.assertEqual(probe.get("dismiss_hovered_node"), -1)
        self.assertEqual(probe.get("dismiss_cursor"), 0)

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

    def test_card_hover_enlarges_hand_card_and_then_resets(self):
        probe = self._run_card_hover_probe()
        self.assertEqual(probe.get("scale_before"), {"x": 1.0, "y": 1.0})
        self.assertGreaterEqual(probe.get("scale_hover", {}).get("x", 0.0), 1.45)
        self.assertGreaterEqual(probe.get("scale_hover", {}).get("y", 0.0), 1.45)
        self.assertGreater(probe.get("z_hover", 0), probe.get("z_before", 0))
        self.assertEqual(probe.get("scale_after"), {"x": 1.0, "y": 1.0})
        self.assertEqual(probe.get("z_after", 0), 0)

    def test_combat_scene_uses_card_like_geometry_and_face_hooks(self):
        scene_text = Path("scenes/combat/combat_slice.tscn").read_text()
        controller_text = Path("src/ui/combat_hud/combat_hud_controller.gd").read_text()

        self.assertIn('alignment = 1', scene_text)
        self.assertIn('theme_override_constants/separation = -176', scene_text)
        self.assertIn('theme_override_constants/separation = 20', scene_text)
        self.assertIn('size_flags_vertical = 3', scene_text)
        self.assertIn('alignment = 2', scene_text)
        self.assertIn('custom_minimum_size = Vector2(0, 64)', scene_text)
        self.assertGreaterEqual(scene_text.count('custom_minimum_size = Vector2(448, 640)'), 5)
        self.assertGreaterEqual(scene_text.count('custom_minimum_size = Vector2(336, 480)'), 3)
        self.assertIn('func _ensure_card_face(button: Button, is_reward: bool) -> void:', controller_text)
        for hook_name in [
            '"Chrome"',
            '"ArtFrame"',
            '"TitleRail"',
            '"FooterStrip"',
            '"HotkeyBadge"',
            '"CostBadge"',
            '"NameLabel"',
            '"PayoffLabel"',
            '"RulesLabel"',
            '"FooterLabel"',
        ]:
            self.assertIn(hook_name, controller_text)

    def test_encounter_toast_auto_dismisses_without_enter(self):
        probe = self._run_encounter_toast_probe()
        self.assertTrue(probe.get("visible_immediately"))
        self.assertFalse(probe.get("visible_after_auto_delay"))
        self.assertFalse(probe.get("visible_after_enter"))
        self.assertEqual(probe.get("pass_calls_while_visible"), 0)
        self.assertEqual(probe.get("pass_calls_after_auto_dismiss"), 1)

    def test_gsm_core_supports_lifo_and_focus_gate(self):
        probe = self._run_gsm_core_probe()
        self.assertTrue(probe.get("consume_top_ok"))
        self.assertEqual(probe.get("consume_top_gem"), "Sapphire")
        self.assertEqual(probe.get("consume_top_reject_reason"), "ERR_STACK_TOP_MISMATCH")
        self.assertEqual(probe.get("peek_top_before_consume"), "Sapphire")
        self.assertEqual(probe.get("peek_two_before_consume"), ["Ruby", "Sapphire"])
        self.assertEqual(probe.get("peek_three_after_consume"), ["Ruby", "Sapphire"])
        self.assertEqual(probe.get("advanced_without_focus_reason"), "ERR_FOCUS_REQUIRED")
        self.assertTrue(probe.get("advanced_with_focus_ok"))
        self.assertEqual(probe.get("advanced_with_focus_gem"), "Ruby")
        self.assertEqual(probe.get("final_stack"), ["Sapphire"])

    def test_live_starter_surfaces_gsm_pilot_cards_immediately(self):
        probe = self._run_gsm_pilot_probe()
        self.assertEqual(probe.get("deck_size"), 12)
        self.assertEqual(probe.get("gsm_card_count"), 8)
        self.assertTrue(probe.get("has_focus_card"))
        self.assertTrue(probe.get("has_advanced_card"))
        self.assertGreaterEqual(probe.get("opening_hand_gsm_count", 0), 4)
        self.assertIn("gem_focus_a", probe.get("opening_hand", []))
        self.assertIn("gem_offset_consume_ruby_ok", probe.get("opening_hand", []))
        self.assertIn("gem_produce_ruby_a", probe.get("opening_hand", []))
        self.assertIn("Offset Scalpel", probe.get("first_button_text", ""))

    def test_gsm_runner_integration_resolves_focus_gated_cards(self):
        probe = self._run_gsm_integration_probe()
        self.assertTrue(probe.get("advanced_disabled_before_focus"))
        self.assertIn("FOCUS", probe.get("advanced_tooltip_before_focus", ""))
        self.assertFalse(probe.get("failed_play_ok"))
        self.assertEqual(probe.get("focus_gate_reason"), "ERR_FOCUS_REQUIRED")
        self.assertEqual(probe.get("focus_gate_result_reason"), "ERR_FOCUS_REQUIRED")
        self.assertIn("gem_offset_consume_ruby_fail", probe.get("hand_after_failed_play", []))
        self.assertEqual(probe.get("focus_after_failed_play"), 0)
        self.assertEqual(probe.get("stack_after_failed_play"), ["Ruby", "Sapphire"])
        self.assertEqual(probe.get("focus_after_focus_card"), 1)
        self.assertFalse(probe.get("advanced_disabled_after_focus"))
        self.assertNotIn("Unavailable:", probe.get("advanced_tooltip_after_focus", ""))
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
        self.assertEqual(len(probe.get("normal_ids", [])), 3)
        self.assertFalse(probe.get("normal_has_gsm"))
        self.assertTrue(probe.get("gsm_all_are_gsm"))
        self.assertEqual(probe.get("mixed_normal_ids"), ["base_alpha", "base_beta", "base_alpha"])
        self.assertEqual(probe.get("mixed_gsm_ids"), ["gsm_beta", "gsm_alpha", "gsm_alpha"])
        self.assertTrue(probe.get("mixed_normal_all_base"))
        self.assertTrue(probe.get("mixed_gsm_all_gsm"))

    def test_unaffordable_gem_gates_block_room_entry(self):
        probe = self._run_gem_gate_block_probe()
        self.assertTrue(probe.get("ok"), msg=probe)
        self.assertNotIn(probe.get("gated_node_id"), probe.get("legal_moves_before", []))
        self.assertFalse(probe.get("select_ok"))
        self.assertEqual(probe.get("select_reason"), "ERR_GEM_GATE_UNAFFORDABLE")
        self.assertFalse(probe.get("enter_ok"))
        self.assertEqual(probe.get("enter_reason"), "")
        self.assertEqual(probe.get("state_after_attempt"), "room_select")
        self.assertEqual(probe.get("stack_after_attempt"), [])
        self.assertEqual(probe.get("cap_after_attempt"), 6)
        self.assertNotIn("gem_gate_paid", probe.get("event_kinds", []))
        self.assertNotIn("gem_slot_lost", probe.get("event_kinds", []))

    def test_reward_pool_uses_metadata_weights_without_replacement(self):
        probe = self._run_reward_pool_probe()
        self.assertEqual(
            probe.get("weighted_ids"),
            ["weighted_heavy", "weighted_light_a", "weighted_light_b"],
        )
        self.assertEqual(probe.get("modifier_weight_ids"), ["mod_heavy", "mod_light", "mod_plain"])
        self.assertEqual(
            probe.get("conditional_inactive_ids"),
            ["cond_plain_a", "cond_boost", "cond_plain_b"],
        )
        self.assertEqual(
            probe.get("conditional_active_ids"),
            ["cond_boost", "cond_plain_a", "cond_plain_b"],
        )
        self.assertEqual(
            probe.get("real_catalog_modifier_inactive_ids"),
            ["probe_reward_weight_boost", "probe_reward_weight_focus", "probe_reward_weight_plain"],
        )
        self.assertEqual(
            probe.get("real_catalog_modifier_active_ids"),
            ["probe_reward_weight_focus", "probe_reward_weight_boost", "probe_reward_weight_plain"],
        )
        self.assertEqual(probe.get("equal_weight_ids"), ["equal_c", "equal_a", "equal_b"])
        self.assertEqual(probe.get("history_refill_ids"), ["history_a", "history_b", "history_c"])

    def test_live_reward_context_only_switches_to_gsm_on_second_live_checkpoint(self):
        probe = self._run_live_reward_context_probe()
        self.assertEqual(probe.get("first_context_reward_pool_tag"), "base_reward")
        self.assertEqual(probe.get("first_context_active_unlock_key"), "base_set")
        self.assertEqual(len(probe.get("first_offer_ids", [])), 3)
        self.assertTrue(probe.get("first_offer_all_base"))
        self.assertEqual(probe.get("second_context_reward_pool_tag"), "gsm_reward")
        self.assertEqual(probe.get("second_context_active_unlock_key"), "gsm_set")
        self.assertEqual(len(probe.get("second_offer_ids", [])), 3)
        self.assertTrue(probe.get("second_offer_all_gsm"))
        self.assertEqual(probe.get("base_only_second_context_reward_pool_tag"), "base_reward")
        self.assertEqual(probe.get("base_only_second_context_active_unlock_key"), "base_set")
        self.assertEqual(len(probe.get("base_only_second_offer_ids", [])), 3)
        self.assertTrue(probe.get("base_only_second_offer_all_base"))

    def test_event_and_queue_surfaces_use_readable_card_names(self):
        probe = self._run_event_readability_probe()
        self.assertIn("Strike", probe.get("queue_text", ""))
        self.assertIn("strike_01", probe.get("queue_text", ""))
        self.assertIn("Played Strike", probe.get("event_log_text", ""))
        self.assertIn("Resolve Strike", probe.get("event_log_text", ""))
        self.assertIn("Strike+", probe.get("reward_line", ""))
        self.assertIn("Defend+", probe.get("reward_line", ""))
        self.assertIn("Precise Strike", probe.get("reward_line", ""))
        self.assertIn("Offset Scalpel", probe.get("reject_line", ""))
        self.assertIn("needs FOCUS", probe.get("reject_line", ""))
        self.assertIn("Strike", probe.get("no_target_reject_line", ""))
        self.assertIn("living target", probe.get("no_target_reject_line", ""))
        self.assertIn("Ruby Open", probe.get("stack_reject_line", ""))
        self.assertIn("top gem does not match", probe.get("stack_reject_line", ""))

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

    def test_deck_inspection_snapshot_builder_normalizes_shared_modes(self):
        probe = self._run_deck_inspection_snapshot_builder_probe()
        combat_full = probe.get("combat_full", {})
        combat_discard = probe.get("combat_discard", {})
        map_run_deck = probe.get("map_run_deck", {})
        combat_full_repeat = probe.get("combat_full_repeat", {})

        self.assertEqual(combat_full.get("context"), "combat")
        self.assertEqual(combat_full.get("title"), "Combat Deck")
        self.assertTrue(combat_full.get("read_only"))
        self.assertEqual(combat_full.get("active_filter"), "all")
        self.assertEqual(combat_full.get("total_count"), 5)
        self.assertEqual(
            [section.get("id") for section in combat_full.get("sections", [])],
            ["draw", "hand", "discard", "exhaust"],
        )
        self.assertEqual(
            [section.get("count") for section in combat_full.get("sections", [])],
            [2, 1, 1, 1],
        )
        self.assertEqual(
            [card.get("zone") for card in combat_full.get("cards", [])],
            ["draw", "draw", "hand", "discard", "exhaust"],
        )
        self.assertEqual(combat_full.get("cards", [])[0].get("display_name"), "Strike")
        self.assertEqual(combat_full.get("cards", [])[0].get("card_instance_id"), "strike_01")
        self.assertEqual(combat_full.get("cards", [])[2].get("card_instance_id"), "runtime_scheme_alpha")
        self.assertEqual(combat_full.get("cards", [])[2].get("role_label"), "[UTL]")
        self.assertEqual(combat_full.get("cards", [])[2].get("rules_text"), "Utility • Draw 1 • Cost 1")
        self.assertEqual(combat_full.get("cards", [])[0].get("art_path"), "")
        self.assertEqual(combat_full.get("cards", [])[0].get("flags"), {})
        self.assertEqual(combat_full, combat_full_repeat)

        self.assertEqual(combat_discard.get("context"), "combat")
        self.assertEqual(combat_discard.get("active_filter"), "discard")
        self.assertEqual(combat_discard.get("total_count"), 1)
        self.assertEqual(len(combat_discard.get("cards", [])), 1)
        self.assertEqual(combat_discard.get("cards", [])[0].get("zone"), "discard")
        self.assertEqual(combat_discard.get("cards", [])[0].get("display_name"), "Strike+")

        self.assertEqual(map_run_deck.get("context"), "map")
        self.assertEqual(map_run_deck.get("title"), "Run Deck")
        self.assertEqual(map_run_deck.get("active_filter"), "all")
        self.assertEqual(map_run_deck.get("total_count"), 4)
        self.assertEqual(map_run_deck.get("sections"), [{"id": "deck", "label": "Deck", "count": 4}])
        self.assertEqual(
            [card.get("display_name") for card in map_run_deck.get("cards", [])],
            ["Defend", "Scheme", "Strike", "Strike+"],
        )
        self.assertTrue(all(card.get("zone") == "deck" for card in map_run_deck.get("cards", [])))
        self.assertTrue(all(card.get("zone_label") == "Deck" for card in map_run_deck.get("cards", [])))

    def test_deck_inspection_overlay_renders_snapshot_and_filters_cards(self):
        probe = self._run_deck_inspection_overlay_probe()
        self.assertFalse(probe.get("initially_visible"))
        self.assertTrue(probe.get("after_open_visible"))
        self.assertEqual(probe.get("title_text"), "Combat Deck")
        self.assertEqual(probe.get("count_after_open"), "3 cards")
        self.assertEqual(probe.get("filter_texts"), ["Draw (1)", "Hand (1)", "Discard (1)"])
        self.assertEqual(probe.get("visible_card_count_after_open"), 3)
        self.assertTrue(probe.get("detail_art_has_texture_after_open"))
        self.assertEqual(probe.get("detail_title_after_open"), "Strike")
        self.assertIn("[ATK]", probe.get("detail_meta_after_open", ""))
        self.assertIn("Draw", probe.get("detail_meta_after_open", ""))
        self.assertEqual(probe.get("detail_rules_after_open"), "Attack • 6 dmg • Cost 1")
        self.assertEqual(probe.get("visible_card_count_after_discard"), 1)
        self.assertTrue(probe.get("detail_art_has_texture_after_discard"))
        self.assertEqual(probe.get("detail_title_after_discard"), "Strike+")
        self.assertEqual(probe.get("count_after_discard"), "1 card")
        self.assertFalse(probe.get("after_close_visible"))

    def test_combat_deck_and_discard_hotkeys_work_on_live_stage(self):
        probe = self._run_combat_deck_overlay_probe()
        self.assertTrue(probe.get("has_unhandled_input"))
        self.assertFalse(probe.get("initial_visible"))
        self.assertTrue(probe.get("after_deck_hotkey_visible"))
        self.assertEqual(probe.get("deck_title_text"), "Combat Deck")
        self.assertTrue(probe.get("deck_count_text", "").endswith("cards"))
        self.assertGreaterEqual(probe.get("deck_card_grid_count", 0), 1)
        self.assertEqual(probe.get("hand_before_block"), probe.get("hand_after_block"))
        self.assertTrue(probe.get("after_discard_switch_visible"))
        self.assertEqual(probe.get("discard_title_text"), "Combat Deck")
        self.assertEqual(probe.get("discard_count_text"), "0 cards")
        self.assertEqual(probe.get("discard_card_grid_count"), 0)
        self.assertFalse(probe.get("after_discard_toggle_close_visible"))
        self.assertTrue(probe.get("discard_open_from_closed_visible"))
        self.assertEqual(probe.get("discard_open_from_closed_title"), "Combat Deck")

    def test_escape_closes_open_windows_before_opening_exit_overlay(self):
        probe = self._run_escape_exit_overlay_probe()
        self.assertFalse(probe.get("initial_exit_visible"))
        self.assertFalse(probe.get("initial_keybindings_visible"))
        self.assertTrue(probe.get("keybindings_visible_after_f9"))
        self.assertFalse(probe.get("keybindings_visible_after_escape"))
        self.assertFalse(probe.get("exit_visible_after_closing_keybindings"))
        self.assertTrue(probe.get("exit_visible_after_first_escape"))
        self.assertFalse(probe.get("exit_visible_after_second_escape"))
        self.assertTrue(probe.get("deck_visible_before_escape"))
        self.assertFalse(probe.get("deck_visible_after_escape"))
        self.assertFalse(probe.get("exit_visible_after_closing_deck"))
        self.assertTrue(probe.get("exit_visible_after_opening_from_combat"))

    def test_map_deck_overlay_opens_and_closes_from_map_screen(self):
        probe = self._run_map_deck_overlay_probe()
        self.assertFalse(probe.get("initial_visible"))
        self.assertTrue(probe.get("after_open_visible"))
        self.assertEqual(probe.get("title_text"), "Run Deck")
        self.assertTrue(probe.get("count_text", "").endswith("cards"))
        self.assertGreaterEqual(probe.get("card_grid_count", 0), 1)
        self.assertFalse(probe.get("after_close_visible"))


if __name__ == "__main__":
    unittest.main()
