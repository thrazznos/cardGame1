# Retrospective: Sprint 001

Period: 2026-04-04 -- 2026-04-04
Generated: 2026-04-04

## Scope Note

This retrospective is artifact-based.

The Sprint 001 taskboard was not kept current during implementation, so this review reconstructs actual progress from commit history, current repo artifacts, tests, and the playable prototype rather than from checkbox completion data alone.

## Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Taskboard tasks | 25 | 0 marked complete | -25 tracked |
| Completion Rate | -- | 0% by taskboard / substantial artifact completion | -- |
| Sprint capacity | 10 working days / 50 hours | Not reliably tracked | n/a |
| Bugs Found | -- | 0 recorded artifacts | -- |
| Bugs Fixed | -- | 0 recorded artifacts | -- |
| Unplanned tasks added | -- | 2 inferred (dynamic hand controls/event telemetry; second determinism baseline fixture) | +2 |
| Commits | -- | 9 | -- |

## Artifact Outcomes Actually Delivered

Despite the stale taskboard, Sprint 001 produced meaningful implementation outcomes:
- Approved MVP/vertical-slice design foundation across the GDD set
- Production-entry gate artifacts
- Sprint 001 plan + taskboard scaffold
- Playable deterministic combat slice
- Minimal combat HUD with dynamic hand controls
- Determinism smoke harness with expected-baseline comparison coverage
- Second smoke fixture to deepen replay confidence

## Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| n/a | n/a | n/a | n/a |
| Sprint 001 (taskboard tracking) | 25 tasks | 0 tracked complete | 0% tracked |
| Sprint 001 (artifact reconstruction) | Thin combat slice + harness + HUD | Delivered | Substantial but undocumented |

**Trend**: Initial baseline only.

There is no prior sprint history yet. The main signal is that implementation moved faster than process tracking, not that the team failed to deliver.

## What Went Well
- **The project crossed the line from theory to playable software**
  - A real combat slice now runs in Godot and can be played locally.
- **Determinism was treated as a first-class concern early**
  - Replay fixture comparison and smoke tests landed alongside the prototype instead of being deferred.
- **The thin-slice boundary was mostly respected**
  - Work focused on combat rather than exploding into the full map/reward/hub loop too early.
- **Architecture shape matches project intent**
  - The current split across TSRE, queue, RNG, ERP, deck lifecycle, bootstrap runner, and HUD is directionally aligned with the ADR/GDD structure.

## What Went Poorly
- **Task tracking became unreliable almost immediately**
  - The taskboard still reports early scaffolding while the repo contains a playable combat slice and passing validations.
- **UI readability is too weak for strong feedback**
  - Manual playtest indicates the loop works, but fonts/contrast are currently too poor to gather high-quality design feedback.
- **Validation claims were not archived as project artifacts**
  - Play happened, but there is no formal playtest report.
  - Tests pass, but there is no stored performance evidence for the browser target.
- **Automation portability is brittle**
  - The repo expects `godot4`, while the current machine exposes `godot`, forcing a local shim during verification.

## Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| UI legibility too low for rich feedback | Present at first manual playtest checkpoint | Not yet resolved | Make readability a Sprint 002 must-have, not polish-later work |
| `godot4` executable mismatch on local machine | Encountered during verification | Temporary PATH shim to local Godot binary | Normalize runner command or add a repo helper script/alias |
| Progress tracking drift | Entire implementation snapshot | Manual reconstruction from git + artifacts | Treat taskboard maintenance as part of Definition of Done |

## Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| E4 Minimal Browser HUD | 7h | Functional HUD delivered, readability still missing | Underestimated | Prototype UI work solved function first, but not playtest-quality legibility |
| E5 Determinism harness baseline | 3h | Harness + baseline comparison + second smoke fixture delivered | Better than expected | Thin-slice scope made validation tractable |

**Overall estimation accuracy**: insufficient reliable time-tracking data to score precisely.

The dominant problem was not estimation math; it was tracking hygiene. The retrospective signal is clear enough to act on: prototype delivery succeeded, but process evidence lagged behind it.

## Carryover Analysis

| Task | Original Sprint | Times Carried | Reason | Action |
|------|----------------|---------------|--------|--------|
| First reward checkpoint integration | Sprint 001 candidate carry-over backlog | 1 | Combat slice currently stops at combat end | Complete in Sprint 002 |
| UI readability and explainability polish | Sprint 001 E4/E5 gap | 1 | Functional prototype shipped before feedback-ready readability | Complete in Sprint 002 |
| Cross-browser/perf evidence bundle | Sprint 001 E5 | 1 | Local determinism baseline landed first; evidence pass was not archived | Complete in Sprint 002 |
| Expanded effect/status coverage beyond sprint subset | Sprint 001 carry-over backlog | 1 | Slice intentionally stayed narrow | Defer unless required by reward/checkpoint work |

## Technical Debt Status
- Current TODO count in `src/`: 0
- Current FIXME count in `src/`: 0
- Current HACK count in `src/`: 0
- Current TODO/FIXME/HACK count in `tests/`: 0
- Trend: **Stable / low comment debt**
- Concern: comment debt is low, but **process debt** increased because tracking and validation artifacts lagged delivery.

## Previous Action Items Follow-Up

| Action Item (from Sprint N-1) | Status | Notes |
|-------------------------------|--------|-------|
| None | -- | Sprint 001 is the first sprint artifact in the repo |

## Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | Normalize local Godot test invocation so validation runs without ad-hoc shell shims | gameplay-programmer / tools-programmer | High | Sprint 002 end |
| 2 | Make the combat HUD readable enough for useful playtest feedback (font scale, contrast, hierarchy) | ui-programmer / ux-designer | High | Sprint 002 mid-sprint |
| 3 | Extend the vertical slice through the first post-combat reward/checkpoint flow | gameplay-programmer | High | Sprint 002 end |
| 4 | Archive one formal playtest report and one baseline browser performance note | qa-tester / performance-analyst | High | Sprint 002 end |

## Process Improvements
- Treat taskboard maintenance as part of the Definition of Done for implementation clusters.
- Require a persistent artifact for every validation claim (playtest, performance, gate confidence), not just verbal confirmation.
- Keep thin-slice discipline: extend the slice one adjacent step at a time instead of opening the entire run loop at once.

## Summary

Sprint 001 succeeded at the most important thing: it made Dungeon Steward real. The project now has a playable deterministic combat slice instead of only design intent.

The main correction for Sprint 002 is not to broaden wildly, but to make the existing slice legible, evidence-backed, and one step more complete by carrying it through the first post-combat reward checkpoint.
