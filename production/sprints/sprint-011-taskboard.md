# Sprint 011 Taskboard - Execution

Status: Complete
Sprint: production/sprints/sprint-011.md
Updated: 2026-04-07
Commitment: Must Have + Should Have
Platform: Native-only (no browser automation)

## Epic E1 - Status Effect System Core (S11.M1 + S11.M2)
- [ ] E1.T1 Define status effect JSON schema and create data/status_effects/effects_v1.json
- [ ] E1.T2 Create StatusRegistry (src/core/status/status_registry.gd) to load and validate effects
- [ ] E1.T3 Create StatusTracker (src/core/status/status_tracker.gd) to manage active statuses per entity
- [ ] E1.T4 Add apply_status and tick_status effect types to ERP
- [ ] E1.T5 Wire status ticking into combat turn boundaries (turn start for poison, damage calc for weakness/strength/vulnerability)

## Epic E2 - Status Cards and Enemy Intents (S11.M3 + S11.M4)
- [ ] E2.T1 Add status-applying cards to catalog (poison, strength, vulnerability striker, gem-status payoff)
- [ ] E2.T2 Add status-applying intents to attrition and burst pressure profiles
- [ ] E2.T3 Update telegraph text to show status effects clearly

## Epic E3 - Combat Stage Status Display (S11.M5)
- [ ] E3.T1 Status icon strip below player and enemy portraits
- [ ] E3.T2 Duration counters and stack indicators
- [ ] E3.T3 Status tick events in event feed

## Epic E4 - Circuit and Seal Floor Objectives (S11.S1 + S11.S2)
- [ ] E4.T1 Circuit tracker: target sequence, progress tracking, penalty on wrong color
- [ ] E4.T2 Circuit generator solvability check
- [ ] E4.T3 Seal nodes with gem costs, boss gate lock until all seals broken
- [ ] E4.T4 Seal generator solvability check
- [ ] E4.T5 Map HUD banners for circuit and seal objectives

## Epic E5 - Validation (S11.M6)
- [ ] E5.T1 Status effect smoke probe (apply/tick/expire cycle)
- [ ] E5.T2 Status determinism fixture
- [ ] E5.T3 Circuit/seal floor probes
- [ ] E5.T4 Existing probes still pass

## Optional Stretch
- [ ] O1 Gem-consume status payoff card (S11.N1)
- [ ] O2 Status preview on map room hover (S11.N2)

## Outcome Notes
- Status effects deepen combat decisions: play order matters more when buffs/debuffs are in play.
- Circuit and seal complete the map objective trio (conduit already implemented).
- The gem stack gains new payoff targets through status-applying consume cards.
