# NEXT AGENT HANDOFF

Current state
- Project: Dungeon Steward
- Engine: Godot 4.6.2
- Run command on this machine: `/opt/homebrew/bin/godot --path /Users/ericfode/src/cardgame1`
- Current local game process has been restarted after the latest changes.
- Sprint 004 is effectively closed and Sprint 005 card-data migration is implemented at the Must-Have level.

What just landed
1. Sprint 004 closeout
   - Added explicit `peek_top()` / `peek_n()` helpers to GSM.
   - Surfaced an 8-card GSM pilot subset in the live starter deck.
   - Archived GSM pilot validation notes and marked Sprint 004 docs/taskboard complete.
2. Sprint 005 card-data migration
   - Added repo-tracked JSON data assets:
     - `data/cards/catalog_v1.json`
     - `data/decks/starter_run_v1.json`
   - Added runtime helpers:
     - `src/core/card/card_catalog.gd`
     - `src/core/card/card_presenter.gd`
     - `src/core/card/card_validator.gd`
   - Added headless validation / sim follow-through:
     - `tests/smoke/run_card_catalog_probe.gd`
     - balance-sim value proxies now derive from card catalog effect data
   - Began runtime card-instance separation:
     - `src/core/card/card_instance.gd`
     - DeckLifecycle zones can now carry `{instance_id, card_id}` dictionaries while view-model hand output remains stable strings
   - Refactored:
     - `src/bootstrap/combat_slice_runner.gd`
     - `src/core/reward/reward_draft.gd`
     - `src/ui/combat_hud/combat_hud_controller.gd`
   - Reward-card variants no longer collapse into generic Strike/Defend labels.
   - Encounter transition toast now auto-dismisses instead of waiting for Enter.
3. Validation
   - Full tests green:
     - `python3 -m unittest discover -s tests -p 'test_*.py' -v`
   - Determinism baselines updated intentionally after data migration.

Files most relevant right now
- `data/cards/catalog_v1.json`
- `data/decks/starter_run_v1.json`
- `src/core/card/card_catalog.gd`
- `src/core/card/card_presenter.gd`
- `src/core/card/card_validator.gd`
- `src/bootstrap/combat_slice_runner.gd`
- `src/core/reward/reward_draft.gd`
- `src/ui/combat_hud/combat_hud_controller.gd`
- `production/sprints/sprint-004.md`
- `production/sprints/sprint-004-taskboard.md`
- `production/sprints/sprint-005.md`
- `production/sprints/sprint-005-taskboard.md`
- `production/playtests/playtest-2026-04-05-gsm-pilot.md`
- `production/playtests/playtest-2026-04-05-card-data-migration.md`

Important implementation notes
- Card content is now data-driven via JSON, not large prefix-based switch tables.
- Reward pools still use a simple checkpoint-prefix gate (`gsm_` vs normal) inside `RewardDraft`, but the actual card pool entries now come from `CardCatalog`.
- Fixture starter decks remain hardcoded/stable in `FIXTURE_STARTER_RUN_DECK` to avoid coupling live starter-deck iteration to determinism fixtures.
- Determinism baselines updated intentionally after the data migration changed event payload representation.
- `reward_summary_text` has been removed from authoritative final-state hashing, so reward microcopy no longer perturbs determinism hashes.
- Exact play requests no longer silently degrade to prefix matches; this is a smaller step toward cleaner card identity semantics.
- The live runtime still uses string card instance identifiers like `strike_01`; true `card_id` vs instance-ID separation is still debt, not solved.

Validation commands
- Full tests:
  - `python3 -m unittest discover -s tests -p 'test_*.py' -v`
- Basic Godot startup check:
  - `/opt/homebrew/bin/godot --headless --path /Users/ericfode/src/cardgame1 --quit-after 1`
- Launch the game:
  - `/opt/homebrew/bin/godot --path /Users/ericfode/src/cardgame1`

Likely next good slices
1. Split stable card definition identity from runtime instance identity
   - stop leaning on `strike_01`-style strings as both content and instance handles
2. Push deeper simulation/report metadata into the card catalog
   - current value proxies are effect-derived and acceptable, but richer explicit metadata may be desirable
3. Replace remaining stringly deck/zone payloads with explicit card-instance dictionaries
   - this is the real cleanup if you want the identity model to stop being politely fictional
   - implementation plan drafted at `docs/plans/2026-04-05-card-instance-identity-split.md`

Things to avoid
- Do not reintroduce card-prefix switch tables in runner/HUD code; that would be a relapse, not a feature.
- Do not couple fixture starter decks to live starter-deck content without deliberately updating determinism expectations.
- Do not assume JSON data assets are second-class just because they are not `.tres`; for this prototype, they are currently the more civilized choice.
