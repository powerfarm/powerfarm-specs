# App Contract v0

**Status:** Draft operational specification  
**Specification:** `AppContract`  
**API version:** `powerfarm.specs/v0`  
**Canonical basis:** PF-03 §§3.3–3.8, 3.12–3.16; PF-04 Representation Doctrine

## 1. Purpose

An App Contract is the root institutional contract for one Powerfarm application materialization.

It answers:

> What application is Powerfarm being asked to recognize, which exact software is being materialized, where will it live, which state does it own, which authority does that state carry, and which institutional relationships must exist before admission is valid?

An App Contract is not a deployment script and is not a dump of application configuration. It declares the institutional facts that must be made true and proved.

The governing lifecycle is:

```text
Declare
  ↓
Materialize
  ↓
Prove
  ↓
Recognize
```

An application MUST NOT be treated as admitted merely because its bytes exist on a machine or inside an App Park.

## 2. Root versus subordinate contracts

The App Contract is a root contract. It MUST remain bounded.

It MAY require relationships with Antenna, Heartime, Continuity, Search, Identity, or another service, but it SHOULD reference relationship-specific contracts rather than inline all of their terms.

```text
App Contract
│
├── identity / source / placement / stores
├── Antenna relationship ──→ Antenna Contract
├── Heartime relationship ─→ Heartime Contract
├── executable capability ─→ Executability Contract
└── searchable surface ────→ Search Contract
```

A relationship reference says that the relationship must exist. The subordinate contract owns its detailed terms.

## 3. Contract identity and generation

Each App Contract has:

- a stable contract identifier;
- a positive integer generation;
- one application subject;
- one owner responsible for the declaration.

Example:

```yaml
metadata:
  id: pf.contract.app.coloured-places
  generation: 3
  subject: pf.coloured-places
  owner: pf.danvoulez
```

The contract identifier identifies the continuing institutional relationship. `generation` identifies one immutable set of terms for that relationship.

A material change to recognized terms MUST create a new generation rather than silently mutate the recognized bytes of an existing generation.

Examples of changes that normally require a new App Contract generation include:

- changing the exact source revision or recognized artifact version;
- moving the app to another Place when placement is contractual;
- adding, removing, or materially changing an authoritative state store;
- changing the authority claimed by a store;
- changing a required service relationship;
- changing a machine identity or principal boundary;
- changing admission requirements;
- changing lifecycle intent from active to retired.

Purely operational state inside an application database does not create a new App Contract generation.

## 4. Serialization and digest

The normative data model is JSON. YAML MAY be used as authoring syntax under the repository-wide serialization rules.

A recognized App Contract generation MUST have a material digest calculated using the repository contract-digest procedure:

```text
validated JSON value
  ↓
RFC 8785 canonical JSON
  ↓
SHA-256
  ↓
sha256:<hex>
```

The Registry records that digest. The contract document MAY live in the Content Store, source control, or another resolvable immutable source, but the bytes used for recognition MUST be independently verifiable against the recognized digest.

## 5. Top-level model

A conforming document has this shape:

```yaml
apiVersion: powerfarm.specs/v0
kind: AppContract
metadata:
  id: pf.contract.app.example
  generation: 1
  subject: pf.example
  owner: pf.office.example-owner
spec:
  source: {}
  placement: {}
  runtime: {}
  authentication: {}
  stateStores: []
  content: {}
  capabilities: {}
  relationships: []
  lifecycle: {}
  admission: {}
```

The machine-readable constraints are in `schemas/app-contract-v0.schema.json`.

## 6. Source

`spec.source` identifies the exact software materialization being admitted.

It MUST include:

- a recognized artifact version reference;
- a repository URI;
- an exact revision.

It MAY additionally include:

- a path within the repository;
- an immutable source snapshot `ContentRef`;
- build or package references.

Example:

```yaml
source:
  artifact:
    artifactId: pf.software.coloured-places
    version: 0.5.1
  repository: https://github.com/powerfarm/powerfarm-coloured-places
  revision: 0123456789abcdef0123456789abcdef01234567
  path: .
  snapshot:
    digest: sha256:...
    mediaType: application/vnd.powerfarm.source-tree+json
    size: 18324
```

A branch name such as `main` is not an exact revision and MUST NOT be the only source identity used for admission.

A source snapshot does not replace human-readable repository history. It gives exact material identity when the implementation needs location-independent immutable source input.

## 7. Placement

`spec.placement` identifies the institutional placement domain and logical application location.

Example:

```yaml
placement:
  place: pf.app-park.8gb
  relativePath: coloured-places
```

The contract SHOULD identify a Place rather than hard-code an operating-system mount root.

The intended locator chain is:

```text
application
  → place
  → relative path
  → current physical path
```

`relativePath` MUST be relative, MUST NOT contain `..` traversal segments, and SHOULD use `/` as the logical separator even when an implementation maps it onto another local filesystem convention.

A Place MAY itself resolve to a machine, mount, volume, sandbox, container, or future placement mechanism. Those details belong to the Place's recognized contract or implementation.

## 8. Runtime declaration

`spec.runtime` MAY declare the minimal runtime facts needed for admission and operation, for example:

- runtime kind;
- entry point or launch target;
- health capability;
- process identity expectations.

It SHOULD NOT duplicate an entire process manager configuration when that configuration can be referenced as an artifact or delegated to a runtime-native descriptor.

Runtime details are replaceable implementation. The App Contract records only details that are institutionally meaningful for this materialization.

## 9. Authentication and principal

`spec.authentication` identifies the app's machine principal and relevant institutional auth profile.

It MUST NOT contain passwords, client secrets, private keys, refresh tokens, or bearer tokens.

Example:

```yaml
authentication:
  principal: pf.coloured-places
  oauth:
    required: true
    profile: powerfarm-identity
  grantRefs: []
```

The contract MAY identify a public client identifier or grant reference if doing so is useful, but possession of the App Contract is never possession of credentials.

Authentication infrastructure and auth-account linking belong to Identity. They are not Registry Core state merely because the app uses them.

## 10. State stores

### 10.1 Ownership rule

Every institutionally relevant operational store owned by the app SHOULD be declared under `spec.stateStores`.

A database does not acquire institutional meaning merely by appearing on disk.

The declaration says:

> This app is expected to own this store, at this logical location, under this schema identity, with this declared authority and durability policy.

The declaration does not copy the store contents into the Registry.

### 10.2 Store identity

A store declaration contains a stable institutional store id.

Example:

```yaml
- id: pf.store.coloured-places.primary
  engine: sqlite
  purpose: Operator projection and observation history
```

The store id survives ordinary database file replacement, vacuuming, page reorganization, or migration of its physical mount path.

### 10.3 Locator

A store locator SHOULD use a Place plus a relative path:

```yaml
locator:
  place: pf.app-park.8gb
  relativePath: coloured-places/state/app.db
```

If `place` is omitted, the app placement MAY be inherited.

The locator tells a conforming materializer where the store should exist. It does not itself grant read or write authority.

### 10.4 Schema identity

A live mutable database MUST NOT use its complete file digest as its persistent institutional identity.

A store SHOULD instead identify its schema or migration state using one or more stable references:

```yaml
schema:
  version: 3
  content:
    digest: sha256:...
    mediaType: application/sql
    size: 4821
```

or a recognized artifact version:

```yaml
schema:
  version: 3
  artifact:
    artifactId: pf.schema.coloured-places
    version: 3
```

Implementations MAY additionally record:

- genesis digest;
- migration-set digest;
- immutable snapshot digests.

Those values identify exact preserved material. They do not replace the logical store identity.

### 10.5 Authority

`authoritativeFor` declares the semantic scopes for which the app claims institutional authority through this store.

Example:

```yaml
authoritativeFor:
  - pf.scope.place-observation
  - pf.scope.health-history
```

Authority is explicit and SHOULD be narrow enough to be meaningful.

A store containing a copy, cache, index, or projection of information MUST NOT claim authority for the underlying fact merely because it can answer a query about it.

A Search index, for example, is a projection unless a separate contract explicitly assigns it authority.

### 10.6 Durability, snapshots, and sensitivity

A store MAY declare:

- durability class;
- snapshot policy;
- sensitivity class;
- migration authority;
- whether it is discoverable for federated Search.

These declarations are operational constraints, not a centralized storage mandate.

`searchable: true` means the store MAY participate in Search discovery. It is not a read grant and does not authorize Search to bypass the app's access boundary.

## 11. Content declarations

`spec.content` describes classes of immutable content the application produces or consumes.

Example:

```yaml
content:
  produces:
    - kind: observation-snapshot
      mediaType: application/vnd.powerfarm.observations+sqlite
  consumes:
    - kind: place-definition-set
      mediaType: application/json
```

This is a type-level contract, not an inventory of every object ever produced.

Specific immutable objects that are part of one materialization MAY be referenced with `ContentRef` values elsewhere in the contract. Operational output history belongs to the app's local state, evidence system, Content Store indexes, or research records as appropriate.

## 12. Capabilities

`spec.capabilities` declares important capabilities provided or consumed by the application.

A capability declaration SHOULD identify an existing machine contract where possible, for example MCP, OpenAPI, AsyncAPI, or W3C WoT.

Example:

```yaml
capabilities:
  provides:
    - id: pf.capability.coloured-places.health
      interface:
        kind: openapi
        ref: https://places.example.invalid/openapi.json
        operation: getHealth
```

An App Contract SHOULD NOT create a local procedural API description when an established interface standard can faithfully represent the boundary.

A capability identifier is a semantic name in the Powerfarm namespace; using that identifier does not by itself require a separate Registry entity row. When a capability definition or profile is institutionally versioned, it SHOULD be represented as an artifact version and may be referenced from the capability declaration.

Capability authority and effect semantics MAY be refined by subordinate contracts or Continuity Capability Profiles.

## 13. Relationships

`spec.relationships` declares contracts that must exist for the application to be validly admitted.

Example:

```yaml
relationships:
  - type: antenna
    required: true
    contract:
      id: pf.contract.antenna.coloured-places.observability
      generation: 2
```

Supported v0 relationship labels are:

- `antenna`;
- `heartime`;
- `executability`;
- `search`;
- `other`.

The label aids tooling. The referenced contract remains authoritative for the relationship terms.

### 13.1 Antenna

If an application depends on observational ingress, heartbeat, delivery, or another Antenna-provided service, the App Contract SHOULD reference the applicable Antenna Contract.

Heartbeat is observational evidence. Its detailed cadence, route, limits, and acceptance terms belong to the Antenna relationship, not the root App Contract.

### 13.2 Heartime

An application requires a Heartime relationship when its behavior depends on durable temporal semantics such as a deadline, temporal window, recurrence, retry time, hold duration, or census obligation.

A passive application MAY have no Heartime relationship.

### 13.3 Executability

If the app participates in transitions materialized by Continuity, the App Contract SHOULD reference one or more Executability Contracts.

### 13.4 Search

If the app exposes searchable surfaces whose access semantics require more than the basic store declaration, the App Contract SHOULD reference a Search Contract when such a specification exists.

Search remains a read model and MUST NOT become the authority merely because it can locate the data.

## 14. Lifecycle

`spec.lifecycle.desiredState` declares the institutional state intended by this generation:

- `active`;
- `suspended`;
- `retired`.

A lifecycle change that changes Powerfarm's recognized relationship to the app SHOULD normally be represented by a new contract generation.

`retired` does not require historical bytes or evidence to be destroyed. Retirement removes current institutional operation or authority while preserving reconstructable history where required by canon.

## 15. Admission requirements

`spec.admission.requirements` declares the checks that must be proved before this contract generation can become recognized as admitted.

Recommended v0 checks include:

```text
source_verified
identity_bound
placement_materialized
stores_materialized
schemas_verified
relationships_materialized
authentication_configured
health_verified
```

Not every app requires every check. The contract declares the checks relevant to its actual shape.

A requirement MAY be implementation-specific if its name is namespaced, but implementation-specific checks MUST NOT weaken a required canonical invariant.

## 16. Admission Receipt

Materialization produces an `AdmissionReceipt` conforming to `schemas/admission-receipt-v0.schema.json`.

The receipt records:

- which contract id and generation were evaluated;
- the exact contract digest;
- who or what performed the materialization;
- each admission check;
- evidence references;
- the resulting outcome.

An Admission Receipt is evidence. It does not grant authority by itself.

The Registry MAY recognize the App Contract generation only when the required evidence satisfies the admission policy.

## 17. Materialization semantics

A conforming materializer SHOULD follow this sequence:

```text
validate contract
  ↓
verify exact source
  ↓
resolve/create stable app entity identity
  ↓
verify target Place
  ↓
materialize app bytes
  ↓
instantiate or verify declared stores
  ↓
apply/verify schema or migrations
  ↓
configure machine identity / auth relationship
  ↓
materialize required service relationships
  ↓
verify health and declared admission requirements
  ↓
produce Admission Receipt
  ↓
recognize contract generation
```

This sequence MAY be implemented as a recoverable workflow rather than one transaction.

Powerfarm does not require distributed ACID across the Registry, filesystem, app databases, OAuth system, Antenna, or Heartime.

Materializers SHOULD therefore be idempotent and SHOULD persist enough progress to recover safely from interruption.

## 18. Existing stores

If the target store already exists, onboarding MUST NOT blindly replace it.

The materializer MUST determine whether the existing store is compatible with the contract by checking, as applicable:

- ownership;
- expected locator;
- schema or migration identity;
- application identity;
- declared durability expectations.

An unrecognized or incompatible existing store MUST cause a bounded failure, quarantine, or explicit migration path rather than silent overwrite.

## 19. Upgrade semantics

An upgrade normally creates a new App Contract generation.

A conforming upgrade SHOULD:

1. validate the new generation;
2. compare it with the currently recognized generation;
3. classify source, placement, store, authority, relationship, and auth changes;
4. require migration analysis for persistent state changes;
5. materialize the new desired state;
6. prove admission checks;
7. atomically recognize the new generation and supersede the prior generation at the Registry boundary;
8. preserve the prior generation and evidence.

An implementation MUST NOT silently rewrite the recognized bytes of the prior generation.

## 20. Retirement semantics

Retirement SHOULD be explicit and evidence-bearing.

A retirement flow MAY:

- stop admitting new executable activations;
- revoke or expire grants;
- disable external service relationships;
- preserve or snapshot local state according to policy;
- remove live placement after preservation requirements are met;
- recognize a retired App Contract generation or retire the active generation in the Registry.

Deleting a directory is not sufficient retirement evidence.

## 21. Search discovery semantics

The foundation for federated Search is the store topology declared by recognized App Contracts.

A Search implementation MAY:

```text
ask Registry for current recognized App Contracts
  ↓
resolve verified contract documents
  ↓
extract searchable store declarations + authority scopes
  ↓
resolve permitted access surfaces
  ↓
query relevant stores
  ↓
return normalized results + provenance
```

Derived indexes of these declarations MAY be maintained for performance. They are caches or projections and MUST remain reconstructable from recognized contracts.

## 22. Conformance

An App Contract implementation conforms to v0 when it satisfies all of the following:

- validates the contract against the v0 schema;
- calculates the recognized contract digest correctly;
- treats contract generation as immutable recognized terms;
- treats physical placement as insufficient for admission;
- keeps app operational data out of Registry Core;
- materializes declared authoritative stores or fails explicitly;
- does not use live database whole-file hashes as persistent store identity;
- materializes required subordinate relationships or fails admission;
- emits admission evidence before active recognition;
- preserves prior recognized generations across upgrade and retirement.

Conformance is behavioral. A particular installer, database, runtime, or programming language is not required.

## 23. Minimal example

See `examples/app-contract.minimal.yaml`.

A target-state Coloured Places example is in `examples/app-contract.coloured-places.yaml`.
