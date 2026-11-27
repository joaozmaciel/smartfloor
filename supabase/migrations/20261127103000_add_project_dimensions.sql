alter table public.projects
  add column if not exists width_m numeric
    check (width_m is null or width_m > 0),
  add column if not exists length_m numeric
    check (length_m is null or length_m > 0),
  add column if not exists height_m numeric
    check (height_m is null or height_m > 0);
