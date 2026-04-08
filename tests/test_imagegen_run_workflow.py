import importlib.util
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "imagegen" / "run_workflow.py"
SPEC = importlib.util.spec_from_file_location("cardgame1_run_workflow", MODULE_PATH)
RUN_WORKFLOW = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(RUN_WORKFLOW)


class RunWorkflowDefaultsTests(unittest.TestCase):
    def test_flux_defaults_require_ae_when_no_override_and_no_ae_present(self):
        mapping = {"__VAE__": "taef1.safetensors"}
        with tempfile.TemporaryDirectory() as temp_dir:
            with self.assertRaises(SystemExit) as exc:
                RUN_WORKFLOW.apply_workflow_defaults(
                    "flux_schnell_fp8_api.json",
                    mapping,
                    overridden_keys=set(),
                    vae_dir=Path(temp_dir),
                )
        self.assertIn("flux-schnell-ae-auth", str(exc.exception))

    def test_flux_defaults_prefer_ae_when_present(self):
        mapping = {"__VAE__": "taef1.safetensors"}
        with tempfile.TemporaryDirectory() as temp_dir:
            vae_dir = Path(temp_dir)
            (vae_dir / "ae.safetensors").write_text("stub")
            resolved = RUN_WORKFLOW.apply_workflow_defaults(
                "flux_schnell_fp8_api.json",
                mapping,
                overridden_keys=set(),
                vae_dir=vae_dir,
            )
        self.assertEqual(resolved["__VAE__"], "ae.safetensors")

    def test_flux_explicit_vae_override_is_respected(self):
        mapping = {"__VAE__": "custom_vae.safetensors"}
        with tempfile.TemporaryDirectory() as temp_dir:
            resolved = RUN_WORKFLOW.apply_workflow_defaults(
                "flux_schnell_fp8_api.json",
                mapping,
                overridden_keys={"__VAE__"},
                vae_dir=Path(temp_dir),
            )
        self.assertEqual(resolved["__VAE__"], "custom_vae.safetensors")

    def test_non_flux_workflow_is_unchanged(self):
        mapping = {"__VAE__": "taef1.safetensors"}
        with tempfile.TemporaryDirectory() as temp_dir:
            resolved = RUN_WORKFLOW.apply_workflow_defaults(
                "sdxl_relic_concept_api.json",
                mapping,
                overridden_keys=set(),
                vae_dir=Path(temp_dir),
            )
        self.assertEqual(resolved["__VAE__"], "taef1.safetensors")


if __name__ == "__main__":
    unittest.main()
