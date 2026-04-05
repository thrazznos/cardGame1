# Combat HUD Art Swap Points

This directory contains runtime HUD art assets wired by `src/ui/combat_hud/combat_hud_controller.gd`.

## Active swap points

| UI role | Constant | File | Scene node path | Preferred display size |
|---|---|---|---|---|
| Player portrait | `PLAYER_PORTRAIT_PATH` | `player_cat_steward_bust_128.png` | `Margin/VBox/StatsRow/PlayerPanel/PlayerVBox/PlayerPortrait` | 96x96 |
| Enemy portrait | `ENEMY_PORTRAIT_PATH` | `enemy_badger_warden_068.png` | `Margin/VBox/StatsRow/EnemyPanel/EnemyVBox/EnemyPortrait` | 88x88 |
| Banner crest | `CREST_PATH` | `banner_crest_steward_064.png` | `Margin/VBox/Banner/BannerRow/BannerCrest` | 40x40 |
| Reward seal | `REWARD_SEAL_PATH` | `reward_wax_seal_centered_112.png` | `RewardOverlay/Center/RewardPanel/RewardVBox/RewardSealRow/RewardSeal` | 96x96 |

## How to replace art safely

1. Keep filenames stable and overwrite the files above, OR update the path constants in `combat_hud_controller.gd`.
2. Preserve approximate aspect ratios to avoid awkward letterboxing in `STRETCH_KEEP_ASPECT_CENTERED` mode.
3. Verify in game by launching `godot --path .` and checking banner, both portraits, and reward overlay.

## Missing-art behavior (intentional)

If an asset cannot be loaded, HUD no longer hides that element.
Instead it shows:
- an empty placeholder rect
- a muted fallback tint (`MISSING_ART_TINT`)
- tooltip text: `Missing art asset: <path>`

This allows quick visual diagnosis while keeping layout stable.

## Notes

- Pixel-art filtering is used only for the crest and enemy portrait path currently.
- All swaps are presentation-only; no combat logic or deterministic behavior depends on these files.
