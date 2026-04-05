import json
import os
import tempfile
import unittest

from src.tools.determinism_report_compare import compare_report_to_expected


class DeterminismReportCompareTests(unittest.TestCase):
    def _tmp_json(self, payload):
        fd, path = tempfile.mkstemp(suffix=".json")
        os.close(fd)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f)
        return path

    def test_returns_mismatch_when_hash_differs(self):
        expected = {
            "fixture_id": "seed_smoke_001",
            "final_state_hash": "abc",
            "event_sequence_hash": "def",
            "rng_cursor_snapshot": {"encounter.intent": 2},
        }
        actual = {
            "fixture_id": "seed_smoke_001",
            "final_state_hash": "xyz",
            "event_sequence_hash": "def",
            "rng_cursor_snapshot": {"encounter.intent": 2},
        }

        expected_path = self._tmp_json(expected)
        actual_path = self._tmp_json(actual)

        result = compare_report_to_expected(actual_path, expected_path)

        self.assertFalse(result["ok"])
        self.assertIn("final_state_hash", result["mismatches"])

    def test_returns_ok_when_all_fields_match(self):
        payload = {
            "fixture_id": "seed_smoke_001",
            "final_state_hash": "abc",
            "event_sequence_hash": "def",
            "rng_cursor_snapshot": {"encounter.intent": 2},
        }

        expected_path = self._tmp_json(payload)
        actual_path = self._tmp_json(payload)

        result = compare_report_to_expected(actual_path, expected_path)

        self.assertTrue(result["ok"])
        self.assertEqual(result["mismatches"], {})


if __name__ == "__main__":
    unittest.main()
