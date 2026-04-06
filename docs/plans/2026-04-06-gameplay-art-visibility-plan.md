# Gameplay Art Visibility Plan — 2026-04-06

Goal
- Make the newly generated prototype gameplay-art pack visibly appear inside the native combat slice without destabilizing current smoke coverage.

Scope
- Wire shared card-art thumbnails into hand and reward buttons.
- Wire role icons (attack / defend / utility) into those same card buttons.
- Add a compact gem/status HUD strip that shows Ruby/Sapphire top-of-stack art, FOCUS icon + count, and locked-state icon when the player is gated.
- Keep existing card text, hotkeys, and reward flow intact.

Non-goals
- Full bespoke card scene/widget rewrite.
- Final production card frame system.
- Replacing every text explanation with iconography.
- New gameplay logic.

Files expected
- `src/ui/combat_hud/combat_hud_controller.gd`
- `scenes/combat/combat_slice.tscn`
- `tests/smoke/test_playable_prototype.py`
- possibly a focused probe under `tests/smoke/` if a dedicated UI assertion is cleaner than inflating an existing probe

Implementation approach
1. Add repo-local asset-path constants for generated card art, placeholder art, gem art, and role/status icons.
2. Introduce small HUD helpers in `combat_hud_controller.gd`:
   - canonical card family resolution for runtime/alias hand ids before art lookup
   - card family -> art path
   - card role -> icon path
   - gem name -> gem token path
   - reusable texture-thumb assignment for button child `TextureRect`s
3. Extend hand/reward buttons to visually show:
   - left-side card-art thumbnail
   - small role icon
   - unchanged text on the right
4. Add a small gem/status strip to the HUD showing:
   - up to top 3 gem tokens from `vm["gem_stack_top"]`
   - FOCUS icon and count
   - locked icon only when one of these explicit states is active:
     - `resolve_lock == true`
     - `play_gate_reason != ""`
     - `last_reject_reason` in gem-gating codes such as `ERR_FOCUS_REQUIRED`, `ERR_STACK_EMPTY`, `ERR_STACK_TOP_MISMATCH`, `ERR_STACK_TARGET_MISMATCH`, `ERR_SELECTOR_INVALID`
5. Preserve smoke compatibility for the existing GSM HUD assertions by keeping the current Zones text content intact while adding the art strip as a parallel visual surface.
6. Preserve existing missing-art safety behavior: if a generated asset is absent, use the placeholder art or muted empty state rather than crashing.

Verification
- `python3 -m unittest discover -s tests -p 'test_*.py' -v`
- Add smoke assertions proving:
  - hand and reward buttons expose art/icon child nodes with textures for populated cards
  - gem/status strip shows gem art when gems exist
  - focus icon/count is visible when FOCUS is present
  - existing Zones text still contains the compatibility strings expected by the current GSM integration coverage

Acceptance criteria
- No regressions in existing 31-test suite.
- At least one hand card visibly carries generated art.
- Reward choices visibly carry generated art.
- Gem stack uses generated Ruby/Sapphire art instead of text alone.
- FOCUS is represented with the generated focus icon.
- Lock state can surface the generated locked icon when applicable.
