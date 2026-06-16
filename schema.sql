-- ============================================================
-- PPL 트레이닝 일지 — Supabase 스키마 (own-data-only)
-- Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 RUN 하세요.
-- 재실행 안전(idempotent). 각자 본인 기록만 보고/쓰기 가능.
-- ============================================================
create extension if not exists pgcrypto;

-- 1) 세션: 날짜 + 운동(하루 1인) ------------------------------------
create table if not exists public.ppl_sessions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  session_date  date not null,
  day_type      text not null check (day_type in ('push','pull','legs')),
  week_block    text not null default 'S' check (week_block in ('S','H')),  -- 스트렝스/하이퍼트로피
  level_mode    text not null default 'adv' check (level_mode in ('adv','onb')),
  condition     smallint check (condition between 1 and 3),  -- 😣1 😐2 😀3
  bodyweight_kg numeric(5,2),
  sleep_hours   numeric(3,1),
  is_deload     boolean not null default false,
  memo          text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (user_id, session_date, day_type),  -- 하루 같은 운동 1회(upsert 키)
  unique (id, user_id)                        -- entries 복합 FK 대상
);

-- 2) 종목 기록 ------------------------------------------------------
create table if not exists public.ppl_entries (
  id            uuid primary key default gen_random_uuid(),
  session_id    uuid not null,
  user_id       uuid not null default auth.uid(),
  session_date  date not null,                  -- 추세 쿼리용 비정규화(created_at 아님)
  week_block    text not null default 'S' check (week_block in ('S','H')),
  exercise_key  text not null,                  -- 'push-0' 등 (DAYS 키)
  exercise_name text,                           -- A/B 선택 종목의 실제 수행 변형
  weight_kg     numeric(6,2),
  reps          smallint,
  rir           smallint check (rir between 0 and 10),
  note          text,
  created_at    timestamptz not null default now(),
  unique (session_id, exercise_key),            -- 종목당 1행(upsert 키)
  foreign key (session_id, user_id)             -- 자식 소유자 = 부모 세션 소유자 강제
    references public.ppl_sessions (id, user_id) on delete cascade
);

-- 3) updated_at 자동 갱신 ------------------------------------------
create or replace function public.touch_updated_at() returns trigger
  language plpgsql as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists trg_ppl_sessions_touch on public.ppl_sessions;
create trigger trg_ppl_sessions_touch before update on public.ppl_sessions
  for each row execute function public.touch_updated_at();

-- 4) 인덱스 --------------------------------------------------------
create index if not exists ppl_sessions_user_date_idx
  on public.ppl_sessions(user_id, session_date desc);
create index if not exists ppl_entries_user_ex_date_idx
  on public.ppl_entries(user_id, exercise_key, session_date desc);
create index if not exists ppl_entries_session_idx
  on public.ppl_entries(session_id);

-- 5) RLS: 본인 행만 (anon 정책 없음 = 기본 거부) --------------------
alter table public.ppl_sessions enable row level security;
alter table public.ppl_sessions force  row level security;
alter table public.ppl_entries  enable row level security;
alter table public.ppl_entries  force  row level security;

drop policy if exists ppl_sessions_own on public.ppl_sessions;
create policy ppl_sessions_own on public.ppl_sessions
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists ppl_entries_own on public.ppl_entries;
create policy ppl_entries_own on public.ppl_entries
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- 6) GRANT: anon 차단 + 로그인 사용자만 ---------------------------
--    (신규 테이블은 자동 노출되지 않으므로 GRANT 필수)
revoke all on public.ppl_sessions from anon, public;
revoke all on public.ppl_entries  from anon, public;
grant select, insert, update, delete on public.ppl_sessions to authenticated;
grant select, insert, update, delete on public.ppl_entries  to authenticated;

-- ============================================================
-- 7) 실행 후 검증 (선택) — 아래 두 쿼리를 따로 돌려 확인
--    (a) RLS 켜짐/강제: 두 테이블 모두 true,true 여야 함
--    (b) anon/public 권한: 결과가 0행이어야 안전
-- ============================================================
-- select relname, relrowsecurity, relforcerowsecurity from pg_class
--   where relname in ('ppl_sessions','ppl_entries');
-- select grantee, privilege_type from information_schema.role_table_grants
--   where table_schema='public' and table_name in ('ppl_sessions','ppl_entries')
--     and grantee in ('anon','public');
