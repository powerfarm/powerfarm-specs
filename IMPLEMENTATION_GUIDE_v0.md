# Powerfarm Specifications Implementation Guide v0

**Status:** Draft operational guide  
**Applies to:** App Contract v0, Executability Contract v0, Registry Core v0  
**Role:** Procedural glue. This guide does not create a new architectural organ.

## 1. Purpose

This guide describes how a conforming Powerfarm implementation can make the v0 specifications real.

It turns:

```text
canon
  ↓
contracts / schemas
  ↓
materialized software
```

without turning any one current database, runtime, installer, or repository into permanent architecture.

The implementation rule is:

> Implement the specified semantics with the smallest reliable mechanism. Do not add a central subsystem when local state plus explicit contracts already solve the problem.

## 2. Implementation planes

A useful implementation model has three durable planes and one temporary working set:

```text
INSTITUTIONAL PLANE
Identity · Registry · Contracts · Grants
meaning / recognition / authority

CONTENT PLANE
Content Store
immutable values / references / verification / transport / cache

STATE PLANE
app-owned stores
mutable operational state

MODEL CONTEXT
temporary reasoning working set
```

Source control crosses these planes as the human-readable authoring and change-history layer.

Antenna, Heartime, and Continuity operate causally across the planes but do not merge them.

## 3. Required implementation capabilities

A minimal v0 implementation needs:

1. a contract parser and JSON Schema validator;
2. RFC 8785 canonicalization and SHA-256 digesting;
3. a Content Store resolver capable of verifying `ContentRef` values;
4. Registry operations for entities, artifacts, artifact versions, contracts, and grants;
5. an App Contract materializer that can create/verify placement and local stores;
6. an admission receipt producer;
7. an Executability Contract compiler or adapter into Continuity;
8. an atomic claim mechanism;
9. effect-certainty and verification handling;
10. conformance tests.

These capabilities MAY live in existing repositories and tools. Their existence does not imply ten new services.

## 4. Contract processing pipeline

Every v0 contract SHOULD pass through the same deterministic front door:

```text
authoring document
      ↓
parse YAML/JSON
      ↓
normalize to JSON data model
      ↓
JSON Schema validation
      ↓
semantic validation
      ↓
RFC 8785 canonicalization
      ↓
SHA-256
      ↓
contract digest
```

### 4.1 Structural versus semantic validation

Schema validation catches:

- missing required fields;
- invalid identifiers;
- malformed content references;
- invalid enums;
- unexpected object shape.

Semantic validation catches:

- referenced Registry entities that do not exist;
- a source revision that cannot be resolved;
- a Place that cannot host the requested materialization;
- two stores claiming incompatible paths;
- a contract generation lower than or conflicting with recognized history;
- missing subordinate contracts;
- a workflow ContentRef whose bytes do not match its digest;
- a predicate reference whose provider does not recognize it;
- an effect that lacks a required verification path.

Do not treat JSON Schema success as institutional admission.

## 5. Content Store resolver

### 5.1 Resolver contract

A v0 content resolver conceptually exposes:

```text
resolve(ContentRef, principal) -> verified bytes | denied | unavailable | corrupt
```

The resolver SHOULD:

1. check authorization before disclosing non-public content;
2. check a trusted local object cache;
3. check configured local stores;
4. fetch from an authorized remote source when necessary;
5. verify byte length;
6. calculate SHA-256;
7. compare it with the expected digest;
8. reject corrupt or mismatched bytes;
9. optionally cache the verified object;
10. return bytes or a bounded streaming reader.

Identity is location-independent. Resolution strategy is not.

### 5.2 Local digest compatibility

Existing implementations MAY use another digest internally.

For example, current Antenna uses BLAKE3 for its local content-addressed bucket. That is compatible with v0 if a Powerfarm `ContentRef` crossing the application boundary also has a verified SHA-256 identity.

A practical promotion path is:

```text
local BLAKE3 object
      ↓
promote / exchange
      ↓
compute SHA-256
      ↓
create ContentRef
      ↓
optionally record both digests locally
```

The v0 cross-system digest is SHA-256 so contracts, Registry versions, OCI-like descriptors, source snapshots, and supply-chain attestations share one interoperable identity form.

### 5.3 Do not inline by reflex

For large stable immutable content, prefer:

```text
small manifest + ContentRefs
```

over:

```text
copy the same bytes into every contract / prompt / model context
```

LLM context is a working set. It should resolve only what the current reasoning step needs.

## 6. App admission

### 6.1 Admission is recoverable workflow

Admission spans multiple authority and storage boundaries. It SHOULD be implemented as a recoverable workflow, not as an imaginary global transaction.

The reference flow is:

```text
1. validate App Contract
2. compute contract digest
3. verify exact source artifact/revision
4. reserve/resolve stable app entity identity
5. verify target Place
6. materialize application bytes
7. instantiate or verify declared local stores
8. apply/verify schemas and migrations
9. configure machine identity/auth relationship
10. materialize required subordinate contracts
11. verify runtime health where required
12. run admission checks
13. emit Admission Receipt
14. recognize App Contract generation
15. expose current derived topology
```

Step 4 may create a stable entity before final app admission. Entity existence alone MUST NOT be interpreted as active app membership or broad authority.

### 6.2 Staging

The materializer SHOULD stage mutable operations so interruption does not create ambiguous half-admission.

A practical local directory flow is:

```text
<park>/.staging/<contract-id>/<generation>/
      ↓ verify
atomic rename / controlled promotion
      ↓
<park>/<app-relative-path>/
```

This is an implementation pattern, not a required filesystem layout.

### 6.3 Existing application directory

If the target path already exists:

- identify whether it belongs to the same app;
- compare recognized source/materialization identity;
- inspect declared stores before mutating them;
- refuse silent takeover of unrecognized bytes;
- require an explicit upgrade or recovery path.

Physical occupancy is evidence, not authority.

## 7. Store materialization

### 7.1 SQLite default

For app-owned operational state, SQLite is the default when it satisfies the workload.

A SQLite materializer SHOULD normally configure:

- foreign keys enabled;
- WAL when compatible with the deployment and durability requirements;
- explicit busy timeout;
- a documented synchronous level appropriate to the consequence;
- schema migrations inside local transactions;
- backups/snapshots according to the App Contract.

These are implementation quality recommendations, not architectural identity.

### 7.2 Genesis versus living state

On first materialization:

```text
create store
  ↓
apply schema/migrations
  ↓
verify schema identity
  ↓
record genesis evidence
```

Do not keep recalculating a whole-file digest and calling that the store identity.

If an immutable snapshot is required:

```text
checkpoint app-owned store
  ↓
produce stable snapshot bytes
  ↓
Content Store
  ↓
ContentRef
```

The live database continues evolving.

### 7.3 Migration

An App Contract generation that changes persistent state MUST have migration analysis before active recognition.

A safe migration sequence is:

```text
verify current recognized generation
  ↓
backup / snapshot when consequence warrants
  ↓
begin local migration
  ↓
apply deterministic migration set
  ↓
verify schema identity + invariants
  ↓
commit local state
  ↓
continue admission proof
```

A failed local migration SHOULD leave the prior recognized app materialization recoverable.

## 8. Authentication and grants

The app's machine principal is configured through Identity.

Do not put runtime credentials inside App Contracts or Registry contract bytes.

A practical flow is:

```text
App Contract principal
   ↓
Identity implementation
   ↓
client/key/workload binding
   ↓
Registry grants
   ↓
credential permits actions consistent with grants
```

Grant decisions and OAuth token issuance MAY be implemented in the same service. Their persistent concepts remain distinct.

OAuth 2.1 is still a moving IETF draft in 2026. Pin actual protocol behavior and related RFCs in the Identity implementation rather than storing the phrase `OAuth 2.1` as if it were a fully stable wire version.

## 9. Subordinate service relationships

### 9.1 Antenna

If an App Contract requires an Antenna relationship:

1. resolve the referenced Antenna Contract generation;
2. verify its exact terms digest;
3. verify provider and consumer entities;
4. materialize routes/limits/authority needed by the implementation;
5. test the declared service boundary;
6. include evidence in the Admission Receipt.

Antenna's own operational receipts remain in Antenna-owned state.

### 9.2 Heartime

If an app requires temporal semantics:

1. resolve the Heartime relationship contract;
2. materialize durable temporal predicates/obligations in Heartime-owned state;
3. verify recurrence/window/deadline identity;
4. ensure occurrence identity survives Heartime restart;
5. include relationship proof in admission evidence.

The app does not need a Heartime relationship merely to satisfy a form. No temporal semantics means no temporal contract.

### 9.3 Search

Search relationships MAY be materialized after authoritative store declarations exist.

Search discovery SHOULD derive from recognized App Contracts. Search authorization SHOULD still flow through Identity/contracts/grants and MUST NOT be inferred from `searchable: true` alone.

## 10. Admission Receipt

An Admission Receipt is written after materialization checks and before final active recognition.

A receipt SHOULD be immutable after emission.

Example flow:

```text
materialization state
     ↓
checks
     ↓
AdmissionReceipt JSON
     ↓
canonicalize + digest
     ↓
Content Store
     ↓
Registry contract recognition references receipt digest
```

A failed or partial receipt MAY also be preserved when useful for recovery or learning.

Final recognition policy decides which outcomes are acceptable.

## 11. Registry recognition transaction

Where the Registry is PostgreSQL, active recognition of a new contract generation and supersession of the previous current generation SHOULD be done in one local database transaction.

Conceptually:

```sql
BEGIN;

-- verify no conflicting current generation / lock relationship
-- insert new exact generation
-- mark previous generation superseded
-- record admission receipt reference

COMMIT;
```

The exact SQL MAY differ.

PostgreSQL unique constraints and `INSERT ... ON CONFLICT` can provide useful atomicity for idempotent recognition, but the semantic key must be chosen correctly. Do not use upsert as a substitute for thinking about immutable generation history.

## 12. Executability compilation

A conforming Continuity compiler SHOULD perform this sequence:

```text
1. load recognized Executability Contract generation
2. verify contract digest
3. resolve T and O predicate relationships
4. resolve policy terms
5. resolve workflow graph bytes
6. validate Open Workflow syntax
7. validate graph semantics
8. resolve every capability to a machine contract/profile
9. resolve authorization and placement
10. resolve verification requirements
11. compile immutable ExecutionBundle
12. store bundle in Content Store
13. hand bundle to durable runtime
```

Compilation SHOULD fail before execution if required capability, authority, schema, placement, or verification information cannot be resolved.

Fail early on missing semantics rather than discovering them after a side effect has begun.

## 13. Predicate evaluation path

Antenna and Heartime own their evidence. Continuity does not need direct shared-database access to both.

A conforming integration may use durable messages, runtime signals, explicit query capabilities, or another mechanism to present predicate results to the contract evaluator.

The semantic interface is roughly:

```text
PredicateResult
  contract
  generation
  predicate
  state = true | false | unknown
  scopeKey
  evidence refs
  evaluatedAt
```

Implementation transport is replaceable.

### 13.1 Missing evidence

Do not turn `no fresh heartbeat` into `app is dead` unless the relevant predicate contract defines that inference.

The raw situation may be:

```text
heartbeat freshness predicate = false
census result = unknown
```

A projection such as Coloured Places may combine them into an operator-facing state while preserving provenance.

## 14. Trigger and claim implementation

### 14.1 Activation id

The policy evaluator MUST produce a stable activation id before claim.

Examples:

- webhook: Antenna receipt id;
- cron/census: Heartime occurrence id;
- correlated meet: deterministic id derived from the contract generation and policy-selected evidence identities.

### 14.2 Atomic uniqueness key

For exclusive execution, the durable uniqueness key is conceptually:

```text
(contract_id, contract_generation, activation_id)
```

A runtime attempt id MUST NOT replace this logical key.

### 14.3 Current Continuity

The current Continuity implementation delegates durable execution to Temporal. Temporal is a suitable place to implement claim/run recovery if its workflow identity and signal/timer model preserve the v0 activation semantics.

Temporal is not canon. A replacement runtime is conforming if it preserves the same observable semantics.

## 15. Transactional outbox

When a local state change must cause an external message/effect, prefer:

```text
BEGIN
  mutate local state
  insert outbox intent with stable logical id
COMMIT

relay outbox
retry delivery
consumer deduplicates by logical id
```

This avoids requiring distributed two-phase commit.

The outbox relay MAY publish more than once after crash. Consumers therefore SHOULD be idempotent or otherwise capable of deduplicating the logical operation.

The current Antenna design already follows this general discipline for durable receipts and deliveries.

## 16. Effect certainty

Continuity and adapters should preserve these distinctions when meaningful:

```text
dispatched
acknowledged
observed
verified
uncertain
```

Do not translate HTTP 200 into `verified` unless the capability contract explicitly defines the HTTP transaction itself as the desired effect and no stronger world-state verification is required.

### 16.1 Crash windows

Test at least these crash windows:

```text
before claim persistence
after claim, before dispatch
after dispatch, before acknowledgement persisted
after acknowledgement, before verification
after verification evidence, before terminal state persisted
```

Recovery must not invent certainty or duplicate irreversible effects.

## 17. OPA / policy engines

A policy engine such as OPA may evaluate authorization or semantic policy, but policy decision and enforcement remain distinct.

A conforming integration SHOULD preserve:

- input used for the decision;
- policy/bundle identity;
- decision id when available;
- resulting allow/deny/structured decision;
- enforcement point outcome when consequence warrants.

If the policy engine is unavailable, fail-open versus fail-closed behavior must be an explicit implementation decision appropriate to the boundary. It must not be accidental.

## 18. Search implementation

A reference Search discovery cycle is:

```text
query intent
   ↓
Registry current App Contracts
   ↓
resolve and verify contract docs
   ↓
match authoritativeFor scopes
   ↓
filter by searchable declarations + grants
   ↓
resolve store access surfaces
   ↓
fan-out read queries
   ↓
normalize results
   ↓
attach provenance
```

Search SHOULD return enough provenance to identify:

- source app;
- store id;
- record reference or query surface;
- relevant authority scope;
- observation / update time where available;
- contract generation used for discovery.

Search result ranking or synthesis must not erase source provenance.

## 19. Coloured Places implementation

Coloured Places is a projection. It may combine:

```text
Registry      expected population
Antenna       spontaneous observations / heartbeat
Heartime      census due / temporal obligation status
Continuity    census execution + verification receipts
```

A displayed state such as `Healthy` SHOULD be explainable by its inputs.

Useful discrepancies include:

```text
expected + observed
expected + not observed
observed + not expected
stale
unknown
```

A signal from an unrecognized entity is observational evidence, not permission to create Registry identity automatically.

## 20. Upgrade

App upgrades SHOULD be contract-generation transitions, not mutable configuration edits hidden from the Registry.

Reference sequence:

```text
new App Contract generation
  ↓
validate / diff against current
  ↓
classify state migration + relationship changes
  ↓
materialize new source
  ↓
migrate/verify local stores
  ↓
materialize changed relationships
  ↓
health + admission proof
  ↓
recognize new generation + supersede old
  ↓
retire old runtime bytes when safe
```

If admission fails, the current recognized generation should remain authoritative unless an explicit rollback/incident decision says otherwise.

## 21. Retirement

Reference retirement sequence:

```text
stop new activations
  ↓
finish / cancel / reconcile in-flight work
  ↓
revoke or expire authority as required
  ↓
preserve snapshots/evidence required by policy
  ↓
disconnect service relationships
  ↓
retire Registry contract generation
  ↓
remove physical bytes when safe
```

Historical evidence and content may remain addressable after live retirement.

## 22. Current Powerfarm mapping

This section is informative and expected to change faster than the specs.

### Identity / Registry

Current implementation: Supabase/PostgreSQL in `powerfarm-identity`.

Target responsibility:

```text
shared institutional truth
entities / artifacts / artifact versions / contracts / grants
+
separate Identity protocol infrastructure
```

### Antenna

Current implementation: Rust, SQLite durable record, content-addressed object bucket, durable receipt-before-acknowledge boundary.

Target responsibility: observational evidence and Antenna service relationships.

### Heartime

Current repository exists but implementation is intentionally not yet established.

Target responsibility: durable temporal evidence and temporal predicate evaluation.

### Continuity

Current v2 implementation already follows the target direction:

```text
Open Workflow plan
+
Capability Profiles
  ↓
resolver/compiler
  ↓
immutable ExecutionBundle
  ↓
Temporal / OPA / NATS / MCP / WoT / OpenAPI adapters
  ↓
effect journal + verification
```

The spec should tighten this implementation, not force a rewrite for naming purity.

### Applications

Default: app-owned SQLite unless another store is materially justified.

### Content Store

No new Powerfarm organ is required. Existing local content-addressed stores and future remote backends can conform behind the `ContentRef`/resolver semantics.

## 23. Registry strangler migration

Do not start with destructive SQL.

### 23.1 Classify current tables

Classify each current table as:

```text
Registry Core
Identity infrastructure
Continuity/runtime state
application-owned state
derived projection
historical-only
obsolete
```

### 23.2 Introduce target path first

Implement:

1. Registry Core contract recognition;
2. App Contract validation/admission;
3. general contracts replacing special-case service-contract authority;
4. target readers.

Only then remove legacy writers/readers.

### 23.3 Preserve history

Before dropping old runtime or service-contract tables:

- identify live callers;
- export data needed for history;
- preserve exact migrations;
- create explicit mapping or archive notes;
- prove no remaining authority depends on the old shape.

## 24. Conformance automation

The first conformance harness SHOULD validate:

- all JSON Schemas are valid Draft 2020-12;
- all examples validate structurally;
- contract digests are deterministic after YAML→JSON normalization;
- invalid path traversal is rejected;
- duplicate contract generation recognition is idempotent or rejected safely;
- App Contract admission cannot become active without required checks;
- content digest mismatch fails closed;
- Executability activation replay does not duplicate exclusive claims;
- crash/uncertainty cases preserve effect certainty;
- Registry reference SQL installs in an isolated PostgreSQL test database where available.

A future `powerfarm` CLI command MAY expose these checks. Do not build a separate validator service merely because validation exists.

## 25. Implementation order

Implement in this order unless evidence justifies otherwise:

```text
1. schemas + examples + conformance parser
2. Registry Core contract/artifact path
3. App Contract materializer + Admission Receipt
4. Executability Contract adapter/compiler
5. Heartime minimal predicate store only when an actual temporal contract needs it
6. Search discovery from recognized App Contracts
7. legacy Registry reduction
```

This order follows PF-03's architecture freeze rule.

## 26. Engineering standard

All implementation code inherits PF-04.

In particular:

- semantics SHOULD rise into contracts, graphs, and schemas where faithful;
- traditional code remains the executable substrate;
- production languages use adopted Language Profiles;
- English is the institutional technical language;
- direct main pushes are exceptional;
- material agent-authored changes receive the same verification bar as human-authored changes;
- machines enforce mechanical quality while review focuses on semantics and risk.

Do not duplicate the PF-04 code standard in this repository. Reference it.

## 27. Final implementation test

Before adding a new table, queue, daemon, database, service, or contract family, ask:

> Which existing specified responsibility cannot represent this correctly?

If the answer is unclear, do not add the subsystem yet.
