# Registry Core v0

**Status:** Draft operational specification
**Specification:** Registry Core
**Version:** v0
**Canonical basis:** PF-03 §§3.2–3.7, 3.12, 3.16; PF-04 Representation Doctrine
**V0 materialization:** `powerfarm-research-docs` V0-01 (data), V0-03 (rebuild), V0-07 (names)

## 1. Purpose

The Registry records institutionally recognized assertions.

It answers:

> What does Powerfarm recognize as existing, which exact versions and contract generations are current, and who may do what?

It does not answer:

> What is the complete operational state of every Powerfarm system right now?

Operational state belongs to the software that produces and governs it. The Registry is a service within Identity, not a global application database and not a fourth durable sector.

## 2. Minimal ontology

```text
contracts
entities
artifacts
artifact_versions
grants
```

This is an ontology, not a promise of exactly five tables. Derived indexes, views and support tables MAY exist when they acquire no independent institutional meaning.

Every recognized change is also recorded as an act in the act log (§12). The act log records the history of the five concepts; it adds no new kind of institutional meaning.

A new durable Registry concept requires evidence that the existing five cannot faithfully represent the institutional relationship.

## 3. Registry boundary

Registry Core MUST NOT become the canonical home for:

- application business records;
- Antenna observations, receipts, deliveries or routing history;
- Heartime temporal evidence;
- Continuity runtime histories, workflow checkpoints or effect journals;
- Search indexes or query caches;
- research working state;
- deployment controller or CI run state;
- OAuth tokens, sessions, secrets or provider account-link state;
- Content Store bytes.

Such state may be discoverable through recognized contracts, but it remains owned by the system whose semantics govern it.

## 4. Names

Every entity, artifact and contract has a name of the form defined by V0-07:

```text
powerfarm.app/<type>/<name>          entities and artifacts
powerfarm.app/contract/<name>        contracts
```

- The type segment is the name of the contract that defines the type.
- Names are lowercase ASCII, stored without a scheme, never reused and never renamed.
- A name identifies an institutional thing, never a provider object, a filesystem path or a database row.

## 5. Types come from contracts

Every type column points to a **current contract**:

| column | points to |
|---|---|
| `contracts.type` | a Contract Type contract |
| `entities.type` | an Entity Type contract |
| `artifacts.type` | an Artifact Type contract |
| `grants.action` | an Action Type contract |

Rules:

1. A type exists only while a contract defining it is current.
2. The single exception is the first contract, *Contract Type* (`powerfarm.app/contract/contract-type`), whose type is itself.
3. Contracts that define types have no subject entity: the definition exists before any entity of that type.
4. Every other contract names its participants (subject; provider and consumer where the relationship has those roles).
5. Adding a type is recognizing one contract. It needs no schema change and no deploy.

Each contract generation points to exactly one document (§8.2). A type-defining document carries what the type means:

- a **Contract Type** document carries the JSON Schema that documents of that type must satisfy;
- an **Entity Type** document declares the name pattern, the rights every entity of the type has, its duties, and its prerogatives (such as holding a mandate);
- an **Artifact Type** document carries the JSON Schema for content of that type and names any validator that checks what a schema cannot;
- an **Action Type** document names exactly one institutional authority: OBSERVE, JUDGE, PROPOSE, GENERATE, EXECUTE, ORCHESTRATE, PERSIST or AUTHORIZE.

## 6. Birth

The Registry is born empty and filled only by acts.

1. **The migration creates tables, rules and functions, never rows.**
2. **The Foundation Act** runs once, on an empty Registry, and is act number 1. It recognizes the minimum needed for someone to hold authority: *Contract Type*, *Entity Type*, the other contract types, the entity types *person* and *office*, the Director's action types, the Director office, the first person, that person's mandate and admission. Then it closes forever.
3. **Everything else** (other types, entities, artifacts, contracts, grants) is recognized afterwards through the institutional API, one act at a time.

No entity, contract or grant is ever created by a seed.

## 7. Entities and artifacts

### 7.1 Entity

An **entity** is a stable institutional identity for something Powerfarm recognizes across changes of implementation or version.

```text
powerfarm.app/sector/identity
powerfarm.app/service/antenna
powerfarm.app/app/coloured-places
powerfarm.app/machine/lab-8gb
powerfarm.app/agent/lab-8gb
powerfarm.app/office/director
```

An entity:

- has a stable name (§4) and a type (§5);
- MAY have a title and summary;
- MAY be retired, never deleted;
- MUST NOT absorb arbitrary operational state merely because that state concerns it.

A type describes and grants the rights its Entity Type contract declares; it grants nothing else.

### 7.2 Artifact

An **artifact** is a stable identity for something that has exact versions: software, capabilities, schemas, datasets, prompts, documents, execution bundles, Minivault items.

```text
powerfarm.app/software/coloured-places
powerfarm.app/document/pf-03
powerfarm.app/program/intake.review
```

The artifact survives its versions.

## 8. Versions and contracts

### 8.1 Artifact version

An **artifact version** identifies one exact material version:

```text
artifact name
version label
content digest (sha256), or a manifest digest
source repository, revision and path, when sourced from source control
media type and size
recognized at / by
superseded at / by
retired at
```

- SHA-256 is Powerfarm's one fingerprint: every digest is `sha256:<lowercase-hex>`.
- A source reference (repository + revision + path) and a content digest answer different questions and MAY coexist.
- The Registry never stores the bytes themselves.
- At most one version of an artifact is current: superseded and retired versions are not.

**Promotion is explicit.** An object can exist in the Content Store without being recognized:

```text
these exact bytes exist          (Content Store)
        ≠
Powerfarm recognizes them        (an artifact version or a contract document)
```

### 8.2 Contract

A **contract** records one recognized relationship or definition. It has a stable name and one or more immutable **generations**:

```text
contract name        = the continuing relationship
contract generation  = one immutable set of recognized terms
```

A generation records:

- its type (a Contract Type contract);
- its participants: subject, provider and consumer, where the relationship has them (none for type-defining contracts);
- the digest, media type and size of its document;
- its effective interval;
- recognized at / by;
- its acceptance receipt, when acceptance is required;
- supersession and retirement.

The Registry verifies the document's digest against the stored bytes before recognizing the generation. A cached copy of the document MUST NOT become a second authority.

Participants are queryable columns, so topology is discoverable without parsing documents. The document remains authoritative for the full terms.

## 9. Grants and authority

### 9.1 Grant

A **grant** is an explicit authority assignment to one entity:

- subject entity;
- action (an Action Type contract);
- optional resource;
- granted by, and the contract that is its basis;
- valid from / until;
- revoked at, and the reason.

A grant is not an OAuth token. Tokens are ephemeral protocol credentials; grants are institutional assertions. Revocation is a new fact and never erases the grant.

### 9.2 Computing authority

Authority is computed at request time from current contracts. Nowhere is a copy of permissions kept.

```text
may(entity, action, resource) =
    rights of the entity's type                 (current Entity Type contract)
  + powers of the offices the entity holds      (current mandates, if its type may hold one)
  + the entity's current grants
```

- The answer is `true`, `false` or `unknown`. Only `true` passes; `unknown` carries its reason.
- An agent acting for a person never exceeds that person: the effective rights are the intersection of both.
- When a contract generation changes, everyone it covers gains or loses the corresponding authority immediately.

### 9.3 Offices and mandates

An **office** is an entity whose Office contract declares which entity types may hold it and which powers it confers. A **mandate** is a contract that binds one holder to one office for an effective interval: `powerfarm.app/contract/mandate.<office>.<holder>`. The autonomy an office's charter grants per operation class is defined in V0-01 §2.8.

## 10. Identity infrastructure versus Registry

Identity contains more than Registry Core: login accounts, OAuth clients, sessions, consent records, passwordless flows, keys.

- The list of people and agents is the Registry's entities. A login account or machine credential is a **binding** to exactly one entity, never a second list.
- Those tables do not become Registry Core concepts merely because they live in the same database.

```text
Identity protocol infrastructure  → authenticate keys, bind them to entities, issue credentials
Registry Core                     → recognize contracts, entities, artifacts and grants; compute may()
```

## 11. Stores, Search and projections

- A store is an entity of type `store`, declared by a store-authority contract that names its owner and what it is authoritative for. No separate stores table is needed.
- A store catalog MAY be derived for performance. It is reconstructable from recognized contracts and never becomes the authority for ownership.
- Search MAY query the Registry for recognized things, current contracts and declared stores. It MUST NOT infer authority from data presence or from its own index. If Search disappears, Registry truth remains intact.

## 12. The act log

Every successful write through the institutional API appends one act:

| field | meaning |
|---|---|
| sequence | strictly increasing; the act's name is `powerfarm.app/act/<sequence>` |
| at | time |
| actor | the entity that acted, and the person it acted for, if any |
| action | the action type |
| target | the name of the thing acted on |
| content | SHA-256 of the act's content |
| previous | the hash of the previous act |
| hash | this act's hash, over a fixed encoding of the fields above, computed by the database |

Properties:

- acts are never edited or removed; a correction is a new act;
- the chain verifies from act 1 to the last act;
- the act log is the audit, the event stream, and the story: **replaying it in order over the preserved content rebuilds the same Registry** (PF-03 §3.3; V0-03).

## 13. Recognition states, supersession and immutability

States: `recognized`, `superseded`, `retired`. Proposed content may exist in source control or the Content Store before recognition; uploading bytes never makes anything look recognized.

Recognizing a new current generation or version never deletes the previous one. Supersession records what became current, what it superseded, and when; historical queries can always identify the prior recognized state. Recognition of a new generation and supersession of the old one happen atomically.

These fields MUST NOT change after recognition:

- entity, artifact and contract names;
- an artifact version's source and digest identity;
- a contract's generation number, document digest and participants;
- a grant's subject, action, resource and grantor.

Lifecycle fields (`superseded_at`, `retired_at`, `valid_until`, `revoked_at`) change only by acts. Implementations SHOULD use database constraints so that accidental mutation is impossible.

## 14. Content Store boundary

```text
Content Store   → these exact bytes exist
Registry        → Powerfarm recognizes these bytes as this artifact version or contract document
```

Reading non-public content is subject to `may()`. A digest is an identity, not a capability.

## 15. Operations

A conforming Registry Core supports these operations, whatever the physical API:

| operation | effect |
|---|---|
| Foundation Act | once, on an empty Registry (§6) |
| recognize contract generation | verify the document digest and participants; supersede the current generation atomically |
| inscribe entity | a new entity of an existing type |
| recognize artifact, recognize artifact version | a new identity; a new exact version, superseding the current one |
| supersede, retire | change current state; history stays |
| grant, revoke | an explicit authority, or its revocation |
| may | compute authority (§9.2) |

Every operation passes through `may()` and records its act.

## 16. Reference implementation

The Registry migration in `powerfarm/minivault` (`supabase/migrations`) is the reference implementation of this specification. Its tests exercise the conformance cases (§18). It excludes Auth tables, OAuth state, runtime tables, application data, Content Store bytes and Search indexes.

## 17. Security properties

A Registry implementation MUST enforce at least:

- authenticated writes, all through the institutional API;
- explicit authority to recognize, supersede, retire, grant or revoke;
- no secret values in any Registry row or contract document that is not private;
- digest verification before recognizing referenced content;
- least privilege on administrative paths;
- every write recorded as an act.

## 18. Conformance

A conforming implementation demonstrates that:

- the migration creates no rows, and a second Foundation Act fails;
- every type column references a current contract, and a type disappears when its contract is retired;
- operational application data never becomes Registry state;
- names stay stable across implementation changes;
- artifact versions and contract generations are exact and historically addressable;
- byte identity is distinct from recognition;
- contracts are queryable as topology;
- grants are explicit and aware of time and revocation;
- `may()` changes immediately when a contract generation changes;
- authentication state stays separate from Registry Core;
- the act log's chain verifies, and replaying it into an empty implementation reproduces the same Registry;
- no projection can become authority by indexing Registry data.

## 19. Principle

> The Registry stays deliberately smaller than the systems it describes.
