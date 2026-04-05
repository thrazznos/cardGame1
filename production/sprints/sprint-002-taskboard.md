# Sprint 002 Taskboard - Execution

Status: Planned
Sprint: production/sprints/sprint-002.md
Updated: 2026-04-04
Commitment: Must Have only
Platform: Native-only

## Epic E1 - Combat HUD Legibility (S2.M1)
- [ ] E1.T1 Font scale and spacing pass across phase banner, hand, resource display, intent strip, and combat log
- [ ] E1.T2 Higher-contrast palette pass for critical combat information
- [ ] E1.T3 Visual hierarchy cleanup so phase, HP/block/energy, enemy intent, and hand read clearly at normal desktop viewing distance

## Epic E2 - Combat Explainability Surfaces (S2.M2)
- [ ] E2.T1 ResolveLock state made visually obvious during resolution
- [ ] E2.T2 Rejected actions show readable mapped reason text
- [ ] E2.T3 Queue/order cues reflect the authoritative ordering fields for the current slice

## Epic E3 - Deterministic Post-Combat Reward Checkpoint (S2.M3-S2.M4)
- [ ] E3.T1 Combat victory emits exactly one reward/checkpoint trigger
- [ ] E3.T2 Reward offer generation is deterministic for the same seed/input path
- [ ] E3.T3 Reward generation uses isolated reward streams only; no ambient RNG in the checkpoint flow
- [ ] E3.T4 Reward draft scaffold presents a pick-1-of-3 reward offer
- [ ] E3.T5 Chosen reward applies once and only once
- [ ] E3.T6 Reward selection commit is recorded in the event log

## Epic E4 - Validation, Ergonomics, and Evidence (S2.M5-S2.M6)
- [ ] E4.T1 Local validation runs on this machine without ad-hoc PATH hacks
- [ ] E4.T2 At least one deterministic validation path covers the reward/checkpoint flow
- [ ] E4.T3 One focused playtest report artifact is written
- [ ] E4.T4 One native validation note or measurement artifact is captured
- [ ] E4.T5 Known issues for the delivered slice are documented

## Current Focus
- Start: E1.T1/E1.T2 HUD readability pass on the native build
- Next: E1.T3 plus E2.T1/E2.T2 once layout and contrast are stable
- Checkpoint: E4.T1 quick local/native validation after the first HUD iteration
- Then: E3.T1-E3.T3 deterministic checkpoint trigger and reward generation
- Then: E3.T4-E3.T6 reward selection flow, apply-once behavior, and event-log confirmation
- Finish: E4.T2-E4.T5 validation coverage, playtest artifact, native evidence, and issue log
