# Generated gameplay art pack — 2026-04-06

Status:
- Prototype gameplay-art pack generated with Pixellab MCP.
- Files are stored repo-locally under `assets/generated/`.
- The combat HUD now wires this pack into the native prototype for:
  - hand card thumbnails
  - reward card thumbnails
  - role icons
  - gem stack tokens
  - FOCUS icon
  - lock icon
- This remains prototype-grade presentation, not final production art.

Primary directories:
- `assets/generated/cards/`
- `assets/generated/cards/placeholders/`
- `assets/generated/gems/`
- `assets/generated/ui/icons/`

## Active runtime swap points

Runtime wiring currently lives in:
- `src/ui/combat_hud/combat_hud_controller.gd`
- `scenes/combat/combat_slice.tscn`

Primary swap surfaces:
- Hand buttons:
  - `CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1..Card5/ArtThumb`
  - `CombatHud/Margin/VBox/HandPanel/HandVBox/HandButtons/Card1..Card5/RoleIcon`
- Reward buttons:
  - `CombatHud/RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1..Reward3/ArtThumb`
  - `CombatHud/RewardOverlay/Center/RewardPanel/RewardVBox/RewardChoices/Reward1..Reward3/RoleIcon`
- Generated status strip:
  - `CombatHud/Margin/VBox/StatsRow/GeneratedStatusPanel/GeneratedStatusVBox/GeneratedStatusStrip/GemTop1`
  - `.../GemTop2`
  - `.../GemTop3`
  - `.../FocusIcon`
  - `.../FocusValue`
  - `.../LockIcon`

Presentation mapping currently follows shared family lanes rather than one-image-per-card:
- strike lane -> `card_strike_cat_duelist_md.png`
- defend lane -> `card_defend_badger_bulwark_md.png`
- utility lane -> `card_scheme_seep_goblin_md.png`
- ruby/gem attack lane -> `card_ember_jab_ruby_md.png`
- sapphire/gem defend lane -> `card_ward_polish_sapphire_md.png`
- focus lane -> `card_vault_focus_seal_md.png`
- unknown card fallback -> `card_placeholder_steward_warrant_md.png`

## Asset inventory

### Shared card-art lanes

1. `assets/generated/cards/card_strike_cat_duelist_md.png`
- Intended coverage: `strike`, `strike_plus`, `strike_precise`
- Source Pixellab object id: `682104c3-9f05-4125-855e-dfe828125818`
- Notes: updated portrait-first strike lane with stronger face/silhouette read for the enlarged combat cards; still somewhat courtly/static, but materially better than the original full-body prototype art.

2. `assets/generated/cards/card_defend_badger_bulwark_md.png`
- Intended coverage: `defend`, `defend_plus`, `defend_hold`
- Source Pixellab object id: `2400596d-dbe6-4ab0-9ac8-d6685312c6a7`
- Notes: updated defend lane with a stronger shield-forward silhouette and clearer defensive portrait read for the enlarged cards; darker value grouping still needs care, but it is stronger than the previous lane art.

3. `assets/generated/cards/card_scheme_seep_goblin_md.png`
- Intended coverage: `scheme_flow`
- Source Pixellab object id: `aecfe1b8-4c45-418a-93f7-0140298ff804`
- Notes: readable goblin utility lane; less explicitly "seep" than ideal, but strong as a first utility placeholder.

4. `assets/generated/cards/card_ember_jab_ruby_md.png`
- Intended coverage: `gem_produce_ruby`, `gem_hybrid_ruby_strike`, `gem_consume_top_ruby`, `gem_offset_consume_ruby`
- Source Pixellab object id: `d2b5f650-2ff8-4019-80dc-a1b16b8128cf`
- Notes: this reads more like a ruby attack emblem/object than a character portrait, which is fine for the gem lane.

5. `assets/generated/cards/card_ward_polish_sapphire_md.png`
- Intended coverage: `gem_produce_sapphire`, `gem_hybrid_sapphire_guard`, `gem_hybrid_sapphire_burst`, `gem_consume_top_sapphire`, `gem_offset_consume_sapphire`
- Source Pixellab object id: `e137327f-4599-45b5-8566-59a0f0207677`
- Notes: shield/sapphire read is clean and mechanically obvious.

6. `assets/generated/cards/card_vault_focus_seal_md.png`
- Intended coverage: `gem_focus`, `gem_hybrid_focus_guard`
- Source Pixellab object id: `e8ec88c1-b5a7-4145-b5d9-662d45a6bf4f`
- Notes: emblematic focus/eye rosette rather than a portrait. Good for prototype clarity.

### Generic fallback card art

7. `assets/generated/cards/placeholders/card_placeholder_steward_warrant_md.png`
- Intended coverage: fallback for any card without a bespoke/shared art assignment
- Source Pixellab object id: `2a2cbbeb-8b04-4995-b568-0df3eb9982a9`
- Notes: parchment/warrant placeholder. Slightly ornate, but stable and in-world.

### Gem art

8. `assets/generated/gems/obj_gem_ruby_token_md.png`
- Intended usage: Ruby stack marker / tooltip / inline gem art
- Source Pixellab object id: `c29f2232-4299-4415-9ee2-56b6b353df47`

9. `assets/generated/gems/obj_gem_sapphire_token_md.png`
- Intended usage: Sapphire stack marker / tooltip / inline gem art
- Source Pixellab object id: `5c885790-ab05-49de-ab6a-a3a0d1b7dc63`

### UI icons

10. `assets/generated/ui/icons/ui_icon_attack_sm.png`
- Intended usage: attack marker replacing raw `[ATK]` in later card-frame work
- Source Pixellab object id: `e7888838-ca25-4b30-8f14-c7d4257786b7`

11. `assets/generated/ui/icons/ui_icon_defend_sm.png`
- Intended usage: defend marker replacing raw `[DEF]`
- Source Pixellab object id: `81094916-1856-4510-8bfe-c3c6ec292cdd`

12. `assets/generated/ui/icons/ui_icon_utility_sm.png`
- Intended usage: utility marker replacing raw `[UTL]`
- Source Pixellab object id: `ed7256d1-3b1d-4d72-bfc4-f22db60b8437`
- Notes: cog-based utility icon. Inner detail may need hand simplification for the tiniest use.

13. `assets/generated/ui/icons/ui_icon_focus_sm.png`
- Intended usage: FOCUS indicator / card tag / tooltip badge
- Source Pixellab object id: `67a58a67-7595-41fa-a478-ba31d2170991`

14. `assets/generated/ui/icons/ui_icon_stack_top_sm.png`
- Intended usage: gem-stack-top badge
- Source Pixellab object id: `ae63f296-1c31-44e3-b97c-70b3dac75467`

15. `assets/generated/ui/icons/ui_icon_locked_sm.png`
- Intended usage: locked / gated / unavailable badge
- Source Pixellab object id: `5fd17804-2605-4d1b-9f48-4fe1f66ea1bf`

## Recommended next-agent work

1. Do not start by generating more portraits at random.
2. The runtime swap points now exist; use them rather than changing gameplay code:
   - shared card-art mapping by card family lives in `src/ui/combat_hud/combat_hud_controller.gd`
   - hand/reward visual nodes live in `scenes/combat/combat_slice.tscn`
   - gem/focus/lock strip lives in `GeneratedStatusPanel`
3. If you improve images, prefer replacing the existing mapped files first before expanding the mapping table.
4. Hand-clean the tiny icons before treating them as final truth-assets.
5. If a stricter portrait lane is needed later, regenerate only the weak cases:
   - `card_strike_cat_duelist_md.png` for a more portrait-safe bust crop
   - `card_scheme_seep_goblin_md.png` for a more explicitly seep-goblin read
   - `card_defend_badger_bulwark_md.png` if the civic badge language feels too modern

## Related handoff docs

- `tools/imagegen/prompts/next-art-agent-prompts.md`
- `design/art-bible.md`
- `docs/plans/2026-04-05-art-generation-backlog.md`
- `~/.hermes/skills/cardgame1/cardgame1-mcp-art-generation-pipeline/SKILL.md`
