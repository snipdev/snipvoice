-- SnipVoice: voice trade journal
-- Run this in Supabase Dashboard > SQL Editor.

create table if not exists public.voice_entries (
  id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  duration_sec int not null default 0,
  session_label text not null default '',
  note text,
  storage_path text not null,
  local_path text
);

alter table public.voice_entries enable row level security;

drop policy if exists "Users manage their voice entries" on public.voice_entries;
create policy "Users manage their voice entries"
  on public.voice_entries for all
  using (auth.uid() = user_id or user_id is null)
  with check (auth.uid() = user_id or user_id is null);

-- Storage bucket (can also be created from Dashboard > Storage):
insert into storage.buckets (id, name, public)
values ('voice-notes', 'voice-notes', false)
on conflict (id) do nothing;

drop policy if exists "Users manage voice audio" on storage.objects;
create policy "Users manage voice audio"
  on storage.objects for all
  using (bucket_id = 'voice-notes' and (auth.uid()::text = (storage.foldername(name))[1] or (storage.foldername(name))[1] = 'anon'))
  with check (bucket_id = 'voice-notes');
