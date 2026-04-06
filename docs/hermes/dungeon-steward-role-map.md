# Dungeon Steward Role Map

Derived from: `docs/hermes/gamestudio-role-map.md`

This is the project-specific role-aware delegation policy for Dungeon Steward / the current `cardgame1` repository.

It customizes the generic GameStudio role map for this project's actual needs:
- Godot 4.6.2
- deterministic combat and seed-sensitive validation
- current emphasis on native iteration over web concerns
- heavy use of design docs in `design/gdd/`
- an active art-generation pipeline in `tools/imagegen/`
- a UI/HUD readability loop already under active development

## Project Principles

1. Prefer the smallest hierarchy that prevents bad delegation.
2. Keep current sprint work biased toward playable native prototype progress.
3. Treat deterministic correctness as a first-class technical constraint.
4. Treat the art pipeline as operational infrastructure, not merely “creative output.”
5. Keep project state explicit in files; do not rely on memory providers as the sole source of workflow truth.

## Active Core Team

### 1. producer-orchestrator
Purpose
- Main coordinator for Dungeon Steward workflows.

Owns
- routing between design, implementation, art pipeline, UI, and validation
- sequencing sprint work
- blocker management
- deciding whether a task is single-role, multi-role, or escalation-worthy

Delegates to
- all active roles

Escalates to
- user for scope, priority, and strategic trade-offs

File/domain scope
- `production/**`
- `docs/plans/**`
- future orchestration metadata under `docs/hermes/**`

Required signoff on
- cross-domain changes
- changes that affect both code and design/art docs
- workflow completion for multi-role tasks

### 2. creative-director
Purpose
- Protect the identity of Dungeon Steward as a browser-first roguelite deckbuilder with a deadpan but coherent fantasy tone.

Owns
- core fantasy and tone
- pillar protection
- cross-discipline coherence
- “does this still feel like Dungeon Steward?”

Delegates to
- game-designer
- art-director

Escalates to
- user when a choice changes the project’s identity or sacrifices a major pillar

File/domain scope
- `design/gdd/game-concept.md`
- top-level vision docs
- high-level art-direction docs

Required signoff on
- changes to core fantasy
- major tone shifts
- faction/world identity changes

### 3. technical-director
Purpose
- Protect architectural coherence and deterministic correctness.

Owns
- high-level architecture
- technical risk
- performance strategy
- determinism-sensitive system boundaries

Delegates to
- lead-programmer
- qa-validation-lead

Escalates to
- user when architecture materially changes scope, schedule, or engine strategy

File/domain scope
- `docs/architecture/**`
- ADR-class docs if introduced
- architecture sections in plans/docs

Required signoff on
- architecture changes
- engine-level or determinism-critical refactors
- tool/pipeline changes that alter core development flow

### 4. game-designer
Purpose
- Own mechanics and systems intent for combat, progression, reward, map, and deck systems.

Owns
- gameplay rules
- formulas and tuning intent
- acceptance criteria
- system design documents

Delegates to
- narrowly scoped specialist design subtasks later if needed

Escalates to
- creative-director for pillar conflict
- producer-orchestrator for scope conflict
- user for unresolved rules ambiguity

File/domain scope
- `design/gdd/**`
- especially:
  - `design/gdd/systems/*.md`
  - `design/gdd/card-data-definitions.md`
  - `design/gdd/systems-index.md`

Required signoff on
- changes to gameplay/system rules
- combat balance model updates
- mechanic changes affecting design intent

### 5. art-director
Purpose
- Own the visual identity and concept direction of Dungeon Steward.

Owns
- art bible
- material/color language
- concept priorities
- concept lane selection
- consistency across generated/reference art

Delegates to
- art-pipeline-operator
- ui-hud-specialist for UI visual review

Escalates to
- creative-director if visual direction drifts from project identity
- user for major style pivots

File/domain scope
- `design/art-bible.md`
- `tools/imagegen/prompts/**`
- art-direction notes under `docs/**` or `docs/hermes/**`

Required signoff on
- art bible changes
- selected concept lane changes
- visual identity changes

### 6. lead-programmer
Purpose
- Translate Dungeon Steward system design into code structure in a Godot-native way.

Owns
- implementation decomposition
- code review
- code-level architecture below TD scope
- programmer task routing

Delegates to
- godot-gameplay-programmer
- ui-hud-specialist
- future tooling subtasks as needed

Escalates to
- technical-director for structural architecture changes
- game-designer for ambiguous mechanics
- producer-orchestrator for sequencing conflicts

File/domain scope
- `src/**`
- implementation notes in `docs/plans/**`

Required signoff on
- meaningful code changes in `src/**`
- multi-file gameplay refactors
- implementation architecture for new systems

### 7. godot-gameplay-programmer
Purpose
- Implement gameplay systems in Godot idiomatically.

Owns
- concrete gameplay code
- scene/script changes tied to combat and systemic behavior
- implementation details within approved architecture

Delegates to
- narrow inspection/research subtasks only

Escalates to
- lead-programmer for structural changes
- game-designer for mechanic ambiguity
- technical-director when engine/performance/determinism constraints appear

File/domain scope
- `src/core/**`
- `src/bootstrap/**`
- relevant test runner glue in `src/tools/**`

Required signoff on
- none globally; executor role

### 8. ui-hud-specialist
Purpose
- Own readable, native-feeling interface work for the current playable prototype.

Owns
- HUD readability
- combat HUD behavior
- card/UI presentation details
- UI implementation in Godot

Delegates to
- visual critique / readability review subtasks if needed

Escalates to
- art-director for visual language
- lead-programmer for UI architecture
- creative-director if UI meaningfully alters tone or hierarchy

File/domain scope
- `src/ui/**`
- especially `src/ui/combat_hud/**`

Required signoff on
- major HUD/UI changes
- readability-affecting revisions

### 9. qa-validation-lead
Purpose
- Own acceptance, smoke, determinism, and regression validation.

Owns
- “is it done?” checks
- regression expectations
- determinism validation routing
- smoke validation routing

Delegates to
- test/check subtasks
- review subtasks

Escalates to
- technical-director for repeated structural failures
- producer-orchestrator when quality blocks progress

File/domain scope
- `tests/**`
- validation reports and bug reports

Required signoff on
- completion of implementation workflows
- “done” status on code tasks

### 10. art-pipeline-operator
Purpose
- Run the project’s MCP-first concept-art production machine.

Owns
- generation bookkeeping
- prompt/output traceability
- concept manifest and browser state
- batch generation workflow
- generated file registration

Delegates to
- prompt refinement subtasks
- image critique subtasks
- backlog seeding subtasks

Escalates to
- art-director when outputs drift stylistically
- producer-orchestrator when the workflow/process breaks
- creative-director when a concept lane is aesthetically wrong at a higher level

File/domain scope
- `tools/imagegen/**`
- especially:
  - `tools/imagegen/catalog/**`
  - `tools/imagegen/browser/**`
  - `tools/imagegen/prompts/**`
  - `tools/imagegen/output/**`

Required signoff on
- generated asset registration
- selected-file state changes in the concept manifest
- batch completion status

## Dormant Specialists (Not Always Active)

These exist conceptually but should not be active routing roles by default yet:
- audio specialist
- narrative specialist
- localization
- release manager
- security specialist
- live ops
- dedicated performance analyst
- economy specialist as a separate authority role

Wake them only when the work genuinely demands it.

## Delegation Rules for This Repo

### Core rule
Most work should pass through a lead role before reaching an executor role.

Good
- producer-orchestrator -> game-designer -> lead-programmer -> godot-gameplay-programmer
- producer-orchestrator -> art-director -> art-pipeline-operator
- producer-orchestrator -> ui-hud-specialist -> qa-validation-lead

Bad
- producer-orchestrator directly spawning multiple executor roles without a framing lead
- gameplay implementers making cross-domain decisions about design or visual identity
- art pipeline work modifying canon style direction without art-director review

## Project-Specific Escalation Triggers

Escalate to creative-director when:
- a mechanic change alters the player fantasy
- art outputs no longer feel like the same world
- UI changes alter tone or visual hierarchy in a project-wide way

Escalate to technical-director when:
- deterministic behavior may change
- RNG/seed contracts are affected
- architecture or cross-system interfaces change
- a tool/pipeline change alters the core dev loop

Escalate to producer-orchestrator when:
- a task crosses design/code/art/QA boundaries
- work expands beyond the originally scoped workflow
- signoff routing becomes ambiguous
- sprint sequencing is affected

Escalate to the user when:
- a choice meaningfully trades off scope vs pillar fidelity
- a choice changes the game’s identity
- a choice commits the project to a costly technical direction

## File/Domain Ownership

### Design-owned
- `design/gdd/**`
- `design/art-bible.md`

### Code-owned
- `src/core/**`
- `src/bootstrap/**`
- `src/ui/**`
- `src/tools/**`

### Validation-owned
- `tests/determinism/**`
- `tests/smoke/**`
- `tests/sim/**`

### Art-pipeline-owned
- `tools/imagegen/**`

### Production-owned
- `production/**`
- `docs/plans/**`
- `docs/hermes/**`

## Project Signoff Matrix

### `design/gdd/**`
Required
- game-designer

Additionally
- creative-director if the change touches pillars, fantasy, tone, or faction identity

### `design/art-bible.md` and art-direction docs
Required
- art-director

Additionally
- creative-director if the art-direction change alters project identity

### `src/core/**` and `src/bootstrap/**`
Required
- lead-programmer
- qa-validation-lead before completion

Additionally
- technical-director if determinism, architecture, or performance risk is involved

### `src/ui/**`
Required
- ui-hud-specialist
- qa-validation-lead before completion

Additionally
- art-director if visual language/readability hierarchy changes materially

### `tests/**`
Required
- qa-validation-lead

Additionally
- lead-programmer if test changes reflect an implementation contract shift

### `tools/imagegen/**`
Required
- art-pipeline-operator

Additionally
- art-director for selected artistic direction or style changes
- producer-orchestrator if the workflow impacts broader project process

### Cross-domain changes
Required
- producer-orchestrator

## Typical Workflow Shapes

### Combat/system feature
- game-designer
- lead-programmer
- godot-gameplay-programmer
- qa-validation-lead

### HUD readability / UI polish
- ui-hud-specialist
- art-director
- qa-validation-lead

### Concept-art batch
- art-director
- art-pipeline-operator
- creative-director only if drift occurs

### Determinism-sensitive refactor
- lead-programmer
- godot-gameplay-programmer
- qa-validation-lead
- technical-director if contracts shift

## Suggested Machine-Readable Seed

```yaml
project: dungeon-steward
engine: godot-4.6.2
priorities:
  - deterministic-combat-correctness
  - native-prototype-iteration
  - art-pipeline-traceability
  - hud-readability

roles:
  - role: game-designer
    file_scopes:
      - design/gdd/**
    escalates_to:
      - creative-director
      - producer-orchestrator
      - user

  - role: art-pipeline-operator
    file_scopes:
      - tools/imagegen/**
    escalates_to:
      - art-director
      - producer-orchestrator
      - creative-director
```

## Guidance for Hermes

For this repository, Hermes should use this file as the project-specific policy pack and use the generic `gamestudio-role-map.md` only as the parent template.

The point is to make delegation structure explicit in files rather than leaving it implicit in memory or in the mood of the current session.
