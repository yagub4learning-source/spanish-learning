begin;

-- Delete a card and its shared review data in one transaction.
create or replace function public.delete_shared_flashcard(p_card_id text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  saved_image_path text;
begin
  if p_card_id is null or length(p_card_id) > 160 then
    raise exception 'Invalid card id';
  end if;

  select image_path into saved_image_path
  from public.shared_flashcards
  where card_id = p_card_id
  for update;

  if not found then
    raise exception 'Card not found';
  end if;

  delete from public.shared_flashcard_reviews where card_id = p_card_id;
  delete from public.shared_flashcard_progress where card_id = p_card_id;
  delete from public.shared_flashcards where card_id = p_card_id;

  return saved_image_path;
end;
$$;

revoke all on function public.delete_shared_flashcard(text) from public, anon, authenticated;
grant execute on function public.delete_shared_flashcard(text) to anon, authenticated;

drop policy if exists "Visitors delete card images" on storage.objects;
create policy "Visitors delete card images" on storage.objects
  for delete to anon, authenticated
  using (bucket_id = 'card-images' and (storage.foldername(name))[1] = 'cards');

notify pgrst, 'reload schema';
commit;
