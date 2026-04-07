# Sprint 010 Taskboard - Execution

Status: Complete
Sprint: production/sprints/sprint-010.md
Updated: 2026-04-06
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - Combat Stage Layout (S10.M1 + S10.M2)
- [ ] E1.T1 Replace VBox panel layout with stage arena (top 60%) + hand overlay (bottom 40%)
- [ ] E1.T2 Player portrait on left, enemy portrait on right, HP bars below each
- [ ] E1.T3 Enemy intent as large centered indicator between portraits
- [ ] E1.T4 Card hand as overlapping fan with hover-scale, energy counter near hand
- [ ] E1.T5 Integrate block/energy/phase indicators into stage layout

## Epic E2 - Gem Stack Icon Component (S10.M3)
- [ ] E2.T1 Build shared gem stack icon strip using Ruby/Sapphire texture assets
- [ ] E2.T2 Empty slot outlines for stack cap visualization
- [ ] E2.T3 Focus counter as icon + number
- [ ] E2.T4 Wire into both map HUD and combat HUD

## Epic E3 - Map HUD Frame and Events (S10.M4 + S10.M5)
- [ ] E3.T1 Consistent panel/border treatment for map screen
- [ ] E3.T2 Event room scene (text + auto-resolve, not invisible)
- [ ] E3.T3 Map node gem affinity as icons (if time)

## Epic E4 - Validation (S10.M6)
- [ ] E4.T1 All existing combat probes pass with new layout
- [ ] E4.T2 Floor integration probe verifies transitions
- [ ] E4.T3 Visual review screenshots

## Optional Stretch
- [ ] O1 Combat event log as compact side feed (S10.S1)
- [ ] O2 Reward screen visual polish with constraint badges (S10.S2)
- [ ] O3 Stage background tint per encounter profile (S10.N2)

## Outcome Notes
- This sprint is purely visual/layout. No new game mechanics.
- The view model contract stays identical — only rendering changes.
- Success means the game looks and feels like a card game, not a data viewer.
