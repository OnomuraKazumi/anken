-- エンジニア案件管理：データベース設定（AnkenKanri.PJ には適用済み。作り直すときだけ SQL Editor で実行）
-- ログインしたユーザーだけがデータを読み書きできます（未ログインの人には何も見えません）。

create extension if not exists pgcrypto;

-- エンジニア
create table if not exists public.engineers (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (length(trim(name)) > 0),
  role        text not null default '',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 案件（月単価・開始月・終了月）
create table if not exists public.projects (
  id           uuid primary key default gen_random_uuid(),
  title        text not null check (length(trim(title)) > 0),
  client       text not null default '',
  engineer_id  uuid not null references public.engineers(id) on delete restrict,
  price        integer not null check (price >= 0),
  start_month  text not null check (start_month ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  end_month    text check (end_month is null or end_month ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  note         text not null default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check (end_month is null or end_month >= start_month)
);
create index if not exists projects_engineer_idx on public.projects(engineer_id);

-- 更新日時を自動で入れる
create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists engineers_touch on public.engineers;
create trigger engineers_touch before update on public.engineers for each row execute function public.touch_updated_at();
drop trigger if exists projects_touch on public.projects;
create trigger projects_touch before update on public.projects for each row execute function public.touch_updated_at();

-- アクセス制限（Row Level Security）：ログイン済みユーザーのみ
alter table public.engineers enable row level security;
alter table public.projects  enable row level security;

drop policy if exists "logged-in users read engineers"   on public.engineers;
drop policy if exists "logged-in users insert engineers" on public.engineers;
drop policy if exists "logged-in users update engineers" on public.engineers;
drop policy if exists "logged-in users delete engineers" on public.engineers;
drop policy if exists "logged-in users read projects"    on public.projects;
drop policy if exists "logged-in users insert projects"  on public.projects;
drop policy if exists "logged-in users update projects"  on public.projects;
drop policy if exists "logged-in users delete projects"  on public.projects;

create policy "logged-in users read engineers"   on public.engineers for select to authenticated using (true);
create policy "logged-in users insert engineers" on public.engineers for insert to authenticated with check (true);
create policy "logged-in users update engineers" on public.engineers for update to authenticated using (true) with check (true);
create policy "logged-in users delete engineers" on public.engineers for delete to authenticated using (true);
create policy "logged-in users read projects"    on public.projects  for select to authenticated using (true);
create policy "logged-in users insert projects"  on public.projects  for insert to authenticated with check (true);
create policy "logged-in users update projects"  on public.projects  for update to authenticated using (true) with check (true);
create policy "logged-in users delete projects"  on public.projects  for delete to authenticated using (true);

-- 未ログイン（anon）からは一切触れないようにする
revoke all on public.engineers from anon;
revoke all on public.projects  from anon;
grant select, insert, update, delete on public.engineers to authenticated;
grant select, insert, update, delete on public.projects  to authenticated;
