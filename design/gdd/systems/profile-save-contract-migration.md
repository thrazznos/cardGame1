# Profile Save Contract Migration Notes (Dependent Systems)

> Status: Draft for QA
> Last Updated: 2026-04-05
> Scope: Replace provisional profile-save assumptions in UOG, MHIS, and Hub UI docs
> Canonical Source: design/gdd/systems/profile-progression-save.md

## Purpose

QA-focused migration checklist for replacing provisional persistence assumptions in:
- design/gdd/systems/unlock-option-gating.md
- design/gdd/systems/meta-hub-investment.md
- design/gdd/systems/hub-ui.md

Primary risk coverage:
- offline/reconnect
- duplicate submits
- rollback/tamper
- partial writes
- multi-device races

## Canonical Contract Delta

Dependent docs must align to PPS canonical contract language.

1) Canonical read
- `GetProfileProgressSnapshot(profile_id) -> ProfileProgressSnapshot`
- Required snapshot fields for dependents:
  - `schema_version`
  - `commit_seq`
  - `unlock_flags`
  - `unlock_counters`
  - `hub_currency_balances`
  - `hub_investments_owned`
  - `hub_reward_bias_profile`
  - `read_only_fallback`
  - `fallback_reason_code`
  - `integrity_hash` (optional MVP, required post-MVP)

2) Canonical write
- `ApplyProfileEvents(profile_id, events[], expected_base_seq|null) -> ApplyEventsResult`
- `event_id` is idempotency key.
- `expected_base_seq` handles optimistic concurrency.
- Result must classify:
  - `applied_event_ids[]`
  - `duplicate_event_ids[]`
  - `rejected_event_ids[]`
  - `reason_codes[]` (including `ERR_EXPECTED_SEQ_CONFLICT` and payload mismatch codes)

3) Canonical reconciliation
- `GetEventCommitStatus(profile_id, event_id)` for lost-ack and reconnect recovery.
- Commit-order authority token is `commit_seq`.

4) Integrity/tamper policy
- Snapshot integrity is verifiable.
- Integrity failure triggers read-only fallback path.
- Local cached data is never write authority.

5) Atomicity policy
- Commit is all-or-nothing across affected fields.
- Crash/fault recovery yields pre-state or post-state only.

## Edge Cases (QA Matrix)

1) Offline before submit
- Expected: no authority write; client enters explicit read-only/offline mode.

2) Offline after submit, before ack
- Expected: pending_unknown until resolved via `GetEventCommitStatus(event_id)` or authoritative snapshot + `commit_seq`.

3) Duplicate submit same `event_id`
- Expected: one apply only; later deliveries classified duplicate, no extra mutation.

4) Duplicate submit different `event_id` for same logical intent
- Expected: deterministic business-rule reject when state already changed; no double-spend.

5) Stale `expected_base_seq`
- Expected: `ERR_EXPECTED_SEQ_CONFLICT`; caller reloads and rebases.

6) Multi-device simultaneous write
- Expected: one ordered commit first; other rebases from newer `commit_seq`.

7) Multi-device opposite spends with shared currency
- Expected: deterministic winner by commit order; loser rejected or conflicted; never negative balance.

8) Partial write crash simulation
- Expected: never observe mixed currency/ownership/unlock state.

9) Rollback replay attempt
- Expected: stale-seq conflict; older state cannot overwrite newer commit.

10) Tampered local cache payload
- Expected: authority ignores client-mutated state claims; reject/integrity path only.

11) Tampered transport payload
- Expected: integrity/payload-hash mismatch reject; telemetry emitted.

12) Legacy snapshot missing fields
- Expected: migration/default fill to safe empty/zero values without crash.

13) Migration failure
- Expected: `read_only_fallback=true`, writes blocked, baseline gameplay intact.

14) Reconnect unresolved beyond timeout
- Expected: non-destructive manual reconcile/retry path; never local authoritative commit.

15) Event status lookup beyond retention
- Expected: unknown status documented; resolve via authoritative latest snapshot.

## Acceptance Criteria (Cross-Doc)

AC-1 Idempotency
- Any `event_id` mutates state at most once.

AC-2 Atomicity
- Fault injection never exposes partial commits.

AC-3 Offline safety
- Offline clients do not advance authoritative `commit_seq`.

AC-4 Reconnect determinism
- Pending unknown intents resolve deterministically via event-status and/or snapshot reconciliation.

AC-5 Concurrency correctness
- Stale `expected_base_seq` always yields `ERR_EXPECTED_SEQ_CONFLICT`, never silent overwrite.

AC-6 Multi-device race safety
- Concurrent writes never cause negative currency or duplicate ownership grants.

AC-7 Rollback resistance
- Older snapshot/seq cannot replace newer authoritative state.

AC-8 Tamper containment
- Integrity/payload mismatch routes to reject/read-only-safe behavior with telemetry.

AC-9 Migration compatibility
- Legacy schemas migrate with safe defaults and no runtime crash.

AC-10 Migration failure containment
- Failing migration enters read-only fallback and preserves core baseline accessibility.

AC-11 Consumer alignment
- UOG/MHIS/HUI use the same event_id, expected_base_seq, commit_seq, and fallback flag semantics.

AC-12 Telemetry coverage
- Conflict, duplicate, integrity failure, and read-only fallback paths all emit required counters.

## Migration Notes by Dependent Doc

1) unlock-option-gating.md
- Replace provisional read/write assumptions with PPS APIs.
- Add stale-seq, duplicate replay, partial-write, tamper, and multi-device race edge cases.
- Keep `base_set` fail-open fallback with PPS read-only signals.

2) meta-hub-investment.md
- Map `purchase_event_id` to canonical PPS `event_id`.
- Use `expected_commit_seq -> expected_base_seq` mapping for conflicts.
- Ensure lost-ack recovery and atomic purchase commit language is explicit.

3) hub-ui.md
- Reconcile pending intents via `event_id` status + authoritative `commit_seq`.
- Handle unresolved status with explicit non-destructive UX.
- Drive read-only fallback from `read_only_fallback` + `fallback_reason_code`.

## Definition of Done

1) Provisional assumption sections replaced in UOG/MHIS/HUI.
2) Each dependent doc includes edge cases for offline/reconnect, duplicates, rollback/tamper, partial writes, multi-device races.
3) Acceptance criteria in dependent docs include idempotency, atomicity, conflict handling, and fallback behavior.
4) Dependent docs reference PPS canonical contract (`profile-progression-save.md`) and this QA migration note.
