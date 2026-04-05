import argparse
import subprocess
import sys
from pathlib import Path

try:
    from src.tools.godot_test_runner import resolve_godot_executable
except ModuleNotFoundError:
    ROOT = Path(__file__).resolve().parents[3]
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from src.tools.godot_test_runner import resolve_godot_executable


def _extract_prefixed_value(stdout: str, prefix: str) -> str:
    for line in stdout.splitlines():
        if line.startswith(prefix):
            return line[len(prefix) :].strip()
    return ""


def run_pipeline(scenario: str, output_dir: Path) -> dict:
    output_dir.mkdir(parents=True, exist_ok=True)

    godot_bin = resolve_godot_executable()
    batch_cmd = [
        godot_bin,
        "--headless",
        "--path",
        ".",
        "-s",
        "res://tests/sim/run_balance_batch.gd",
        "--",
        scenario,
    ]
    batch_proc = subprocess.run(batch_cmd, capture_output=True, text=True, check=True)
    artifact_path = _extract_prefixed_value(batch_proc.stdout, "BALANCE_BATCH_ARTIFACT=")
    if not artifact_path:
        raise RuntimeError("Batch runner did not emit BALANCE_BATCH_ARTIFACT")

    aggregate_cmd = [
        "python3",
        "src/tools/balance/aggregate_reports.py",
        "--input",
        artifact_path,
        "--output-dir",
        str(output_dir),
    ]
    subprocess.run(aggregate_cmd, check=True)

    summary_json = output_dir / "summary.json"
    card_csv = output_dir / "card_metrics.csv"
    policy_csv = output_dir / "policy_compare.csv"
    md_path = output_dir / "balance_report.md"

    render_cmd = [
        "python3",
        "src/tools/balance/render_markdown_report.py",
        "--summary-json",
        str(summary_json),
        "--card-csv",
        str(card_csv),
        "--policy-csv",
        str(policy_csv),
        "--output",
        str(md_path),
    ]
    subprocess.run(render_cmd, check=True)

    return {
        "artifact_jsonl": artifact_path,
        "summary_json": str(summary_json),
        "card_metrics_csv": str(card_csv),
        "policy_compare_csv": str(policy_csv),
        "markdown_report": str(md_path),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run full balance simulator pipeline in one command.")
    parser.add_argument("--scenario", default="res://tests/sim/scenarios/baseline_commons_v1.json")
    parser.add_argument("--output-dir", required=True)
    args = parser.parse_args()

    outputs = run_pipeline(args.scenario, Path(args.output_dir))
    print("BALANCE_PIPELINE_ARTIFACT=" + outputs["artifact_jsonl"])
    print("BALANCE_PIPELINE_SUMMARY=" + outputs["summary_json"])
    print("BALANCE_PIPELINE_CARD_CSV=" + outputs["card_metrics_csv"])
    print("BALANCE_PIPELINE_POLICY_CSV=" + outputs["policy_compare_csv"])
    print("BALANCE_PIPELINE_MARKDOWN=" + outputs["markdown_report"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
