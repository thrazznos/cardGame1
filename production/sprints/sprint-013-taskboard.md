# Sprint 013 Taskboard - Execution

Status: Planned
Sprint: production/sprints/sprint-013.md
Updated: 2026-04-08
Commitment: Must Have + Should Have
Platform: Native-only (no browser automation)

## Epic E1 - Card Presentation Polish (S13.M1)
- [ ] E1.T1 Keep hovered card cost badge readable in all hover states
- [ ] E1.T2 Remove accidental background artifacts from card header / role surfaces
- [ ] E1.T3 Tighten title / rules / cost visual hierarchy for live combat cards
- [ ] E1.T4 Verify polish applies consistently across idle and hovered cards

## Epic E2 - Combat HUD Information Layout (S13.M2)
- [ ] E2.T1 Place energy in the hand-selection region instead of the arena region
- [ ] E2.T2 Place gem stack directly under energy with clear labeling
- [ ] E2.T3 Center combat log beneath the intent preview
- [ ] E2.T4 Verify the resulting HUD information order reads naturally in live play

## Epic E3 - Reward / Hover / Hit-Area Visual QA (S13.M3)
- [ ] E3.T1 Verify hand hover scaling does not hide critical card information
- [ ] E3.T2 Verify reward overlay hit areas match visual card bounds
- [ ] E3.T3 Verify event-feed readability in normal combat and reward states
- [ ] E3.T4 Preserve or improve current combat-stage probe coverage for these paths

## Epic E4 - Preflight / CI Reliability Hardening (S13.M4)
- [ ] E4.T1 Keep local preflight strict on branch/rebase/dirty-tree behavior
- [ ] E4.T2 Allow CI preflight to run safely in detached-HEAD environments
- [ ] E4.T3 Keep stale-branch warnings informative without rebasing in CI
- [ ] E4.T4 Verify workflow YAML and script behavior remain stable on PR runs

## Epic E5 - Validation and Regression Proof Pass (S13.M5)
- [ ] E5.T1 Run headless Godot startup after the UI polish pass
- [ ] E5.T2 Run key combat-stage smoke probes tied to hover/reward/log layout
- [ ] E5.T3 Add or refine at least one targeted regression proof for a recent HUD/layout fix
- [ ] E5.T4 Confirm no new parser or interaction regressions were introduced by polish work

## Optional Stretch
- [ ] O1 Map HUD readability / hover polish (S13.S1)
- [ ] O2 Visual asset import hygiene and `.import` policy cleanup (S13.S2)
- [ ] O3 Card style token cleanup into `src/ui/theme.gd` (S13.N1)
- [ ] O4 Narrow UI layout proof probes for recent fixes (S13.N2)

## Outcome Notes
- Sprint 013 is a combat presentation and workflow reliability sprint, not a new combat-system expansion sprint.
- Success means the live combat UI feels intentional, readable, and stable under real use.
- Changes should land in small, verifiable units so visual regressions are easy to isolate and review.
