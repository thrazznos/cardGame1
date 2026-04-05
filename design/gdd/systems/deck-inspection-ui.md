# Deckbuilder/Inspection UI

> **Status**: Approved
> **Author**: Nathan + Hermes agents
> **Last Updated**: 2026-04-05
> **Implements Pillar**: Readable Tactical Clarity; Sequencing Mastery Over Raw Stats; High Run Variety, Low Grind
> **Upstream References**: design/gdd/card-data-definitions.md, design/gdd/systems/deck-lifecycle.md, design/gdd/systems/relics-passive-modifiers.md, design/gdd/systems/combat-ui-hud.md

## Overview

Deckbuilder/Inspection UI (DIUI) is the deterministic read-and-plan surface for card/deck information in two contexts:
1) Run context (combat/map overlays): inspect current runtime deck composition, zone distribution, card-instance state, and active relic/passive interactions.
2) Hub context (between runs): inspect persistent deck list, card catalog status, and synergy planning surfaces before starting a run.

DIUI does not own card logic, zone transitions, passive resolution, or unlock legality. It renders authoritative data from Card Data, Deck Lifecycle System (DLS), and Relics/Passive Modifiers (RPM), then exposes stable sorting/filtering/explanation tools so players can reason about builds without ambiguity.

Primary objective:
- Make deck state and card interaction potential legible and trustworthy in browser runtime, including high-density turns and large collection views.

Non-goals (MVP):
- UI-side mutation of runtime deck zones or passive order.
- Hidden “smart recommendations” that use non-authoritative/private signals.
- Animation-authored logic outcomes.
- Auto-builder deck optimization.

## Player Fantasy

The player should feel:
- “I can always understand what is in my deck right now, and where important cards are.”
- “When I inspect a card, I immediately see how it fits my sequencing and relic engine.”
- “I can compare options quickly without losing trust in what is factual vs inferred.”
- “The UI helps planning, but never lies or leaks hidden information.”

Emotional outcome:
- Confidence from deterministic visibility.
- Mastery through clear synergy inspection.
- Reduced cognitive load in combo-heavy runs.

## Detailed Design

### Design Goals

1) Deterministic presentation
- Same authoritative snapshot must produce identical card ordering, counts, chips, and explanation text across browsers.

2) Context parity
- Core inspection interactions are consistent in run and hub contexts, while respecting each context’s information entitlements.

3) Progressive depth
- Casual users can read deck fundamentals quickly; advanced users can inspect tags, timing, and source breakdowns without modal overload.

4) Explanation-first UX
- Every computed indicator (synergy badge, passive highlight, filter result) is traceable to explicit data contracts.

5) Browser-first performance
- Large card pools and frequent runtime updates remain responsive under target budgets.

### Information Architecture (MVP)

Primary regions:
1. Header context strip
- Context badge: `Run` or `Hub`.
- Snapshot/version token.
- Deck size and zone totals.

2. Left rail controls
- Search input.
- Filter chips/groups (cost, rarity, archetype, combo tags, lifecycle tags, zone, generated/temp, relic-interaction).
- Sort selector and direction.

3. Center card list/grid
- Deterministically ordered card rows/cards.
- Supports compact list and visual card-grid modes.
- Selection state persistent across filter changes when possible.

4. Right detail panel
- Selected card definition fields + runtime overlays.
- Effect summary, sequencing metadata, targeting contract, lifecycle behavior.
- Related relic/passive interactions and “why shown” explanation.

5. Footer summary bar
- Aggregate metrics: counts by cost/rarity/archetype/zone, curve histogram, tag distribution.
- Warning chips (for example: high temporary density, low starter density).

Context-specific additions:
- Run mode: zone breakdown, card-instance state badges (retained, ephemeral, generated, in limbo), passive trigger history links.
- Hub mode: persistent deck composition, catalog ownership/unlock status (if exposed), planning pins/bookmarks.

### Core Rules

1) Authority boundary rule
- DIUI renders read models only.
- Runtime mutations remain owned by TSRE/DLS/RPM via their source systems.

2) Deterministic ordering rule
- Primary ordering contract for card list:
  - `sort_key = (context_group_key, user_sort_key, card_id, card_instance_id?)`
- Tie-breakers are mandatory and stable.
- In hub context without instances, omit `card_instance_id` and use deterministic synthetic index where needed.

3) Clear source-of-truth rule
- Every displayed field is labeled internally by source:
  - Card definition fields from Card Data (`card_id`, `rarity`, `base_cost`, `speed_class`, `timing_window`, `combo_tags[]`, `target_mode`, `effects[]`, `zone_on_play`, `ephemeral`, `generated_only`, UI keys).
  - Runtime location/state fields from DLS (`zone`, `retain_flags`, `generated`, `creation_seq_id`, transition reasons).
  - Passive interaction fields from RPM (`relic_instance_id`, `passive_node_id`, trigger outcomes, cooldown/suppression states).

4) Hidden-information safety rule
- Run mode must not reveal hidden draw order or unresolved private data unless entitlement flag exists.
- No inferred top-of-draw preview from event timing.

5) Explainable derived insights rule
- Any derived badge (for example “Relic synergy”, “Chain starter density”, “Retain loop risk”) must have a deterministic formula and drilldown explanation.

6) Filter correctness rule
- Filter operations are pure over current snapshot.
- Applying/removing filters must not mutate source data or ordering outside declared sort.

7) Search normalization rule
- Search compares normalized tokens over localized display name and canonical IDs.
- Diacritics/case-insensitive matching in UI layer, but identifiers remain exact in debug views.

8) Runtime update rule (run mode)
- Incoming DLS/RPM events update views incrementally in event order.
- If stale snapshot detected, DIUI enters reconciliation state and blocks misleading interaction outcomes.

9) Context behavior parity rule
- Same card detail panel structure in run and hub mode.
- Fields unavailable in context show explicit “Not available in this context” markers, never blank ambiguity.

10) Accessibility rule
- All statuses encoded by icon + text + optional color.
- Keyboard navigation supports search, filter, card focus, detail expand/collapse.

11) Input safety rule
- During ResolveLock in combat, DIUI remains inspect-only and cannot submit gameplay actions.

12) Data contract mismatch rule
- Unknown enums/fields render with deterministic fallback chips (`UNKNOWN_<field>`) in dev.
- Release mode maps to safe generic copy + telemetry.

### Card Inspection Model

Card detail sections (in order):
1) Identity and rarity
- `card_id`, localized name, rarity, archetype.

2) Cost and play constraints
- `base_cost`, `cost_type`, `play_conditions[]`, target contract (`target_mode`, `target_filters[]`, `max_targets`, `invalid_target_policy`).

3) Sequencing and timing
- `speed_class`, `timing_window`, `combo_tags[]`, `chain_flags[]`.

4) Effect payload summary
- Ordered `effects[]` with preview priorities.
- Compact human text + expandable raw payload.

5) Lifecycle behavior
- `zone_on_play`, `ephemeral`, `generated_only`, retain/temp semantics.

6) Runtime state (run mode only)
- Current zone, instance markers (retained/temp/generated), latest transition reason code/event reference.

7) Relic/passive interaction lens
- Active relics/passives that match card tags/events/predicates.
- Last observed trigger outcomes involving this card (if present).

8) Source provenance
- Base deck / generated source (`generated_by_source_instance_id` if available), and creation turn metadata.

### Filtering and Sorting (MVP)

Filter groups:
- Text search (name/id/rules text token index)
- Zone: draw/hand/discard/exhaust/limbo (run mode)
- Cost bucket: 0,1,2,3+
- Rarity
- Archetype
- Sequencing: speed class, timing window, combo tags
- Lifecycle: retain/ephemeral/generated_only
- Runtime flags: retained, generated, temp, recently moved
- Relic interaction: has active passive linkage / recently triggered / suppressed

Sort options:
- Name
- Cost (then name)
- Rarity (then cost then name)
- Archetype (then cost then name)
- Recent movement (run mode)
- Zone then insertion order (run mode)
- Synergy score (derived, deterministic formula below)

Determinism policy:
- Each sort defines complete tie-break chain ending in stable identifiers.
- Changing locale does not alter non-localized fallback tie-break behavior.

### Interaction Flows

Flow A: Quick inspect during run
1) Player opens deck inspection overlay.
2) DIUI requests/uses latest authoritative inspection snapshot.
3) Card list renders using saved sort/filter profile.
4) Player selects card -> detail panel opens.
5) Player expands “Relic interactions” -> sees active/passive links and reason text.

Flow B: Event-driven update while open
1) DLS emits transition events and RPM emits passive outcomes.
2) DIUI applies event deltas in order.
3) Affected card rows update badges/counts with non-blocking highlight.
4) Existing selection remains if card still in filtered result; otherwise selection shifts deterministically.

Flow C: Hub deck planning
1) Player opens deckbuilder/inspection in hub.
2) DIUI loads persistent deck + catalog snapshot.
3) Player filters by archetype/tags and sorts by cost or synergy score.
4) Player pins cards for planning; pins stored as UI-only metadata.
5) Start-run handoff consumes authoritative deck state, not UI pin state.

Flow D: “Why this badge?” explanation
1) Player hovers a derived badge (example: “Relic synergy: 3”).
2) Popover shows formula inputs and matching relic/passive nodes.
3) Links to relevant card/relic details.

### States and Transitions

DIUI macro states:
- InspectionUiInit
- AwaitSnapshot
- InteractiveBrowse
- CardFocused
- FilterEdit
- ReconcileSnapshot
- ContextSwitching
- ReadOnlyInspect (resolve lock / offline fallback)
- InspectionUiErrorRecover

Primary transitions:
- InspectionUiInit -> AwaitSnapshot
- AwaitSnapshot -> InteractiveBrowse (snapshot valid)
- InteractiveBrowse -> CardFocused (selection)
- CardFocused -> FilterEdit (filter drawer/search active)
- FilterEdit -> InteractiveBrowse (apply/clear)
- InteractiveBrowse -> ReconcileSnapshot (version drift/event gap)
- ReconcileSnapshot -> InteractiveBrowse (reconciled)
- InteractiveBrowse -> ContextSwitching (run <-> hub)
- ContextSwitching -> AwaitSnapshot
- Any -> ReadOnlyInspect (context-imposed read-only)
- Any -> InspectionUiErrorRecover (contract mismatch/fatal parse)

Invalid transitions:
- AwaitSnapshot -> CardFocused without valid render model.
- ReconcileSnapshot -> CardFocused with stale selected reference.
- InspectionUiErrorRecover -> InteractiveBrowse without fresh valid snapshot.

State guards:
- GuardHasValidSnapshot
- GuardSortKeyComplete
- GuardSelectionExistsInModel
- GuardReasonMappingsComplete

### Data Model and API Contracts

Consumed run inspection snapshot (read):
- `DeckInspectionRunSnapshot`
  - `run_id`
  - `version_token`
  - `zone_counts`
  - `cards[]` (definition + runtime projection fields)
  - `relic_links[]` (card_id/card_instance_id -> passive nodes)
  - `recent_events[]` (bounded)
  - `visibility_entitlements`

Consumed hub inspection snapshot (read):
- `DeckInspectionHubSnapshot`
  - `profile_id`
  - `version_token`
  - `persistent_deck_cards[]`
  - `catalog_cards[]` (if enabled)
  - `ownership/unlock visibility fields` (if exposed)

Optional query contracts:
- `GetDeckInspectionSnapshot(context, cursor/version_token?)`
- `GetCardInspectionDetail(card_id, card_instance_id?)`
- `GetRelicCardInteractionSlice(card_id|card_instance_id)`

UI-local ephemeral state:
- `filter_state`
- `sort_state`
- `selection_state`
- `pinned_cards` (hub-only, non-authoritative)
- `last_seen_version_token`

Contract requirements:
- Arrays consumed by DIUI must either be pre-sorted canonically or include sufficient keys for canonical sorting.
- All reason codes must map to UI text keys.

### Interactions with Other Systems

1) Card Data & Definitions (hard)
- Supplies card schema and localization/ui payload fields.
- DIUI must reflect schema fields exactly; no redefinition of enums.

2) Deck Lifecycle System (hard in run context)
- Supplies zone membership, card-instance metadata, transition history.
- DIUI uses DLS zone model (`draw_pile`, `hand`, `discard_pile`, `exhaust_pile`, `limbo_pending_resolve`) and reason/event references.

3) Relics/Passive Modifiers (hard in run context)
- Supplies passive trigger attempts/outcomes and relic state (active/suppressed/cooldown/exhausted).
- DIUI links passive data to card inspect panels and derived synergy indicators.

4) Combat UI/HUD (adjacent)
- DIUI may be embedded/overlaid within combat HUD.
- Must obey ResolveLock input constraints and shared reason taxonomy.

5) Unlock & Option Gating / Profile systems (soft-provisional for hub)
- If hub catalog shows lock/ownership states, DIUI consumes those outputs but does not own progression logic.

## Formulas

Notation:
- `I(condition)` in {0,1}
- `clamp(x,a,b)=min(max(x,a),b)`

1) Deck composition percentages

`zone_pct(z) = zone_count(z) / max(1, total_runtime_cards_visible)`

Used for summary bars in run mode.

2) Mana curve bucket ratios

For bucket set `B={0,1,2,3+}`:

`curve_ratio(b) = count(cards where cost_bucket=b) / max(1, visible_card_count)`

3) Synergy score (card-level display only)

`synergy_score(card) = W_tag*tag_match_count + W_trigger*trigger_link_count + W_lifecycle*lifecycle_match_count`

Where:
- `tag_match_count`: number of active relic/passive nodes whose predicates/tags match card metadata.
- `trigger_link_count`: recent trigger outcomes involving this card (bounded window).
- `lifecycle_match_count`: matches on retain/temp/generated interactions relevant to active passives.

MVP defaults:
- `W_tag = 1.0`
- `W_trigger = 1.25`
- `W_lifecycle = 0.75`
- Display clamp: `synergy_score_display = clamp(score, 0, 99)`

4) Filtered result count

`result_count = Σ I(card satisfies all active filters)`

Filter order must not change result set; only evaluation performance.

5) Deterministic sort key resolution

`final_sort_key = (primary_sort_fields..., card_id, card_instance_id_or_0)`

Constraint:
- Every sort option must produce a total ordering over the visible set.

6) Snapshot freshness indicator

`stale = I(now_ms - snapshot_received_at_ms > stale_threshold_ms)`

MVP default:
- `stale_threshold_ms = 1500` (run mode overlay)
- `stale_threshold_ms = 5000` (hub mode)

7) UI performance budgets

`list_recompute_ms_p95 <= LIST_RECOMPUTE_BUDGET_MS`
`input_to_visual_feedback_ms_p95 <= INSPECT_INPUT_FEEDBACK_P95_MS`

MVP defaults:
- `LIST_RECOMPUTE_BUDGET_MS = 4.0`
- `INSPECT_INPUT_FEEDBACK_P95_MS = 80`

## Edge Cases

1) Card exists in events but missing from current snapshot
- Show tombstone row in debug mode; in release, silently remove row and log telemetry.

2) Card transitions zones while selected
- Keep selection by `card_instance_id`; detail panel updates zone and reason history live.

3) Selected card filtered out by new filter
- Deterministically select next visible card by current order; if none, clear selection.

4) Unknown enum from upstream (`speed_class`, `zone_on_play`, etc.)
- Render fallback token and include contract mismatch warning in debug.

5) Passive trigger references removed/suppressed relic
- Preserve historical trigger row with “source no longer active” badge.

6) Hidden-information leak attempt through DOM inspection
- Release build omits hidden payload fields entirely from client snapshot.

7) Locale change mid-session
- Rebuild text and localized sort collation while preserving identifier tie-break determinism.

8) Large generated-card bursts in run mode
- Virtualized list rendering and batched updates; maintain event-order consistency.

9) Snapshot version drift during filter edits
- Enter ReconcileSnapshot; suspend stale derived badges until fresh model applied.

10) Missing localization key for card or reason
- Dev: explicit `UNMAPPED_KEY(...)` token.
- Release: deterministic fallback copy and telemetry.

## Dependencies

| System | Direction | Dependency Type | Interface Contract |
|---|---|---|---|
| Card Data & Definitions | Upstream authority | Hard | Supplies card schema fields, effect payload metadata, lifecycle tags, and UI localization keys consumed by DIUI. |
| Deck Lifecycle System | Upstream runtime authority | Hard (run) | Supplies zone membership/order, instance flags, transition reason/event references, and deterministic update stream. |
| Relics/Passive Modifiers | Upstream runtime authority | Hard (run) | Supplies relic/passive state, trigger outcomes, and reason-coded linkage data for card interaction surfaces. |
| Combat UI/HUD | Adjacent host | Hard-adjacent | Provides overlay integration, resolve-lock behavior, and shared reason messaging style in combat context. |
| Unlock/Profile/Hub systems | Upstream context provider | Soft (hub MVP) | Supplies optional catalog ownership/unlock projections for hub inspection surfaces. |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Too Low Risk | Too High Risk |
|---|---|---:|---|---|---|
| `stale_threshold_ms_run` | int | 1500 | 750-3000 | Frequent stale warnings | Outdated run data appears trustworthy |
| `stale_threshold_ms_hub` | int | 5000 | 2000-10000 | Excess refresh churn | Old hub state confusion |
| `LIST_RECOMPUTE_BUDGET_MS` | float | 4.0 | 2.0-8.0 | Aggressive degradation | Frame hitch risk |
| `INSPECT_INPUT_FEEDBACK_P95_MS` | int | 80 | 50-140 | Hard on low-end devices | Sluggish feel |
| `max_recent_events_shown` | int | 40 | 10-120 | Less forensic clarity | Visual noise/perf pressure |
| `search_debounce_ms` | int | 120 | 50-250 | Excess recompute churn | Typing feels laggy |
| `virtualization_enable_threshold` | int cards | 80 | 40-200 | Overhead on small lists | Large lists stutter |
| `W_tag` | float | 1.0 | 0.5-2.0 | Tag links under-valued | Overstates weak links |
| `W_trigger` | float | 1.25 | 0.5-2.5 | Recent interactions underemphasized | Recency bias noise |
| `W_lifecycle` | float | 0.75 | 0.25-1.5 | Lifecycle patterns hidden | Misleading lifecycle emphasis |
| `show_raw_payload_default` | bool | false | false/true | Less expert transparency | Overwhelming info density |

Governance:
- Knob changes must preserve deterministic ordering and hidden-information safety.
- Out-of-range changes require browser perf and readability validation.

## Visual/Audio Requirements

Visual requirements:
- Deterministic card row visuals for state badges: retained, temp, generated, in-limbo, passive-linked.
- Zone summary bars/chips with numeric counts.
- Derived badge tooltips with formula/source drilldown.
- Context badge (Run/Hub) always visible.
- Reconciliation/stale-state indicators non-modal but persistent while active.
- Skeleton/loading placeholders during AwaitSnapshot.

Audio requirements (minimal MVP):
- Optional subtle open/close panel cues.
- Optional soft cue for selection changes and filter-apply.
- No rapid-fire per-event audio spam from runtime updates.

## UI Requirements

1) Fast deck readability
- User can identify deck size, zone distribution, and cost curve within one glance.

2) Deterministic inspect panel
- Selecting a card always shows stable section order and field names.

3) Filter/search usability
- Multi-filter combinations are supported and reversible.
- Active filter chips are always visible and clearable.

4) Relic/passive interaction visibility
- Card panel clearly shows linked relic/passive nodes and latest outcomes/reasons.

5) Run/hub context clarity
- UI labels unavailable data explicitly by context.

6) No hidden-info leakage
- Draw-order and private data never appear unless entitlement exists.

7) Keyboard/controller support
- Navigate cards, apply filters, open detail, and close panel without mouse.

8) Responsive browser layout
- On narrow viewports, detail panel collapses into overlay drawer while preserving key data.

## Acceptance Criteria

1) Deterministic rendering
- Same snapshot + same UI state yields identical visible order/values across supported browsers.

2) Filter/sort correctness
- Automated fixtures verify each filter and sort returns expected set/order with stable tie-breakers.

3) Contract alignment with Card Data
- 100% of published cards render inspect panel fields without missing required schema mappings.

4) Contract alignment with DLS
- Runtime zone and instance badges match DLS authoritative state in replay fixtures (0 mismatches).

5) Contract alignment with RPM
- Passive interaction panel reflects trigger attempts/outcomes and reason codes exactly from RPM event stream.

6) Hidden-info safety
- Security/content fixtures confirm no unauthorized draw-order/private payload leakage in release snapshots.

7) Explainability completeness
- All derived badges and disabled states expose formula or reason mapping; no “unknown reason” in release.

8) Performance
- With 200 visible cards and active filtering, list recompute p95 <= configured budget on target browsers.

9) State recovery
- Snapshot reconciliation recovers from version drift without crashes or silent stale displays.

10) Accessibility baseline
- Core inspection actions and state interpretation are usable via keyboard and non-color cues.

## Open Questions

1) In hub context, should DIUI include full locked-card catalog visibility or only owned/available cards?
2) Should synergy score be player-facing in MVP or advanced/debug toggle only?
3) Do we need pin/export deck notes in MVP, or defer to post-MVP planning tools?
4) Should run-mode inspection allow optional mini-timeline of card transitions beyond latest event only?
5) Do challenge modes require stricter “no derived recommendations” policy for competitive parity?