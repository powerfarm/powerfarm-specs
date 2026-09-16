# Registry Core v0

**Status:** Draft operational specification  
**Specification:** Registry Core  
**Version:** v0  
**Canonical basis:** PF-03 §§3.2–3.7, 3.12, 3.16; PF-04 Representation Doctrine

## 1. Purpose

The Registry records institutionally recognized assertions.

It answers:

> What does Powerfarm recognize as existing, which exact versions or contract generations are current, and which authorities have been granted?

It does not answer:

> What is the complete operational state of every Powerfarm system right now?

Operational state belongs to the software that produces and governs it.

The Registry is therefore a service within Identity, not a global application database and not a fourth durable sector.

## 2. Minimal ontology

The v0 conceptual core is deliberately small:

```text
entities
artifacts
artifact_versions
contracts
grants
```

This is an ontology, not a promise that every implementation will expose exactly five SQL tables forever. Derived indexes, projections, caches, views, and implementation support tables MAY exist when they do not acquire independent institutional meaning.

A new durable Registry concept requires evidence that the existing five cannot faithfully represent the institutional relationship.

## 3. Registry boundary

Registry Core MUST NOT become the canonical home for:

- application business records;
- Antenna receipts, deliveries, or routing history;
- Heartime temporal evidence;
- Continuity runtime histories, workflow checkpoints, or effect journals;
- Search indexes or query result caches;
- Workspace research state;
- deployment controller state;
- CI run state;
- OAuth tokens, sessions, secrets, or provider-specific account-link state;
- Content Store bytes.

Such state may be discoverable through recognized contracts, but it remains owned by the system whose semantics govern it.

## 4. Entity

An `entity` is a stable institutional identity for a thing Powerfarm needs to recognize across changes in implementation or version.

Examples include:

```text
pf.identity
pf.continuity
pf.antenna
pf.heartime
pf.research
pf.coloured-places
pf.lab-8gb
pf.app-park.8gb
pf.danvoulez
```

### 4.1 Entity invariants

An entity:

- has a stable id;
- has a kind used for description and tooling;
- MAY have a title and summary;
- MAY be retired;
- MUST NOT absorb arbitrary operational state merely because that state concerns the entity.

The recommended id form is:

```text
pf.<segment>[.<segment>...]
```

with lowercase ASCII letters, digits, and hyphens inside segments.

Entity kind is intentionally extensible. Suggested values include `person`, `office`, `app`, `service`, `sector`, `place`, and `machine`.

Kind is descriptive. Authority comes from contracts and grants, not from kind alone.

## 5. Artifact

An `artifact` is a stable semantic identity for something that can have exact versions.

Examples include:

- software;
- capability profiles;
- schemas;
- datasets;
- prompts;
- policies;
- documents;
- execution bundles;
- experimental outputs promoted to institutional significance.

The artifact survives its versions.

Example:

```text
pf.software.coloured-places
```

might identify the software artifact while exact revisions are recorded as artifact versions.

Artifact kinds SHOULD remain extensible rather than frozen to an early enum that forces unrelated things into the wrong category.

## 6. Artifact version

An `artifact_version` identifies one exact material version of an artifact.

It SHOULD record enough provenance to locate and verify the exact object, for example:

```text
artifact id
version label
source repository
source revision
source path
content digest
media type
size
recognized_at
publisher / recognizer
```

A version MAY be sourced from Git, the Content Store, an external package registry, or another stable source.

The Registry MUST NOT require the bytes themselves to be stored in the Registry.

### 6.1 Exactness

When a content digest is present, v0 uses the repository-wide `sha256:<hex>` digest format.

Repository + revision + path identifies source provenance. A content digest identifies exact bytes. They answer different questions and MAY coexist.

### 6.2 Promotion

An immutable object can exist in the Content Store without being a Registry artifact version.

Institutional promotion is explicit:

```text
CAS object exists
      !=
Powerfarm recognizes an artifact version
```

Promotion creates or links an artifact version and records why/when it became institutionally significant.

## 7. Contract

A `contract` records one recognized legitimate relationship or declaration.

Examples include:

- App Contract;
- Antenna service contract;
- Heartime temporal relationship;
- Executability Contract;
- Search relationship;
- another future relationship that fits the contract model without requiring a new architectural organ.

### 7.1 Stable id and generation

A contract has a stable id and one or more immutable generations.

```text
contract id          = continuing institutional relationship
contract generation  = one immutable set of recognized terms
```

A generation SHOULD contain or reference:

- contract kind;
- subject entity;
- provider and consumer where the relationship has those roles;
- exact contract document digest;
- content media type and size when available;
- issuer / recognizer;
- effective interval;
- supersession / retirement state;
- admission evidence where required.

### 7.2 Contract bytes

The Registry SHOULD record a verifiable reference to the exact contract bytes rather than using a mutable JSON blob as the only source of truth.

The preferred boundary is:

```text
Registry contract row
   │ semantic identity + recognition
   ▼
ContentRef / source reference
   │ exact material identity
   ▼
contract bytes
```

An implementation MAY cache the verified document for query performance. A cache MUST NOT silently become a second authority and MUST be invalidated or reverified when its digest does not match the recognized generation.

### 7.3 Contract participants

For relationships with provider/consumer roles, the Registry SHOULD expose those participants as queryable columns or an equivalent derived projection so topology can be discovered without parsing every document.

The contract document remains authoritative for the full terms.

## 8. Grant

A `grant` is an explicit institutional authority assignment.

It identifies:

- subject entity;
- allowed action;
- optional resource scope;
- grantor;
- validity interval;
- revocation state;
- optional policy reference or constraints.

A grant is not an OAuth access token.

OAuth tokens are ephemeral protocol credentials. Grants are institutional authority assertions that may be used by Identity/authorization systems to determine what credentials should permit.

### 8.1 Time bounds

Grant validity is evaluated using explicit timestamps or equivalent temporal evidence.

A grant SHOULD support:

```text
valid_from
valid_until
revoked_at
revoked_reason
```

Revocation is a new institutional fact. It MUST NOT erase the original grant history.

## 9. Identity infrastructure versus Registry

Identity contains more than Registry Core.

OAuth client registrations, account links, keys, sessions, consent records, token state, passwordless flows, and provider-specific authorization infrastructure MAY exist inside the Identity implementation.

Those tables do not become Registry Core concepts merely because they live in the same Postgres database.

The durable conceptual split is:

```text
Identity protocol infrastructure
  -> authenticate principals and issue/validate credentials

Registry Core
  -> recognize entities, artifacts, contracts, and grants
```

A machine principal MAY map to a Registry entity, but the mapping mechanism is Identity implementation detail.

## 10. Store discovery

Registry Core does not require a `stores` table in v0.

Institutionally relevant stores are declared inside recognized App Contracts.

This preserves the rule:

```text
store state is local
store topology is contractual
```

A Search or operator implementation MAY derive a store catalog by resolving active App Contract generations.

For performance it MAY maintain a projection such as:

```text
recognized_store_catalog
```

That projection is derived state. It MUST be reconstructable from recognized App Contracts and MUST NOT become the authority for store ownership or semantic scope.

## 11. Search boundary

Search MAY query the Registry to discover:

- which apps are recognized;
- which current App Contract generations apply;
- which stores those contracts declare;
- which semantic scopes those stores claim authority for;
- which Search relationships define access.

Search MUST NOT infer authority from data presence or from its own index.

If Search disappears, Registry truth and application truth remain intact.

## 12. Recognition states

Registry implementations MAY expose states such as:

```text
recognized
superseded
retired
```

`draft` or `proposed` content may exist in source control or the Content Store before recognition. The Registry SHOULD avoid making a proposed contract look active merely because its bytes were uploaded.

A current-state query is a projection over historical generations, not permission to overwrite history.

## 13. Supersession

Recognizing a new current generation of a contract or artifact does not delete the previous generation.

Supersession records:

- what became current;
- what it superseded;
- when the boundary became effective.

Historical queries MUST remain able to identify the prior recognized generation.

For contracts, recognition of a new generation and supersession of the old generation SHOULD occur atomically at the Registry boundary when both are part of the same institutional decision.

## 14. Immutability rules

The following material identity fields MUST NOT be silently changed after recognition:

- entity stable id;
- artifact id;
- artifact version's material source/digest identity;
- contract id + generation;
- contract document digest;
- contract subject/provider/consumer identities when those fields define the recognized relationship;
- grant subject/action/resource/grantor for an existing grant record.

Lifecycle fields such as `superseded_at`, `retired_at`, `valid_until`, and `revoked_at` MAY be updated or appended according to implementation, provided the historical transition remains reconstructable.

An implementation SHOULD use database constraints or equivalent mechanisms to make accidental mutation difficult.

## 15. Content Store boundary

The Registry does not assign meaning to content merely because a digest exists.

```text
Content Store
  -> these exact bytes exist

Registry
  -> Powerfarm recognizes these bytes as this artifact version or contract generation
```

Content Store resolution MUST remain subject to Identity and grant checks when content is not public.

The digest is an identity, not a capability.

## 16. Provenance

Important Registry assertions SHOULD retain provenance sufficient to answer:

```text
what is asserted?
who or what asserted/recognized it?
when did it become current?
which exact material document or artifact does it refer to?
what admission / decision evidence justified recognition when required?
what superseded or retired it?
```

The Registry need not adopt W3C PROV as its internal schema. PROV-DM is a useful external vocabulary for checking that the model retains entities, activities, agents, derivation, and responsibility where material.

## 17. Registry operations

A conforming Registry Core SHOULD support these semantic operations, whatever the physical API:

### 17.1 Recognize entity

Create a stable institutional entity identity if it does not already exist.

Entity creation alone MUST NOT confer broad authority.

### 17.2 Recognize artifact

Create the stable semantic artifact identity.

### 17.3 Recognize artifact version

Record one exact version and its source/content identity without overwriting earlier versions.

### 17.4 Recognize contract generation

Record one exact contract generation, verify its digest, enforce participant existence, and establish its effective current state.

For App Contracts whose admission requires proof, active recognition MUST require adequate admission evidence.

### 17.5 Supersede / retire

Change current recognized state while preserving prior generations and timestamps.

### 17.6 Grant / revoke authority

Create and revoke explicit institutional grants without deleting history.

## 18. Reference SQL schema

`registry/reference-schema.sql` provides one PostgreSQL reference shape for these semantics.

It is not a live migration and MUST NOT be applied blindly to the current Powerfarm database.

Its purpose is to make invariants concrete enough to inspect, test, and challenge.

The reference schema intentionally excludes:

- Supabase Auth tables;
- RLS policy implementation;
- OAuth clients/tokens;
- runtime execution tables;
- app data;
- Content Store blobs;
- Search indexes.

## 19. Mapping from current Powerfarm Registry

The current implementation contains useful ancestors of the v0 model and also substantial architectural legacy.

The following migration direction is intended:

| Current concept | v0 direction |
|---|---|
| `identities` | map stable institutional identities into `entities` where semantically appropriate; keep auth-specific infrastructure separate |
| `artifacts` | retain concept; expand kinds rather than forcing future artifacts into old enum |
| `artifact_versions` | retain concept; normalize content digest format and immutable source identity |
| `artifact_relations` | evaluate case-by-case; dependency/supersession may live in artifact metadata, contracts, or derived graph rather than automatically becoming core |
| `grants` | retain institutional authority role; separate it clearly from OAuth tokens |
| `service_contracts` | migrate to general `contracts` with exact immutable contract documents |
| `service_contract_events` | preserve as migration/history evidence if useful; do not automatically make event ledger a core Registry concept |
| `runs`, ADK sessions/events/checkpoints/effects | move out of Registry authority; Continuity/runtime-owned state |
| gadgets/workspace/deployments/CI tables | move to owning systems or retire after caller/data audit |

No destructive migration is implied by this table.

## 20. Strangler migration rule

The path from the existing database to Registry Core v0 SHOULD be incremental:

1. inventory live readers/writers and externally depended-on queries;
2. classify each table as Registry Core, Identity infrastructure, app/runtime state, derived projection, or obsolete;
3. introduce the new contract representation and recognition path first;
4. dual-read or project old data only where necessary during migration;
5. migrate authoritative callers;
6. preserve or export historical data required for reconstruction;
7. remove legacy tables only after caller evidence shows they are no longer authoritative.

Do not optimize security/performance warnings on tables scheduled for removal merely to make the old shape prettier. Fix issues that are exploitable now, but spend architectural effort on the target boundary.

## 21. Security properties

A Registry implementation MUST enforce at least:

- authenticated writes;
- explicit authority to recognize, supersede, retire, grant, or revoke;
- no secret values in public contract metadata;
- content digest verification before recognition of referenced immutable material;
- least privilege on administrative mutation paths;
- auditable recognition and revocation actions.

How this is implemented in Supabase/Postgres, OPA, application code, or another system is an implementation decision.

## 22. Conformance

A conforming Registry Core implementation MUST demonstrate that:

- operational application data is not made canonical Registry state;
- entity/artifact/contract identity remains stable across implementation changes;
- artifact versions and contract generations are exact and historically addressable;
- byte identity is distinct from institutional recognition;
- contracts are queryable as topology;
- grants are explicit and time/revocation aware;
- auth protocol state remains conceptually separate from Registry Core;
- current-state projections are reconstructable from preserved history;
- Search or another projection cannot become authority by indexing Registry data;
- new contract generations supersede rather than rewrite recognized history.

## 23. Principle

> The Registry should remain deliberately smaller than the systems it describes.
