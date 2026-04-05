import json
import os
import subprocess
import tempfile
import unittest

from src.tools.determinism_report_compare import compare_report_to_expected
from src.tools.godot_test_runner import resolve_godot_executable


def _run_fixture(fixture_path: str) -> dict:
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
    for line in proc.stdout.splitlines():
        if line.startswith("DETERMINISM_REPORT="):
            return json.loads(line[len("DETERMINISM_REPORT="):])
    raise AssertionError("missing DETERMINISM_REPORT line")


class FixtureCompareTests(unittest.TestCase):
    def _assert_fixture_matches_expected(self, fixture: str, expected: str):
        report = _run_fixture(fixture)
        fd, tmp = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(report, f)
        result = compare_report_to_expected(tmp, expected)
        self.assertTrue(result["ok"], msg=f"mismatches: {result['mismatches']}")

    def test_seed_smoke_001_matches_expected_baseline(self):
        self._assert_fixture_matches_expected(
            "res://tests/determinism/fixtures/seed_smoke_001.json",
            "tests/determinism/fixtures/seed_smoke_001.expected.json",
        )

    def test_seed_smoke_002_matches_expected_baseline(self):
        self._assert_fixture_matches_expected(
            "res://tests/determinism/fixtures/seed_smoke_002.json",
            "tests/determinism/fixtures/seed_smoke_002.expected.json",
        )

    def test_seed_reward_001_matches_expected_baseline(self):
        self._assert_fixture_matches_expected(
            "res://tests/determinism/fixtures/seed_reward_001.json",
            "tests/determinism/fixtures/seed_reward_001.expected.json",
        )

    def test_seed_continue_001_matches_expected_baseline(self):
        self._assert_fixture_matches_expected(
            "res://tests/determinism/fixtures/seed_continue_001.json",
            "tests/determinism/fixtures/seed_continue_001.expected.json",
        )

    def test_seed_second_reward_001_matches_expected_baseline(self):
        self._assert_fixture_matches_expected(
            "res://tests/determinism/fixtures/seed_second_reward_001.json",
            "tests/determinism/fixtures/seed_second_reward_001.expected.json",
        )


if __name__ == "__main__":
    unittest.main()
