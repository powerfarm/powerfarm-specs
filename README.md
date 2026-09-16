# Powerfarm Specifications

Operational specifications that make the Powerfarm canon implementable without turning any current implementation into canon.

**Status:** Draft operational specification set  
**Version:** v0  
**Primary canonical sources:** PF-03 Powerfarm Operating System v1.2 and PF-04 Intelligence and Technology System v1.1  
**Effective working date:** 16 September 2026

## 1. Role of this repository

`powerfarm-research-docs` contains Powerfarm's canonical institutional doctrine. This repository sits one level below canon and one level above implementation.

```text
Powerfarm canon
PF-01 .. PF-05
      |
      v
powerfarm-specs
exact representations + semantics + conformance
      |
      v
implementation repositories
identity / continuity / antenna / heartime / apps / search / workspace
```

The governing rule is:

> A specification MUST be more precise than the canon it derives from, but MUST NOT introduce a new architectural responsibility.

If implementation pressure appears to require a new durable organ, authority boundary, or architectural responsibility, the correct action is to revisit canon rather than smuggle the new architecture into a schema.

## 2. Primary v0 specifications

This repository has four primary documents:

| Document | Purpose |
|---|---|
| [App Contract v0](specs/APP_CONTRACT_v0.md) | Defines the root institutional contract by which an application is declared, materialized, proved, and recognized. |
| [Executability Contract v0](specs/EXECUTABILITY_CONTRACT_v0.md) | Defines the contract that joins temporal evidence, observational evidence, policy, claims, executable graphs, effects, and verification. |
| [Registry Core v0](specs/REGISTRY_CORE_v0.md) | Defines the smallest durable institutional model around entities, artifacts, artifact versions, contracts, and grants. |
| [Implementation Guide v0](IMPLEMENTATION_GUIDE_v0.md) | Defines how conforming implementations materialize the three specifications together without adding architectural meaning. |

Machine-readable schemas, a PostgreSQL reference schema, examples, and conformance cases support these documents. They do not replace the normative prose.

## 3. Specification precedence

When two sources appear to disagree, use this order:

1. PF-01 through PF-05 canon.
2. Normative prose in this repository.
3. Machine-readable schemas in this repository.
4. Examples and conformance fixtures.
5. Implementation-specific documentation and code.

A lower layer MUST NOT redefine a higher layer silently.

## 4. Normative language

The keywords **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are normative within this repository in the BCP 14 sense.

- **MUST / MUST NOT**: required for v0 conformance.
- **SHOULD / SHOULD NOT**: the default; a material deviation requires an explicit reason.
- **MAY**: optional.

v0 is intentionally pre-stable. A v0 change MAY be incompatible when implementation evidence shows the current design is wrong. Such changes MUST preserve history and state the compatibility impact.

## 5. Core architectural commitments

The specifications preserve the following Powerfarm architecture:

```text
State is local.
Contracts are global.
Authority is explicit.
Execution is causal.
Important assertions carry provenance.
Context is a working set, not a warehouse.
```

Powerfarm separates concerns that are often collapsed:

```text
source control   -> human-readable source and change history
Registry         -> institutional recognition and semantic identity
contracts        -> legitimate relationships and authority boundaries
Content Store    -> immutable values, references, composition, transport
app-owned stores -> mutable operational state
model context    -> temporary reasoning working set
```

The Content Store identifies bytes. It does not assign authority. The Registry records institutionally recognized assertions. It does not become the operational database of the systems it describes.

## 6. Representation profile

Powerfarm is technology-replaceable, not architecture-agnostic. The preferred order of representation is:

```text
intent
  -> existing international standard
  -> Powerfarm contract
  -> graph / declarative representation
  -> schema / data
  -> traditional source code
  -> machine / world effects
```

The v0 specifications therefore prefer machine-inspectable contracts and existing standards over new Powerfarm languages.

Continuity executable structure has graph semantics. `powerfarm-specs` does not define another workflow language.

## 7. Serialization and identity

### 7.1 JSON data model

The normative machine data model for v0 contracts is JSON.

YAML MAY be used as an authoring syntax if it parses losslessly into the JSON data model accepted by the relevant JSON Schema. YAML-specific scalar types that cannot be represented as ordinary JSON values are not conforming contract values.

Authors SHOULD quote timestamps, revisions that look numeric, and other scalars when YAML implicit typing could change the intended JSON type. A contract digest is over the parsed JSON value, never over YAML presentation details.

### 7.2 Validation

Schemas use **JSON Schema Draft 2020-12**.

Schema validation establishes structural conformance only. Semantic conformance also includes cross-object rules, authority checks, uniqueness, graph validity, materialization evidence, and runtime behavior that JSON Schema alone cannot establish.

### 7.3 Contract digest

When a Powerfarm contract requires a material digest, implementations MUST:

1. parse the authoring representation into the JSON data model;
2. validate it against the applicable schema;
3. canonicalize that JSON value using RFC 8785 JSON Canonicalization Scheme;
4. calculate SHA-256 over the canonical UTF-8 bytes;
5. represent the result as `sha256:<lowercase-hex>`.

Values participating in this procedure MUST be representable under RFC 8785 canonicalization. Schema authors SHOULD use strings for identifiers and exact quantities when JSON number normalization could otherwise change intended semantics.

The digest MUST NOT be embedded as a field whose value participates in its own digest. The Registry records the recognized digest for a contract generation.

### 7.4 Content references

A v0 `ContentRef` follows the useful core shape of an OCI content descriptor without requiring the object to live in an OCI registry:

```json
{
  "digest": "sha256:...",
  "mediaType": "application/json",
  "size": 18293
}
```

`digest` establishes material identity. `mediaType` and `size` describe and help verify transfer.

All cross-Powerfarm v0 `ContentRef` values MUST use SHA-256. Implementations MAY maintain additional local digests such as BLAKE3, but a promoted or exchanged v0 content reference MUST be addressable and verifiable by SHA-256.

Knowing a digest is not authorization to resolve its content.

## 8. External standards profile

Powerfarm reuses established standards wherever they can carry the required semantics. v0 intentionally pins concrete versions at the interoperability boundary while allowing future specification generations to move forward.

| Concern | v0 reference |
|---|---|
| Normative requirement language | RFC 2119 + RFC 8174 / BCP 14 |
| JSON structural validation | JSON Schema Draft 2020-12 |
| Deterministic JSON bytes for digesting | RFC 8785 JSON Canonicalization Scheme |
| JSON sub-value addressing | RFC 6901 JSON Pointer |
| Resource identifiers | RFC 3986 URI syntax |
| General identifiers where UUIDs are appropriate | RFC 9562 UUIDs; UUIDv7 is preferred for newly generated time-ordered operational IDs when supported |
| Immutable content descriptor shape | OCI Descriptor concepts: digest, media type, size |
| Executable workflow syntax and control flow | Open Workflow Specification 1.0.3 |
| Event envelope | CloudEvents 1.0.2 |
| Synchronous HTTP API description | OpenAPI 3.1.1 |
| Event-driven API description | AsyncAPI 3.0.0 |
| Physical / web capability description | W3C Web of Things Thing Description 1.1 |
| Agent / tool interface where applicable | Model Context Protocol 2026-07-28 |
| HTTP machine-readable errors | RFC 9457 Problem Details |
| Supply-chain provenance inspiration | SLSA 1.2 and in-toto Attestation Framework 1.0 |
| General provenance vocabulary inspiration | W3C PROV-DM |

Current Powerfarm implementations also use systems such as Temporal for durable execution and OPA for policy decisions. Those products are implementation choices, not specification identity.

OAuth 2.1 remains an active IETF Internet-Draft at the time of this v0 set. Identity implementations that use it MUST pin the concrete draft/profile and related RFCs they actually support rather than treating the moving label `OAuth 2.1` as a stable wire contract.

### 8.1 External references

- JSON Schema 2020-12: https://json-schema.org/draft/2020-12
- RFC 8785: https://www.rfc-editor.org/rfc/rfc8785.html
- RFC 6901: https://www.rfc-editor.org/rfc/rfc6901.html
- RFC 3986: https://www.rfc-editor.org/rfc/rfc3986.html
- RFC 9562: https://www.rfc-editor.org/rfc/rfc9562.html
- OCI descriptors: https://github.com/opencontainers/image-spec/blob/main/descriptor.md
- Open Workflow Specification: https://open-workflow-specification.org/
- CloudEvents: https://github.com/cloudevents/spec
- OpenAPI 3.1.1: https://spec.openapis.org/oas/v3.1.1.html
- AsyncAPI 3.0: https://www.asyncapi.com/docs/reference/specification/v3.0.0
- W3C WoT Thing Description 1.1: https://www.w3.org/TR/wot-thing-description11/
- MCP 2026-07-28: https://modelcontextprotocol.io/specification/2026-07-28
- RFC 9457: https://www.rfc-editor.org/rfc/rfc9457.html
- SLSA 1.2 provenance: https://slsa.dev/spec/v1.2/provenance
- in-toto specifications: https://in-toto.io/docs/specs/
- W3C PROV-DM: https://www.w3.org/TR/prov-dm/
- OAuth 2.1 draft: https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/

### 8.2 Powerfarm implementation evidence reviewed

The v0 specifications were also checked against current implementation evidence. These sources are informative, not normative:

- Canonical architecture: `powerfarm-research-docs/PF-03_Powerfarm_Operating_System.md`
- Technical doctrine: `powerfarm-research-docs/PF-04_Intelligence_and_Technology_System.md`
- Continuity v2 and its current capability profile: `powerfarm-continuity/README.md` and `spec/continuity-profile.md`
- Antenna implemented invariants: `powerfarm-antenna/ANTENNA_SPEC.md`
- Registry ancestry: `powerfarm-identity/supabase/migrations/0001_identity.sql`, `0002_manifest.sql`, and `0003_autoridade.sql`

When current implementation contradicts canon, the implementation is migration input, not authority for changing the specification silently.

## 9. Repository structure

```text
powerfarm-specs/
├── README.md
├── IMPLEMENTATION_GUIDE_v0.md
├── specs/
│   ├── APP_CONTRACT_v0.md
│   ├── EXECUTABILITY_CONTRACT_v0.md
│   └── REGISTRY_CORE_v0.md
├── schemas/
│   ├── common.schema.json
│   ├── app-contract-v0.schema.json
│   ├── executability-contract-v0.schema.json
│   └── admission-receipt-v0.schema.json
├── registry/
│   └── reference-schema.sql
├── examples/
│   ├── app-contract.minimal.yaml
│   ├── app-contract.coloured-places.yaml
│   ├── executability.webhook.yaml
│   ├── executability.census.yaml
│   ├── executability.retry.yaml
│   └── admission-receipt.minimal.yaml
└── conformance/
    └── cases.yaml
```

The small tree is intentional. New folders and specification families SHOULD appear only after a real recurring interoperability need exists.

## 10. Change protocol

Changes to these specifications use the normal Powerfarm technical change path:

```text
branch
  -> pull request
  -> automated validation
  -> semantic review
  -> merge
```

A material spec change MUST state:

- the problem being corrected or capability being enabled;
- affected canon and existing implementations;
- compatibility impact;
- migration implications for persistent state or recognized contracts;
- new or changed conformance cases.

A specification change MUST NOT be justified only by implementation convenience if it weakens a canonical invariant.

## 11. Conformance principle

A component is conforming because its observable behavior satisfies a specification, not because it uses a particular library, database, runtime, programming language, or vendor.

Reference implementations are evidence about a specification. They are not the specification.

## Temporal continuity and cognitive turns

- [Heartime Contract v0](specs/HEARTIME_CONTRACT_v0.md): temporal obligations, occurrences and dispositions, planning coverage, return deadlines, explicit fallback and the restart account.
- [Attention and Context v0](specs/ATTENTION_CONTEXT_v0.md): Cards and immutable WakePacks, occupancy receipts and handoff through institutional state, without a new subsystem.
- [Executability Contract v0 §17.1–17.3](specs/EXECUTABILITY_CONTRACT_v0.md): technical recovery routing, the Direction boundary with its decision record, and the delegated-mandate representation gap.
- [Go Language Profile](profiles/GO.md): proposed profile for the new Go implementation.

These additions derive from the same canon. They do not make Heartime a planner or the prompt a durable handoff. Examples are not Registry admission or grants.

## Validation

```bash
python -m pip install --no-deps -r tools/requirements.txt
```

```bash
python tools/validate.py
```

The validator checks schemas, examples by `kind`, semantic invariants the schemas cannot express, the conformance catalog and local links. It runs on every pull request. Behavioral conformance is proven by implementations.
