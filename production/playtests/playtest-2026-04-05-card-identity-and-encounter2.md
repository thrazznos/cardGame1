# Playtest Report

## Session Info
- **Date**: 2026-04-05
- **Build**: 0d9dcd8
- **Duration**: Targeted smoke/readability pass
- **Tester**: Hermes agent (local runtime + automated smoke probes)
- **Platform**: Local native desktop
- **Input Method**: Scripted + runtime visual sanity pass
- **Session Type**: Focused validation

## Test Focus
Validate Sprint 003 improvements for:
1) card identity readability in hand/reward surfaces,
2) encounter-2 differentiation cues,
3) missing-art fallback robustness,
4) HUD contrast floor.

## Evidence Captured
- Full tests green: `python3 -m unittest discover -s tests -p 'test_*.py' -v` (16 tests, all pass)
- New card identity probe confirms role markers:
  - `[ATK]`, `[DEF]`, `[UTL]` labels and role-specific tooltip language.
- Encounter-2 presentation checks confirm distinct metadata:
  - `encounter_title`: Encounter 2 • Warden Counterpush
  - `encounter_intent_style`: Aggressive opener
- Missing-art probe confirms non-crashing placeholder behavior:
  - node stays visible,
  - texture safely null,
  - tooltip exposes missing asset path.
- HUD contrast probe confirms configured palette meets minimum readability thresholds for sampled text/background pairs.

## What Worked Well
- Card role parsing is faster due to explicit marker prefixes and clearer semantic labels.
- Encounter 2 now communicates a distinct presentation identity without gameplay-contract changes.
- Asset failures are diagnosable in-place without collapsing HUD layout.
- Determinism coverage now explicitly guards encounter presentation fields in expected baselines.

## Issues / Risks Observed
- E1.T4 still benefits from human readability confirmation at normal play distance (automation covers contrast/math, not subjective scan speed).
- E3.T4 currently lacks human-player qualitative sentiment for this exact pass.

## Recommended Next Steps
1. Run one short human readability pass to capture subjective scan speed and comprehension.
2. Optional: apply reward-card microcopy polish (S3.S2) if sprint buffer remains.
3. Keep deterministic baseline checks for encounter presentation fields as permanent guardrail.
