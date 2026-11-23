-- Flashcard progress and review history for the GitHub Pages client.
-- Run this once in Supabase SQL Editor. The browser uses only the publishable/anon key.

create table if not exists public.flashcard_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id text not null,
  fsrs_card jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, card_id)
);

create table if not exists public.flashcard_reviews (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id text not null,
  rating smallint not null check (rating between 1 and 4),
  reviewed_at timestamptz not null,
  due_at timestamptz not null,
  difficulty double precision not null,
  stability double precision not null,
  stability_fast double precision not null,
  revlog jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.flashcard_progress enable row level security;
alter table public.flashcard_reviews enable row level security;

drop policy if exists "Users manage their own flashcard progress" on public.flashcard_progress;
create policy "Users manage their own flashcard progress"
  on public.flashcard_progress for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "Users read their own flashcard reviews" on public.flashcard_reviews;
create policy "Users read their own flashcard reviews"
  on public.flashcard_reviews for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "Users insert their own flashcard reviews" on public.flashcard_reviews;
create policy "Users insert their own flashcard reviews"
  on public.flashcard_reviews for insert to authenticated
  with check (user_id = (select auth.uid()));

grant select, insert, update, delete on public.flashcard_progress to authenticated;
grant select, insert on public.flashcard_reviews to authenticated;

grant usage, select on sequence public.flashcard_reviews_id_seq to authenticated;

create or replace function public.review_flashcard(
  p_card_id text,
  p_fsrs_card jsonb,
  p_review jsonb
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;
  if p_card_id is null or length(p_card_id) > 160 then
    raise exception 'Invalid card id';
  end if;
  if (p_review->>'rating')::smallint not between 1 and 4 then
    raise exception 'Invalid rating';
  end if;

  insert into public.flashcard_progress (user_id, card_id, fsrs_card, updated_at)
  values (current_user_id, p_card_id, p_fsrs_card, now())
  on conflict (user_id, card_id) do update
    set fsrs_card = excluded.fsrs_card,
        updated_at = excluded.updated_at;

  insert into public.flashcard_reviews (
    user_id, card_id, rating, reviewed_at, due_at,
    difficulty, stability, stability_fast, revlog
  ) values (
    current_user_id,
    p_card_id,
    (p_review->>'rating')::smallint,
    (p_review->>'reviewed_at')::timestamptz,
    (p_review->>'due_at')::timestamptz,
    (p_review->>'difficulty')::double precision,
    (p_review->>'stability')::double precision,
    (p_review->>'stability_fast')::double precision,
    p_review->'revlog'
  );
end;
$$;

grant execute on function public.review_flashcard(text, jsonb, jsonb) to authenticated;

-- Public shared mode: all visitors share one deck. This intentionally permits
-- anonymous reads and writes, so do not store private data in these tables.
create table if not exists public.shared_flashcard_progress (
  card_id text primary key,
  fsrs_card jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.shared_flashcard_reviews (
  id bigint generated always as identity primary key,
  card_id text not null,
  rating smallint not null check (rating between 1 and 4),
  reviewed_at timestamptz not null,
  due_at timestamptz not null,
  difficulty double precision not null,
  stability double precision not null,
  stability_fast double precision not null,
  revlog jsonb not null,
  created_at timestamptz not null default now()
);

alter table public.shared_flashcard_progress enable row level security;
alter table public.shared_flashcard_reviews enable row level security;

drop policy if exists "Public shared flashcard progress" on public.shared_flashcard_progress;
create policy "Public shared flashcard progress"
  on public.shared_flashcard_progress for all to anon, authenticated
  using (true)
  with check (true);

drop policy if exists "Public shared flashcard reviews" on public.shared_flashcard_reviews;
create policy "Public shared flashcard reviews"
  on public.shared_flashcard_reviews for all to anon, authenticated
  using (true)
  with check (true);

grant select, insert, update, delete on public.shared_flashcard_progress to anon, authenticated;
grant select, insert, update, delete on public.shared_flashcard_reviews to anon, authenticated;
grant usage, select on sequence public.shared_flashcard_reviews_id_seq to anon, authenticated;

create or replace function public.review_shared_flashcard(
  p_card_id text,
  p_fsrs_card jsonb,
  p_review jsonb
) returns void
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if p_card_id is null or length(p_card_id) > 160 then
    raise exception 'Invalid card id';
  end if;
  if (p_review->>'rating')::smallint not between 1 and 4 then
    raise exception 'Invalid rating';
  end if;

  insert into public.shared_flashcard_progress (card_id, fsrs_card, updated_at)
  values (p_card_id, p_fsrs_card, now())
  on conflict (card_id) do update
    set fsrs_card = excluded.fsrs_card,
        updated_at = excluded.updated_at;

  insert into public.shared_flashcard_reviews (
    card_id, rating, reviewed_at, due_at,
    difficulty, stability, stability_fast, revlog
  ) values (
    p_card_id,
    (p_review->>'rating')::smallint,
    (p_review->>'reviewed_at')::timestamptz,
    (p_review->>'due_at')::timestamptz,
    (p_review->>'difficulty')::double precision,
    (p_review->>'stability')::double precision,
    (p_review->>'stability_fast')::double precision,
    p_review->'revlog'
  );
end;
$$;

grant execute on function public.review_shared_flashcard(text, jsonb, jsonb) to anon, authenticated;
