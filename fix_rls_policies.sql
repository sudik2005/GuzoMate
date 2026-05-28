-- ==============================================
-- GUZOMATE RLS POLICY FIX
-- ==============================================
-- Run this in Supabase SQL Editor.
-- This aligns table policies with app behavior in lib/services/* and screens.

-- =========================
-- walk_invites (create if missing)
-- =========================
create table if not exists public.walk_invites (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references auth.users (id) on delete cascade,
  to_user_id uuid not null references auth.users (id) on delete cascade,
  scheduled_time timestamptz not null,
  meeting_location text not null default 'To be decided',
  message text,
  suggested_route_id text,
  estimated_distance_km double precision,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'cancelled', 'completed')),
  created_at timestamptz not null default now()
);

create index if not exists walk_invites_from_user_id_idx
  on public.walk_invites (from_user_id);

create index if not exists walk_invites_to_user_id_idx
  on public.walk_invites (to_user_id);

-- Ensure RLS is enabled on all app tables.
alter table if exists public.users enable row level security;
alter table if exists public.active_walkers enable row level security;
alter table if exists public.swipes enable row level security;
alter table if exists public.matches enable row level security;
alter table if exists public.messages enable row level security;
alter table if exists public.walk_invites enable row level security;

-- =========================
-- users
-- =========================
drop policy if exists "users_select_authenticated" on public.users;
create policy "users_select_authenticated"
on public.users
for select
to authenticated
using (true);

drop policy if exists "users_insert_own_row" on public.users;
create policy "users_insert_own_row"
on public.users
for insert
to authenticated
with check (id = auth.uid());

drop policy if exists "users_update_own_row" on public.users;
create policy "users_update_own_row"
on public.users
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- =========================
-- active_walkers
-- =========================
drop policy if exists "active_walkers_select_authenticated" on public.active_walkers;
create policy "active_walkers_select_authenticated"
on public.active_walkers
for select
to authenticated
using (true);

drop policy if exists "active_walkers_modify_own_row" on public.active_walkers;
create policy "active_walkers_modify_own_row"
on public.active_walkers
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- =========================
-- swipes
-- =========================
drop policy if exists "swipes_select_participants" on public.swipes;
create policy "swipes_select_participants"
on public.swipes
for select
to authenticated
using (liker_id = auth.uid() or target_id = auth.uid());

drop policy if exists "swipes_insert_self_as_liker" on public.swipes;
create policy "swipes_insert_self_as_liker"
on public.swipes
for insert
to authenticated
with check (liker_id = auth.uid());

drop policy if exists "swipes_update_self_as_liker" on public.swipes;
create policy "swipes_update_self_as_liker"
on public.swipes
for update
to authenticated
using (liker_id = auth.uid())
with check (liker_id = auth.uid());

-- =========================
-- matches
-- =========================
drop policy if exists "matches_select_participants" on public.matches;
create policy "matches_select_participants"
on public.matches
for select
to authenticated
using (user_id_1 = auth.uid() or user_id_2 = auth.uid());

drop policy if exists "matches_insert_participant" on public.matches;
create policy "matches_insert_participant"
on public.matches
for insert
to authenticated
with check (user_id_1 = auth.uid() or user_id_2 = auth.uid());

drop policy if exists "matches_update_participants" on public.matches;
create policy "matches_update_participants"
on public.matches
for update
to authenticated
using (user_id_1 = auth.uid() or user_id_2 = auth.uid())
with check (user_id_1 = auth.uid() or user_id_2 = auth.uid());

-- =========================
-- messages
-- =========================
drop policy if exists "messages_select_match_participants" on public.messages;
create policy "messages_select_match_participants"
on public.messages
for select
to authenticated
using (
  exists (
    select 1
    from public.matches m
    where m.id = messages.match_id
      and (m.user_id_1 = auth.uid() or m.user_id_2 = auth.uid())
  )
);

drop policy if exists "messages_insert_sender_is_auth_user" on public.messages;
create policy "messages_insert_sender_is_auth_user"
on public.messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.matches m
    where m.id = messages.match_id
      and (m.user_id_1 = auth.uid() or m.user_id_2 = auth.uid())
  )
);

-- =========================
-- walk_invites
-- =========================
drop policy if exists "walk_invites_select_participants" on public.walk_invites;
create policy "walk_invites_select_participants"
on public.walk_invites
for select
to authenticated
using (from_user_id = auth.uid() or to_user_id = auth.uid());

drop policy if exists "walk_invites_insert_sender_only" on public.walk_invites;
create policy "walk_invites_insert_sender_only"
on public.walk_invites
for insert
to authenticated
with check (from_user_id = auth.uid());

drop policy if exists "walk_invites_update_participants" on public.walk_invites;
create policy "walk_invites_update_participants"
on public.walk_invites
for update
to authenticated
using (from_user_id = auth.uid() or to_user_id = auth.uid())
with check (from_user_id = auth.uid() or to_user_id = auth.uid());

