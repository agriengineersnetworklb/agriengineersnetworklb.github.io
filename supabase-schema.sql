create extension if not exists pgcrypto;
create table if not exists public.admin_users(email text primary key);
create table if not exists public.listings(
 id uuid primary key default gen_random_uuid(), name text not null, business_types text[] not null default '{}', description text, description_ar text, description_en text,
 year_established text, employees text, governorate text, district text, town text, address text, map_url text, multiple_locations text,
 contact_name text, position text, phone text, whatsapp text, email text, website text, facebook text, instagram text,
 owner_name text, owner_whatsapp text, managed_by_engineer boolean not null default false, engineer_name text,
 products_services text[] not null default '{}', crops text[] not null default '{}', details text, logo_url text, main_photo_url text,
 additional_photos text[] not null default '{}', works_directly text, delivery text, service_outside text, areas_served text[], online_available text,
 store_url text, accuracy_confirmation text, consent text, status text not null default 'pending' check(status in('pending','approved','rejected','archived')),
 directory_category text check(directory_category in('farm','nursery','laboratory','supplies','irrigation','organization','food','services')),
 directory_categories text[] not null default '{}',
 verified boolean not null default false, reviewer_notes text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.listings enable row level security; alter table public.admin_users enable row level security;
alter table public.listings add column if not exists directory_category text check(directory_category in('farm','nursery','laboratory','supplies','irrigation','organization','food','services'));
alter table public.listings add column if not exists directory_categories text[] not null default '{}';
alter table public.listings add column if not exists owner_name text;
alter table public.listings add column if not exists owner_whatsapp text;
alter table public.listings add column if not exists managed_by_engineer boolean not null default false;
alter table public.listings add column if not exists engineer_name text;
alter table public.listings add column if not exists description_ar text;
alter table public.listings add column if not exists description_en text;
create or replace function public.is_admin() returns boolean language sql security definer stable set search_path=public as $$select exists(select 1 from admin_users where lower(email)=lower(coalesce(auth.jwt()->>'email','')))$$;
drop policy if exists "admins read listings" on public.listings; create policy "admins read listings" on public.listings for select to authenticated using(public.is_admin());
drop policy if exists "admins update listings" on public.listings; create policy "admins update listings" on public.listings for update to authenticated using(public.is_admin()) with check(public.is_admin());
create or replace view public.listings_public with(security_invoker=false) as select id,name,business_types,directory_category,directory_categories,description,description_ar,description_en,owner_name,governorate,district,town,map_url,phone,whatsapp,email,website,facebook,instagram,products_services,crops,details,logo_url,main_photo_url,additional_photos,managed_by_engineer,engineer_name,verified from public.listings where status='approved' and consent is not null;
grant select on public.listings_public to anon,authenticated; revoke all on public.listings from anon;
drop policy if exists "public can submit pending listings" on public.listings;
create policy "public can submit pending listings" on public.listings for insert to anon with check(status='pending' and verified=false and reviewer_notes='' and consent is not null and accuracy_confirmation is not null and length(trim(name))>=2);
grant insert on public.listings to anon;
-- After creating the admin in Authentication > Users, replace the email below and run it once:
-- insert into public.admin_users(email) values ('YOUR_ADMIN_EMAIL') on conflict do nothing;
