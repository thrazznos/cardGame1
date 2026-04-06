# Combat Fun Roadmap — 2026-04-05

Goal
- Make Dungeon Steward's combat slice genuinely fun before expanding into broader run-loop UI or meta systems.
- A player should be able to read the board quickly, see at least one meaningful sequencing line, and feel the payoff of good ordering immediately.

Why this is the right focus now
- Sprint 005 is complete and stabilized the card catalog / presenter path.
- The combat HUD is the only implemented player-facing UI surface in `src/` today.
- Deck inspection, map/node UI, and hub UI are designed in GDDs but are not yet implemented.
- Recent readability feedback still points at core combat problems: too much text parsing, weak at-a-glance state read, and insufficient payoff feedback.
- If combat is not fun, the rest of the loop does not yet deserve expansion.

Guiding principles
- Combat-first over UI breadth.
- Readability must serve decision quality, not just aesthetics.
- Sequencing mastery should be more rewarding than raw stat inflation.
- Every turn should offer some compounding or setup-vs-payoff tension.
- Failure should be educational, not mysterious.
- Keep everything deterministic, debuggable, and data-driven.

What “fun” means for this roadmap
1. Fast read
- The player can tell what matters right now in a couple of seconds.

2. Real choice
- The player usually has at least one meaningful sequencing decision instead of just dumping cards.

3. Visible payoff
- Good order and timing produce immediate, legible upside.

4. Educational failure
- Bad order, rejected actions, and low-value turns are understandable from the game surfaces.

5. Encounter texture
- Different fights pressure different sequencing habits rather than feeling like the same math problem.

Non-goals for this roadmap
- Full map/node implementation.
- Hub UI implementation.
- Broad deckbuilder / hub planning surfaces.
- Large cosmetic-polish waves disconnected from combat feel.
- Full localization framework work.
- Any feature that expands loop breadth without directly improving combat fun.

Wave 1 — Sprint 006: Readable + satisfying combat

Goal
- Make the existing combat slice fast to parse and satisfying to play without expanding into map/hub scope.

Primary problems to solve
- Too much tactical state requires text parsing.
- Played cards do not always feel impactful enough.
- Setup / producer turns can feel like homework instead of progress.
- Rejections and resolution order are more explainable than before, but still not pleasant enough to read in live play.

Scope
1. Readability floor
- Strengthen HP / resource read with better at-a-glance bars and clearer hierarchy.
- Improve enemy intent readability.
- Improve hand scan speed using stronger card role / cost / payoff cues.
- Make resolve-lock and unavailable-action messaging more obvious.
- Tighten queue and “what changed / why” surfaces so they support trust, not noise.

2. Turn feel
- Add lightweight feedback for played-card impact.
- Make produces / consumes / blocks / rejects / sequencing payoffs read cleanly in the live HUD.
- Improve event log phrasing so outcomes are quick to understand.
- Keep feedback deterministic and debuggable; avoid cinematic timing authority.

3. Starter deck and opening-turn audit
- Identify boring or dead opener patterns.
- Raise the floor on setup / producer cards so they still contribute now.
- Make opening hands teach the sequencing fantasy instead of obscuring it.

4. Combat affordance cleanup
- Clarify why cards are legal / illegal.
- Improve queue/order hint trust.
- Reduce text bloat where stable scan cues can carry meaning faster.

5. Validation
- Focused native playtests on the first two encounters.
- Smoke coverage for combat readability regressions.
- Determinism fixtures for representative combo turns and rejection paths.

Likely file touch points
- `src/ui/combat_hud/combat_hud_controller.gd`
- `scenes/combat/combat_slice.tscn`
- `src/core/card/card_presenter.gd`
- `data/cards/catalog_v1.json`
- `data/decks/starter_run_v1.json`
- `src/core/reward/reward_draft.gd` (only if reward-facing combat experimentation needs narrow support)
- `tests/smoke/`
- `tests/determinism/`

Wave 1 exit criteria
- Players can parse the combat state quickly without heavy text-reading overhead.
- The first few turns usually offer at least one meaningful sequencing decision.
- Setup / producer cards have a visible floor and do not feel like wasted clicks.
- Reject reasons and resolution outcomes are understandable without debugger use.
- Combat feels better without broadening the game loop.

Wave 2 — Sprint 007: Interesting + build-shaping combat

Goal
- Make combat turns genuinely interesting, not merely readable.

Primary problems to solve
- Some cards likely still collapse into obvious or low-expression lines.
- Resource pressure may not yet create enough sequencing tension.
- Rewards need to support combat experimentation rather than just adding content volume.

Scope
1. Card role pass
- Clarify functional roles such as starters, bridges, payoffs, and rescue / fixup tools.
- Make roles legible both in authored data and combat-facing presentation.

2. Sequencing depth pass
- Improve synergies in the live combat slice.
- Make strong ordering produce visible upside.
- Make weak ordering understandable rather than opaque.
- Add cards only when they create new decisions, not just more content.

3. Economy / tension pass
- Tune energy / focus / resource pressure so turns are neither trivial nor dead.
- Reduce obviously correct play patterns when they flatten decision space.

4. Reward-in-service-of-combat
- Keep reward work narrowly focused on amplifying combat experimentation.
- Avoid broad run-loop expansion in this wave.
- Ensure reward picks materially affect the next combat’s decision space.

Likely file touch points
- `data/cards/catalog_v1.json`
- `data/decks/starter_run_v1.json`
- `src/core/card/`
- `src/core/reward/reward_draft.gd`
- combat runner / validation paths already used by the current slice
- `tests/smoke/`
- `tests/determinism/`
- balance / probe scripts if needed

Wave 2 exit criteria
- Multiple lines within a turn feel viable often enough to be interesting.
- Players can explain why one play order was stronger than another.
- Reward choices materially shape the next combats.
- Combat begins to create build identity rather than isolated card clicks.

Wave 3 — Sprint 008: Varied + replayable combat

Goal
- Make combat stay fun across encounters, not just inside one sandbox.

Primary problems to solve
- Fights may still ask too little of the player beyond repeating the same sequencing habits.
- Encounter pacing may not yet support both compounding and pressure.

Scope
1. Encounter variety
- Create distinct enemy pressure profiles.
- Use different intent patterns and timing demands.
- Let some encounters punish greed, some punish slow setup, and some test defense timing / sequencing discipline.

2. Pacing and pressure
- Shorten dull fights.
- Preserve room for compounding turns.
- Avoid pure stat-race feel.

3. Combat progression texture
- Make “next fight” feel different because of deck state and reward choices.
- Continue deferring full map/hub breadth unless combat clearly earns it.

Likely file touch points
- `src/core/encounter/` or current enemy/runtime encounter paths
- combat HUD intent surfaces where enemy readability must improve
- reward / deck data where encounter-response tools need support
- `tests/smoke/`
- `tests/determinism/`

Wave 3 exit criteria
- At least a few clearly different combat pressures exist.
- Players adapt sequencing plans between encounters.
- Fights are memorable for decisions and pacing, not just numbers.

Validation approach across all waves
- Prefer native desktop validation first for the current prototype reality.
- Preserve the UI authority boundary from ADR-0001: UI submits intents and renders authoritative state only.
- Keep smoke tests aligned with player-facing readability promises.
- Keep determinism fixtures aligned with authoritative logic and document any intentional baseline change.
- Use focused playtests after each readability / feel pass instead of waiting for a giant polish phase.

Recommended execution order
1. Convert Wave 1 into `production/sprints/sprint-006.md`.
2. Keep Sprint 006 tightly bounded to combat readability, turn feel, and starter-deck / opening-turn quality.
3. Run focused playtests after the first pass instead of delaying feedback to sprint closeout.
4. Only begin Wave 2 after combat in Wave 1 is clearly more fun in live play.
5. Only expand into broader run-loop UI once combat consistently earns that breadth.

Decision summary
- Prioritize making combat readable, satisfying, and strategically interesting.
- Treat UI, tuning, reward shaping, and encounter work as servants of combat fun, not parallel vanity tracks.
- Delay map / hub breadth until the combat loop is worth replaying on its own.
