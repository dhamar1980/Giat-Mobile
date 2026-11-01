-- =============================================================================
-- GIAT — Modul ADMIN (Supabase / PostgreSQL)
-- Tanggal : 2026-10-28
-- Ringkas  :
--   1. Role baru 'admin' di tabel "user" + kolom status akun (is_active)
--   2. Tabel profil  : admin
--   3. Edukasi       : kolom tambahan di edukasi_artikel (ringkasan, status, dll)
--   4. Update sistem : tabel update_sistem (notifikasi pembaruan sistem)
--   5. Riwayat hak akses : tabel admin_log_hak_akses
--   6. Seed akun admin default
-- Script ini IDEMPOTENT (aman dijalankan berulang kali).
-- =============================================================================

begin;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. TABEL "user": status akun + batasan role
-- ─────────────────────────────────────────────────────────────────────────────
alter table public."user"
  add column if not exists is_active boolean not null default true;

alter table public."user" drop constraint if exists user_role_check;
alter table public."user"
  add constraint user_role_check
  check (role in ('pasien', 'dokter', 'apotek', 'apoteker', 'admin'));

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. TABEL PROFIL ADMIN (relasi 1-1 dengan "user", pola sama seperti pasien/dokter/apotek)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.admin (
  id_admin      char(36)     primary key
                references public."user"(id) on delete cascade,
  nama          varchar(255) not null,
  no_hp         varchar(20),
  jabatan       varchar(100) default 'Administrator Sistem',
  foto_profile  varchar(255),
  created_at    timestamp    default current_timestamp,
  updated_at    timestamp    default current_timestamp
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. EDUKASI KESEHATAN (tabel existing: edukasi_artikel, view: edukasi_kesehatan)
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.edukasi_artikel
  add column if not exists ringkasan          text,
  add column if not exists durasi_baca_menit  integer      default 3,
  add column if not exists status             varchar(20)  not null default 'published',
  add column if not exists id_admin           char(36)
        references public."user"(id) on delete set null,
  add column if not exists updated_at         timestamp    default current_timestamp;

alter table public.edukasi_artikel drop constraint if exists edukasi_artikel_status_check;
alter table public.edukasi_artikel
  add constraint edukasi_artikel_status_check
  check (status in ('draft', 'published'));

create index if not exists edukasi_artikel_kategori_idx on public.edukasi_artikel (kategori);
create index if not exists edukasi_artikel_status_idx   on public.edukasi_artikel (status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. NOTIFIKASI UPDATE SISTEM
--    Saat dipublikasikan, backend akan menyebarkan ke tabel "notifikasi"
--    (kategori = 'update_sistem') sesuai target_role.
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.update_sistem (
  id            char(36)     primary key default gen_random_uuid()::text,
  versi         varchar(20)  not null,                     -- contoh: v1.2.0
  judul         varchar(255) not null,
  deskripsi     text         not null,                     -- penjelasan update
  tipe          varchar(20)  not null default 'fitur',     -- fitur | perbaikan | keamanan | pemeliharaan
  target_role   varchar(20)  not null default 'semua',     -- semua | pasien | dokter | apotek
  prioritas     varchar(10)  not null default 'normal',    -- normal | penting
  status        varchar(20)  not null default 'published', -- draft | published
  id_admin      char(36)     references public."user"(id) on delete set null,
  published_at  timestamp,
  created_at    timestamp    default current_timestamp,
  updated_at    timestamp    default current_timestamp,
  constraint update_sistem_tipe_check
    check (tipe in ('fitur', 'perbaikan', 'keamanan', 'pemeliharaan')),
  constraint update_sistem_target_check
    check (target_role in ('semua', 'pasien', 'dokter', 'apotek')),
  constraint update_sistem_prioritas_check
    check (prioritas in ('normal', 'penting')),
  constraint update_sistem_status_check
    check (status in ('draft', 'published'))
);

create index if not exists update_sistem_published_idx on public.update_sistem (published_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. RIWAYAT PERUBAHAN HAK AKSES (audit trail manajemen akun)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.admin_log_hak_akses (
  id            char(36)     primary key default gen_random_uuid()::text,
  id_admin      char(36)     references public."user"(id) on delete set null,
  id_user       char(36)     not null references public."user"(id) on delete cascade,
  role_lama     varchar(20),
  role_baru     varchar(20),
  aksi          varchar(30)  not null default 'ubah_role',  -- buat_akun | ubah_role | nonaktifkan | aktifkan
  keterangan    text,
  created_at    timestamp    default current_timestamp
);

create index if not exists admin_log_hak_akses_user_idx on public.admin_log_hak_akses (id_user);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. SEED AKUN ADMIN DEFAULT
--    Email    : admin@gmail.com
--    Password : password123   (bcrypt $2y$, kompatibel Hash::check Laravel)
-- ─────────────────────────────────────────────────────────────────────────────
delete from public."user"
where email = 'admin@gmail.com'
  and id <> 'a0000000-0000-4000-8000-000000000001';

insert into public."user" (id, email, password, role, auth_provider, is_active, created_at, updated_at)
values (
  'a0000000-0000-4000-8000-000000000001',
  'admin@gmail.com',
  '$2y$12$xdjv21QQAurUCyyQbIAnA.Sikyuk1W8NzKYHnnUQE6cbsOPcVaDFK',
  'admin',
  'local',
  true,
  now(),
  now()
)
on conflict (id) do update
  set email = excluded.email,
      password = excluded.password,
      role = 'admin',
      is_active = true,
      updated_at = now();

insert into public.admin (id_admin, nama, no_hp, jabatan, created_at, updated_at)
select u.id, 'Admin GIAT', '081200000001', 'Administrator Sistem', now(), now()
from public."user" u
where u.email = 'admin@gmail.com'
on conflict (id_admin) do nothing;

-- Contoh data update sistem (supaya UI tidak kosong)
insert into public.update_sistem (id, versi, judul, deskripsi, tipe, target_role, prioritas, status, id_admin, published_at)
values (
  'b0000000-0000-4000-8000-000000000001',
  'v1.0.0',
  'Peluncuran Modul Admin GIAT',
  'Admin kini dapat mengelola akun pengguna, hak akses, edukasi kesehatan, serta mengirim notifikasi pembaruan sistem.',
  'fitur', 'semua', 'normal', 'published',
  'a0000000-0000-4000-8000-000000000001',
  now()
)
on conflict (id) do nothing;

commit;
