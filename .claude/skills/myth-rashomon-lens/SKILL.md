---
name: myth-rashomon-lens
description: "Generate multiple culture-specific interpretations of the same underlying world truth while keeping belief, propaganda, and objective canon clearly separated."
argument-hint: "[truth, event, institution, or symbol to reinterpret]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite, HonchoSearch, HonchoConclude
---

When this skill is invoked:

1. Read before reframing:
   - `design/world/canon-foundation.md`
   - `design/world/factions-and-cultures.md`
   - `design/world/institutions-and-locations.md`
   - `design/world/open-questions.md`
   - any task-relevant prompt packs or flavor docs

2. Identify the underlying truth or anchor event first.
   Never start by inventing contradictory myths without naming what they are myths ABOUT.

3. Build the output in this order:
   - underlying truth or agreed anchor
   - faction/culture A interpretation
   - faction/culture B interpretation
   - public/common version
   - suppressed or minority version
   - what no version willingly admits
   - practical consequences (law, ritual, card flavor, enemy behavior, event stakes)

4. Use bias patterns intentionally:
   - heroic projection
   - moral alignment
   - causal simplification
   - selective amnesia
   - inversion
   - institutional self-justification
   - counter-hegemonic preservation when appropriate

5. Keep explicit labels:
   - `Truth:` for objective canon
   - `Belief:` for in-world interpretation
   - `Public Story:` for common circulation
   - `Suppressed Reading:` for contested or hidden narratives

6. Do not use this skill to muddy the setting with arbitrary contradiction.
   The goal is useful plurality, not incoherence.

7. Default write targets:
   - patch relevant sections in `design/world/canon-foundation.md`
   - patch `design/world/factions-and-cultures.md`
   - or capture unresolved variants in `design/world/open-questions.md`

8. Ask before writing.

9. Only sync stable belief statements to Honcho after the file-backed version is approved.
