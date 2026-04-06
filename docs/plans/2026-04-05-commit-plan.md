# Commit Plan for Sprint 004/005 Worktree

Purpose: split the current work into clean commits without actually committing yet.

## Group 1 -- Sprint 004 closeout: GSM pilot in live slice

Suggested commit message:
`feat(gsm): close sprint 004 with live pilot surfacing and peek helpers`

Files
- `src/core/gsm/gem_stack_machine.gd`
- `src/bootstrap/combat_slice_runner.gd`
- `tests/smoke/run_gsm_core_probe.gd`
- `tests/smoke/run_gsm_pilot_probe.gd`
- `tests/smoke/test_playable_prototype.py`
- `production/sprints/sprint-004.md`
- `production/sprints/sprint-004-taskboard.md`
- `production/playtests/playtest-2026-04-05-gsm-pilot.md`
- `design/gdd/systems/gem-stack-machine.md`

Notes
- This commit should capture the playable GSM pilot and the explicit `peek_top` / `peek_n` contract closure.
- If you want an even cleaner split, keep the later card-catalog changes out of this commit and only include the portions of `combat_slice_runner.gd` / tests directly needed for Sprint 004.

## Group 2 -- Card catalog infrastructure and starter deck data

Suggested commit message:
`feat(cards): add data-driven card catalog and starter deck assets`

Files
- `data/cards/catalog_v1.json`
- `data/decks/starter_run_v1.json`
- `src/core/card/card_catalog.gd`
- `src/core/card/card_presenter.gd`
- `src/core/card/card_validator.gd`
- `design/gdd/card-data-definitions.md`
- `production/sprints/sprint-005.md`
- `production/sprints/sprint-005-taskboard.md`
- `production/playtests/playtest-2026-04-05-card-data-migration.md`

Notes
- This is the new authoritative card-data layer.
- If desired, `sprint-005` docs can be split into their own docs-only commit, but keeping them here is reasonable because they describe the infrastructure landing.

## Group 3 -- Migrate runner, reward draft, and HUD to data-driven cards

Suggested commit message:
`refactor(cards): move runner reward and hud card logic onto card catalog`

Files
- `src/bootstrap/combat_slice_runner.gd`
- `src/core/reward/reward_draft.gd`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `tests/smoke/run_card_identity_probe.gd`
- `tests/smoke/test_playable_prototype.py`

Notes
- This is the large refactor commit that removes the prefix-based switch tables.
- Includes the distinct reward-variant rendering regression.
- Also includes the stricter exact-card play behavior (no silent prefix fallback on play requests).

## Group 4 -- Determinism and fixture baseline refresh

Suggested commit message:
`test(determinism): refresh fixtures after card-data migration`

Files
- `tests/determinism/fixtures/seed_continue_001.expected.json`
- `tests/determinism/fixtures/seed_continue_001.json`
- `tests/determinism/fixtures/seed_gsm_001.expected.json`
- `tests/determinism/fixtures/seed_reward_001.expected.json`
- `tests/determinism/fixtures/seed_reward_001.json`
- `tests/determinism/fixtures/seed_second_reward_001.expected.json`
- `tests/determinism/fixtures/seed_second_reward_001.json`
- `tests/determinism/fixtures/seed_smoke_001.expected.json`
- `tests/determinism/fixtures/seed_smoke_001.json`
- `tests/determinism/fixtures/seed_smoke_002.expected.json`
- `tests/determinism/fixtures/seed_smoke_002.json`

Notes
- This commit should include the intentional baseline refresh after:
  1. card-data migration changed event payload representation, and
  2. `reward_summary_text` was removed from authoritative final-state hashing.

## Group 5 -- Follow-through probes, sim cleanup, toast polish, and partial card-instance slice

Suggested commit message:
`test(cards): add catalog probe sim metadata and toast polish`

Files
- `src/core/card/card_instance.gd`
- `src/core/dls/deck_lifecycle.gd`
- `src/bootstrap/combat_slice_runner.gd`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `tests/smoke/run_card_catalog_probe.gd`
- `tests/smoke/run_card_instance_probe.gd`
- `tests/smoke/run_encounter_toast_probe.gd`
- `tests/sim/run_balance_sim.gd`
- `tests/sim/test_balance_sim_smoke.py`
- `tests/smoke/test_playable_prototype.py`
- `NEXT_AGENT.md`
- `PR_SUMMARY.md`
- `docs/CHANGELOG-2026-04-05-sprints-004-005.md`
- `docs/plans/2026-04-05-commit-plan.md`
- `docs/plans/2026-04-05-card-instance-identity-split.md`

Notes
- This is the follow-through commit after the main migration: extra probes, sim cleanup, auto-dismissing toast, and the first partial instance-identity slice.
- If you want maximal tidiness, split this into:
  1. toast polish
  2. card-instance helper / DeckLifecycle partial migration
  3. sim + probe follow-through
  4. docs/handoff only

## Staging order suggestion
1. Group 1
2. Group 2
3. Group 3
4. Group 4
5. Group 5

## Sanity check before any actual commits
Run:
- `python3 -m unittest discover -s tests -p 'test_*.py' -v`
- `git diff --stat`
- `git status --short`

No commits have been made yet.
