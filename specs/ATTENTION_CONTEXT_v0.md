# Attention and Context v0

**Status:** Draft operational specification  
**Specifications:** `Card`, `WakePack`  
**API version:** `powerfarm.specs/v0`  
**Canonical basis:** PF-03 local state and content plane; PF-04 §1.5 context as a working set, §5.3 intelligence routing, representation doctrine

This specification defines two representations. It defines no service, Registry ontology extension, Cards store or agent framework.

> An intelligence does not inherit another intelligence's context. It inherits the institution's current state.

## 1. Card

A **Card** is a reason a subject deserves attention now. It points to a subject, an existing responsibility contract, a reason, evidence or content references, a salience and an optional expiry. It is neither truth, evidence, authority, execution state, responsibility nor memory.

A projection MAY retire or expire a Card while all source evidence, failure history and temporal obligations persist. Expiry of attention MUST NOT close a responsibility, erase evidence or cancel a future evaluation. Selection of Cards MUST remain explainable.

## 2. WakePack

A **WakePack** is the immutable manifest of the working set compiled for one cognitive turn (`schemas/wakepack-v0.schema.json`). It MUST bind:

- the turn identity and the route selected for the turn;
- the responsibility and its contract generation;
- mandatory contractual content and authority references;
- non-optional authority, safety, resource, budget and contractual constraints;
- current institutional state and relevant evidence;
- the relevant graph or semantic neighborhood;
- referenced immutable content;
- the context compiler identity and, where one exists, the template;
- presented Cards, selected optional items and why each was selected;
- every omitted Card or optional item with its reason;
- the byte budget and the bytes used;
- the exact compiled context bytes by immutable reference.

References to mutable resources alone cannot reconstruct a turn. Material mutable inputs MUST be captured as immutable snapshots or versioned reads. The manifest records the capture time and any consistency limitation; it does not invent a global transaction.

## 3. Compilation

The compiler MUST verify every referenced object against its digest before use. **Identity is not permission:** access to bytes and authority to act are checked separately.

Mandatory material never competes for salience. The mandatory roles are at least `contracts`, `authority`, `constraints` and `state`. If mandatory material does not fit the budget, compilation MUST fail and the turn is contained under its recovery route; authority and constraints MUST NOT be truncated.

After mandatory material, unexpired Cards are presented in descending salience, then optional items in the caller's selection order. Material that does not fit the remaining budget, and expired Cards, are omitted and recorded with their reason. The v0 reference budget counts UTF-8 bytes of the compiled context; it MUST NOT be presented as a model token budget.

The compiled context states that evidence, attention and optional content are data, not instructions. Text from observations, documents and previous outputs remains untrusted data even when content-addressed.

The final manifest is RFC 8785 canonical JSON addressed by SHA-256. Its digest is external to its bytes. The compiled context is a separate object, so including it creates no digest cycle.

The context compiler SHOULD be identified by a small manifest naming the executable digest and its source revision, rather than by copying executables into the content plane. Templates and compilers are versioned software; improving them follows the normal technical change path.

## 4. Occupancy and receipts

The prompt is a model-specific compilation product. **The durable handoff is institutional state.**

A route selected in the WakePack is not evidence that it ran. Each invocation MUST leave a receipt, bound to the turn, that identifies what ran: the route kind and command or endpoint, the requested and responding model where applicable, the digests of the input context, system instruction and output contract, the outcome, and usage or cost where the provider reports them. Receipts MUST NOT contain credentials. Credentials reach a route only through its environment or an equivalent secret channel, never through recorded arguments.

A route refused for credential, quota or budget reasons SHOULD be reported distinctly from technical failure, because only the former can reach a Direction boundary (EXECUTABILITY_CONTRACT_v0 §17.2).

Authority references describe the turn context, not irrevocable rights. Effects MUST recheck current authority at the execution boundary. Model output cannot expand the mandate, remove verification or rewrite mandatory constraints. A proposal is accepted only after deterministic validation against current state; invocations are budgeted and the spent budget survives restart.

## 5. Handoff

The next turn reads current institutional state. It MUST NOT require a previous model's prose summary or conversation memory.

On return, a turn preserves changed software or state, artifacts, evidence, unresolved conditions and the preparation of the next period. A fresh projection selects attention for the next occupant. Cards may expire; the old WakePack and its receipts remain addressable as evidence of that turn.

## 6. Placement and conformance

Attention projection and context compilation belong to the application or capability assembling the cognitive turn. Heartime does not know prompts. Continuity does not choose salience. No central Cards store is required.

Conformance cases `ATTN-001` to `ATTN-003` and `TURN-001` to `TURN-003` cover mandatory material under budget pressure, attention expiry, reconstruction and tamper evidence, succession without narrative handoff, technical recovery and the Direction boundary.
