**POWERFARM SPECIFICATION**

Names and Addresses

How Powerfarm names what it recognizes, the bytes it keeps, and the services people connect to

| **DOCUMENT**       | SPEC-02                                                                 |
|--------------------|-------------------------------------------------------------------------|
| **STATUS**         | **ADOPTED**                                                             |
| **VERSION**        | 1.0                                                                     |
| **EFFECTIVE**      | 27 September 2026                                                       |
| **IMPLEMENTATION** | `registry.is_name` in `powerfarm/minivault`; `schemas/common.schema.json` |

| **OWNS**         | The form of every Powerfarm name: things, contracts, versions, acts, bytes and hostnames. The rules that keep names stable, and the list of Powerfarm's services. |
|------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **DOES NOT OWN** | What a thing is or who may act on it (SPEC-01), how bytes are stored and resolved (SPEC-03), or which types exist (they are contracts, recognized in the story, SPEC-11). |

> **One name per thing**
>
> The name is the identity, the address and the link, and it says Powerfarm in full.
>
> MUST means required. SHOULD means the default, and a material deviation needs a reason. MAY means optional.

# 1. Three kinds of names

| **kind**                               | **form**                        | **example**                  |
|----------------------------------------|---------------------------------|------------------------------|
| **Things and contracts** Powerfarm recognizes | `powerfarm.app/<type>/<name>` | `powerfarm.app/agent/lab-8gb` |
| **Bytes**                              | `sha256:<hex>`                  | `sha256:9f2c…` (64 hex digits) |
| **Services** people connect to         | `<service>.powerfarm.app`       | `id.powerfarm.app`           |

A name says *what*. A digest says *exactly which bytes*. A version binds the two.

# 2. Principles

| **Principle**              | **Operating meaning**                                                                                         |
|----------------------------|---------------------------------------------------------------------------------------------------------------|
| What, never where          | A name never carries a provider, a machine, a storage location or a technology.                              |
| Forever                    | A name is never reused and never changed.                                                                     |
| One namespace              | Entities and objects share one space of names; contracts have their own family under `/contract/`.            |
| Stored bare                | Names are stored without a scheme. Putting `https://` in front resolves them.                                 |
| Bindings, not names        | Provider identities are bound to names; they never become names.                                              |
| Public hosts, private paths | A hostname is public the moment it has a certificate. What lives under a path is not listed.                 |

# 3. Things and contracts

## 3.1 Grammar

```text
name     = "powerfarm.app/" type "/" local [ "@" version ]
type     = [a-z][a-z0-9-]{0,39}
local    = [a-z0-9] ( [a-z0-9.-]{0,98} [a-z0-9] )?     no "..", no "--"
version  = [a-z0-9][a-z0-9.+-]{0,39}
```

- Always exactly two path segments after the host. Hierarchy inside a name uses dots: `intake.review`, `mandate.director.<holder>`.
- Lowercase ASCII only, so there is never a case question.
- No trailing slash, no query string, no fragment.
- `https://powerfarm.app/<type>/<name>` **resolves** the name: the answer is the thing's card, or "not allowed" when the Registry says the caller may not view it.

## 3.2 The type segment

Every entity and object lives under the type its contract defines. The type segment is the name of that contract:

```text
powerfarm.app/person/<holder>         type defined at powerfarm.app/contract/person
powerfarm.app/agent/lab-8gb           …at powerfarm.app/contract/agent
powerfarm.app/machine/lab-8gb         …at powerfarm.app/contract/machine
powerfarm.app/store/company           …at powerfarm.app/contract/store
powerfarm.app/program/intake.review   a Minivault item; "program" is an object type
powerfarm.app/document/pf-03@1.5      a canon document at an exact version
```

Asking "what is a person?" means opening `powerfarm.app/contract/person`.

## 3.3 Contracts

Contracts define the types, so they form one family under `/contract/`:

```text
powerfarm.app/contract/contract-type        the first contract; its type is itself
powerfarm.app/contract/entity-type          the second
powerfarm.app/contract/person               defines the entity type "person"
powerfarm.app/contract/program              defines the object type "program"
powerfarm.app/contract/director             the Director's office
powerfarm.app/contract/mandate.director.<holder>
powerfarm.app/contract/entity-type@2        a generation
```

- `@<n>` after a contract names one generation. Without it, the name means the current generation.
- A type name is unique across all families (contract, entity, object and action types), because each is one contract.
- `contract`, `act` and `content` name other families and are never types of entities or objects.
- By convention a mandate is named after its office and holder: `mandate.<office>.<holder>`. The convention helps readers; the Registry relies on the contract's `holds` field, not on the name.

## 3.4 Acts and versions

- Every act in the act log is `powerfarm.app/act/<sequence>`, resolvable for receipts and links.
- A version of an object is its name with `@<version>`: `powerfarm.app/program/intake.review@3`.

# 4. Names are forever

1. A name is never reused, even after the thing or contract is retired.
2. A name is never changed. When a thing truly needs a different name, it becomes a new thing, and the old one is retired with a pointer to the new one.
3. Replacing a provider, machine or technology never renames anything.

> **What, never where**
>
> The Identity substrate is `powerfarm.app/store/company`, whichever provider hosts it.

# 5. People and provider identities

- The first person's name is chosen at the Foundation Act and is not recorded in public documents.
- A person's e-mail MAY match their name by convention (`<name>@powerfarm.app`). The e-mail stays a login key in Identity, never the identity (SPEC-03).
- Provider identities (a Supabase user, Apple, GitHub, a machine credential, an OAuth subject) are **bindings** to entities. They are never names.

# 6. Bytes

- Exact bytes are named by their SHA-256 digest: `sha256:` and 64 lowercase hex digits. SHA-256 is Powerfarm's one fingerprint.
- A digest identifies content. It is **not a capability**: knowing it gives no right to read it.
- Content resolves through the API at `powerfarm.app/content/sha256:<hex>`, subject to the Registry (SPEC-03).

# 7. Services

## 7.1 Rules

1. **A subdomain exists only for something you connect to**: a running service with an owner entity and a contract. People, contracts, documents and machines never get subdomains.
2. **One word, lowercase, naming the role.** Never a provider, a machine or a technology.
3. **Each service is itself an entity** (`powerfarm.app/service/<x>` or `powerfarm.app/app/<x>`), and its contract names its hostname.
4. **Previews** use `<service>-preview.powerfarm.app`.
5. **`powerfarm.app` is first-party only.** Generated or untrusted apps never live under it, so they can never read Powerfarm's login cookies. They get a separate domain.
6. **One passkey for all of Powerfarm:** the WebAuthn relying-party ID is `powerfarm.app`, so a passkey made at `id.powerfarm.app` works on every Powerfarm service.

## 7.2 The services

| **hostname**           | **what it is**                                                                                | **entity**                          |
|------------------------|-----------------------------------------------------------------------------------------------|-------------------------------------|
| `powerfarm.app`        | the front door and name resolver: every `powerfarm.app/<type>/<name>` opens here              | `powerfarm.app/service/registry`    |
| `id.powerfarm.app`     | Identity: sign-in, the OAuth 2.1 issuer, consent                                              | `powerfarm.app/service/identity`    |
| `api.powerfarm.app`    | the institutional API: Registry, Content Store and Minivault functions, the only door          | `powerfarm.app/service/api`         |
| `vault.powerfarm.app`  | Minivault web: the human and LLM view, a projection                                           | `powerfarm.app/app/minivault-web`   |
| `places.powerfarm.app` | Coloured Places                                                                               | `powerfarm.app/app/coloured-places` |
| `mcp.powerfarm.app`    | the MCP door for ChatGPT and Claude; closed until Identity issues audience-bound tokens (SPEC-03) | `powerfarm.app/service/mcp`     |
| `search.powerfarm.app` | Search (SPEC-10); not yet running                                                             | `powerfarm.app/service/search`      |

A hostname not in this table has no place in Powerfarm.

# 8. Types in use

The types below are contracts recognized in the story (SPEC-11). This document fixes only their names.

| **family**     | **names**                                                                                                                  |
|----------------|----------------------------------------------------------------------------------------------------------------------------|
| entity types   | `person`, `agent`, `app`, `service`, `host-runner`, `engine`, `mcp`                                                         |
| object types   | `sector`, `machine`, `process`, `store`, `repository`, `secret`, `search-source`, `projection`                              |
| object types with versions | `document`, `software`, `schema`, `dataset`, `prompt`, `capability`, `execution-bundle`, `migration-evidence`; Minivault's `program`, `component`, `knowledge`, `idea`, `decision`, `trajectory`, `unknown` |
| contract types | the roots `contract-type`, `entity-type`, `object-type`, `action-type`; then `office`, `mandate`, `permission`, `app-contract`, `engine-capability`, `store-authority`, `search-contract`, `machine-placement`, `secret-consumer`, `execution-approval`, `backup-custody` |
| action types   | `view`, `converse`, `propose`, `publish`, `release`, `approve`, `admit-person`, `recognize-contract`, `inscribe`, `grant`, `store-content`, `read-content`, `write-observation` |

Minivault's old kinds map as follows: `contract` becomes the object type `schema`; `repository` is the object type `repository`; `identity` and `authority` are entities and contracts, not types.

# 9. Conformance

A conforming implementation demonstrates that:

1. every stored name matches the grammar of §3.1, and names outside it are refused;
2. a thing's type is the type segment of its name, and the reserved segments are never types;
3. a retired name is never recognized again;
4. no name contains a scheme, a provider, a machine or a storage location;
5. every digest is `sha256:` and 64 lowercase hex digits;
6. every hostname in use appears in §7.2 and belongs to an entity whose contract names it.

# 10. On the current provider

| **part**            | **where**                                                                                  |
|---------------------|--------------------------------------------------------------------------------------------|
| the name grammar    | `registry.is_name` in the Registry migration (SPEC-01) and `thingId` / `contractId` in `schemas/common.schema.json` |
| hostnames           | DNS for `powerfarm.app`; each hostname points to the service its contract names             |

# 11. Change rule

Names are forever, so this document changes by adding, never by renaming. A new service needs a row in §7.2 and a contract that names its hostname. A change to the grammar needs evidence that no recognized name is affected.

> **Names**
>
> A name says what. A digest says exactly which bytes. A version binds the two.
