set check_function_bodies = off;

create extension if not exists pgcrypto;

create or replace function public.current_month_text(
  ts timestamptz default timezone('utc', now())
)
returns text
language sql
immutable
as $$
  select to_char(ts at time zone 'utc', 'YYYY-MM');
$$;

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  photo_url text,
  subscription_tier text not null default 'free' check (subscription_tier in ('free', 'basic', 'pro')),
  preferred_genres text[] not null default '{}',
  preferred_mood text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  prompt text not null,
  audio_url text not null default '',
  video_url text,
  thumbnail_url text not null default '',
  genre text[] not null default '{}',
  mood text,
  duration integer not null default 0 check (duration >= 0),
  is_public boolean not null default false,
  content_kind text not null default 'song' check (content_kind in ('song', 'lyrics')),
  lyrics_title text,
  lyrics_language text,
  lyrics_sections jsonb not null default '[]'::jsonb,
  translated_lyrics_sections jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.usage_quotas (
  user_id uuid not null references auth.users (id) on delete cascade,
  month text not null,
  songs_generated integer not null default 0 check (songs_generated >= 0),
  videos_generated integer not null default 0 check (videos_generated >= 0),
  lyrics_generated integer not null default 0 check (lyrics_generated >= 0),
  last_request_at timestamptz,
  minute_window_started_at timestamptz,
  requests_in_window integer not null default 0 check (requests_in_window >= 0),
  primary key (user_id, month)
);

create table if not exists public.playlists (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  is_public boolean not null default false,
  song_ids uuid[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists songs_user_created_idx on public.songs (user_id, created_at desc);
create index if not exists songs_public_created_idx on public.songs (is_public, created_at desc);
create index if not exists playlists_owner_created_idx on public.playlists (owner_id, created_at desc);

alter table public.users enable row level security;
alter table public.songs enable row level security;
alter table public.usage_quotas enable row level security;
alter table public.playlists enable row level security;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    display_name,
    photo_url,
    subscription_tier
  )
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, ''), '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url',
    'free'
  )
  on conflict (id) do nothing;

  insert into public.usage_quotas (
    user_id,
    month
  )
  values (
    new.id,
    public.current_month_text()
  )
  on conflict (user_id, month) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user();

create or replace function public.prevent_client_subscription_tier_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() <> 'service_role'
    and new.subscription_tier is distinct from old.subscription_tier then
    raise exception 'subscription_tier is server-managed';
  end if;

  return new;
end;
$$;

drop trigger if exists users_subscription_tier_guard on public.users;
create trigger users_subscription_tier_guard
before update on public.users
for each row
execute function public.prevent_client_subscription_tier_change();

create or replace function public.ensure_quota_row(
  p_user_id uuid,
  p_month text
)
returns public.usage_quotas
language plpgsql
security definer
set search_path = public
as $$
declare
  quota_row public.usage_quotas;
begin
  insert into public.usage_quotas (
    user_id,
    month
  )
  values (
    p_user_id,
    p_month
  )
  on conflict (user_id, month) do nothing;

  select *
  into quota_row
  from public.usage_quotas
  where user_id = p_user_id
    and month = p_month
  for update;

  return quota_row;
end;
$$;

create or replace function public.touch_rate_limit(
  p_user_id uuid,
  p_requests_per_minute integer
)
returns public.usage_quotas
language plpgsql
security definer
set search_path = public
as $$
declare
  month_text text := public.current_month_text();
  quota_row public.usage_quotas;
begin
  quota_row := public.ensure_quota_row(p_user_id, month_text);

  if quota_row.minute_window_started_at is null
    or quota_row.minute_window_started_at <= timezone('utc', now()) - interval '1 minute' then
    update public.usage_quotas
    set minute_window_started_at = timezone('utc', now()),
        requests_in_window = 1,
        last_request_at = timezone('utc', now())
    where user_id = p_user_id
      and month = month_text
    returning * into quota_row;

    return quota_row;
  end if;

  if quota_row.requests_in_window >= p_requests_per_minute then
    raise exception 'Too many requests';
  end if;

  update public.usage_quotas
  set requests_in_window = requests_in_window + 1,
      last_request_at = timezone('utc', now())
  where user_id = p_user_id
    and month = month_text
  returning * into quota_row;

  return quota_row;
end;
$$;

create or replace function public.increment_usage(
  p_user_id uuid,
  p_feature text,
  p_monthly_limit integer default null
)
returns public.usage_quotas
language plpgsql
security definer
set search_path = public
as $$
declare
  month_text text := public.current_month_text();
  quota_row public.usage_quotas;
begin
  quota_row := public.ensure_quota_row(p_user_id, month_text);

  if p_feature = 'songs'
    and p_monthly_limit is not null
    and quota_row.songs_generated >= p_monthly_limit then
    raise exception 'Monthly song quota reached';
  end if;

  if p_feature = 'videos'
    and p_monthly_limit is not null
    and quota_row.videos_generated >= p_monthly_limit then
    raise exception 'Monthly video quota reached';
  end if;

  if p_feature = 'lyrics'
    and p_monthly_limit is not null
    and quota_row.lyrics_generated >= p_monthly_limit then
    raise exception 'Monthly lyrics quota reached';
  end if;

  update public.usage_quotas
  set songs_generated = songs_generated + case when p_feature = 'songs' then 1 else 0 end,
      videos_generated = videos_generated + case when p_feature = 'videos' then 1 else 0 end,
      lyrics_generated = lyrics_generated + case when p_feature = 'lyrics' then 1 else 0 end
  where user_id = p_user_id
    and month = month_text
  returning * into quota_row;

  return quota_row;
end;
$$;

revoke all on function public.ensure_quota_row(uuid, text) from public, anon, authenticated;
revoke all on function public.touch_rate_limit(uuid, integer) from public, anon, authenticated;
revoke all on function public.increment_usage(uuid, text, integer) from public, anon, authenticated;

drop policy if exists "users_select_self" on public.users;
create policy "users_select_self"
on public.users
for select
using (auth.uid() = id);

drop policy if exists "users_update_self" on public.users;
create policy "users_update_self"
on public.users
for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "songs_select_own_or_public" on public.songs;
create policy "songs_select_own_or_public"
on public.songs
for select
using (auth.uid() = user_id or is_public = true);

drop policy if exists "songs_insert_own" on public.songs;
create policy "songs_insert_own"
on public.songs
for insert
with check (auth.uid() = user_id);

drop policy if exists "songs_update_own" on public.songs;
create policy "songs_update_own"
on public.songs
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "songs_delete_own" on public.songs;
create policy "songs_delete_own"
on public.songs
for delete
using (auth.uid() = user_id);

drop policy if exists "usage_quotas_select_self" on public.usage_quotas;
create policy "usage_quotas_select_self"
on public.usage_quotas
for select
using (auth.uid() = user_id);

drop policy if exists "playlists_select_own_or_public" on public.playlists;
create policy "playlists_select_own_or_public"
on public.playlists
for select
using (auth.uid() = owner_id or is_public = true);

drop policy if exists "playlists_insert_own" on public.playlists;
create policy "playlists_insert_own"
on public.playlists
for insert
with check (auth.uid() = owner_id);

drop policy if exists "playlists_update_own" on public.playlists;
create policy "playlists_update_own"
on public.playlists
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

drop policy if exists "playlists_delete_own" on public.playlists;
create policy "playlists_delete_own"
on public.playlists
for delete
using (auth.uid() = owner_id);
