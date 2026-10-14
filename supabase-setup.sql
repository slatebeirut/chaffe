-- Chaffe HQ: run this once in Supabase > SQL Editor.

-- 1. Team members allowed in. Add each teammate's email.
create table if not exists public.hq_members (
  email text primary key
);
insert into public.hq_members (email) values
  ('marcbasbous307@gmail.com')
  -- ,('teammate2@email.com')
  -- ,('teammate3@email.com')
  -- ,('teammate4@email.com')
on conflict do nothing;

-- 2. One row per section: leads, contacts, canvas, snap, kpis.
create table if not exists public.hq_state (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz default now()
);

-- 3. Row level security: only signed in members may read or write.
alter table public.hq_state enable row level security;
alter table public.hq_members enable row level security;

create or replace function public.is_member()
returns boolean language sql stable security definer as $$
  select exists (select 1 from public.hq_members where email = auth.jwt() ->> 'email');
$$;

drop policy if exists "members read" on public.hq_state;
drop policy if exists "members write" on public.hq_state;
drop policy if exists "members update" on public.hq_state;
create policy "members read"   on public.hq_state for select to authenticated using (public.is_member());
create policy "members write"  on public.hq_state for insert to authenticated with check (public.is_member());
create policy "members update" on public.hq_state for update to authenticated using (public.is_member()) with check (public.is_member());

-- 4. Realtime: push every change to every open screen.
alter publication supabase_realtime add table public.hq_state;
alter table public.hq_state replica identity full;
