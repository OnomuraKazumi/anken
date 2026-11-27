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

-- ===== 追加：利用者リスト（システム内のアカウント管理） =====
create table if not exists public.allowed_emails (
  email      text primary key check (email = lower(email) and email like '%_@_%'),
  is_admin   boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.allowed_emails enable row level security;

create or replace function public.is_member() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.allowed_emails where email = lower(coalesce(auth.jwt()->>'email','')));
$$;
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.allowed_emails where email = lower(coalesce(auth.jwt()->>'email','')) and is_admin);
$$;
revoke all on function public.is_member() from public, anon;
revoke all on function public.is_admin()  from public, anon;
grant execute on function public.is_member() to authenticated;
grant execute on function public.is_admin()  to authenticated;

drop policy if exists "admins read allowed"   on public.allowed_emails;
drop policy if exists "admins insert allowed" on public.allowed_emails;
drop policy if exists "admins update allowed" on public.allowed_emails;
drop policy if exists "admins delete allowed" on public.allowed_emails;
create policy "admins read allowed"   on public.allowed_emails for select to authenticated using (public.is_admin() or email = lower(coalesce(auth.jwt()->>'email','')));
create policy "admins insert allowed" on public.allowed_emails for insert to authenticated with check (public.is_admin());
create policy "admins update allowed" on public.allowed_emails for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admins delete allowed" on public.allowed_emails for delete to authenticated using (public.is_admin() and email <> lower(coalesce(auth.jwt()->>'email','')));
revoke all on public.allowed_emails from anon;
grant select, insert, update, delete on public.allowed_emails to authenticated;

-- 案件データは「利用者リストに登録された人」だけが使える
drop policy if exists "logged-in users read engineers"   on public.engineers;
drop policy if exists "logged-in users insert engineers" on public.engineers;
drop policy if exists "logged-in users update engineers" on public.engineers;
drop policy if exists "logged-in users delete engineers" on public.engineers;
drop policy if exists "logged-in users read projects"    on public.projects;
drop policy if exists "logged-in users insert projects"  on public.projects;
drop policy if exists "logged-in users update projects"  on public.projects;
drop policy if exists "logged-in users delete projects"  on public.projects;
drop policy if exists "members read engineers"   on public.engineers;
drop policy if exists "members insert engineers" on public.engineers;
drop policy if exists "members update engineers" on public.engineers;
drop policy if exists "members delete engineers" on public.engineers;
drop policy if exists "members read projects"    on public.projects;
drop policy if exists "members insert projects"  on public.projects;
drop policy if exists "members update projects"  on public.projects;
drop policy if exists "members delete projects"  on public.projects;
create policy "members read engineers"   on public.engineers for select to authenticated using (public.is_member());
create policy "members insert engineers" on public.engineers for insert to authenticated with check (public.is_member());
create policy "members update engineers" on public.engineers for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "members delete engineers" on public.engineers for delete to authenticated using (public.is_member());
create policy "members read projects"    on public.projects  for select to authenticated using (public.is_member());
create policy "members insert projects"  on public.projects  for insert to authenticated with check (public.is_member());
create policy "members update projects"  on public.projects  for update to authenticated using (public.is_member()) with check (public.is_member());
create policy "members delete projects"  on public.projects  for delete to authenticated using (public.is_member());

insert into public.allowed_emails (email, is_admin) values ('k-onomura@legarea.jp', true)
on conflict (email) do update set is_admin = true;
