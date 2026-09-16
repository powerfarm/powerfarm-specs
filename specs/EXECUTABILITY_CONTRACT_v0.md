# Executability Contract v0

**Status:** Draft operational specification  
**Specification:** `ExecutabilityContract`  
**API version:** `powerfarm.specs/v0`  
**Canonical basis:** PF-03 Appendix A and §§3.9–3.14; PF-04 Representation Doctrine and Continuity graph semantics

## 1. Purpose

An Executability Contract defines when an authorized transition becomes eligible to occur, how semantic readiness becomes a trigger, how one execution acquires ownership, what executable graph represents the effect, and how effect certainty is established afterwards.

Its semantic core is:

```text
C = (T, O, pi, E, V)
```

where:

- `T` is a temporal predicate evaluated over temporal evidence;
- `O` is an observational predicate evaluated over observational evidence;
- `pi` is the semantic trigger policy;
- `E` is the executable graph representing the intended transition;
- `V` is the verification condition.

The contract does not require one global database and does not assume omniscient access to world state or perfect time.

## 2. Responsibility separation

The v0 contract preserves this separation:

| Operation | Primary responsibility |
|---|---|
| temporal evidence and `T` | Heartime |
| observational evidence and `O` | Antenna |
| readiness | predicate convergence |
| trigger semantics `pi` | contract policy |
| execution ownership | atomic claim mechanism |
| transition materialization `E` | Continuity |
| post-effect certainty `V` | verification over subsequent evidence |

Implementations MAY co-locate mechanisms. They MUST preserve the semantic boundaries.

## 3. No new workflow language

Powerfarm does not define a proprietary graph DSL in this specification.

The executable structure interpreted by Continuity MUST have graph semantics, but the graph SHOULD use an established workflow representation. v0 pins **Open Workflow Specification 1.0.3** as the default workflow syntax used by the reference Continuity profile.

A future specification generation MAY adopt a newer compatible version or another established representation after explicit compatibility analysis.

Graph semantics and graph storage are distinct:

```text
mandatory graph semantics
        !=
mandatory graph database
        !=
custom Powerfarm graph language
```

The graph MAY be serialized as JSON/YAML workflow source, compiled into another structure, stored as a CAS object, or materialized in memory. Nodes, edges, dependencies, causal order, conditions, capabilities, effects, and verification MUST remain inspectable.

## 4. Contract identity and generation

Each Executability Contract has:

- a stable contract id;
- a positive integer contract generation;
- one institutional subject;
- one owner.

Contract generation means **version of contract terms**. It is not the same thing as an execution attempt or trigger occurrence.

A material semantic change MUST create a new contract generation.

Examples include changing:

- a temporal or observational predicate;
- edge versus level behavior;
- evidence retention semantics;
- executable graph identity;
- claim exclusivity;
- retry or uncertainty semantics;
- verification conditions;
- expiration or cancellation behavior.

## 5. Evidence model

### 5.1 Evidence is local

Antenna and Heartime maintain evidence available to Powerfarm under explicit contracts. Evidence is not synonymous with truth about the complete world.

An evidence item SHOULD be addressable by a stable provider-scoped identifier and SHOULD carry enough provenance to reconstruct why it was accepted.

A useful conceptual envelope is:

```text
Evidence
  id
  provider
  domain          temporal | observational
  subject
  observed_at
  contract_ref
  content_ref?    exact bytes when material
  correlation?    optional provider/contract scope key
```

This envelope is conceptual in v0. Relationship-specific specifications MAY define a more precise wire representation.

### 5.2 Predicate evaluation is three-state operationally

PF-03 expresses `T` and `O` as boolean predicates for the formal readiness equation. Implementations MUST nevertheless distinguish operationally between:

```text
true      evidence satisfies the predicate
false     evidence establishes the predicate is not satisfied
unknown   available evidence is insufficient to establish true or false
```

Only `true` contributes a satisfied guard.

`unknown` MUST NOT be silently collapsed into an affirmative result. For readiness computation it behaves as not satisfied, while remaining distinguishable for diagnosis, freshness, uncertainty, and future evidence.

### 5.3 Scope and correlation

A temporal and observational result MUST NOT be combined merely because both are true if they concern different subjects or correlation scopes.

Predicate evaluators SHOULD produce or inherit a `scopeKey` identifying the logical subject or correlation domain to which the result applies.

Readiness exists only within one compatible scope.

For a contract scoped to a single app or object, the default `scopeKey` MAY be the contract subject.

## 6. Guard representation

The Executability Contract has exactly two foundational readiness guards:

```text
guards.temporal
  -> T

guards.observational
  -> O
```

Each guard is either:

1. a literal boolean for a degenerate case; or
2. a reference to a predicate owned by an evidence provider under a relationship contract.

Example:

```yaml
guards:
  temporal:
    literal: true
  observational:
    ref:
      provider: pf.antenna
      contract:
        id: pf.contract.antenna.example-webhook
        generation: 1
      predicate: receipt.arrived
      parameters:
        route: /hooks/example
```

The Executability Contract does not define the complete predicate language of Antenna or Heartime. It identifies which recognized predicate must be evaluated and with which parameters.

## 7. Readiness

For compatible scope `s`:

```text
Ready_c(s) = T_c(t_hat, s) AND O_c(w_hat, s)
```

Readiness is semantic state. It is not execution ownership.

Events, observations, timer occurrences, retries, census obligations, and other inputs update evidence. Evidence updates predicate evaluation. Predicate convergence creates readiness.

The important transition is entry into the admissible region:

```text
not ready
   ↓
ready
```

A conventional event is one way to update evidence, not the foundational primitive.

## 8. Policy `pi`

Readiness alone is insufficient to determine execution.

`spec.policy` defines how readiness becomes a trigger candidate.

v0 intentionally keeps the built-in policy surface small.

### 8.1 Trigger mode

`triggerMode` is one of:

- `edge`: trigger eligibility occurs on a transition from not-ready to ready;
- `level`: trigger eligibility may exist while readiness remains true, subject to explicit retrigger semantics.

`edge` is the default conceptual mode.

A level-triggered contract MUST define bounded retrigger behavior. A conforming implementation MUST NOT busy-loop merely because readiness remains true.

### 8.2 Retrigger policy

`retrigger` is one of:

- `never`: one successful trigger for the contract generation/scope prevents another;
- `after-terminal`: a new readiness activation may trigger after the previous activation reaches a terminal state;
- `per-evidence-change`: a new qualifying evidence change may create a new activation even if the same high-level predicate becomes true again.

The policy evaluator MUST derive distinct activations deterministically enough that replay of the same accepted evidence does not manufacture a second logical trigger.

### 8.3 Hold duration

`holdFor` MAY require readiness to remain satisfied for a duration before trigger eligibility.

The implementation MUST define hold duration over Heartime temporal evidence rather than process sleep alone if the hold must survive restart.

### 8.4 Evidence arrival order

The policy declares what to do when one guard becomes satisfied before the other:

```text
temporalBeforeObservation: retain | discard
observationBeforeTemporal: retain | discard
```

`retain` means the satisfied guard may remain eligible until invalidated by its provider, expiration, supersession, or another declared rule.

`discard` means a later meet requires a new qualifying change from that side.

Relationship-specific contracts MAY impose stronger freshness or expiration rules.

### 8.5 History

Policy may depend on relevant causal history `H_c`:

```text
TriggerCandidate_c = pi_c(Ready_c, H_c)
```

A policy decision SHOULD be reproducible from recognized contract terms and preserved evidence/history in proportion to consequence.

## 9. Activation identity

A **trigger activation** is one logical occurrence that may be claimed and executed.

This specification distinguishes:

```text
contract generation  -> immutable version of terms
activation            -> one logical trigger occurrence under those terms
attempt               -> one runtime attempt to materialize that activation
```

Every trigger activation MUST have a stable `activationId` within the contract generation.

The policy evaluator is responsible for deriving or accepting the activation identity.

The activation identity MUST be:

- stable across replay of the same accepted evidence;
- different for distinct intended trigger occurrences;
- available before atomic claim;
- included in execution and verification provenance.

Implementations MAY derive it from timer occurrence ids, Antenna receipt ids, correlation ids, deterministic hashes of evidence sets, or another contract-defined strategy.

## 10. Trigger

A trigger is a semantic assertion that one activation is eligible for execution.

A useful conceptual trigger contains:

```text
contract id
generation
activation id
scope key
policy identity
temporal predicate result ref
observational predicate result ref
causal history/evidence refs
created_at
```

Creating a trigger does not mean the effect has happened and does not grant exclusive ownership to one worker.

## 11. Atomic claim

Execution coordination begins after trigger semantics.

For an activation:

```text
Claim_c = AtomicAcquire(contract_id, generation, activation_id)
```

### 11.1 Uniqueness

Where `claim.mode = exclusive`, at most one live claim may authorize materialization of one activation at a time.

Multiple workers MAY observe the same trigger. Exactly one must win the atomic claim where exclusivity is required.

The required atomicity MAY be implemented by:

- a durable execution runtime;
- a database uniqueness constraint;
- compare-and-swap / conditional write;
- a lease service;
- another mechanism with equivalent observable semantics.

No specific claim technology is part of v0 identity.

### 11.2 Claim is not success

A claim asserts execution ownership. It does not assert dispatch, acknowledgement, world effect, or verification.

### 11.3 Lease and recovery

An implementation MAY use leases. Lease expiry does not by itself prove that a prior effect did not occur.

Before another worker re-materializes after ambiguous dispatch, the effect-certainty and retry rules MUST be consulted.

## 12. Effect `E`: executable graph

In v0, `E` is represented by an executable graph descriptor.

Example:

```yaml
effect:
  graph:
    standard: open-workflow/1.0.3
    content:
      digest: sha256:...
      mediaType: application/yaml
      size: 4812
  capabilityProfiles:
    - artifact:
        artifactId: pf.capability-profile.service-restart
        version: 2
```

The graph SHOULD remain small by referring to immutable content and recognized capability contracts rather than embedding every large object directly.

### 12.1 Content references

Workflow source, prompts, schemas, policy data, datasets, and capability definitions MAY be loaded by `ContentRef`.

This follows the Powerfarm rule:

> Context is a working set, not a warehouse.

### 12.2 Capability resolution

Executable graph nodes that invoke a capability MUST resolve that capability to an explicit machine contract before compilation or execution.

Current Continuity practice supports contracts such as:

- MCP;
- OpenAPI;
- AsyncAPI;
- W3C WoT;
- other explicitly profiled interfaces.

A capability MAY carry an effect-certainty class such as:

```text
observe
idempotent
reconcilable
at_most_once
irreversible
```

These classes are especially important after dispatch uncertainty.

## 13. ExecutionBundle

Before durable execution, Continuity SHOULD compile the recognized Executability Contract, executable graph, resolved capability profiles, policy context, placement, and verification requirements into an immutable `ExecutionBundle`.

The bundle SHOULD be content-addressed.

Conceptually:

```text
Executability Contract
+
workflow graph
+
resolved capabilities
+
authority / policy context
+
verification requirements
        ↓
Continuity compiler
        ↓
immutable ExecutionBundle
        ↓
durable runtime
```

The bundle is a material execution input. Registry recognition of a bundle, when required, is separate from its mere existence in the Content Store.

## 14. Idempotency

A retryable material effect SHOULD have a stable idempotency key tied to the logical activation/effect, not to an individual runtime attempt.

A new runtime attempt after crash MUST NOT receive a new logical effect identity merely because the process restarted.

Where an external protocol supports idempotency keys, Continuity or the adapter SHOULD propagate the stable logical key.

Idempotency is not equivalent to exactly-once execution. It is one technique for making duplicate delivery safe.

## 15. Effect certainty

A transport result is evidence about transport, not necessarily evidence that the intended world transition occurred.

Continuity SHOULD represent at least these certainty states where applicable:

```text
dispatched
acknowledged
observed
verified
uncertain
```

A mutating effect MUST NOT be considered semantically successful solely because dispatch returned successfully when the declared capability requires independent verification.

## 16. Retry semantics

`spec.retry` defines contract-level retry limits and timing. Capability-level effect certainty constrains whether a particular effect can actually be repeated.

A conforming implementation MUST NOT blindly retry:

- an `at_most_once` effect after ambiguous dispatch;
- an `irreversible` effect after ambiguous dispatch;
- a `reconcilable` effect until required observation/reconciliation has occurred.

An `idempotent` effect MAY normally be retried with the same idempotency key, subject to contract limits.

`observe` operations MAY normally be retried because they do not intentionally mutate the observed target.

## 17. Uncertain effects

If the runtime cannot establish whether a dispatched mutation occurred, the activation enters an explicit uncertain state.

The contract's uncertainty handling is one of:

- `verify-before-retry`;
- `safe-retry`;
- `do-not-retry`.

This contract-level setting MUST NOT weaken a stricter capability effect class.

For example, `safe-retry` cannot make an irreversible capability replayable.

## 18. Verification `V`

Verification determines what Powerfarm may assert after attempted materialization.

`spec.verification` defines whether verification is required and identifies the verification predicate.

Conceptually:

```text
Verified_c = V_c(w_hat_prime)
```

where `w_hat_prime` is observational evidence available after execution.

Verification SHOULD use evidence independent enough from the producer to meaningfully establish the intended effect.

Examples:

- after `service.restart`, observe `service.status.running == true`;
- after writing a file, verify expected digest at the destination;
- after a census graph, verify that probe results were durably recorded as observations;
- after an idempotent API mutation, read back the target resource state.

A successful transport acknowledgement MAY contribute evidence. It MUST NOT substitute for a stronger declared verification predicate.

## 19. Expiration

A contract MAY define an expiration guard.

If expiration becomes satisfied before claim, the activation MUST NOT be newly claimed unless policy explicitly defines a different behavior.

If expiration occurs after claim or dispatch, it does not erase already-caused effects. Continuity MUST complete, cancel, reconcile, or compensate according to the declared policy and actual effect certainty.

## 20. Cancellation

Cancellation is an explicit state transition, not deletion of history.

A cancellation request MUST NOT rewrite prior evidence, triggers, claims, or dispatch records.

Before claim, cancellation normally prevents materialization.

After claim, cancellation MAY be cooperative. If an external effect may already have happened, verification or compensation can still be necessary.

## 21. Supersession

When a new contract generation supersedes an older one:

- new activations SHOULD be derived only from the current generation after the effective boundary;
- accepted evidence history for the old generation MUST remain reconstructable where material;
- an in-flight activation from the old generation MUST follow the old generation's effect-certainty, retry, verification, and compensation terms unless an explicit migration decision states otherwise.

Supersession MUST NOT silently reinterpret old execution history under new policy.

## 22. Replay

Replaying accepted evidence is useful for reconstruction and recovery.

Replay MUST NOT create duplicate logical effects for an already claimed/terminal activation when the same evidence deterministically produces the same `activationId`.

This is a core reason to separate:

```text
evidence replay
trigger semantics
activation identity
claim uniqueness
effect attempts
```

## 23. Ordering

Powerfarm does not assume one global total order across Antenna, Heartime, external systems, and execution runtimes.

Implementations MAY use provider-local sequence numbers, timestamps, causal links, correlation ids, and runtime histories.

A contract whose semantics require ordering MUST identify the ordering source or relationship explicitly.

Civil time and monotonic execution time are different concerns. Heartime implementations SHOULD preserve the distinction when clock adjustments or long-running holds matter.

## 24. Lifecycle state machine

A conceptual activation lifecycle is:

```text
dormant
   ↓
armed
   ├── waiting_temporal
   ├── waiting_observation
   └── waiting_both
             ↓
           ready
             ↓
          trigger
             ↓
        atomic claim
             ↓
          claimed
             ↓
         executing
       /     |        \
    done   failed    uncertain
             ↓
       retry / reconcile / compensate
```

Expiration, cancellation, and supersession may terminate or redirect the lifecycle.

The exact runtime state names MAY differ. The semantic distinctions MUST remain observable.

## 25. Degenerate cases

### 25.1 Webhook

```text
T = true
O = accepted arrival
```

Each distinct accepted arrival may produce a distinct activation. Replaying the same receipt must not duplicate the activation.

### 25.2 Cron-like execution

```text
T = scheduled occurrence due
O = true
```

Each durable temporal occurrence provides a distinct activation identity.

### 25.3 Census

```text
T = census obligation due
O = true
E = graph that asks Registry for expected population and probes it
V = observational evidence that census results were durably recorded
```

Heartime establishes that observation is due. Continuity performs the observation. Antenna records what was observed.

### 25.4 Retry

```text
T = retry_at reached
O = prior effect remains unverified
```

The retry activation must still obey effect-certainty rules.

### 25.5 Physical class

```text
T = 07:00 <= local temporal evidence <= 08:00
O = teacher_present AND students_present AND room_ready
```

The class becomes ready only when both predicates are true for the same relevant scope. Policy determines whether that readiness produces a trigger.

## 26. Machine-readable model

The v0 schema is `schemas/executability-contract-v0.schema.json`.

The schema validates structure. It cannot by itself prove:

- that predicate references exist;
- that Antenna or Heartime evaluated them correctly;
- that scope keys are compatible;
- that policy history is deterministic;
- that the workflow graph is semantically valid;
- that claims are actually atomic;
- that capability effects are correctly classified;
- that verification is independent enough to establish certainty.

Those are semantic conformance requirements.

## 27. Conformance

A conforming v0 implementation MUST demonstrate at least:

- temporal and observational guards remain distinct;
- missing evidence can remain `unknown` rather than becoming false truth by accident;
- readiness does not itself confer execution ownership;
- replay of the same evidence does not create duplicate activation identity;
- exclusive claim is atomic for one activation;
- a crash between claim, dispatch, acknowledgement, and verification is recoverable without inventing certainty;
- idempotency keys survive attempt restart;
- reconcilable, at-most-once, and irreversible effects are not blindly replayed;
- transport acknowledgement is distinguishable from verification;
- cancellation and expiration preserve history;
- contract supersession does not reinterpret old activations;
- executable structure has graph semantics and resolves explicit capabilities.

The repository conformance cases provide the initial behavioral suite.

## 28. Examples

See:

- `examples/executability.webhook.yaml`;
- `examples/executability.census.yaml`;
- `examples/executability.retry.yaml`.
