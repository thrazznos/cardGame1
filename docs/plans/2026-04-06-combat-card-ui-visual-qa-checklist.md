# Combat Card UI Visual QA Checklist

Purpose
- Evaluate whether the first-pass combat card redesign actually makes the hand and reward surfaces read as cards instead of buttons.
- Judge both card feel and tactical readability.
- Support manual review after implementation, not replace automated smoke coverage.

When to use
- After the first visual implementation pass.
- Before sign-off on the combat card UI redesign.
- During native runtime review at normal play distance.
- Alongside the approved spec and implementation plan.

Primary references
- `docs/plans/2026-04-06-combat-card-ui-spec.md`
- `docs/plans/2026-04-06-combat-card-ui-implementation-plan.md`
- `production/playtests/playtest-2026-04-04-combat-ui-readability.md`

Core rule
- A card UI pass only succeeds if it passes both:
  1. card feel
  2. tactical readability

Failure conditions
- If the UI looks prettier but still reads like buttons, it fails.
- If the UI looks more like cards but readability gets worse, it fails.

---

## 1. First-glance read

Question
- When the hand appears, do these read as cards immediately?

Pass
- First impression is `cards in hand`.
- They no longer read as a toolbar, action bar, or menu row.
- Each object feels like an individual card, not a stretched option button.

Fail
- They still feel like wide buttons.
- They read as a button row with art thumbnails attached.
- Reward choices feel like modal options instead of drafted cards.

---

## 2. Silhouette and proportions

Question
- Do the card shapes support card-ness?

Pass
- Hand cards feel portrait-leaning.
- Reward cards feel like larger cards from the same family.
- Fixed-width cards read clearly in the tray.
- Spacing helps each card silhouette stand on its own.

Fail
- Cards still stretch horizontally to fill space.
- Card proportions still resemble buttons/list items.
- Reward cards are just `taller buttons`.

---

## 3. Card-face hierarchy

Question
- Can the player visually identify the main card regions?

Expected regions
- hotkey or draft marker
- cost medallion
- framed art window
- title rail
- payoff chips
- short rules body
- footer strip

Pass
- The regions are visually distinct.
- Cost is easy to spot.
- Title has a real home.
- Payoff is more prominent than body text.
- Footer reads as a state lane, not leftover text.

Fail
- All information still collapses into one text block.
- Art still feels pasted in.
- No strong title/cost/payoff separation exists.
- Footer feels like random extra copy.

---

## 4. Scan speed

Question
- Can a player scan the hand quickly without reading every word?

Pass
- Cost is visible in peripheral vision.
- Name is readable quickly.
- Primary payoff is obvious.
- Gating/condition is easy to spot.
- Cards are distinguishable fast enough to support turn planning.

Fail
- The player must read sentence text for every card.
- Cost still gets buried.
- Payoff still hides inside prose.
- Cards still feel too similar at a glance.

---

## 5. Card identity

Question
- Do cards have distinct personalities without relying on giant flood-fill colors?

Pass
- Attack / defend / utility feel distinct.
- Role identity comes from crest + accent + hierarchy.
- Cards have stronger individual identity than the current prototype.
- Identity survives even when viewed small.

Fail
- The only way to tell cards apart is reading names.
- Role identity still depends too heavily on flat background color.
- Cards still feel samey.

---

## 6. Charter Warrant tone

Question
- Do the cards feel like Dungeon Steward cards specifically?

Pass
- Steward / warrant / civic fantasy tone comes through.
- Parchment / ink / brass / heraldic cues feel coherent.
- Reward cards feel ceremonial but disciplined.
- The cards feel world-bound, not generic fantasy UI.

Fail
- They look like generic CCG chrome.
- They look like mobile game UI.
- They look too tarot-ornate.
- They look too plain/ledger-like to feel rewarding.

---

## 7. Art integration

Question
- Does the art now feel embedded in the card?

Pass
- Art sits in a framed window/cameo.
- Art supports card feel instead of acting like a thumbnail.
- The frame helps sell the object as a card.
- Placeholder/shared art still looks intentional inside the shell.

Fail
- Art still looks like an avatar pasted on a button.
- The frame is too weak to matter.
- Art placement still reinforces `button with icon`.

---

## 8. Cost treatment

Question
- Is cost a first-class read?

Pass
- Cost medallion is easy to locate instantly.
- Numerals are readable.
- Zero-cost cards still feel intentional.
- Cost contributes to scan speed.

Fail
- Cost is hidden in text.
- Medallion is too small or too decorative.
- The player has to hunt for cost.

---

## 9. Payoff chip quality

Question
- Do the payoff chips make the tactical promise visible?

Pass
- Chips are visually stronger than rules body.
- Damage/block/focus/gem ops scan quickly.
- Chips support `why would I play this?` immediately.
- Chips do not become clutter.

Fail
- Chips are too weak to matter.
- Chips are too decorative to read.
- The card still depends on body text to explain core value.

---

## 10. Footer strip usefulness

Question
- Does the footer communicate runtime truth cleanly?

Pass
- Footer clearly communicates condition/state.
- Examples like:
  - `Playable`
  - `Needs top Ruby`
  - `Needs FOCUS`
  - `Add to deck`
  - `Chosen`
  work immediately.
- Footer reads as a dedicated lane, not flavor text.

Fail
- Footer is vague.
- Footer competes with body text.
- Disabled/locked state still feels confusing.

---

## 11. Hover and focus behavior

Question
- Do hover and focus make the card feel more physical without harming layout?

Pass
- Hover lift feels like card emphasis, not button hover.
- Focus ring/treatment is clear and not hover-dependent.
- State change feels stable and polished.
- Tray does not jitter or collapse.

Fail
- Hover still just feels like a border recolor.
- Focus is unclear for keyboard/controller.
- Animation causes layout instability.
- Cards twitch or shove each other around.

---

## 12. Pressed / played feel

Question
- When interacting, does the card feel committed rather than clicked?

Pass
- Pressed state feels intentional and card-like.
- Reward selection feels like choosing a card.
- Interactions feel tactile, not software-y.

Fail
- Interaction still feels like pressing a menu button.
- There is no sense of commitment.
- Reward selection still feels like clicking options in a dialog.

---

## 13. Disabled state readability

Question
- Are unusable cards still readable?

Pass
- Disabled cards retain name/cost/payoff legibility.
- State clearly explains why unavailable.
- The card still feels like a card, just temporarily gated.

Fail
- Disabled cards turn into gray mush.
- The player cannot read what the card is anymore.
- Reason is hidden or unclear.

---

## 14. Reward-card ceremony

Question
- Do reward cards feel more special than hand cards while staying in the same family?

Pass
- Larger presentation feels intentional.
- Reward cards still clearly belong to the same system.
- Chosen/applied state feels ceremonial.
- Reward overlay supports comparison well.

Fail
- Reward cards feel unrelated to hand cards.
- Reward cards are only bigger, not better presented.
- Chosen state feels like a generic checkbox/list selection.

---

## 15. Readability at play distance

Question
- Can this be comfortably read in actual play conditions?

Pass
- Title is readable at normal distance.
- Cost is readable.
- Payoff chips are readable.
- Footer is readable enough to support decisions.
- Eye strain is reduced vs the current prototype.

Fail
- Text is still too small.
- Value-bearing information still requires leaning in.
- Card face got prettier but not more usable.

---

## 16. Resolution/layout sanity

Check at minimum
- comfortable desktop size
- narrower laptop-ish width
- reward overlay with 3 visible cards
- hand with 5 populated cards

Pass
- No obvious clipping.
- No overlap bugs.
- No layout collapse.
- Hierarchy survives smaller widths.

Fail
- Labels clip badly.
- Art or chips overlap text.
- Reward layout breaks at common desktop widths.

---

## 17. Keyboard/controller parity

Question
- Can a non-mouse user still read and navigate the card states?

Pass
- Focus state is obvious.
- Hotkey markers remain legible.
- Reward choice focus is clear.
- No essential info is hover-only.

Fail
- Hover gets all the good affordances.
- Focus ring is weak or missing.
- Keyboard/controller users get a worse read.

---

## 18. “Still looks like a button?” kill test

Question
- If someone saw this for 2 seconds, would they say `cards` or `fancy buttons`?

Pass
- Answer is clearly `cards`.

Fail
- Answer is `fancy buttons`.

---

## 19. Reviewer prompts for fast feedback

Use these in a short review session
- What did you think these were on first glance?
- Could you tell cost immediately?
- Could you tell what each card mostly does without reading everything?
- Did the hand feel like cards or UI controls?
- Which parts still felt too button-like?
- Were disabled cards still understandable?
- Did reward choices feel like drafting cards?

---

## 20. Ship / no-ship summary

Greenlight only if
- hand reads as cards immediately
- reward cards feel like card choices
- cost/name/payoff/gating scan faster than before
- disabled/focus states remain readable
- no layout jitter/clipping at real sizes
- the tone fits Dungeon Steward

Do not greenlight if
- the redesign still reads as a button bar
- readability regressed
- role identity is still too weak
- reward selection still feels like modal option buttons
- hover/focus polish hides structural problems

---

## 21. Recommended review method

1. Open the native combat slice.
2. Inspect a 5-card hand and a 3-card reward state.
3. Review once at normal play distance before zooming in.
4. Perform a keyboard-only focus pass.
5. Trigger at least one disabled/gated state.
6. Use this checklist before approving the first-pass redesign.

Bottom line
- The redesign is successful only when the hand stops reading like a toolbar and starts reading like a hand of tactical cards, without sacrificing Dungeon Steward’s combat clarity.