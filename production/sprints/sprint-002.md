# Sprint 002 -- 2026-04-06 to 2026-04-17

## Sprint Goal
Turn the current deterministic combat prototype into a legible, feedback-ready native vertical slice that continues through the first post-combat reward/checkpoint flow.

## Capacity
- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work
- Available: 8 days

## Tasks

### Must Have (Critical Path)
| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S2.M1 | Combat HUD legibility pass (font scale, contrast, spacing, clearer hierarchy) | ui-programmer + ux-designer | 2.0 | Current combat HUD | Combat is comfortably readable on desktop at normal viewing distance; larger fonts and higher-contrast palette are applied; player can identify phase, HP/block/energy, enemy intent, and hand without strain |
| S2.M2 | Explainability/readability surfaces (resolve-lock state, rejection reasons, clearer queue/order cues) | gameplay-programmer + ui-programmer | 1.0 | S2.M1, TSRE/HUD APIs | Rejected actions show readable reason text; resolve-lock state is visually obvious; queue/order cues map to the authoritative order fields for the current slice |
| S2.M3 | Deterministic post-combat checkpoint trigger and reward draft scaffold | gameplay-programmer + godot-gdscript-specialist | 2.0 | Combat end event, RNG streams, card data | Winning combat triggers exactly one reward checkpoint; reward offer generation is deterministic for the same seed/input path; no ambient RNG is used |
| S2.M4 | Reward selection flow (pick 1 of 3) and state application | gameplay-programmer | 1.5 | S2.M3, DLS/card schema | Player can select one reward after victory; chosen reward is applied once and only once; selection commit is visible in the event log |
| S2.M5 | Test/dev ergonomics and validation coverage for the reward path | tools-programmer + qa-tester | 1.0 | S2.M3, S2.M4 | Local validation works on this machine without ad-hoc PATH hacks; reward/checkpoint flow has at least one deterministic validation path |
| S2.M6 | Evidence pass: playtest report + basic native validation capture | qa-tester + performance-analyst | 0.5 | S2.M1-S2.M5 | One playtest report artifact is written; one native validation note or measurement artifact is captured; known issues are documented |

### Should Have

Scope-protection rule for Sprint 002:
- No Should Have items are committed at sprint start.
- If the sprint runs ahead, the first candidate follow-up is reward screen readability polish / skip affordance.

### Nice to Have

Deferred backlog (not part of Sprint 002 commitment):
- High-contrast theme toggle or scale preset for playtest sessions
- Expanded card/effect subset for richer reward variety
- Cross-browser replay procedure for the current slice

## Carryover from Previous Sprint
| Task | Reason | New Estimate |
|------|--------|-------------|
| UI readability/accessibility polish | Functional HUD shipped, but feedback quality is limited by legibility | 3.0 days (S2.M1 + S2.M2) |
| First reward checkpoint integration | Explicit Sprint 001 carry-over backlog item; current slice ends at combat result | 3.5 days (S2.M3 + S2.M4) |
| Native validation evidence | Local harness exists, but evidence is not archived as a stable project artifact | 0.5 days (S2.M6) |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| HUD cleanup balloons into a full UI redesign | Medium | High | Constrain the sprint to readability, hierarchy, and explainability only; do not chase final art direction |
| Reward flow pulls scope into the full map/meta loop | High | High | Hard boundary: only first post-combat reward/checkpoint flow; no full map traversal or hub implementation this sprint |
| Deterministic reward generation introduces hidden RNG coupling | Medium | High | Isolate reward streams, log cursor state, and add at least one validation path for the checkpoint flow |
| Readability changes regress local/native responsiveness | Medium | Medium | Capture a lightweight native validation pass after the first HUD iteration and cut nonessential UI motion before reducing gameplay information |
| Validation artifacts slip again | Medium | Medium | Make playtest report and perf note explicit Must Have work, not end-of-sprint cleanup |

## Dependencies on External Factors
- Human playtest pass after readability improvements
- Local Godot runner normalization for reliable automated verification

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] Combat UI is legible enough to gather useful playtest feedback
- [ ] Winning combat transitions into a deterministic first reward/checkpoint flow
- [ ] Reward selection applies exactly once and records deterministic event output
- [ ] Automated validations pass on the local machine without ad-hoc manual PATH edits
- [ ] At least one playtest report and one native validation evidence note are archived
- [ ] No S1 or S2 bugs in delivered slice
- [ ] Design/docs updated for any contract deviations
