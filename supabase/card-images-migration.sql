begin;
-- Optional image per card, stored in the public card-images bucket.
alter table public.shared_flashcards add column if not exists image_path text;
alter table public.shared_flashcards add column if not exists image_side text not null default 'back' check (image_side in ('front','back'));
grant update (image_path, image_side) on public.shared_flashcards to anon, authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('card-images','card-images',true,5242880,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set public=true,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "Visitors upload card images" on storage.objects;
create policy "Visitors upload card images" on storage.objects for insert to anon, authenticated
with check (bucket_id='card-images' and (storage.foldername(name))[1]='cards');
notify pgrst, 'reload schema';
commit;
