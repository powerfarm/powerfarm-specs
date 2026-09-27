**POWERFARM SPECIFICATION**

Registry

How Powerfarm recognizes what exists, computes who may act, and keeps every change

| **DOCUMENT**       | SPEC-01                                          |
|--------------------|--------------------------------------------------|
| **STATUS**         | **ADOPTED**                                      |
| **VERSION**        | 1.0                                              |
| **EFFECTIVE**      | 27 September 2026                                |
| **IMPLEMENTATION** | `powerfarm/minivault`, `supabase/migrations`     |

| **OWNS**         | The four basics (entities, objects, versions, contracts), the type roots, the computation of authority, the Foundation Act, the institutional API's write path, the act log, and the immutability of recognized facts. |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **DOES NOT OWN** | The form of names (SPEC-02), keys, sign-in and stored bytes (SPEC-03), what Minivault items mean (SPEC-04), app admission (SPEC-05), or how Powerfarm is rebuilt from its copies (SPEC-11). Canon: PF-03 §§3.3–3.6. |

> **Registry question**
>
> What does Powerfarm recognize as existing, which exact versions and terms are current, and who may do what?
>
> MUST means required. SHOULD means the default, and a material deviation needs a reason. MAY means optional.

# 1. Purpose

The Registry records what Powerfarm institutionally recognizes. It is a service within Identity, not a global application database and not a fourth durable sector.

It answers what exists, which version of it is current, which terms are in force, and who may act. It does not answer what every system is doing right now. Operational state belongs to the software that produces it.

The Registry MUST NOT become the home of:

- application business records;
- observations, signals, receipts or routing history;
- temporal evidence, workflow checkpoints or effect journals;
- search indexes or caches;
- OAuth tokens, sessions, secret values or provider account state;
- stored bytes.

Such state may be discoverable through recognized contracts. It stays owned by the system whose meaning governs it.

# 2. Principles

| **Principle**                    | **Operating meaning**                                                                                                  |
|----------------------------------|------------------------------------------------------------------------------------------------------------------------|
| Four basics                      | Entities, objects, versions and contracts. Everything else Powerfarm names is a contract of some type.                |
| Entities act                     | An entity holds keys, signs in, and is the one whose authority is computed. An object is acted on and never acts.       |
| Types come from contracts        | Every type is a current contract. Adding a type is recognizing one contract; it needs no deploy.                       |
| Authority is computed            | Authority is derived at request time from current contracts. No copy of permissions exists anywhere.                    |
| Born empty                       | The schema creates no rows. The first write is the Foundation Act, and every later write is an act through the API.    |
| Nothing is erased                | Contracts change by new generation, versions by supersession, things by retirement. History stays addressable.         |
| Every write is an act            | Each change appends one act to a hash-chained log. The log is the audit, the event stream and the story.               |
| Smaller than what it describes   | A new basic requires evidence that the four cannot faithfully represent the relationship.                              |

# 3. The four basics

| **basic**     | **what it is**                                  | **main fields**                                                                                                                                           |
|---------------|-------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **entities**  | things that act                                 | name, type, title, summary, created at/by, retired at, reason                                                                                              |
| **objects**   | things that are acted on                        | name, type, title, summary, created at/by, retired at, reason                                                                                              |
| **versions**  | exact bytes of an object                        | object, version label, content digest (or manifest digest), source (repository, revision, path), recognized at/by, superseded at/by, retired at            |
| **contracts** | every recognized definition and relationship    | name, generation, type, subject, provider, consumer, holds, document digest, effective from/until, acceptance receipt, recognized at/by, superseded at/by, retired at |

Entities and objects share one space of names (SPEC-02). A name is never reused, even after retirement.

## 3.1 Entities and objects

Whether a thing is an entity or an object follows one rule:

> **Entities act; objects are acted on.**

People, agents, apps, services, Host Runners and engines are entities. Machines, stores, sectors, repositories, secret references, documents, software and Minivault items are objects.

A thing's record identifies it. It MUST NOT absorb operational state that belongs to it.

## 3.2 Versions

Some types of object have versions. A version names exact bytes by SHA-256, of the content itself or of a manifest listing content (SPEC-03).

- At most one version of an object is current. The database guarantees it.
- A new version supersedes the current one atomically, and names the version it expects to replace (none for the first). A publication that expected a different current version is refused.
- A source reference (repository, revision, path) and a content digest answer different questions and MAY coexist.
- Retiring an object retires its current version with it.

**Storing is not recognizing.** Bytes can exist in the Content Store without any version pointing to them.

## 3.3 Contracts

A contract has a stable name and one or more immutable **generations**. A generation records its type, its participants, the digest of its document, its effective interval, and who recognized it and when.

- **Participants** are entities or objects, held in queryable columns so topology is discoverable without reading documents: a **subject**, and a **provider** and **consumer** where the relationship has those roles.
- **Holds** names another contract whose powers this one passes to its subject (§5).
- **The document** is JSON bytes in the Content Store. The Registry verifies the digest against the stored bytes before recognizing the generation. The document is authoritative for the full terms.
- A new generation keeps the type, participants and held contract of the previous one, and supersedes it atomically. Recognizing the same terms again is refused.
- Retiring a contract is final: its name is never recognized again.

# 4. Types

Every type column points to a current contract. Four contract types are the **type roots**, the only types the Registry knows by name:

| **type root**                              | **its contracts define**                  | **the document declares**                                                                                  |
|--------------------------------------------|-------------------------------------------|------------------------------------------------------------------------------------------------------------|
| `powerfarm.app/contract/contract-type`     | contract types (including itself)         | the JSON Schema of documents of that type, and which participants its contracts name                        |
| `powerfarm.app/contract/entity-type`       | entity types                              | the name pattern, the **rights** every entity of the type has, and its **duties**                          |
| `powerfarm.app/contract/object-type`       | object types                              | the name pattern, whether objects of the type have versions, and the schema and validator of version content |
| `powerfarm.app/contract/action-type`       | action types                              | exactly one authority: OBSERVE, JUDGE, PROPOSE, GENERATE, EXECUTE, ORCHESTRATE, PERSIST or AUTHORIZE      |

Rules:

1. *Contract Type* is its own type. Every other contract's type is a current contract whose type is *Contract Type*.
2. A type exists only while its contract is current. Retiring the contract removes the type: nothing new of that type is recognized, and authority that depends on it becomes `unknown`.
3. A thing's type is the type segment of its name: `powerfarm.app/agent/lab-8gb` is of type `powerfarm.app/contract/agent`.
4. The segments `contract`, `act` and `content` name other families of names and are never types of entities or objects.
5. A contract type whose contracts are **definitions** declares no participants: a definition exists before anything it defines. A contract type whose contracts are **relationships** requires at least a subject.

Every other contract type (office, mandate, permission, placement, store authority and the rest) is recognized through the API as data. The Registry does not know them by name.

# 5. Authority

```text
may(entity, action, resource) =
    rights of the entity's type                           (its current Entity Type contract)
  + powers of current contracts that name it as subject   (a permission)
  + powers of current contracts it holds                  (through a current contract that names it
                                                           as subject and holds that contract, when
                                                           the held contract accepts its type as holder)
```

A contract document gives powers with two terms:

- **powers**: a list of `{ "may": <action type or "*">, "resource": <pattern> }`. A pattern is `*` (anything), `self` (the entity itself), an exact name, or `<prefix>/*`.
- **holders**: the entity types that may hold the contract. A contract that declares holders gives its powers **only** to those who hold it. Any other contract gives its powers to its subject.

An **office** is therefore a contract with holders and powers, and a **mandate** is a contract whose subject is the holder and which holds the office for an effective interval. When the office's terms change, every holder gains or loses authority at once.

Rules:

1. The answer is `true`, `false` or `unknown`, always with a reason. Only `true` passes. `unknown` means the question cannot be answered from current contracts: the action or the entity's type is not current.
2. A retired entity may do nothing.
3. An agent acting for a person never exceeds that person: both must be allowed.
4. **Authority never widens.** Recognizing a contract that gives powers requires `grant` for its subject, and whoever recognizes it must hold every power it gives.
5. Consequential effects (destructive machine change, giving powers, adopting a registry target) need an approval bound to the exact plan or effect by digest. A materially changed plan needs a new approval.

> **Offices and autonomy**
>
> What a mandate lets its holder do *without asking* is capped, per operation class, by the autonomy matrix in the office's document. Autonomy never removes the need for authority.

# 6. Birth

The Registry is born empty and filled only by acts.

1. **The schema creates tables, rules and functions, never rows.**
2. **The Foundation Act** runs once, on an empty Registry, and is act number 1. Nobody may perform it: it has no action type. It recognizes the minimum for someone to hold authority, and then closes forever:
   - the four type roots;
   - the contract types that define an office and a mandate;
   - the entity type *person*;
   - the action types its founder needs;
   - an office and its powers;
   - the founder, the founder's mandate, and the founder's admission (SPEC-03).
3. The Foundation Act is refused if it would leave its founder holding no authority.
4. **Everything else** (other types, entities, objects, versions, contracts) is recognized afterwards through the API, one act at a time.

No entity, object or contract is ever created by a seed.

# 7. The institutional API

The API is the only door. Every table denies everything; only the API's functions reach them. Every write follows one path:

```text
key → entity (and the person it acts for) → may? → the operation → the act
```

| **operation**                                | **requires**                                     |
|----------------------------------------------|--------------------------------------------------|
| recognize a contract, or a new generation    | `recognize-contract` on the contract's name      |
| retire a contract, entity or object          | `recognize-contract` on its name                 |
| inscribe an entity or an object              | `inscribe` on its name                           |
| recognize a version                          | `publish` on the object                          |
| give powers (a permission or a mandate)      | also `grant` on the subject, and the powers given |
| admit a person                               | `admit-person` on the person                     |
| store content                                | `store-content` on its digest                    |
| read content                                 | `read-content` on a version, contract or act that references it |
| who am I, may I, verify the acts             | any valid key                                    |

A refused operation leaves no trace. Storing content that is already stored changes nothing and records no act.

# 8. The act log

Every successful write appends one act.

| **field**   | **meaning**                                                                          |
|-------------|--------------------------------------------------------------------------------------|
| sequence    | strictly increasing, from 1; the act's name is `powerfarm.app/act/<sequence>`         |
| at          | the time of the act, in milliseconds                                                  |
| actor       | the entity that acted                                                                 |
| on behalf   | the person it acted for, if any                                                       |
| action      | the action type; empty only for act 1                                                 |
| target      | the name of the thing acted on                                                        |
| content     | the SHA-256 of the act's **payload**: the operation and its terms, kept in the Content Store |
| previous    | the hash of the previous act; empty only for act 1                                    |
| hash        | this act's hash, computed by the database                                             |

The hash is the SHA-256 of one field per line, in UTF-8:

```text
powerfarm.act.v1
<sequence>
<at, UTC, YYYY-MM-DDTHH:MM:SS.mmmZ>
<actor>
<on behalf, or empty>
<action, or empty>
<target>
<content>
<previous, or empty>
```

Anyone can recompute it from an export of the log.

> **The log is the story**
>
> Acts are never edited or removed; a correction is a new act. The chain verifies from act 1 to the last act. Replaying the acts in order, over the preserved content, into an empty Registry reproduces the same Registry, act for act and hash for hash.

A replayed act is the same operation, by the same actor, at the same time, checked by the same rules. It must arrive in order and reproduce its recorded hash, or the replay stops. Keys are not acts: after a replay, each person signs in again (SPEC-03).

# 9. Immutability

States are `recognized`, `superseded` and `retired`. Recognizing a new generation or version never deletes the previous one.

These never change after recognition:

- names;
- a version's content digest and source;
- a contract generation's number, type, participants, held contract and document digest;
- who recognized something, and when.

Lifecycle fields (superseded at/by, retired at, reason) are set once, by an act. The database MUST make any other change impossible, for the database owner too, and MUST refuse to delete or truncate recognized rows.

# 10. Stores, Search and projections

- A store is an object of type `store`. A store-authority contract names its owner and what it is authoritative for. No separate store table exists.
- Search MAY query the Registry for what is recognized. It MUST NOT infer authority from the presence of data or from its own index.
- Every copy, cache or projection of the Registry can be rebuilt from it and never becomes authority.

# 11. Security properties

A conforming Registry enforces at least:

- authenticated writes, all through the API;
- explicit authority for every recognition, retirement and gift of powers;
- digest verification before recognizing a contract document;
- no secret values in any row or non-private document;
- least privilege on administrative paths (the Foundation Act and replay are not available to ordinary keys);
- every write recorded as an act.

# 12. Conformance

A conforming implementation demonstrates that:

1. the schema creates no rows, and a second Foundation Act fails;
2. a Foundation Act that leaves nobody holding authority is refused;
3. every operation refuses an entity without authority, and a refused write leaves no act;
4. every type column references a current contract, and a type disappears when its contract is retired;
5. `may()` changes the moment a contract generation changes, for every holder of an office at once;
6. permissions respect their effective interval and retirement, and never widen authority;
7. an agent acting for a person never exceeds that person;
8. versions are exact and historically addressable, and stored bytes are not recognition;
9. recognized facts cannot be changed or deleted, even by the database owner;
10. the act chain recomputes outside the database, and a change to history is detected;
11. replaying the log into an empty Registry reproduces every recognized row, the chain head, and the same `may()` answers;
12. no projection can become authority by indexing Registry data.

# 13. On the current provider

| **part**                                       | **where**                                                                                                  |
|------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| Registry, act log, Content Store catalog, Identity tables | PostgreSQL schemas `registry`, `acts`, `content`, `identity`, on the Supabase project of `powerfarm.app/store/company` |
| the API                                        | functions in the `api` schema; the caller is resolved from the verified token's claims (`request.jwt.claims`) |
| the schema                                     | `supabase/migrations` in `powerfarm/minivault`, each migration sealed by hash in `supabase/migrations.lock` |
| conformance                                    | `test/registry.test.ts` in `powerfarm/minivault`, run on embedded PostgreSQL and on PostgreSQL 17           |

Every part has a portable equivalent: any PostgreSQL, any OIDC provider.

# 14. Change rule

A change to this specification changes the schema and its conformance tests in the same step, or states which slice will. A new basic requires evidence that entities, objects, versions and contracts cannot faithfully represent the relationship, and a change to PF-03 first.

> **Registry**
>
> The Registry stays deliberately smaller than the systems it describes.
