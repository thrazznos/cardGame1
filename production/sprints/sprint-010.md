# Sprint 010 -- 2026-07-27 to 2026-08-07

## Sprint Goal
Overhaul the game's visual presentation from spreadsheet-style data panels to a coherent, readable game screen: combat happens on a visual stage with characters, the hand is overlaid at the bottom, and gem state uses icon textures everywhere.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S10.M1 | Combat stage layout — arena with portraits | ui-programmer + technical-artist | 2.0 | Existing combat_slice.tscn, portrait assets | Combat screen has a visual arena (top 60%) with player portrait on left and enemy portrait on right facing each other. HP bars integrated below portraits. Enemy intent shown as a large readable indicator between portraits. Stats are part of the stage, not separate panels. |
| S10.M2 | Hand overlay at bottom of combat stage | ui-programmer | 1.5 | S10.M1 | Card hand renders as an overlapping fan at the bottom 40% of the screen, overlapping the stage. Cards use existing art thumbnails and scale on hover. Playable cards are bright, unplayable are dimmed. Energy counter visible near hand. |
| S10.M3 | Gem stack as icon strip (shared component) | ui-programmer | 1.0 | Existing gem icon textures | Gem stack rendered as a row of Ruby/Sapphire icon textures with empty slot outlines. Same component used on both map and combat screens. Stack cap shown as total slots. Focus counter as icon + number. |
| S10.M4 | Coherent HUD frame for map screen | ui-programmer | 1.0 | S10.M3 | Map screen has a consistent frame: floor banner at top, gem stack icon strip at bottom-left, conduit/objective at top-right, instructions at bottom. Panel backgrounds and borders match combat screen style. |
| S10.M5 | Event room scene transition | gameplay-programmer + ui-programmer | 0.5 | Floor controller | Entering an event room shows a simple event screen (text + choices or auto-resolve) instead of auto-completing invisibly. Uses the same scene transition pattern as combat. |
| S10.M6 | Smoke probes and visual verification | qa-tester | 1.0 | S10.M1-M5 | All existing combat probes pass with new layout. Floor integration probe verifies map->combat->map transitions with new scene structure. Screenshot capture for visual review. |

### Should Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S10.S1 | Combat event log redesign | ui-programmer | 0.75 | S10.M1 | Event log is a compact scrollable feed at the side of the arena, not a full-width panel. Shows last 3-4 events with icons for event types. |
| S10.S2 | Reward screen visual polish | ui-programmer | 0.75 | S10.M2 | Reward cards use the same card rendering as the hand. Constraint tag shown as a badge on each reward card. |

### Nice to Have
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S10.N1 | Map node gem affinity as icons instead of text | ui-programmer | 0.5 | S10.M3 | Map nodes show small gem icons instead of text "R"/"S" for attunement. |
| S10.N2 | Combat stage background per encounter profile | technical-artist | 0.5 | S10.M1 | Different encounter profiles (steady/burst/escalating/attrition) show different stage tint or background. |

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|--------------|
| Map and combat visual presentation is functional but not readable | User feedback: nodes too small, colors bad, combat is a spreadsheet, gem display is text-only | Full sprint dedicated to visual coherence |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Combat HUD controller rewrite breaks existing functionality | High | High | Keep the view model contract identical — only change rendering, not data flow. Run all existing probes after each change. |
| Stage layout doesn't fit browser viewport at small window sizes | Medium | Medium | Design for 1280x720 minimum. Test at min resolution. |
| Card fan overlap makes individual cards hard to click | Medium | Medium | Reuse existing hover-scale pattern (cards grow on hover). Keep minimum click target at 60px. |
| Scope creep into animation and VFX | Medium | Low | This sprint is layout only. Animations are Sprint 011. |

## Dependencies on External Factors
- Existing portrait assets (player_cat_steward_bust_128.png, enemy_badger_warden_068.png) are small — may need larger versions for stage layout
- Gem icon textures exist at assets/generated/gems/ and are sufficient

## Definition of Done for this Sprint
- [ ] Combat screen shows a visual stage with character portraits, not data panels
- [ ] Hand of cards overlays the bottom of the stage as a fan
- [ ] Gem stack uses icon textures everywhere (map and combat)
- [ ] Map screen has a coherent HUD frame matching combat visual style
- [ ] Event rooms show their own scene instead of auto-completing
- [ ] All existing combat and floor probes pass
- [ ] Game feels like a game, not a spreadsheet
