# Sprint 006 Taskboard - Execution

Status: Planned
Sprint: production/sprints/sprint-006.md
Updated: 2026-04-06
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - Hand-Dominant Combat UI (S6.M1)
- [ ] E1.T1 Push resting hand cards to clear visual priority in combat HUD
- [ ] E1.T2 Implement compatibility-safe overlap/fan/tray behavior as needed to support larger cards
- [ ] E1.T3 Keep Button roots, hotkeys, `ArtThumb`, and `RoleIcon` contracts intact while scaling the face

## Epic E2 - Explainability and Legality (S6.M2 + S6.M5)
- [ ] E2.T1 Improve inline/hover legality reasons for individual cards
- [ ] E2.T2 Make resolve-lock and unavailable-action states more obvious at a glance
- [ ] E2.T3 Tighten queue and recent-event surfaces so “what changed / why” reads faster

## Epic E3 - Turn Feel and Early-Game Flow (S6.M3 + S6.M4)
- [ ] E3.T1 Add deterministic impact feedback for attack / block / gem / focus / reject outcomes
- [ ] E3.T2 Audit the live starter deck for low-expression openers and dead-feeling setup turns
- [ ] E3.T3 Raise the floor on setup/producer cards without flattening sequencing value

## Epic E4 - Validation and Evidence (S6.M6)
- [ ] E4.T1 Add/update smoke probes for combat readability promises
- [ ] E4.T2 Add/update determinism fixtures for representative reject and combo turns
- [ ] E4.T3 Capture focused native playtest notes for the first two encounters
- [ ] E4.T4 Re-run full local validation and archive outcomes

## Optional Stretch (Should/Nice)
- [ ] O1 Reward-card comparison readability pass (S6.S1)
- [ ] O2 Encounter-two readability polish based on playtest findings (S6.S2)
- [ ] O3 Hover/focus choreography polish (S6.N1)
- [ ] O4 Readability-probe cleanup/refactor (S6.N2)

## Outcome Notes
- Sprint 006 is explicitly combat-first and should not broaden into map, hub, or deckbuilder scope.
- Success is measured by faster state read, stronger early-turn feel, and better player trust in legality/sequence surfaces.
