-- Complementa a tabela inicial com os dados necessários para reabrir plantas.
alter table public.projects
  alter column user_id set default auth.uid(),
  add column if not exists lot_area_m2 numeric,
  add column if not exists room_count integer not null default 0,
  add column if not exists background_path text,
  add column if not exists data jsonb not null default '{}'::jsonb,
  add column if not exists updated_at timestamptz not null default now();

create or replace function public.set_projects_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists projects_set_updated_at on public.projects;
create trigger projects_set_updated_at
before update on public.projects
for each row execute function public.set_projects_updated_at();

create index if not exists projects_user_updated_at_idx
  on public.projects (user_id, updated_at desc);

grant select, insert, update, delete on public.projects to authenticated;

drop policy if exists "Users can read their own projects" on public.projects;
drop policy if exists "Users can create their own projects" on public.projects;
drop policy if exists "Users can update their own projects" on public.projects;
drop policy if exists "Users can delete their own projects" on public.projects;

create policy "Users can read their own projects"
  on public.projects for select to authenticated
  using (auth.uid() = user_id);
create policy "Users can create their own projects"
  on public.projects for insert to authenticated
  with check (auth.uid() = user_id);
create policy "Users can update their own projects"
  on public.projects for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete their own projects"
  on public.projects for delete to authenticated
  using (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'project-backgrounds',
  'project-backgrounds',
  false,
  null,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users can read their project backgrounds" on storage.objects;
drop policy if exists "Users can upload their project backgrounds" on storage.objects;
drop policy if exists "Users can update their project backgrounds" on storage.objects;
drop policy if exists "Users can delete their project backgrounds" on storage.objects;

create policy "Users can read their project backgrounds"
  on storage.objects for select to authenticated
  using (bucket_id = 'project-backgrounds' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users can upload their project backgrounds"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'project-backgrounds' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users can update their project backgrounds"
  on storage.objects for update to authenticated
  using (bucket_id = 'project-backgrounds' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'project-backgrounds' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users can delete their project backgrounds"
  on storage.objects for delete to authenticated
  using (bucket_id = 'project-backgrounds' and (storage.foldername(name))[1] = auth.uid()::text);
