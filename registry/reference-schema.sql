-- Powerfarm Registry Core v0 reference schema
--
-- REFERENCE ONLY. This file is not a live migration and MUST NOT be applied
-- to an existing Powerfarm database without a migration plan and dependency audit.
--
-- It expresses the smallest durable institutional model defined by
-- specs/REGISTRY_CORE_v0.md. Authentication protocol state, application state,
-- Antenna receipts, Heartime evidence, Continuity execution state, Search indexes,
-- and other operational data do not belong here.

create schema if not exists powerfarm_registry;

-- ---------------------------------------------------------------------------
-- shared helpers
-- ---------------------------------------------------------------------------

create or replace function powerfarm_registry.is_entity_id(value text)
returns boolean
language sql
immutable
as $$
  select value ~ '^pf(\.[a-z0-9][a-z0-9-]*)+$';
$$;

create or replace function powerfarm_registry.is_contract_id(value text)
returns boolean
language sql
immutable
as $$
  select value ~ '^pf\.contract(\.[a-z0-9][a-z0-9-]*)+$';
$$;

create or replace function powerfarm_registry.is_sha256_digest(value text)
returns boolean
language sql
immutable
as $$
  select value ~ '^sha256:[0-9a-f]{64}$';
$$;

-- ---------------------------------------------------------------------------
-- entities
-- Stable institutional identities. Operational state remains with the entity.
-- ---------------------------------------------------------------------------

create table powerfarm_registry.entities (
  id            text primary key,
  kind          text not null,
  title         text not null,
  summary       text,
  created_at    timestamptz not null default now(),
  created_by    text references powerfarm_registry.entities(id),
  retired_at    timestamptz,
  constraint entities_id_shape check (powerfarm_registry.is_entity_id(id)),
  constraint entities_kind_nonempty check (length(btrim(kind)) > 0),
  constraint entities_title_nonempty check (length(btrim(title)) > 0),
  constraint entities_retirement_order check (retired_at is null or retired_at >= created_at)
);

-- ---------------------------------------------------------------------------
-- artifacts
-- Stable semantic identities for versionable institutional objects.
-- ---------------------------------------------------------------------------

create table powerfarm_registry.artifacts (
  id                text primary key,
  kind              text not null,
  title             text not null,
  summary           text,
  publisher_entity  text references powerfarm_registry.entities(id),
  created_at        timestamptz not null default now(),
  created_by        text references powerfarm_registry.entities(id),
  retired_at        timestamptz,
  constraint artifacts_id_shape check (powerfarm_registry.is_entity_id(id)),
  constraint artifacts_kind_nonempty check (length(btrim(kind)) > 0),
  constraint artifacts_title_nonempty check (length(btrim(title)) > 0),
  constraint artifacts_retirement_order check (retired_at is null or retired_at >= created_at)
);

-- ---------------------------------------------------------------------------
-- artifact_versions
-- Immutable material identity for one exact version. A version may be anchored
-- in source control, content-addressed storage, or both. The Registry records
-- recognition; it does not store the bytes.
-- ---------------------------------------------------------------------------

create table powerfarm_registry.artifact_versions (
  artifact_id       text not null references powerfarm_registry.artifacts(id),
  version           text not null,
  source_repo       text,
  source_revision   text,
  source_path       text,
  content_digest    text,
  media_type        text,
  size_bytes        bigint,
  metadata          jsonb not null default '{}'::jsonb,
  recognized_at     timestamptz not null default now(),
  recognized_by     text references powerfarm_registry.entities(id),
  superseded_at     timestamptz,
  superseded_by_version text,
  retired_at        timestamptz,
  primary key (artifact_id, version),
  foreign key (artifact_id, superseded_by_version)
    references powerfarm_registry.artifact_versions(artifact_id, version),
  constraint artifact_versions_version_nonempty check (length(btrim(version)) > 0),
  constraint artifact_versions_material_identity check (
    content_digest is not null
    or (source_repo is not null and source_revision is not null)
  ),
  constraint artifact_versions_digest_shape check (
    content_digest is null or powerfarm_registry.is_sha256_digest(content_digest)
  ),
  constraint artifact_versions_size_nonnegative check (size_bytes is null or size_bytes >= 0),
  constraint artifact_versions_supersession_order check (
    superseded_at is null or superseded_at >= recognized_at
  ),
  constraint artifact_versions_retirement_order check (
    retired_at is null or retired_at >= recognized_at
  ),
  constraint artifact_versions_not_self_superseded check (
    superseded_by_version is null or superseded_by_version <> version
  )
);

create unique index artifact_versions_one_current
  on powerfarm_registry.artifact_versions (artifact_id)
  where superseded_at is null and retired_at is null;

create index artifact_versions_current_by_artifact
  on powerfarm_registry.artifact_versions (artifact_id, recognized_at desc)
  where superseded_at is null and retired_at is null;

create index artifact_versions_by_digest
  on powerfarm_registry.artifact_versions (content_digest)
  where content_digest is not null;

-- ---------------------------------------------------------------------------
-- contracts
-- A stable contract id has immutable generations. Contract documents are
-- normally preserved externally and referenced by digest. Provider/consumer are
-- intentionally optional because not every contract is a binary service relation.
-- ---------------------------------------------------------------------------

create table powerfarm_registry.contracts (
  id                         text not null,
  generation                 integer not null,
  kind                       text not null,
  subject_entity             text not null references powerfarm_registry.entities(id),
  provider_entity            text references powerfarm_registry.entities(id),
  consumer_entity            text references powerfarm_registry.entities(id),
  document_digest            text not null,
  document_media_type        text not null default 'application/json',
  document_size_bytes        bigint,
  document_source_repo       text,
  document_source_revision   text,
  document_source_path       text,
  admission_receipt_digest   text,
  effective_from             timestamptz,
  effective_until            timestamptz,
  recognized_at              timestamptz not null default now(),
  recognized_by              text references powerfarm_registry.entities(id),
  superseded_at              timestamptz,
  superseded_by_generation   integer,
  retired_at                 timestamptz,
  metadata                   jsonb not null default '{}'::jsonb,
  primary key (id, generation),
  foreign key (id, superseded_by_generation)
    references powerfarm_registry.contracts(id, generation),
  constraint contracts_id_shape check (powerfarm_registry.is_contract_id(id)),
  constraint contracts_generation_positive check (generation >= 1),
  constraint contracts_kind_nonempty check (length(btrim(kind)) > 0),
  constraint contracts_document_digest_shape check (
    powerfarm_registry.is_sha256_digest(document_digest)
  ),
  constraint contracts_receipt_digest_shape check (
    admission_receipt_digest is null
    or powerfarm_registry.is_sha256_digest(admission_receipt_digest)
  ),
  constraint contracts_document_size_nonnegative check (
    document_size_bytes is null or document_size_bytes >= 0
  ),
  constraint contracts_effective_window check (
    effective_until is null
    or effective_from is null
    or effective_until > effective_from
  ),
  constraint contracts_supersession_order check (
    superseded_at is null or superseded_at >= recognized_at
  ),
  constraint contracts_retirement_order check (
    retired_at is null or retired_at >= recognized_at
  ),
  constraint contracts_not_self_superseded check (
    superseded_by_generation is null or superseded_by_generation <> generation
  )
);

-- At most one currently recognized generation for a stable contract id.
create unique index contracts_one_current_generation
  on powerfarm_registry.contracts (id)
  where superseded_at is null and retired_at is null;

create index contracts_by_subject
  on powerfarm_registry.contracts (subject_entity, kind, recognized_at desc);

create index contracts_by_provider
  on powerfarm_registry.contracts (provider_entity, kind, recognized_at desc)
  where provider_entity is not null;

create index contracts_by_consumer
  on powerfarm_registry.contracts (consumer_entity, kind, recognized_at desc)
  where consumer_entity is not null;

create index contracts_by_document_digest
  on powerfarm_registry.contracts (document_digest);

-- ---------------------------------------------------------------------------
-- grants
-- Institutional authority. Protocol credentials/tokens belong to Identity
-- infrastructure; grants describe recognized mandate and remain historically
-- addressable after revocation.
-- ---------------------------------------------------------------------------

create table powerfarm_registry.grants (
  id              uuid primary key,
  subject_entity  text not null references powerfarm_registry.entities(id),
  action          text not null,
  resource        text,
  constraints     jsonb not null default '{}'::jsonb,
  policy_digest   text,
  granted_by      text not null references powerfarm_registry.entities(id),
  valid_from      timestamptz not null default now(),
  valid_until     timestamptz,
  revoked_at      timestamptz,
  revoked_reason  text,
  created_at      timestamptz not null default now(),
  constraint grants_action_nonempty check (length(btrim(action)) > 0),
  constraint grants_policy_digest_shape check (
    policy_digest is null or powerfarm_registry.is_sha256_digest(policy_digest)
  ),
  constraint grants_valid_window check (
    valid_until is null or valid_until > valid_from
  ),
  constraint grants_revocation_order check (
    revoked_at is null or revoked_at >= created_at
  )
);

create index grants_current_by_subject_action
  on powerfarm_registry.grants (subject_entity, action, valid_from desc)
  where revoked_at is null;

-- ---------------------------------------------------------------------------
-- lifecycle helpers / projections
-- These are derived conveniences, not additional ontology.
-- ---------------------------------------------------------------------------

create view powerfarm_registry.current_contracts as
select *
from powerfarm_registry.contracts
where superseded_at is null
  and retired_at is null
  and (effective_from is null or effective_from <= now())
  and (effective_until is null or effective_until > now());

create view powerfarm_registry.current_artifact_versions as
select distinct on (artifact_id)
  av.*
from powerfarm_registry.artifact_versions av
where av.superseded_at is null
  and av.retired_at is null
order by artifact_id, recognized_at desc, version desc;

-- ---------------------------------------------------------------------------
-- immutability of recognized material identity
-- Lifecycle fields may change; identity-defining fields may not.
-- ---------------------------------------------------------------------------

create or replace function powerfarm_registry.protect_artifact_version_identity()
returns trigger
language plpgsql
as $$
begin
  if row(
      new.artifact_id,
      new.version,
      new.source_repo,
      new.source_revision,
      new.source_path,
      new.content_digest,
      new.media_type,
      new.size_bytes,
      new.recognized_at,
      new.recognized_by
    ) is distinct from row(
      old.artifact_id,
      old.version,
      old.source_repo,
      old.source_revision,
      old.source_path,
      old.content_digest,
      old.media_type,
      old.size_bytes,
      old.recognized_at,
      old.recognized_by
    ) then
    raise exception 'recognized artifact version identity is immutable';
  end if;
  return new;
end;
$$;

create trigger artifact_versions_identity_immutable
before update on powerfarm_registry.artifact_versions
for each row execute function powerfarm_registry.protect_artifact_version_identity();

create or replace function powerfarm_registry.protect_contract_generation_identity()
returns trigger
language plpgsql
as $$
begin
  if row(
      new.id,
      new.generation,
      new.kind,
      new.subject_entity,
      new.provider_entity,
      new.consumer_entity,
      new.document_digest,
      new.document_media_type,
      new.document_size_bytes,
      new.document_source_repo,
      new.document_source_revision,
      new.document_source_path,
      new.admission_receipt_digest,
      new.effective_from,
      new.effective_until,
      new.recognized_at,
      new.recognized_by
    ) is distinct from row(
      old.id,
      old.generation,
      old.kind,
      old.subject_entity,
      old.provider_entity,
      old.consumer_entity,
      old.document_digest,
      old.document_media_type,
      old.document_size_bytes,
      old.document_source_repo,
      old.document_source_revision,
      old.document_source_path,
      old.admission_receipt_digest,
      old.effective_from,
      old.effective_until,
      old.recognized_at,
      old.recognized_by
    ) then
    raise exception 'recognized contract generation identity is immutable';
  end if;
  return new;
end;
$$;

create trigger contracts_generation_identity_immutable
before update on powerfarm_registry.contracts
for each row execute function powerfarm_registry.protect_contract_generation_identity();

-- This schema intentionally defines no RLS policy. Authorization and deployment
-- policy are implementation concerns that MUST be added by a concrete Registry
-- deployment without changing the semantic model above.
