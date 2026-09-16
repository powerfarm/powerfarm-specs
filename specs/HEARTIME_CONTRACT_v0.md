# Heartime Contract v0

**Status:** Draft operational specification  
**Specification:** `HeartimeContract`  
**API version:** `powerfarm.specs/v0`  
**Canonical basis:** PF-03 §3.10 Heartime, §3.13 census, §3.14 distributed consistency, Appendix A; PF-04 representation doctrine

## 1. Boundary and liveness

Heartime owns temporal obligations and temporal evidence. It does not decide work, execute graphs, observe the world, reconcile outcomes, copy Registry, manage tasks, or notify humans. Different obligations have different deadlines; there is no institutional tick or mandatory period length.

Its liveness invariant is:

> Every active durable responsibility MUST be terminal, currently owed a return with a durable review deadline, or associated with a durable future temporal evaluation.

**Executing is not an unlimited exemption:** a delivered occurrence's return deadline MUST already exist when it is delivered. Paused, blocked, uncertain and suspended responsibilities keep a finite review deadline until explicitly retired. A due but unprocessed evaluation is overdue, not evidence of current coverage. Heartime MUST expose overdue evaluations and any obligation without a future evaluation.

This is a protocol guarantee under stated storage and availability assumptions, not a claim that stopped hardware continues to evaluate time. An independent deployment watchdog is necessary to detect the complete loss of Heartime. Heartime cannot certify its own availability.

## 2. Objects and identity

A HeartimeContract has the common metadata `id`, `generation`, `subject`, `owner`. Its `spec` declares one TemporalObligation of an existing responsibility represented by a contract reference. No Responsibility entity type is introduced.

A TemporalPredicate asks whether a nominal instant is due under available clock evidence. The v0 executable profile supports UTC-anchored fixed-second recurrence, including a one-shot when `everySeconds = 0`. Civil calendar recurrence and restart-spanning hold predicates require a later explicit profile; they MUST NOT be approximated silently as seconds. `graceSeconds` bounds lateness, not authorization.

An **Occurrence** is one logical temporal satisfaction, independent of delivery attempts and execution claims. Its identity is:

```text
sha256(RFC8785([contractId, generation, obligationId, kind, nominalUTC]))
```

`nominalUTC` uses RFC 3339 UTC whole seconds; input timestamps MUST use that profile. The same nominal occurrence after a restart has the same identity. Occurrence kinds are:

| Kind | Meaning |
|---|---|
| `work` | a recurrence instant is due for the handoff relationship |
| `planning-review` | the following period must be prepared before coverage ends |
| `fallback` | coverage ended without a renewal |
| `return-review/<parent occurrence id>` | an unresolved occurrence reached its return deadline or reported failure or uncertainty |

A return review's kind embeds its parent so simultaneous deadlines of different parents never share an identity.

**TemporalEvidence** contains the occurrence identity, contract reference and digest, responsibility reference, kind, nominal instant, covered interval and count, predicate and result, disposition, evaluation instant, clock source, handoff reference and, for return reviews, the parent. Evaluation earlier than evidence already persisted MUST fail explicitly and MUST NOT move any cursor backwards. Wall clock determines civil due-ness; process monotonic timers may optimize waiting only. The implementation is not a trusted time oracle and records whether an instant came from the system clock or was supplied by an operator.

An occurrence has exactly one current **disposition**:

| Disposition | Meaning | Owes a return |
|---|---|---|
| `pending` | due; delivery not yet acknowledged | yes |
| `acknowledged` | delivery acknowledged; effect unknown | yes |
| `failed` | downstream reported failure; effects may remain | yes |
| `uncertain` | downstream cannot establish what happened | yes |
| `verified` | downstream reported independently verified success | no |
| `contained` | failure effects were independently reconciled or bounded; not success | no |
| `skipped` | due outside grace, coverage or expiry; recorded, never delivered | no |
| `coalesced` | never delivered; folded into a newer occurrence | no |
| `superseded` | never delivered when a newer generation was installed | no |
| `lapsed` | never delivered when coverage ended, the contract expired, the obligation retired, or, for a return review, its parent was resolved | no |

Dispositions that owe a return keep a durable review deadline.

## 3. Contract representation

See `schemas/heartime-contract-v0.schema.json`. Required terms are obligation and responsibility identity, anchored recurrence, catch-up, overlap, grace, return review interval, executable relationship, fallback and planning coverage. Contract digest follows the repository RFC 8785/SHA-256 rule.

`handoff` references an existing ExecutabilityContract generation. Heartime emits temporal evidence plus this relationship reference. The receiving evaluator resolves its graph and current authority, combines temporal and observational guards, applies policy, and acquires the execution claim. **Temporal evidence is never a grant.**

Resolution MUST bind exact bytes to recognized terms. Importing a local document is only a trusted-operator cache operation, not Registry admission. An implementation without authenticated Registry resolution MUST label that limitation and MUST NOT advertise autonomous institutional admission.

## 4. Missed time and expiration

- `all`: materialize every nominal instant. `maxBatch` limits one evaluation transaction; the cursor remains at the first unprocessed instant and that instant is immediately due again. Debt is never truncated silently.
- `latest`: materialize one occurrence at the latest missed instant, recording the covered interval and count.
- `skip`: record the earlier missed instants as one `skipped` occurrence covering them, and deliver the latest instant only when it is within grace; otherwise record it as `skipped`.

`expiresAt` ends the obligation defined by these terms. At and after expiry, work and planning evaluations stop, never-delivered `work`, `planning-review` and `fallback` occurrences become `lapsed`, and the expiry is recorded as evidence. Expiration MUST NOT erase occurrences or cancel return reviews owed by delivered occurrences.

A pause defers work; it is not missed time. After a pause, instants follow the original anchor and the contracted catch-up policy.

## 5. Overlap and authority

`overlap` declares `allow`, `defer`, or `coalesce`. Heartime gates *delivery* of work from trusted execution feedback. It does not own an execution lease. Missing feedback is unresolved, never a completed effect.

- `defer`: work is not delivered while delivered work of the same contract, of any generation, remains unresolved.
- `coalesce`: as `defer`; in addition only the newest never-delivered work occurrence is delivered, and older never-delivered ones become `coalesced`. Already delivered work is never cancelled by Heartime.
- `allow`: delivery proceeds; the executable relationship still enforces resource and concurrency bounds.

Overlap admits an occurrence at its first delivery attempt. A retry of possibly delivered work MUST remain possible; otherwise it could deadlock against newer work that its own unresolved state defers. The admission verifier MUST check agreement between this policy and the executable relationship. Cross-occurrence concurrency is distinct from exclusive claim per activation.

## 6. Publication, return, and recovery

A single local atomic transaction MUST persist the occurrence, its temporal evidence, its return deadline, its delivery intent and every advanced cursor or deadline before any delivery. An outbox MAY publish more than once. **Receivers MUST deduplicate by occurrence identity before claiming effects.**

A delivery attempt MUST be recorded before network publication. A crash after send and before acknowledgement leaves the occurrence possibly delivered. Acknowledgement proves delivery only. Completion requires authenticated, occurrence-bound downstream feedback carrying an immutable evidence reference. **Transport success MUST NOT set `verified`.**

The return deadline is armed when the occurrence is materialized, not upon response. When it passes for an occurrence that owes a return, Heartime emits a return review referencing the parent through the fallback relationship and arms the next deadline; it never re-executes the parent. While a return review of a parent has not had its first delivery attempt, later deadlines of that parent MUST NOT add further reviews, so an unreachable receiver cannot grow the ledger without bound. A return review never delivered becomes `lapsed` once its parent is resolved. Return reviews are covered by their parent's deadline and do not themselves produce return reviews.

Feedback outcomes are `verified`, `failed`, `uncertain` and `contained`. Feedback on a never-delivered occurrence MUST be refused. `failed` and `uncertain` make the parent's return review due at once, invoking the predeclared fallback relationship. `verified` and `contained` are final: replaying identical feedback is idempotent, conflicting feedback MUST be refused and requires reconciliation outside Heartime. Heartime MUST NOT interpret free-text results as instructions.

## 7. Pause, retirement, and supersession

Pause requires a finite resume instant and a reason. It suppresses work delivery, not planning evaluation, fallback or return reviews. Resume requires a reason. Only explicit, authorized retirement ends future work and planning evaluation; never-delivered `work`, `planning-review` and `fallback` occurrences then become `lapsed`, and return reviews owed by delivered occurrences continue.

A new generation preserves old contract bytes, occurrences, delivery records and reported evidence. Never-delivered `work`, `planning-review` and `fallback` occurrences of older generations become `superseded` with evidence naming the successor. Return reviews and delivered occurrences of older generations keep their original terms and remain unresolved until reported. Installing a new generation MUST disable the old recurrence and establish the new future evaluations in the same transaction.

## 8. Planning continuity and fallback

`planning` identifies `planValidThrough`, `nextPlanningReviewAt`, `reviewEverySeconds`, and a planning ExecutabilityContract. The initial review MUST lie within coverage. While coverage lasts, each planning evaluation arms the next one no later than the end of coverage, so expiry of coverage is always observed. A period is an instance, never a week primitive.

A successful planning return references an immutable plan and supplies the new coverage and next review. New coverage MUST extend the existing coverage, and the next review MUST lie strictly between acceptance and the new end of coverage. The update and the next planning evaluation MUST commit atomically. A Card expiring, a model exiting, or a run succeeding cannot renew a plan.

When coverage ends without renewal:

- never-delivered work and planning reviews become `lapsed`, and work falling due outside coverage is recorded as `skipped`;
- a planning review whose instant was missed while Heartime was not evaluating is recorded as `skipped`, because the fallback now carries that obligation;
- a `fallback` occurrence, dated at the end of coverage, is emitted through the fallback relationship and re-emitted every `fallback.reviewAfterSeconds` until renewal, supersession, expiry or retirement.

An unsuccessful or uncertain planning return invokes the fallback relationship at once through its return review. Supported fallback meanings are `continue_previous` only within preauthorized validity, `reduce_scope`, `retry_at`, `alternate_planner`, `safe_mode`, and `suspend`. Each has a finite `reviewAfterSeconds` and an executable relationship. Heartime emits the temporal condition; the downstream policy enforces its meaning and authority. **No implicit "ask the owner" fallback exists.** Failed planning never extends coverage.

## 9. Census and attention

Continuity binds each census to an immutable expected-cohort manifest from an authorized Registry read. The manifest records extraction time, source revision or snapshot, and coverage limitations. A cohort frozen at execution start is labelled as such; it is not falsely dated to the nominal timer instant. Discovering unknown presence requires authorized place inventory, not only querying the roster.

The sweep produces observations; Antenna records them. A separately authorized reconciliation capability compares cohort and observations. Unrecognized is not prohibited. Inconclusive coverage is not absence. Detection grants no repair authority. Heartime only keeps the census temporally covered.

## 10. Minimum observable interface

An implementation MUST expose contracts and cache provenance; occurrences with dispositions and evidence; delivery attempts and acknowledgements; reported execution certainty and evidence digests; planning coverage; and the durable future evaluations with overdue marking.

After any restart, from durable state alone, it MUST answer:

1. what was due;
2. what was emitted;
3. what may have executed (delivered and still owing a return);
4. what remains unresolved;
5. what must happen next, and whether any active obligation or unresolved occurrence lacks a future evaluation.

Reference local commands are `import`, `evaluate`, `account`, `status`, `pending`, `attempt`, `ack`, `report`, `renew`, `pause`, `resume`, `retire` and `serve`. Network exposure requires authentication separately; these names do not require an HTTP service.

## 11. Compatibility and conformance

This is an additive subordinate contract. Existing AppContract relationship `heartime` and Executability predicate references remain valid. The one-minute census example is illustrative, not a global cadence. The reference profile does not add parameters to existing recognized generations.

Conformance cases `HEART-001` through `HEART-009` cover planning rollover and fallback, kill and restart, catch-up, overlap, acknowledgement versus verification, pause and supersession, the restart account, and bounded return reviews with lapsing obligations.
