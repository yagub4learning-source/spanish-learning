begin;
-- Vocabulary registry. Accents remain meaningful (sí and si are different words).
create or replace function public.normalize_spanish_word(value text)
returns text language sql immutable strict set search_path = ''
as $$ select lower(regexp_replace(btrim(normalize(value, NFC)), '[[:space:]]+', ' ', 'g')); $$;

create table if not exists public.words (
  id uuid primary key default gen_random_uuid(),
  word text not null,
  normalized_word text generated always as (public.normalize_spanish_word(word)) stored unique,
  created_at timestamptz not null default now()
);
alter table public.words enable row level security;
revoke all on public.words from public, anon, authenticated;
grant select, insert, update, delete on public.words to service_role;
alter table public.shared_flashcards add column if not exists word_id uuid references public.words(id);

-- Import already generated words without changing card IDs or review history.
insert into public.words(word)
select distinct split_part(category, ' · ', 2) from public.shared_flashcards
where category like 'AI word · %'
on conflict (normalized_word) do nothing;
update public.shared_flashcards c set word_id = w.id
from public.words w where c.category like 'AI word · %'
and public.normalize_spanish_word(split_part(c.category, ' · ', 2)) = w.normalized_word
and c.word_id is null;

-- Generated vocabulary is inserted by the generate-word-cards Edge Function
-- using its service role key. Visitors cannot write directly to the deck.
create or replace function public.add_generated_word_cards(
  p_word text,
  p_cards jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  next_order integer;
  vocabulary_id uuid;
  card jsonb;
  expected_types text[] := array['Recognition', 'Recall', 'Cloze'];
  actual_types text[];
begin
  if p_word is null or length(btrim(p_word)) not between 1 and 80 then
    raise exception 'Invalid word';
  end if;
  if jsonb_typeof(p_cards) <> 'array' or jsonb_array_length(p_cards) <> 3 then
    raise exception 'Exactly three generated cards are required';
  end if;

  select array_agg(value->>'type' order by value->>'type')
    into actual_types from jsonb_array_elements(p_cards);
  if actual_types is distinct from array['Cloze', 'Recall', 'Recognition']::text[] then
    raise exception 'Invalid generated card types';
  end if;
  for card in select value from jsonb_array_elements(p_cards) loop
    if coalesce(card->>'card_id', '') = '' or
       length(card->>'card_id') > 160 or
       coalesce(card->>'front', '') = '' or
       coalesce(card->>'back', '') = '' or
       coalesce(card->>'category', '') not like 'AI word · %' then
      raise exception 'Invalid generated card';
    end if;
  end loop;

  insert into public.words(word) values (p_word) returning id into vocabulary_id;

  perform pg_advisory_xact_lock(hashtext('shared_flashcards_sort_order'));
  select coalesce(max(sort_order), 0) + 1 into next_order
    from public.shared_flashcards;

  insert into public.shared_flashcards (card_id, front, back, category, sort_order, word_id)
  select generated.card->>'card_id', generated.card->>'front',
         generated.card->>'back', generated.card->>'category',
         next_order + row_number() over (order by generated.card->>'type')::integer - 1, vocabulary_id
    from jsonb_array_elements(p_cards) as generated(card);
end;
$$;

revoke all on function public.add_generated_word_cards(text, jsonb) from public, anon, authenticated;
grant execute on function public.add_generated_word_cards(text, jsonb) to service_role;

notify pgrst, 'reload schema';

commit;
