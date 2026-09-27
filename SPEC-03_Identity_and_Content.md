**POWERFARM SPECIFICATION**

Identity and Content

How keys reach entities, how people and agents sign in, how exact bytes are kept, and how secrets stay out of everything

| **DOCUMENT**       | SPEC-03                                                                                      |
|--------------------|----------------------------------------------------------------------------------------------|
| **STATUS**         | **ADOPTED**                                                                                  |
| **VERSION**        | 1.0                                                                                          |
| **EFFECTIVE**      | 27 September 2026                                                                            |
| **IMPLEMENTATION** | `powerfarm/minivault`, `supabase/migrations`: admissions, bindings, the content catalog. Acceptances, the gates and the bucket follow in slices S8b, S6 and S9 |

| **OWNS**         | The keyring (bindings, admissions, acceptances), sign-in and its gates, OAuth clients and machine credentials, the Content Store (content, manifests, storing, reading, integrity, custody), the digest procedure and content references, and secret references. |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **DOES NOT OWN** | Who exists and who may act (SPEC-01), the form of names and digests (SPEC-02), what Minivault items mean (SPEC-04), where the copies live and how Powerfarm is rebuilt from them (SPEC-11). Canon: PF-03 §§3.4, 3.5; PF-04 §1.4. |

> **A key is not an identity**
>
> The list of people and agents is the Registry's entities. A login, a machine credential or an OAuth client is a key bound to exactly one entity, never a second list.
>
> MUST means required. SHOULD means the default, and a material deviation needs a reason. MAY means optional.

# 1. Purpose

Identity turns a request into an entity. The Content Store keeps exact bytes. Both serve the Registry and neither decides anything the Registry decides: holding a key grants nothing, and holding a digest reads nothing.

# 2. Principles

| **Principle**                  | **Operating meaning**                                                                                              |
|--------------------------------|--------------------------------------------------------------------------------------------------------------------|
| One list of people and agents  | The entities. Accounts, credentials and clients are keys bound to them.                                            |
| Contact data stays in Identity | E-mail and other contact data never enter the Registry.                                                            |
| Passwordless                   | People sign in with an e-mail link or a passkey. One passkey works for every Powerfarm service.                     |
| Keys grant nothing             | Authority is computed from contracts at every request (SPEC-01 §5).                                                |
| Bytes never change             | Content is named by its SHA-256, never overwritten and never deleted by an ordinary path.                          |
| A digest is not a capability   | Reading content needs the right to read something that references it.                                             |
| Storing is not recognizing     | Content means nothing institutionally until the Registry recognizes it as a version or a contract document.        |
| Secrets are references         | The Registry and the Content Store hold references to secrets, never their values.                                 |

# 3. The keyring

| **table**    | **meaning**                                                                                         |
|--------------|-----------------------------------------------------------------------------------------------------|
| bindings     | key → entity: a login account, a machine credential or an OAuth client, each bound to one entity    |
| admissions   | an invited e-mail → the person it admits, who admitted them, until when, and when it was used      |
| acceptances  | who accepted which generation of which contract, and when, with the digest of the receipt           |

Rules:

1. Every key is bound to exactly one entity. A person has one login account.
2. **Admitting a person is an act** (`admit-person`, SPEC-01 §7). The admission names the person and the e-mail.
3. **Binding a key is not an act.** Keys are rebuilt by signing in again, never replayed (SPEC-11).
4. Objects hold no keys: only entities act.
5. When a login account is deleted, the person remains in the Registry with its history, without a key, until admitted again.

## 3.1 Acceptance

Persons accept their Entity Type contract and every mandate they hold. Each acceptance receipt is content in the Content Store.

- A new generation that only adds rights takes effect without new acceptance.
- A new generation that adds duties requires acceptance again. Until then, the person holds no authority under it.
- The machine decides which case applies by comparing the two generations.

# 4. Sign-in and the gates

People sign in at `id.powerfarm.app`, passwordless: an e-mail link or a passkey. The passkey relying-party ID is `powerfarm.app` (SPEC-02 §7.1).

The gates run inside Identity, before a key is created or a token is issued:

| **situation**                                                                   | **result**                                                         |
|---------------------------------------------------------------------------------|--------------------------------------------------------------------|
| sign-up without a valid, unused admission                                       | refused before the account exists                                  |
| sign-up with an admission                                                       | the account is born bound to the admitted person; the admission is used |
| a person without a current Entity Type contract, or with an overdue acceptance  | no new access token is issued, and the API denies everything       |
| a retired person                                                                | the account is blocked and open sessions are revoked               |

# 5. Apps and agents

Identity is the authorization server for everything Powerfarm runs.

- **Apps.** Each app is an entity of type `app`. Its OAuth clients are keys bound to that entity.
- **Agents.** Each agent has its own machine credential, bound to its agent entity.
- **An agent acting for a person** presents the person's subject and its own client. The API resolves both: the actor is the agent, and it acts on behalf of the person. It never exceeds the person (SPEC-01 §5).
- **Scopes are not authority.** Tokens carry only standard scopes. What an agent may do is what its contracts give it, computed at request time.

> **The MCP door**
>
> ChatGPT and Claude connect through MCP, always for a person. The door at `mcp.powerfarm.app` stays closed until Identity issues audience-bound tokens and supports public clients (§12). Human sign-in does not depend on it.

# 6. The Content Store

The Content Store answers one question: *given this digest, what are the exact bytes?*

| **term**     | **meaning**                                                                                                     |
|--------------|-----------------------------------------------------------------------------------------------------------------|
| content      | exact bytes, named `sha256:<hex>` (SPEC-02 §6)                                                                  |
| catalog      | for each piece of content: digest, size, media type, stored at, stored by                                       |
| manifest     | JSON listing other content (`{path, digest, size}`); software trees, evidence sets and releases are manifests   |

## 6.1 Storing

1. The caller sends bytes. The API computes SHA-256 itself and records the content under that digest. A digest supplied by the caller must match or the store is refused.
2. **Storing is an act** (`store-content`, SPEC-01 §7). Storing bytes that are already stored changes nothing and records no act.
3. Content is **insert only**: it is never updated, overwritten or deleted by an ordinary path.
4. Bytes the Registry must read (contract documents and act payloads) are also held in the database, where a constraint checks them against their digest. Larger bytes live only in the bucket.

## 6.2 Reading

A digest is not a capability. The API returns content only when the caller may `read-content` on something that references it: a version, a contract, or an act. Public content is content referenced by a released version.

## 6.3 Integrity

- The bucket allows insert only: no update, no delete.
- The storage provider does not verify digests, so the API computes them before recording content.
- A periodic sweep re-hashes stored content and reports any mismatch.

## 6.4 Custody

- Promoted immutable bytes are addressable and independently verifiable.
- Material company bytes have off-machine custody.
- Backup is independent of synchronization.
- A claim of redundancy requires a distinct failure domain.

The copies that satisfy these rules are listed in SPEC-11.

# 7. Contract representation and digests

## 7.1 JSON data model

The machine data model of every Powerfarm contract is JSON. YAML MAY be used to author a contract if it parses losslessly into the JSON value its schema accepts; YAML-only scalar types are not conforming values. Authors SHOULD quote timestamps, numeric-looking revisions and other scalars YAML might retype.

Schemas use **JSON Schema Draft 2020-12**. Schema validation establishes structure only. Cross-object rules, authority, uniqueness and runtime behavior need the semantic checks each specification defines.

## 7.2 The digest procedure

When a contract needs a digest, an implementation MUST:

1. parse the authoring representation into the JSON data model;
2. validate it against its schema;
3. canonicalize the JSON value with RFC 8785 (JSON Canonicalization Scheme);
4. compute SHA-256 over the canonical UTF-8 bytes;
5. write the result as `sha256:<lowercase-hex>`.

Values MUST be representable under RFC 8785. Schemas SHOULD use strings for identifiers and exact quantities, so number normalization cannot change their meaning. A digest is never a field of the value it digests; the Registry records it.

## 7.3 Content references

A `ContentRef` follows the core of an OCI content descriptor, without requiring the content to live in an OCI registry:

```json
{
  "digest": "sha256:...",
  "mediaType": "application/json",
  "size": 18293
}
```

`digest` establishes material identity; `mediaType` and `size` describe it and help verify a transfer. Every `ContentRef` uses SHA-256. Knowing a `ContentRef` is not permission to resolve it.

# 8. Secrets

The Registry stores **secret references**, never values. A reference is an object of type `secret`; a `secret-consumer` contract declares who may use it. A reference records:

- its owner, and the provider or system that holds the value;
- its allowed consumers;
- where the value is stored (a reference, never the value);
- its rotation policy and revocation path;
- when it was last verified;
- its state: active, rotating or revoked.

Live secret values MUST NOT enter Git, Registry rows, the Content Store, receipts, Search or any other projection.

> **Secrets are issued, never restored**
>
> Rotation precedes deletion when exposure is possible. A rebuild never restores secret values: it issues new ones, in the recorded order, and binds them to the same references (SPEC-11).

# 9. Security properties

A conforming implementation enforces at least:

- no key without an entity, and no entity with a second list of keys elsewhere;
- sign-up only through a valid, unused admission;
- digests computed by the server, never trusted from the caller;
- insert-only storage for content;
- reads of content only through something the caller may read;
- no secret value in any row, document, receipt, log or projection.

# 10. Conformance

A conforming implementation demonstrates that:

1. sign-up without an admission is refused, and an admission is used once;
2. every key resolves to exactly one entity, and an unbound key is refused;
3. an object cannot hold a key;
4. an agent acting for a person is resolved as that agent, on that person's behalf;
5. a retired person cannot obtain a token;
6. stored content re-hashes to its name, and bytes that do not match a supplied digest are refused;
7. storing the same bytes twice records one piece of content and no second act;
8. content that nothing readable references cannot be read;
9. content exists without recognition until a version or contract refers to it;
10. a contract's digest is reproducible from its JSON value by the procedure of §7.2.

# 11. On the current provider

| **part**                     | **where**                                                                                                                 |
|------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| keyring and content catalog  | PostgreSQL schemas `identity` and `content`, on the Supabase project of `powerfarm.app/store/company` (SPEC-01 §13)        |
| sign-in                      | Supabase Auth: e-mail link and passkeys; the Auth user table is only a keyring                                             |
| the gates                    | Supabase Auth hooks written as Postgres functions: *Before User Created* (admission) and *Custom Access Token* (current contract, acceptance) |
| OAuth                        | the Supabase OAuth 2.1 server                                                                                              |
| content bytes                | a private Supabase Storage bucket, insert only; the key is the digest                                                      |
| integrity sweep              | a scheduled job (`pg_cron`)                                                                                                |

Auth settings of the project:

| **setting**                        | **value**                                                                                       |
|------------------------------------|-------------------------------------------------------------------------------------------------|
| Site URL                           | `https://id.powerfarm.app`                                                                      |
| Redirect URLs                      | `https://id.powerfarm.app/**`, `https://vault.powerfarm.app/**`, `https://places.powerfarm.app/**`; one per service in SPEC-02 §7.2, never a wildcard host |
| Passkeys: relying party            | ID `powerfarm.app`; origin `https://id.powerfarm.app`; display name `Powerfarm`                  |
| OAuth server                       | enabled; consent at `https://id.powerfarm.app/oauth/consent`                                    |
| Dynamic OAuth apps                 | enabled, so apps' clients are provisioned by script. A client registered this way is refused by the API until its key is bound to an app entity (§5) |
| Auth hooks                         | *Before User Created* and *Custom Access Token*, added after the Registry migration is applied; never before, or they refuse every sign-up |

# 12. Current limits

- The Supabase OAuth 2.1 server is in beta.
- It ignores the `resource` parameter, so tokens are not audience-bound (RFC 8707), which MCP requires.
- It blocks MCP connectors that use public clients or `offline_access` (`supabase/auth#2820`).
- It offers Dynamic Client Registration, not Client ID Metadata Documents.
- Its HTTP hooks have an error-format defect, so the gates are Postgres functions.

When these lift, or an OAuth bridge is adopted in front of Identity, the MCP door opens with no change to this specification.

# 13. Change rule

A change to the keyring, the gates or the Content Store changes its migration and conformance tests in the same step, or names the slice that will. A change to the digest procedure changes every digest and needs a change to PF-04 first.

> **Keys and bytes**
>
> A key says who is asking. A digest says which bytes. Neither says what is allowed.
