# Sprint 005 Taskboard -- Card Data Resource Extraction

Status: In Progress
Sprint: production/sprints/sprint-005.md
Updated: 2026-04-05

## Epic E1 -- Schema + Catalog Service
- [ ] E1.T1 Define card schema (id/role/name/cost/effects/ui/metadata/art_key)
- [ ] E1.T2 Create card resource files for base + GSM + hybrid cards
- [ ] E1.T3 Implement card catalog loader with deterministic validation

## Epic E2 -- Runtime Decoupling
- [ ] E2.T1 Replace hard-coded card effect mapping with catalog lookup
- [ ] E2.T2 Keep fallback path for non-migrated cards during transition
- [ ] E2.T3 Add fail-fast behavior for unknown card ids in combat path

## Epic E3 -- HUD Decoupling
- [ ] E3.T1 Replace per-card if chains for button text/tooltips with catalog fields
- [ ] E3.T2 Replace role marker/name lookups with catalog metadata
- [ ] E3.T3 Keep visual behavior unchanged (only source of data changes)

## Epic E4 -- Reward/Card Pool Decoupling
- [ ] E4.T1 Move reward pool card selections to resource-driven tags/sets
- [ ] E4.T2 Ensure GSM opt-in behavior remains controllable by checkpoint policy

## Epic E5 -- QA and Determinism
- [ ] E5.T1 Add schema/ID validation test coverage
- [ ] E5.T2 Add one smoke probe that proves resource-driven render + resolve path
- [ ] E5.T3 Run full suite and update baselines only if intentional

## Current Focus
- Start E1 + E2 first: establish single source of truth and connect combat resolution.
