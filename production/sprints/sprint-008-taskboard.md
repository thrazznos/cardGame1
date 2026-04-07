# Sprint 008 Taskboard - Execution

Status: Complete
Sprint: production/sprints/sprint-008.md
Updated: 2026-04-06
Commitment: Must Have only
Platform: Native-only (no browser automation)

## Epic E1 - Encounter Pressure Profiles (S8.M1)
- [x] E1.T1 Define a small set of clearly different encounter pressure profiles
- [x] E1.T2 Implement those profiles in the live combat slice without broadening into map/meta work
- [x] E1.T3 Validate that each profile pressures a different sequencing habit

## Epic E2 - Intent Readability and Pressure Communication (S8.M2)
- [x] E2.T1 Keep enemy telegraphs readable as variety increases
- [x] E2.T2 Clarify how pressure differences appear in the HUD and event surfaces
- [x] E2.T3 Ensure new encounter pressure does not create hidden or mysterious failure states

## Epic E3 - Response Tools and Fight Pacing (S8.M3 + S8.M4)
- [x] E3.T1 Audit whether the current live card/reward set supports meaningful encounter-specific responses
- [x] E3.T2 Add/tune response tools where variety demands them
- [x] E3.T3 Reduce repetitive or dead-turn pacing while preserving compounding turns

## Epic E4 - Validation and Replayability Evidence (S8.M5 + S8.M6)
- [x] E4.T1 Add/update smoke and determinism coverage for representative encounter styles
- [x] E4.T2 Capture focused playtests on whether players change plans between encounters
- [x] E4.T3 Summarize encounter variety, pacing, and adaptation outcomes in one reviewable artifact
- [x] E4.T4 Re-run full local validation and archive outcomes

## Optional Stretch (Should/Nice)
- [ ] O1 Elite/boss pressure differentiation pass (S8.S1)
- [ ] O2 Encounter-pressure debug counters (S8.S2)
- [ ] O3 High-pressure intent-surface polish (S8.N1)
- [ ] O4 Encounter comparison report snippets (S8.N2)

## Outcome Notes
- Sprint 008 is still combat-first: encounter variety and replayability, not map/hub breadth.
- Success means fights become meaningfully different from each other and worth replaying on combat merits alone.
- E4.T4 requires Godot runtime to re-baseline determinism hashes and run smoke probes.
