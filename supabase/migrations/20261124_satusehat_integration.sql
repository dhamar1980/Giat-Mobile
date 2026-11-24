-- =============================================================================
-- GIAT — Integrasi Pertukaran Data SATUSEHAT Kemenkes RI (HL7 FHIR R4)
-- Tanggal     : 2026-11-24
-- Environment : Sandbox (Organization ID: 8130f30d-7d7e-48c0-abb3-ba551d939e29)
-- Ringkas     :
--   1. Kolom ID/IHS SATUSEHAT pada tabel pasien, dokter, apotek, obat,
--      konsultasi, resep, pesanan_obat, pantau_kesehatan, dan pragi_skrining
--   2. Tabel log & pemetaan sinkronisasi FHIR `satusehat_sync_logs`
-- Script ini IDEMPOTENT (aman dijalankan berulang kali tanpa merusak data).
-- =============================================================================

begin;

alter table public.pasien
  add column if not exists satusehat_ihs_number varchar(64),
  add column if not exists satusehat_synced_at  timestamp;

alter table public.dokter
  add column if not exists nik                  varchar(20),
  add column if not exists satusehat_ihs_number varchar(64),
  add column if not exists satusehat_synced_at  timestamp;

alter table public.apotek
  add column if not exists satusehat_org_id      varchar(64),
  add column if not exists satusehat_location_id varchar(64),
  add column if not exists satusehat_synced_at   timestamp;

alter table public.obat
  add column if not exists kfa_code                varchar(32),
  add column if not exists satusehat_medication_id varchar(64);

alter table public.konsultasi
  add column if not exists satusehat_encounter_id varchar(64),
  add column if not exists satusehat_condition_id varchar(64),
  add column if not exists satusehat_synced_at    timestamp;

alter table public.resep
  add column if not exists satusehat_medication_request_ids text,
  add column if not exists satusehat_condition_id           varchar(64),
  add column if not exists satusehat_synced_at              timestamp;

alter table public.pesanan_obat
  add column if not exists satusehat_medication_dispense_ids text,
  add column if not exists satusehat_synced_at               timestamp;

alter table public.pantau_kesehatan
  add column if not exists satusehat_observation_ids text,
  add column if not exists satusehat_synced_at       timestamp;

alter table public.pragi_skrining
  add column if not exists satusehat_observation_id varchar(64),
  add column if not exists satusehat_synced_at      timestamp;

create table if not exists public.satusehat_sync_logs (
  id                 char(36)     primary key default gen_random_uuid()::text,
  entity_type        varchar(40)  not null,
  local_id           varchar(100) not null,
  fhir_resource_type varchar(50)  not null,
  satusehat_id       varchar(100),
  status             varchar(20)  not null default 'synced',
  http_status        integer,
  payload_summary    jsonb,
  response_data      jsonb,
  error_message      text,
  synced_at          timestamp    not null default current_timestamp
);

create index if not exists satusehat_sync_logs_lookup_idx
  on public.satusehat_sync_logs (entity_type, local_id, fhir_resource_type);

create index if not exists satusehat_sync_logs_ihs_idx
  on public.satusehat_sync_logs (satusehat_id);

commit;
