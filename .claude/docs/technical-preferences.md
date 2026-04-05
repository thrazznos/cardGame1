# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6.2
- **Language**: GDScript (primary), C++ via GDExtension (performance-critical)
- **Rendering**: Compatibility renderer (web target default), optional Forward+ for desktop builds
- **Physics**: Godot Physics 2D

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS (desktop web baseline)
- **Frame Budget**: 16.67 ms/frame (logic+UI target <= 10 ms, render/composite target <= 6.67 ms)
- **Draw Calls**: 300/frame target, 500/frame absolute peak cap
- **Memory Ceiling**: 512 MB runtime target, 768 MB absolute browser ceiling
- **Suggestion**: If profiling exceeds peak budgets, degrade VFX density and UI animation frequency before reducing gameplay readability.

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: 70% project-wide automated coverage (higher for deterministic core systems)
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]
