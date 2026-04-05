import json
import subprocess
import unittest


class PlayablePrototypeSmokeTests(unittest.TestCase):
    def test_seed_smoke_reports_playable_player_win(self):
        cmd = [
            "godot4",
            "--headless",
            "--path",
            ".",
            "-s",
            "res://tests/determinism/run_fixture.gd",
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True, check=True)

        report_line = ""
        for line in proc.stdout.splitlines():
            if line.startswith("DETERMINISM_REPORT="):
                report_line = line[len("DETERMINISM_REPORT="):]
        self.assertTrue(report_line, "missing DETERMINISM_REPORT output")

        report = json.loads(report_line)

        # Playable baseline contract (RED first: currently missing these keys)
        self.assertTrue(report.get("ok"))
        self.assertEqual(report["combat_result"], "player_win")
        self.assertGreater(report["turns_completed"], 0)


if __name__ == "__main__":
    unittest.main()
