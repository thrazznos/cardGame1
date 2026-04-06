# GameStudio Role Map

A lean, reusable role-aware delegation model for running Hermes as a small game studio rather than a single flat assistant.

This document is intentionally generic. It defines the minimum hierarchy, delegation rules, escalation paths, and signoff model that can be specialized per project.

A project-specific variant should derive from this file and customize:
- active roles
- file/domain scopes
- workflow entrypoints
- signoff matrix
- engine- and project-specific escalation triggers

## Design Goals

1. Prefer the smallest hierarchy that prevents bad delegation.
2. Keep authority explicit: who owns a decision, who may delegate, who must review.
3. Make cross-domain changes expensive enough to be noticed, but not theatrical.
4. Keep the reusable kernel small so project-specific policy packs can evolve quickly.
5. Treat workflow structure as explicit policy, not accidental prompt habit.

## Kernel vs Policy Pack

### Reusable kernel
These concepts should remain general across projects:
- role schema
- delegation permissions
- escalation permissions
- signoff routing
- workflow phase model
- task/result packet format

### Project policy pack
These should be specialized per project:
- role roster
- active vs dormant specialists
- file ownership
- signoff rules by path/domain
- engine-specific validation rules
- project-specific escalation triggers

## Lean Core Team

This model assumes a lean 8-10 role team. Not every role needs to be active on day one.

### 1. producer-orchestrator
Purpose
- Main workflow coordinator and cross-domain router.

Owns
- task routing
- workflow phase transitions
- blocker tracking
- sequencing and handoff coordination

Delegates to
- all active roles

Escalates to
- user for scope, priority, schedule, and strategic trade-offs

Typical signoff responsibility
- cross-domain changes
- workflow completion when multiple roles were involved

### 2. creative-director
Purpose
- Protects the game's identity, tone, pillars, and anti-pillars.

Owns
- creative coherence
- pillar protection
- vision arbitration
- high-level tone and feel

Delegates to
- game-designer
- art-director

Escalates to
- user when a decision changes the game's identity or sacrifices a pillar

Typical signoff responsibility
- vision-changing design or art decisions

### 3. technical-director
Purpose
- Protects architectural coherence and technical sanity.

Owns
- architecture
- technical risk
- performance strategy
- system boundaries

Delegates to
- lead-programmer
- qa-validation-lead

Escalates to
- user when architecture materially changes scope, schedule, or core technology choices

Typical signoff responsibility
- major architecture changes
- system rewrites
- high-risk technical decisions

### 4. game-designer
Purpose
- Owns gameplay/system intent and the player-facing rules of the game.

Owns
- core loop and systems rules
- formulas and tuning intent
- acceptance criteria for mechanics
- system design documentation

Delegates to
- specialized system designers later if needed

Escalates to
- creative-director for pillar conflict
- producer-orchestrator for scope conflict
- user for unresolved rules ambiguity

Typical signoff responsibility
- design docs
- mechanic changes
- systemic rule changes

### 5. art-director
Purpose
- Owns visual language and concept direction.

Owns
- art bible
- style guides
- color/material language
- concept priorities
- visual consistency

Delegates to
- art-pipeline-operator
- ui specialist for visual review

Escalates to
- creative-director when visual direction drifts from game identity
- user for major style pivots

Typical signoff responsibility
- art bible changes
- concept lane selection
- visual identity changes

### 6. lead-programmer
Purpose
- Translates design into code structure and implementation assignments.

Owns
- implementation decomposition
- code-level architecture below TD scope
- code review
- programming task routing

Delegates to
- gameplay programmer
- UI specialist
- tools/pipeline programmer if active

Escalates to
- technical-director for architecture changes
- game-designer for ambiguous spec
- producer-orchestrator for sequencing conflicts

Typical signoff responsibility
- meaningful code changes
- refactors
- implementation architecture for new features

### 7. gameplay-programmer
Purpose
- Executes gameplay and systems implementation.

Owns
- gameplay code within approved architecture
- scene/script changes tied to mechanics
- small implementation choices inside approved constraints

Delegates to
- narrow inspection/research subtasks only

Escalates to
- lead-programmer for structural changes
- game-designer for mechanic ambiguity
- technical-director for engine/performance constraints

Typical signoff responsibility
- executor role only; usually does not sign off globally

### 8. ui-specialist
Purpose
- Owns readable, native-feeling game UI.

Owns
- HUD/readability
- UI implementation details
- interaction and presentation details

Delegates to
- visual critique / UX review subtasks if needed

Escalates to
- art-director for visual language
- lead-programmer for UI structure
- creative-director if UI meaningfully alters tone/identity

Typical signoff responsibility
- major UI changes
- readability/interaction-affecting UI revisions

### 9. qa-validation-lead
Purpose
- Owns acceptance and regression validation.

Owns
- acceptance checks
- smoke/regression expectations
- validation routing
- “is this actually done?”

Delegates to
- test-specific subtasks
- review/check subtasks

Escalates to
- technical-director for structural repeated failures
- producer-orchestrator when quality blocks progress

Typical signoff responsibility
- completion of implementation workflows

### 10. art-pipeline-operator
Purpose
- Runs the operational art-generation or asset-processing machine.

Owns
- generation bookkeeping
- prompt/output traceability
- manifests and catalogs
- asset registration workflow

Delegates to
- critique, prompt refinement, and backlog maintenance subtasks

Escalates to
- art-director when outputs drift stylistically
- producer-orchestrator when throughput/process breaks

Typical signoff responsibility
- generated asset registration
- selected output state
- asset pipeline batch completion

## Delegation Rules

### Core rule
Most work should pass through a lead role before reaching an executor role.

Good
- producer-orchestrator -> lead-programmer -> gameplay-programmer
- producer-orchestrator -> art-director -> art-pipeline-operator
- producer-orchestrator -> game-designer -> lead-programmer

Bad
- producer-orchestrator directly spawning multiple executor roles without a framing lead
- executor roles making cross-domain calls on their own authority

### Authority principle
The system should answer five questions explicitly:
1. Who owns this decision?
2. Who may delegate the work?
3. Who may implement it?
4. Who must review it?
5. Who must escalate it if it crosses boundaries?

## Escalation Tree

### User
Final authority on:
- strategy
- taste
- scope trade-offs
- major technical commitments

### producer-orchestrator
First escalation for:
- cross-domain coordination failures
- blocked handoffs
- sequencing and scope conflicts

### creative-director
First escalation for:
- design vs tone conflict
- art vs identity conflict
- “this no longer feels like our game”

### technical-director
First escalation for:
- architecture disputes
- engine/performance/tooling conflicts
- risky implementation patterns

### Lead roles
Should resolve domain-local conflicts first and escalate upward only when the decision crosses authority or domain boundaries.

## Generic Signoff Matrix

This should be specialized per project, but the default shape is:

- design docs
  - game-designer
  - creative-director if vision-level impact

- architecture docs / ADRs
  - technical-director

- code changes
  - lead-programmer
  - qa-validation-lead before completion
  - technical-director if architecture/performance risk

- UI changes
  - ui-specialist
  - art-director if visual language shifts materially

- asset pipeline changes
  - art-pipeline-operator
  - art-director for artistic-direction changes

- cross-domain changes
  - producer-orchestrator

## Practical Usage Rule

Most tasks should involve only 3-4 active roles, not the full roster.

Examples:
- combat feature
  - game-designer
  - lead-programmer
  - gameplay-programmer
  - qa-validation-lead

- HUD readability pass
  - ui-specialist
  - art-director
  - qa-validation-lead

- concept art batch
  - art-director
  - art-pipeline-operator
  - creative-director only if drift occurs

## Suggested Machine-Readable Schema

This is not yet implementation code, but it is the intended shape:

```yaml
roles:
  - role: producer-orchestrator
    owns: [coordination, sequencing, blockers]
    delegates_to: [creative-director, technical-director, game-designer, art-director, lead-programmer, ui-specialist, qa-validation-lead, art-pipeline-operator]
    escalates_to: [user]
    signoff_for: [cross-domain]
    file_scopes: [production/**, docs/plans/**]

  - role: game-designer
    owns: [mechanics, formulas, acceptance-criteria]
    delegates_to: []
    escalates_to: [creative-director, producer-orchestrator, user]
    signoff_for: [design-docs, mechanics]
    file_scopes: [design/**]
```

## Implementation Guidance for Hermes

If this becomes a Hermes policy pack, the role map should be consulted before delegation so the orchestrator can:
- reject invalid delegations
- route work through the proper lead
- infer required reviewers
- know when to escalate instead of continuing blindly

The aim is not to create meetings. The aim is to prevent category mistakes.
