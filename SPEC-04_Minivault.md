**POWERFARM SPECIFICATION**

Minivault

How Powerfarm keeps what its promoted things mean: typed, immutable, related revisions that people and agents read and change through one kernel

| **DOCUMENT**       | SPEC-04                                                                                                   |
|--------------------|-----------------------------------------------------------------------------------------------------------|
| **STATUS**         | **ADOPTED**                                                                                               |
| **VERSION**        | 1.0                                                                                                       |
| **EFFECTIVE**      | 27 September 2026                                                                                         |
| **IMPLEMENTATION** | `powerfarm/minivault`, `src/kernel`. The Registry becomes its authority in slice S4, undo becomes a new publication in S5b, and kinds become Object Type contracts in S7 |

| **OWNS**         | What a Minivault item means: the envelope, kinds and their rules, canonical bytes and revision ids, relations, the admission pipeline, the operations that change items, review of effect changes, and the kernel's reasoning (explain, diff, impact, compatibility, composition, lint, search). |
|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **DOES NOT OWN** | Who exists and who may act (SPEC-01), the form of names (SPEC-02), where bytes are kept (SPEC-03), or execution: a program's meaning is not its runtime (SPEC-06). Canon: PF-03 §3.5; PF-04 §§1.1–1.5. |

> **Meaning and authority**
>
> The Registry decides who exists and who may act. Minivault decides what things mean.
>
> MUST means required. SHOULD means the default, and a material deviation needs a reason. MAY means optional.

# 1. Purpose

Minivault is Powerfarm's machine-native world model for promoted things: programs, components, capabilities, schemas, knowledge, ideas, decisions, trajectories and open questions. Each is a typed object whose revisions are immutable, content-addressed and related to one another.

Agents read and change it through typed operations, never by editing text files. People read a projection of the same objects. Source code, when it exists, is an implementation or an export; it is not the identity of the software.

# 2. Principles

| **Principle**                               | **Operating meaning**                                                                                               |
|---------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| One semantic world                          | Every interface (MCP, web, HTTP, workers) reads and changes the same objects through the same kernel.               |
| Canonical bytes are immutable               | A revision's bytes never change. A change is a new revision.                                                         |
| Same meaning, same id                       | Identical semantic bytes have the same revision id; presentation never creates a revision.                          |
| History lives beside the bytes              | Who, when, derived from and supersedes are recorded on the revision, never hashed into it.                          |
| Relations are first-class                   | A relation lives on its source object, points at a revision id, and is derived from the object's pins.              |
| One pipeline                                | Every path that stores an object runs the same admission and validation.                                             |
| The kernel is the only writer               | Nothing else writes canonical bytes, relations or the relation index.                                               |
| Projections are not truth                   | Markdown, web pages and caches are regenerated from bytes, never edited into them.                                  |
| Evidence informs, never authorizes          | Evidence ranks and explains; it does not change what anyone may do.                                                  |

# 3. Items and revisions

## 3.1 Under the Registry

| **Minivault**         | **Registry (SPEC-01)**                                                                        |
|-----------------------|-----------------------------------------------------------------------------------------------|
| an item               | an **object** of a type with versions: `powerfarm.app/<kind>/<name>` (SPEC-02)                |
| a kind                | an **Object Type** contract whose document holds the kind's JSON Schema and names its validator |
| a revision id         | `sha256:` of the canonical bytes, the same fingerprint as all content (SPEC-03)              |
| canonical bytes       | content in the Content Store                                                                  |
| publishing            | recognizing a **version**, which supersedes the current one                                   |
| who may do it         | `may()` in the Registry, for every operation (§7)                                             |

Adding a kind is recognizing one contract; it needs no deploy.

## 3.2 Four layers

| **layer**              | **in the revision id** | **mutable** | **holds**                                                                        |
|------------------------|------------------------|-------------|----------------------------------------------------------------------------------|
| semantic bytes         | yes                    | never       | schema version, kind, name, summary, semantics, relations pinned to revision ids  |
| revision record        | no                     | never       | item, revision id, created by and at, derived from, supersedes, kernel version     |
| lifecycle              | no                     | by acts     | the current version, deprecation, retirement, release                             |
| projection             | no                     | freely      | layout, collapsed sections, rendered markdown                                     |

## 3.3 The envelope

```json
{
  "schema_version": "minivault.<kind>.v1",
  "kind": "<kind>",
  "metadata": { "name": "…", "summary": "…" },
  "semantics": { },
  "relations": [ { "relation": "…", "target": "sha256:…" } ]
}
```

`schema_version` and `kind` MUST agree, and a kind never changes after creation. The media type of a kind is `application/vnd.powerfarm.minivault.<kind>.v1+json`.

# 4. Admission

Every object passes one pipeline before it is stored:

```text
parse → NFC strings → strip non-semantic fields → refuse what JCS cannot hash stably
      → JSON Schema of the kind → the kind's invariants → RFC 8785 → SHA-256 → store
```

- **Refused without storing:** duplicate keys; NaN, infinities and negative zero; integers outside the IEEE-754 safe range; fractional numbers outside a schema's own numbers; detected credentials.
- **Stored but invalid:** an object whose bytes are safe but which fails its schema or invariants is a draft marked invalid. It is never indexed, published or made current.
- **Limits:** canonical size and node count are bounded; schemas are checked for catastrophic regular expressions before they compile.
- **Idempotent:** a revision id that exists must already hold the same bytes.

# 5. Kinds

| **kind**     | **what it is**                                                                                     |
|--------------|----------------------------------------------------------------------------------------------------|
| `schema`     | a typed boundary: what is accepted, produced, guaranteed or refused; it embeds a JSON Schema that MUST compile |
| `capability` | something the environment knows how to do: an input schema and an output schema                   |
| `component`  | a reusable unit that implements one capability, with its effect class                              |
| `program`    | a graph of paths through state: inputs, component calls, policies, waits and external effects     |
| `knowledge`  | something Powerfarm knows, with its sources                                                        |
| `idea`       | something Powerfarm might do, and why                                                              |
| `decision`   | something Powerfarm decided, under which authority and on what evidence                            |
| `trajectory` | how a thing changed over time, and toward what                                                    |
| `unknown`    | an open question: what is asked, why it matters, the evidence that would answer it, its resolution |

People, agents, authorities and repositories are not kinds: they are Registry entities, objects and contracts, and an item refers to them by name.

## 5.1 Programs

A program is a directed acyclic graph. Its rules make its effects legible:

1. Every path from an input to a `write` or `external` effect passes through an earlier **policy** node, and each exit of a policy is guarded by `decision == "allow"`.
2. A policy calls a component whose output declares `decision` with `"allow"`, and MAY cite an authority.
3. A guard is `eq` or `in`, reads its edge's source, and is type-checked against that source's output schema.
4. Directly connected component calls have compatible schemas.
5. A component call pins its component and capability; the capability pin equals the component's.
6. An external effect names its effect class and binds no resource.

These are structural guarantees about meaning. They are not runtime authorization: at run time, authority is `may()` (SPEC-01).

## 5.2 Relations

| **relation**  | **from**              | **to**      |
|---------------|-----------------------|-------------|
| `accepts`     | capability, component | schema      |
| `produces`    | capability, component | schema      |
| `implements`  | component             | capability  |
| `calls`       | program               | component   |

The Minivault kinds add their own relations to the items they cite. Rules:

- A relation is stored on its source only; its target is a revision id.
- After every change, relations are recomputed from the object's pins. An object imported as raw bytes must carry exactly those relations.
- Inverse relations are index queries. The index is derived from canonical bytes, in the same transaction, and has no other writer.
- The absence of a relation is not compatibility.

# 6. Changing items

## 6.1 Operations

A change never edits a published object. It returns a new revision id:

- **create** applies operations with no base; **derive** applies them to a base revision and records the derivation.
- **Primitives:** `put_metadata`, `put_semantics`, `add_relation`, `remove_relation`, `add_node`, `remove_node`, `set_node`, `connect`, `disconnect`, `set_guard`.
- **Intents:** larger, named steps built from primitives, such as `insert_between`, `gate_behind_policy`, `swap_component` and `rename`.
- Validation runs once on the result of the whole list. A result equal to its base records nothing.

## 6.2 Publication and after

| **act**      | **what happens**                                                                                                   |
|--------------|--------------------------------------------------------------------------------------------------------------------|
| publish      | the kernel revalidates the revision; the Registry recognizes it as the new version, naming the version it expects to replace, and the current one is superseded |
| undo         | the earlier bytes are published again as a **new** version, naming the version they restore and the reason; history only moves forward |
| deprecate    | a reversible flag on the item; it stays readable                                                                   |
| retire       | the object is retired in the Registry; final                                                                        |
| release      | anyone may read that version                                                                                         |

Every derivation of the published bytes is recorded as `derived_from`; publication never picks one parent and hides the others.

# 7. Who may do what

Minivault asks the Registry `may(entity, action, resource)` for every operation, with the item as the resource. Only `true` passes.

| **operation**                          | **action type**                               |
|----------------------------------------|-----------------------------------------------|
| read an item or revision               | `read-content`                                |
| draft, propose a revision              | `propose`                                     |
| publish                                | `publish`, plus an approval when effects change |
| review a proposal                      | `approve`                                     |
| make a version public                  | `release`                                     |
| change who may act on an item          | `grant`                                       |

> **Effects need a second person**
>
> A change to an item's **effect surface** (its effect nodes and everything upstream of them, including their gates and the components feeding them) needs an approved proposal before it is published. The approval is bound to the exact revision by digest. Authors never review their own proposals, and agents never approve effect changes.

An agent acting for a person never exceeds that person. When an engineer may publish without asking is decided per operation class by the autonomy matrix of the Engineer office (SPEC-01 §5).

Non-readers receive an answer indistinguishable from "not found". Only declared pins resolve, so hash-shaped text inside data is inert.

# 8. What stays inside Minivault

Drafts, proposals and reviews, the relation index, derivations, subscriptions and projections are Minivault's operational state. None of it is institutional until a publication is recognized.

# 9. Interfaces

| **interface**    | **for**      | **what it offers**                                                                                                  |
|------------------|--------------|---------------------------------------------------------------------------------------------------------------------|
| MCP              | agents       | search, inspect, get, apply, validate, propose, proposals, review, publish, revert, history, diff, impact, propose upgrade, compose, lint, subscribe, notifications, guide; machine structure by default, with progressive disclosure: search, then inspect, then get |
| web              | people       | `vault.powerfarm.app` (SPEC-02): item pages with graphs, diffs and history, the review queue, an editor whose every gesture is one operation |
| HTTP             | services     | the same operations as the API; item pages resolve at the item's name                                               |
| workers          | maintenance  | stale pins, upgrade drafts, lint findings; **automation proposes and never publishes**                              |

A human projection is a pure function from revision bytes to Markdown. Editing it never creates a revision.

# 10. Reasoning

The kernel reasons about meaning without storing anything:

- **explain** an object or a change in plain language;
- **diff** two revisions semantically: nodes, edges, guards, effect classes, pins, relations and paths added or removed;
- **impact**: which consumers a revision affects, and which pins are stale;
- **compatibility** of two schemas: compatible, incompatible or unknown;
- **compose** capabilities into a candidate program;
- **lint** knowledge for gaps and contradictions;
- **search** by structure, text and typo-tolerant similarity. Evidence informs ranking only.

# 11. Conformance

A conforming implementation demonstrates that:

1. objects that differ only in key order or whitespace share a revision id, and a change of summary changes it;
2. official SHA-256 vectors pass, and revision ids equal an independent SHA-256 of the canonical bytes;
3. refused inputs are never stored, and invalid drafts are never published;
4. a publication with a stale expected version conflicts and changes nothing;
5. an old revision stays readable after a new publication, and undo publishes forward;
6. a path to an external effect that skips a policy is refused, and a cycle is refused;
7. incoming relations are queryable without a field on the target;
8. an effect change cannot be published without a second person's approval, and an agent cannot give it;
9. an agent with only MCP can search, inspect, get, apply, validate, propose and publish;
10. regenerating a projection from the same bytes is stable, and editing it creates nothing.

# 12. On the current provider

| **part**            | **where**                                                                                                        |
|---------------------|------------------------------------------------------------------------------------------------------------------|
| the kernel          | TypeScript in `powerfarm/minivault`, runtime-neutral (Node, Deno, Bun); on Supabase it runs in Edge Functions      |
| canonical bytes     | the Content Store (SPEC-03)                                                                                        |
| Minivault's own state | PostgreSQL, beside the Registry; the schema name is chosen in slice S8 (Supabase already uses `vault`)           |
| agents              | the MCP door (closed until SPEC-03 §12 lifts)                                                                     |
| people              | `vault.powerfarm.app`                                                                                              |

# 13. Change rule

A new kind is a new Object Type contract, not a code change to the Registry. A change to the admission pipeline or the canonical form changes revision ids and needs a change to PF-04 first. A change to program rules needs a conformance case that fails before it and passes after.

> **Minivault**
>
> Minivault invents the semantics. The Registry recognizes them. Everything else is a projection.
