create extension if not exists pgcrypto;
create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  pseudo text unique not null check (pseudo ~ '^[A-Za-z0-9_.]{3,15}$'),
  email text, telephone text, photo_url text, bio text check (char_length(bio)<=150),
  full_name text, poste text, entreprise text, liens jsonb default '{}'::jsonb,
  is_verified boolean default false, device_id text, session_token text,
  last_seen timestamptz, last_active_at timestamptz default now(), created_at timestamptz default now()
);
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('private','group','channel')),
  name text, avatar_url text, last_message_at timestamptz default now(), created_at timestamptz default now()
);
create table public.conversation_participants (
  conversation_id uuid references public.conversations on delete cascade,
  user_id uuid references public.profiles on delete cascade,
  role text default 'member', last_read_at timestamptz, is_pinned boolean default false,
  primary key (conversation_id, user_id)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations on delete cascade,
  sender_id uuid references public.profiles on delete cascade,
  text text, type text default 'text', media_url text, thumbnail_url text, file_size int, duration int,
  reply_to_message_id uuid references public.messages, is_starred boolean default false,
  is_deleted boolean default false, status text default 'sent', created_at timestamptz default now()
);
create table public.message_reactions (
  message_id uuid references public.messages on delete cascade,
  user_id uuid references public.profiles on delete cascade, emoji text,
  primary key (message_id, user_id)
);
create table public.statuses (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles on delete cascade,
  media_url text, media_type text, expires_at timestamptz default now() + interval '24 hours', created_at timestamptz default now()
);
create table public.device_tokens (
  user_id uuid references public.profiles on delete cascade, token text primary key, created_at timestamptz default now()
);
-- IMPORTANT : la V1 utilise la connexion anonyme Supabase (Authentication > Providers > Anonymous : activer).
-- profiles.id = auth.uid() de l'utilisateur.
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.profiles to anon;
alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;
alter table public.message_reactions enable row level security;
alter table public.statuses enable row level security;
alter table public.device_tokens enable row level security;
create or replace function public.is_member(c uuid) returns boolean language sql security definer set search_path=public as
$$ select exists(select 1 from conversation_participants where conversation_id=c and user_id=auth.uid()) $$;
create policy "pseudo visible" on public.profiles for select using (true);
create policy "mon profil insert" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "mon profil update" on public.profiles for update to authenticated using (id = auth.uid());
create policy "mes conv" on public.conversations for select to authenticated using (public.is_member(id));
create policy "creer conv" on public.conversations for insert to authenticated with check (true);
create policy "maj conv" on public.conversations for update to authenticated using (public.is_member(id));
create policy "participants" on public.conversation_participants for select to authenticated using (public.is_member(conversation_id));
create policy "ajouter participants" on public.conversation_participants for insert to authenticated with check (user_id = auth.uid() or public.is_member(conversation_id));
create policy "maj participant" on public.conversation_participants for update to authenticated using (user_id = auth.uid());
create policy "lire messages" on public.messages for select to authenticated using (public.is_member(conversation_id));
create policy "envoyer" on public.messages for insert to authenticated with check (sender_id = auth.uid() and public.is_member(conversation_id));
create policy "maj messages" on public.messages for update to authenticated using (public.is_member(conversation_id));
create policy "reactions" on public.message_reactions for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "statuts lire" on public.statuses for select to authenticated using (expires_at > now());
create policy "statuts moi" on public.statuses for insert to authenticated with check (user_id = auth.uid());
create policy "tokens moi" on public.device_tokens for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
alter publication supabase_realtime add table public.messages, public.conversations;
insert into storage.buckets (id, name, public) values ('media','media',true) on conflict do nothing;
create policy "upload media" on storage.objects for insert to authenticated with check (bucket_id='media');
create policy "lire media" on storage.objects for select using (bucket_id='media');
