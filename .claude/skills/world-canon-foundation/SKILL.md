---
name: world-canon-foundation
description: "Build or refine a file-backed canon foundation: separate truth from belief, define canon tiers, set world rules, and keep the setting usable for gameplay and flavor generation."
argument-hint: "[optional focus, e.g. 'truth split', 'world rules', 'core premise']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, TodoWrite, HonchoSearch, HonchoConclude
---

When this skill is invoked:

1. Read before designing:
   - `design/gdd/game-concept.md`
   - `design/art-bible.md`
   - `design/world/index.md` if present
   - `design/world/canon-foundation.md` if present
   - any relevant faction, conflict, or naming docs under `design/world/`

2. Search Honcho for world-level facts if available, but treat them as recall only.

3. Diagnose the current foundation using four buckets:
   - what is explicitly true in the setting
   - what characters or factions merely believe
   - what is visual/tone guidance rather than literal canon
   - what remains an open question

4. Structure the foundation around these sections:
   - purpose and scope
   - core setting premise
   - truth vs belief split
   - canon tiers
   - tone pillars and anti-tone guardrails
   - current world rules
   - gameplay-facing implications
   - open questions promoted for later resolution

5. Force explicit truth labeling:
   - use wording like `Truth:` and `Belief:` when needed
   - do not let a cool in-world story accidentally masquerade as objective canon
   - if something is only inferred from art or prompts, mark it as working canon, not immutable truth

6. Present 2-4 options whenever the world premise could be framed differently.
   Example: is a thing legal authority, spiritual authority, social custom, or all three?

7. Draft compactly. The goal is a durable north-star doc, not encyclopedic lore.

8. Default write target:
   - `design/world/canon-foundation.md`
   - also patch `design/world/index.md` if the canon stack changed materially

9. Before writing, ask:
   - "May I write this to `design/world/canon-foundation.md`?"

10. After approval/write, suggest a small Honcho sync of only the stable facts.
