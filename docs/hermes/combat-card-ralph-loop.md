# Combat Card Ralph Loop Board

Purpose
- Run a bounded, fresh-context autonomous loop for Dungeon Steward combat-card work.
- Focus on narrow, testable slices only.
- No commits. No broad repo churn. Stop on scope spill or failing validation.

Authority and constraints
- User-approved autonomous scope for this board only.
- Repo: `/Users/ericfode/src/cardgame1`
- Engine: Godot 4.6.2
- Priority area: combat-card runtime, reward, HUD contract, and QA/determinism around those systems.

Read first each run
1. `CLAUDE.md`
2. `NEXT_AGENT.md`
3. `handoff.md`
4. `production/sprints/sprint-005.md`
5. `production/sprints/sprint-005-taskboard.md`
6. This file

Allowed file surface
- `src/bootstrap/combat_slice_runner.gd`
- `src/core/card/*.gd`
- `src/core/reward/reward_draft.gd`
- `src/core/dls/deck_lifecycle.gd`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `scenes/combat/combat_slice.tscn`
- `data/cards/catalog_v1.json`
- `data/decks/starter_run_v1.json`
- `tests/smoke/*.gd`
- `tests/smoke/test_playable_prototype.py`
- `tests/determinism/*`
- `production/sprints/sprint-005-taskboard.md` only for concise autonomous loop progress notes when a slice materially advances sprint-closeout state
- this board file
- `NEXT_AGENT.md` only for concise handoff updates after a completed slice

Frozen / do not edit in this loop unless the user explicitly expands scope
- `assets/generated/README.md`
- `docs/plans/2026-04-05-combat-fun-roadmap.md`
- `docs/plans/2026-04-06-gameplay-art-visibility-plan.md`
- `docs/plans/2026-04-06-combat-card-ui-*`
- `tools/imagegen/prompts/dungeon_steward_card_ui_prompt_pack.md`

Operating rules
- Work only on the first unchecked task.
- Use TDD: add/adjust failing test first, verify RED, implement minimal fix, verify GREEN.
- Run targeted tests, then the relevant suite, then full `discover` if code changed broadly.
- Preserve determinism baselines if possible.
- If determinism expected files must change, update only the necessary expected files and explain why in the run log.
- If the task would require touching frozen files or broadening scope, stop and report instead of improvising.
- Do not create commits.
- Do not schedule more cron jobs.

Current loop backlog
- [x] Implement RewardDraft runtime use of authored metadata: start with `weight_base` and `unlock_key` support while preserving deterministic offer ordering and updating tests as needed.
- [x] Add fixture-boundary identity coverage: support explicit `{instance_id, card_id}` payloads in fixture-driven hand setup and add one dedicated identity determinism fixture.
- [x] Tighten `CardInstance` dictionary canonicalization and add negative coverage so malformed dict inputs cannot quietly reintroduce alias/card-id drift.
- [x] Replace checkpoint-prefix reward family gating with an explicit reward-context contract while preserving current live base-reward behavior.
- [x] Push deeper simulation/report metadata into the card catalog where it materially improves combat-card iteration.
- [x] Decide whether the live runner should ever emit non-base reward contexts, and if so under what explicit combat/run conditions.

Definition of done for each loop run
- One task or one small sub-slice is completed, or a blocker is identified.
- Tests are run and summarized.
- This board is updated.
- If a slice completes, append a short note to `NEXT_AGENT.md` only if it materially changes takeover context.

Run log
- Scope widened by best judgment after the user selected the widening option and the follow-up clarification timed out: the loop may now edit `scenes/combat/combat_slice.tscn`, `tests/smoke/run_gameplay_art_visibility_probe.gd`, and `production/sprints/sprint-005-taskboard.md` within the same combat-card autonomy constraints.
- Manual supervised slice complete: `RewardDraft` now consumes `unlock_key` and `weight_base` inside the draft layer, preserves the equal-weight fast path for current base rewards, and kept determinism baselines unchanged. Validation: targeted reward-pool smoke, full smoke suite, determinism fixture compare, and full unittest discover all passed.
- Follow-up fix in the same slice: reward-history refill now prefers unique eligible cards before duplicating entries, preventing duplicate offers when three unique eligible cards exist but one was initially excluded by history. Validation remained green across smoke, determinism, and full unittest discover.
- Manual supervised slice complete: fixture-driven hand setup now accepts explicit `{instance_id, card_id}` payloads, fixture play steps can target `instance_id`, fixture reports include discard/discard_card_ids, and a new deterministic identity fixture `seed_identity_001` is locked in. Validation: targeted smoke, determinism fixture compare, full smoke suite, full determinism suite, and full unittest discover all passed.
- Manual supervised slice complete: `CardInstance` now canonicalizes dictionary alias inputs instead of preserving malformed/whitespace-padded alias drift, and negative smoke coverage locks that behavior in. Validation remained green across smoke, determinism, and full unittest discover.
- Manual supervised slice complete: reward-family selection no longer depends on `gsm_` checkpoint naming conventions. `CardCatalog` and `RewardDraft` now consume explicit reward context from the caller, while the live runner still explicitly requests the base reward family so gameplay/determinism behavior stayed stable. Validation remained green across smoke, determinism, and full unittest discover.
- Manual supervised slice complete: card catalog entries can now carry authored `sim_metadata`, the balance sim report now surfaces `card_sim_metadata`, and current reward attack variants (`strike_plus`, `strike_precise`) expose distinct authored report roles while preserving existing value-proxy numbers. Validation remained green across sim, smoke, determinism, and full unittest discover.
- Autonomous slice complete: live reward checkpoints now stay on `base_reward` for the first live reward, then switch to `gsm_reward` from the second live checkpoint onward when the live run deck already contains a substantial GSM footprint (currently thresholded at 4 `gsm_set` cards) and the GSM reward pool is populated. Fixture/determinism flows remained stable because fixture starter decks are still base-only. Validation: targeted live reward-context smoke, determinism fixture compare, full smoke suite, and full unittest discover all passed.
