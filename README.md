# Powerfarm Specifications

Operational specifications that make the Powerfarm canon implementable without turning any current implementation into canon.

**Status:** Draft operational specification set
**Version:** v0
**Primary canonical sources:** PF-03 Powerfarm Operating System 1.5 and PF-04 Intelligence and Technology System 1.2
**V0 materialization:** `powerfarm-research-docs/v0` (V0-00 … V0-07)

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
| [SPEC-01 Registry](SPEC-01_Registry.md) | The four basics (entities, objects, versions, contracts), authority, the Foundation Act and the act log. |
| [SPEC-02 Names and Addresses](SPEC-02_Names_and_Addresses.md) | The form of every name: things, contracts, versions, acts, bytes and hostnames. |
| [SPEC-03 Identity and Content](SPEC-03_Identity_and_Content.md) | The keyring, sign-in and its gates, the Content Store, digests and content references, and secret references. |
| [Implementation Guide v0](IMPLEMENTATION_GUIDE_v0.md) | Defines how conforming implementations materialize the three specifications together without adding architectural meaning. |

Machine-readable schemas, examples and conformance cases support these documents. They do not replace the normative prose. The reference implementation of SPEC-01 is the Registry migration in `powerfarm/minivault`.

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

Contracts are JSON; digests follow RFC 8785 and SHA-256; content is referenced by `ContentRef`. All three are defined in [SPEC-03 Identity and Content](SPEC-03_Identity_and_Content.md) §7.

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

Runtimes, storage engines and providers are implementation choices. They live in the V0 materialization documents and in implementation repositories, never in these specifications.

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

### 8.2 Powerfarm sources

These sources are informative, not normative:

- Canonical architecture: `powerfarm-research-docs/PF-03_Powerfarm_Operating_System.md`
- Technical doctrine: `powerfarm-research-docs/PF-04_Intelligence_and_Technology_System.md`
- V0 materialization: `powerfarm-research-docs/v0/` (data V0-01, rebuild V0-03, names V0-07)
- Registry reference implementation: `powerfarm/minivault` (`supabase/migrations`)
- Continuity: `powerfarm-continuity/README.md` and `spec/continuity-profile.md`
- Antenna invariants: `powerfarm-antenna/ANTENNA_SPEC.md`

When an implementation contradicts canon, the implementation changes, not the specification.

## 9. Repository structure

```text
powerfarm-specs/
├── README.md
├── IMPLEMENTATION_GUIDE_v0.md
├── specs/
│   ├── APP_CONTRACT_v0.md
│   ├── EXECUTABILITY_CONTRACT_v0.md
│   ├── HEARTIME_CONTRACT_v0.md
│   └── ATTENTION_CONTEXT_v0.md
├── schemas/            common types and one JSON Schema per contract kind
├── examples/           one or more valid instances per kind
├── conformance/
│   └── cases.yaml
├── profiles/
│   └── GO.md
└── tools/
    └── validate.py     schemas, examples, semantic invariants, catalog, links
```

The small tree is intentional. New folders and specification families SHOULD appear only after a real recurring interoperability need exists.

## 10. Names

Every name in these specifications, schemas and examples follows [SPEC-02 Names and Addresses](SPEC-02_Names_and_Addresses.md). The schemas in `schemas/common.schema.json` enforce it.

## 11. Change protocol

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

## 12. Conformance principle

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
