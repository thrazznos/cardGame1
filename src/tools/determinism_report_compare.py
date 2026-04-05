import json


def _read_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def compare_report_to_expected(actual_path: str, expected_path: str) -> dict:
    actual = _read_json(actual_path)
    expected = _read_json(expected_path)

    keys = ["fixture_id", "final_state_hash", "event_sequence_hash", "rng_cursor_snapshot"]
    mismatches = {}

    for key in keys:
        if actual.get(key) != expected.get(key):
            mismatches[key] = {
                "actual": actual.get(key),
                "expected": expected.get(key),
            }

    return {"ok": len(mismatches) == 0, "mismatches": mismatches}
