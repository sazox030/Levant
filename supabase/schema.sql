-- Mashriq Editions — Supabase / Postgres schema
-- Static storefront (Vercel) + Supabase backend.
-- v1 checkout scope: CART-ONLY (no payment processor) but orders are capturable.
--
-- Conventions:
--   * Trilingual content columns are suffixed _en / _ar / _fr.
--   * Money is stored in whole euros as integers (price_eur, total_eur, unit_price_eur).
--   * DDL is written to be idempotent (safe to re-run) where reasonable.
--
-- Run order: this file first, then seed.sql.

-- gen_random_uuid() lives in pgcrypto. On Supabase this is normally present,
-- but we ensure it for portability.
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

-- Collections: curated, finite groupings of plates.
create table if not exists public.collections (
  id          text primary key,
  name_en     text not null,
  name_ar     text not null,
  name_fr     text not null,
  desc_en     text,
  desc_ar     text,
  desc_fr     text,
  plate_count integer not null default 0 check (plate_count >= 0)
);

-- Material price options. One row per orderable material.
-- Every plate can be ordered in any of these materials.
create table if not exists public.material_prices (
  material  text primary key check (material in ('digital', 'print', 'framed')),
  price_eur integer not null check (price_eur >= 0)
);

-- Plates: the individual map reproductions.
create table if not exists public.plates (
  id               text primary key,
  collection_id    text references public.collections (id) on update cascade on delete set null,
  city_en          text not null,
  city_ar          text not null,
  city_fr          text not null,
  year             integer,
  kind             text,
  default_material text references public.material_prices (material) on update cascade,
  source_plate     text,
  paper            text,
  size             text,
  edition_size     integer not null default 200 check (edition_size > 0),
  note_en          text,
  note_ar          text,
  note_fr          text
);

-- Orders: guest checkout capture (no auth required for v1).
create table if not exists public.orders (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  email      text,
  total_eur  integer check (total_eur >= 0),
  status     text not null default 'pending',
  locale     text
);

-- Order line items.
create table if not exists public.order_items (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references public.orders (id) on delete cascade,
  plate_id       text references public.plates (id) on update cascade on delete set null,
  material       text references public.material_prices (material) on update cascade,
  unit_price_eur integer not null check (unit_price_eur >= 0),
  qty            integer not null default 1 check (qty > 0)
);

-- Newsletter sign-ups. Email is the natural key.
create table if not exists public.newsletter_subscribers (
  email      text primary key,
  created_at timestamptz not null default now(),
  locale     text
);

-- ---------------------------------------------------------------------------
-- Indexes (FK-backing + common lookups)
-- ---------------------------------------------------------------------------

create index if not exists plates_collection_id_idx     on public.plates (collection_id);
create index if not exists plates_default_material_idx   on public.plates (default_material);
create index if not exists order_items_order_id_idx      on public.order_items (order_id);
create index if not exists order_items_plate_id_idx      on public.order_items (plate_id);
create index if not exists order_items_material_idx      on public.order_items (material);
create index if not exists orders_created_at_idx         on public.orders (created_at desc);
create index if not exists orders_email_idx              on public.orders (email);
create index if not exists orders_status_idx             on public.orders (status);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
-- RLS is enabled on every table. With RLS enabled and no permissive policy,
-- access is denied by default for the anon and authenticated roles. The
-- service_role key bypasses RLS entirely, so backend/admin code retains full
-- access without needing explicit policies.

alter table public.collections            enable row level security;
alter table public.material_prices        enable row level security;
alter table public.plates                 enable row level security;
alter table public.orders                 enable row level security;
alter table public.order_items            enable row level security;
alter table public.newsletter_subscribers enable row level security;

-- On a real Supabase project the `anon`, `authenticated`, and `service_role`
-- roles always exist. Create them defensively so this file is also runnable on
-- a vanilla Postgres (local CI, `supabase db reset`, etc.) without erroring.
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end
$$;

-- Drop-if-exists keeps this file idempotent (CREATE POLICY has no IF NOT EXISTS).

-- Public catalog: read-only to everyone (anon + authenticated).
drop policy if exists "collections public read" on public.collections;
create policy "collections public read"
  on public.collections
  for select
  to anon, authenticated
  using (true);

drop policy if exists "material_prices public read" on public.material_prices;
create policy "material_prices public read"
  on public.material_prices
  for select
  to anon, authenticated
  using (true);

drop policy if exists "plates public read" on public.plates;
create policy "plates public read"
  on public.plates
  for select
  to anon, authenticated
  using (true);

-- Orders: guest checkout capture. Anyone may INSERT an order, but no public
-- role may SELECT/UPDATE/DELETE. Reading orders back requires the service_role
-- key (which bypasses RLS). This prevents customers from enumerating or
-- tampering with each other's orders.
drop policy if exists "orders guest insert" on public.orders;
create policy "orders guest insert"
  on public.orders
  for insert
  to anon, authenticated
  with check (true);

-- Order items: same posture as orders — INSERT only for the public roles.
drop policy if exists "order_items guest insert" on public.order_items;
create policy "order_items guest insert"
  on public.order_items
  for insert
  to anon, authenticated
  with check (true);

-- Newsletter: anyone may subscribe (INSERT). No public SELECT, so the
-- subscriber list cannot be harvested via the anon key.
drop policy if exists "newsletter guest insert" on public.newsletter_subscribers;
create policy "newsletter guest insert"
  on public.newsletter_subscribers
  for insert
  to anon, authenticated
  with check (true);
