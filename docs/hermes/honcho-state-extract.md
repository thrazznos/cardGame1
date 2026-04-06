# Honcho State Extract

This document extracts the currently implicit Honcho-backed operating state relevant to Hermes orchestration and makes it explicit in repo files.

The goal is not to replace Honcho. The goal is to prevent workflow structure from existing only as invisible runtime state.

## Why This Exists

Hermes is currently using Honcho as the active memory provider. That is useful for recall, continuity, and cross-session context.

It is not, however, a good sole source of truth for:
- studio structure
- delegation policy
- signoff routing
- project workflow rules
- active project-specific orchestration assumptions

Those should live in explicit repo files.

## Observed Current State

Observed from Hermes runtime and config at the time of writing:

### Hermes memory status
- built-in memory: active
- external provider: Honcho

### Hermes config state
From `~/.hermes/config.yaml`:
- `memory.provider: honcho`
- `delegation.max_iterations: 50`
- `delegation.max_concurrent_children: 6`
- default delegation toolsets:
  - terminal
  - file
  - web

### Honcho runtime status
From `hermes honcho status`:
- host: `hermes`
- enabled: `true`
- workspace: `hermes`
- ai peer: `hermes`
- user peer: `ericfode`
- session key: `cardgame1`
- recall mode: `hybrid`
- memory mode: `hybrid`
- write frequency: `async`
- session strategy: `per-directory`

### Honcho config file state
From `~/.hermes/honcho.json`:
- host block `hermes`
  - workspace: `hermes`
  - aiPeer: `hermes`
  - memoryMode: `hybrid`
  - recallMode: `hybrid`
  - writeFrequency: `async`
  - sessionStrategy: `per-directory`
  - saveMessages: `true`
- host block `hermes.meta`
  - workspace: `hermes`
  - aiPeer: `meta`
  - similar hybrid/async settings

## What This State Means

At the moment, Hermes is effectively treating:
- the Hermes installation as the host identity
- the workspace as a shared Hermes-level memory space
- the current repo as a per-directory session key (`cardgame1`)

This is fine for recall.
It is not sufficient for explicit orchestration.

## State That Should Remain in Honcho

Honcho is a good home for:
- long-lived recall of project facts
- historical conversational context
- accumulated user preferences
- fuzzy retrieval across sessions
- memory provider concerns that are naturally asynchronous and background-oriented

In other words: memory, not policy.

## State That Should Move Into Explicit Repo Files

These should not live only in Honcho-backed implicit memory:
- generic studio role map
- project-specific role map
- delegation permissions
- escalation paths
- signoff matrix
- workflow entrypoints
- project-specific validation expectations
- current project orchestration assumptions

This repo now has explicit homes for the first layer of that:
- `docs/hermes/gamestudio-role-map.md`
- `docs/hermes/dungeon-steward-role-map.md`

## Recommended State Split

### 1. Generic reusable studio policy
File
- `docs/hermes/gamestudio-role-map.md`

Purpose
- reusable hierarchy and role model
- generic delegation and signoff rules

### 2. Project-specific orchestration policy
File
- `docs/hermes/dungeon-steward-role-map.md`

Purpose
- active roles for this repo
- actual file/domain ownership
- actual escalation triggers
- actual signoff matrix

### 3. Runtime/project activity state
Recommended future file(s)
- `production/session-state/active.md` or equivalent
- optionally `docs/hermes/orchestrator-state.yaml` later

Purpose
- what workflow is active right now
- current phase
- pending approvals
- active delegates
- blocked handoffs
- signoff queue

### 4. Honcho memory state
Location
- Honcho provider config and remote memory backend

Purpose
- historical recall and continuity
- non-canonical supporting context

## Recommended Future Runtime State Model

If Hermes gets a role-aware orchestrator for game projects, the canonical runtime state should be explicit and file-backed.

Suggested fields:

```yaml
project: dungeon-steward
workflow: combat-feature
phase: validation
active_roles:
  - producer-orchestrator
  - game-designer
  - lead-programmer
  - qa-validation-lead
pending_approvals:
  - type: signoff
    role: qa-validation-lead
    scope:
      - src/core/gsm/gem_stack_machine.gd
active_delegates:
  - role: godot-gameplay-programmer
    task: implement reward draft integration
blocked: []
```

The key principle:
- project policy should be inspectable in git-tracked files
- runtime state should be inspectable in project files
- Honcho should support recall, not silently own the workflow model

## Project-Specific Observation: Session Key Mismatch Risk

The current session key is `cardgame1`, which reflects the repo directory name rather than the project’s outward-facing identity (`Dungeon Steward`).

That is not inherently wrong, but it is a reminder that directory-derived runtime identity is often accidental.

For orchestration purposes, explicit project naming in repo docs is better than inferring identity from:
- directory name
- active profile name
- Honcho host/workspace defaults

## Guidance Going Forward

1. Keep Honcho enabled for memory and recall.
2. Do not store the only copy of orchestration structure in Honcho-backed memory.
3. Treat `docs/hermes/*.md` as the canonical human-readable policy layer.
4. Add explicit file-backed runtime state later if the orchestrator becomes active.
5. Let Honcho mirror and support this state indirectly, rather than originating it.

## Practical Conclusion

The extracted implicit state is:
- Hermes-wide host/workspace identity: `hermes`
- per-directory session identity: `cardgame1`
- hybrid recall/memory behavior
- async write behavior
- bounded but substantial delegation settings

The repo-level workflow truth should now live in the newly added docs, not only in provider memory.

That is the whole point of this extraction: to move structure from atmosphere into documents.
