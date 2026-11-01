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
 verified boolean not null default false, display_order integer not null default 1000, reviewer_notes text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
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
alter table public.listings add column if not exists display_order integer not null default 1000;
create or replace function public.is_admin() returns boolean language sql security definer stable set search_path=public as $$select exists(select 1 from admin_users where lower(email)=lower(coalesce(auth.jwt()->>'email','')))$$;
revoke all on public.admin_users from anon,authenticated;
revoke execute on function public.is_admin() from public,anon;
grant execute on function public.is_admin() to authenticated;
drop policy if exists "admins read listings" on public.listings; create policy "admins read listings" on public.listings for select to authenticated using(public.is_admin());
drop policy if exists "admins update listings" on public.listings; create policy "admins update listings" on public.listings for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "admins insert listings" on public.listings; create policy "admins insert listings" on public.listings for insert to authenticated with check(public.is_admin());
drop policy if exists "admins delete listings" on public.listings; create policy "admins delete listings" on public.listings for delete to authenticated using(public.is_admin());
update public.listings set owner_name=contact_name where (owner_name is null or trim(owner_name)='') and contact_name is not null;
drop view if exists public.listings_public;
create or replace view public.listings_public with(security_invoker=false) as select id,name,business_types,directory_category,directory_categories,description,description_ar,description_en,coalesce(nullif(trim(owner_name),''),contact_name) as owner_name,contact_name,position,year_established,employees,governorate,district,town,address,map_url,multiple_locations,phone,whatsapp,email,website,facebook,instagram,products_services,crops,details,logo_url,main_photo_url,additional_photos,works_directly,delivery,service_outside,areas_served,online_available,store_url,managed_by_engineer,engineer_name,verified,display_order from public.listings where status='approved' and consent is not null;
grant select on public.listings_public to anon,authenticated; revoke all on public.listings from anon;
drop policy if exists "public can submit pending listings" on public.listings;
create policy "public can submit pending listings" on public.listings for insert to anon with check(status='pending' and verified=false and reviewer_notes='' and consent is not null and accuracy_confirmation is not null and length(trim(name))>=2);
grant insert on public.listings to anon;
grant select,insert,update,delete on public.listings to authenticated;

-- Agricultural engineers directory applications.
create table if not exists public.engineers(
 id uuid primary key default gen_random_uuid(), full_name text not null, phone text not null, email text not null,
 governorate text not null, district text not null, town text not null, university text not null,
 degree text not null, specialization text not null, experience text not null, expertise text[] not null default '{}',
 bio text not null, linkedin text, file_url text, file_type text, consent boolean not null default false,
 status text not null default 'pending' check(status in('pending','approved','rejected','archived')),
 reviewer_notes text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.engineers enable row level security;
drop policy if exists "public submit engineers" on public.engineers;
create policy "public submit engineers" on public.engineers for insert to anon with check(status='pending' and consent=true and reviewer_notes='');
drop policy if exists "admins read engineers" on public.engineers;
create policy "admins read engineers" on public.engineers for select to authenticated using(public.is_admin());
drop policy if exists "admins update engineers" on public.engineers;
create policy "admins update engineers" on public.engineers for update to authenticated using(public.is_admin()) with check(public.is_admin());
drop policy if exists "admins insert engineers" on public.engineers;
create policy "admins insert engineers" on public.engineers for insert to authenticated with check(public.is_admin());
drop policy if exists "admins delete engineers" on public.engineers;
create policy "admins delete engineers" on public.engineers for delete to authenticated using(public.is_admin());
grant insert on public.engineers to anon;
grant select,insert,update,delete on public.engineers to authenticated;

drop view if exists public.engineers_public;
create view public.engineers_public with(security_invoker=false) as
select id,full_name,phone,email,governorate,district,town,university,degree,specialization,experience,expertise,bio,linkedin,file_url,file_type
from public.engineers where status='approved' and consent=true;
grant select on public.engineers_public to anon,authenticated;

-- Editable website content for the no-code admin panel.
create table if not exists public.site_settings(
 id integer primary key default 1 check(id=1),
 eyebrow_ar text, eyebrow_en text,
 hero_title_ar text, hero_title_en text,
 hero_text_ar text, hero_text_en text,
 about_title_ar text, about_title_en text,
 about_text_ar text, about_text_en text,
 contact_email text, instagram text, whatsapp text, banner_url text,
 brand_name_ar text, brand_name_en text, brand_subtitle text, logo_url text,
 team_eyebrow_ar text, team_eyebrow_en text, team_title_ar text, team_title_en text, team_intro_ar text, team_intro_en text,
 mostafa_name text, mostafa_role_ar text, mostafa_role_en text, mostafa_bio_ar text, mostafa_bio_en text, mostafa_photo_url text, mostafa_linkedin text,
 joe_name text, joe_role_ar text, joe_role_en text, joe_bio_ar text, joe_bio_en text, joe_photo_url text, joe_linkedin text,
 footer_copyright text, developer_credit text,
 updated_at timestamptz not null default now()
);
alter table public.site_settings add column if not exists brand_name_ar text;
alter table public.site_settings add column if not exists brand_name_en text;
alter table public.site_settings add column if not exists brand_subtitle text;
alter table public.site_settings add column if not exists logo_url text;
alter table public.site_settings add column if not exists team_eyebrow_ar text;
alter table public.site_settings add column if not exists team_eyebrow_en text;
alter table public.site_settings add column if not exists team_title_ar text;
alter table public.site_settings add column if not exists team_title_en text;
alter table public.site_settings add column if not exists team_intro_ar text;
alter table public.site_settings add column if not exists team_intro_en text;
alter table public.site_settings add column if not exists mostafa_name text;
alter table public.site_settings add column if not exists mostafa_role_ar text;
alter table public.site_settings add column if not exists mostafa_role_en text;
alter table public.site_settings add column if not exists mostafa_bio_ar text;
alter table public.site_settings add column if not exists mostafa_bio_en text;
alter table public.site_settings add column if not exists mostafa_photo_url text;
alter table public.site_settings add column if not exists mostafa_linkedin text;
alter table public.site_settings add column if not exists joe_name text;
alter table public.site_settings add column if not exists joe_role_ar text;
alter table public.site_settings add column if not exists joe_role_en text;
alter table public.site_settings add column if not exists joe_bio_ar text;
alter table public.site_settings add column if not exists joe_bio_en text;
alter table public.site_settings add column if not exists joe_photo_url text;
alter table public.site_settings add column if not exists joe_linkedin text;
alter table public.site_settings add column if not exists footer_copyright text;
alter table public.site_settings add column if not exists developer_credit text;
alter table public.site_settings enable row level security;
insert into public.site_settings(id,eyebrow_ar,eyebrow_en,hero_title_ar,hero_title_en,hero_text_ar,hero_text_en,about_title_ar,about_title_en,about_text_ar,about_text_en,contact_email,instagram)
values(1,'مبادرة وطنية مستقلة · التسجيل مجاني','Independent national initiative · Free registration','كلّ القطاع الزراعي اللبناني، في مكان واحد.','Lebanon’s agricultural sector, all in one place.','اكتشف المؤسسات والمزارع والخدمات الموثوقة حسب النشاط والمنطقة، وتواصل معها مباشرة.','Discover trusted farms, institutions and agricultural services by activity and location.','هل تعمل في القطاع الزراعي؟','Do you work in agriculture?','سجّل مؤسستك أو نشاطك مجاناً وساعدنا في بناء قاعدة بيانات زراعية شاملة ومفيدة للبنان.','Register your organization for free and help build a comprehensive agricultural database for Lebanon.','agriengineersnetwork@gmail.com','@agri.engineersnetwork')
on conflict(id) do nothing;
drop policy if exists "public read site settings" on public.site_settings;
create policy "public read site settings" on public.site_settings for select to anon,authenticated using(true);
drop policy if exists "admins manage site settings" on public.site_settings;
create policy "admins manage site settings" on public.site_settings for all to authenticated using(public.is_admin()) with check(public.is_admin());
grant select on public.site_settings to anon,authenticated;
grant insert,update on public.site_settings to authenticated;
update public.site_settings set whatsapp='71989783',updated_at=now() where id=1;

-- Public media bucket; only authenticated directory admins may write files.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('agri-media','agri-media',true,8388608,array['image/png','image/jpeg','image/webp','image/svg+xml','application/pdf'])
on conflict(id) do update set public=true,file_size_limit=8388608,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "public read agri media" on storage.objects;
create policy "public read agri media" on storage.objects for select to public using(bucket_id='agri-media');
drop policy if exists "admins upload agri media" on storage.objects;
create policy "admins upload agri media" on storage.objects for insert to authenticated with check(bucket_id='agri-media' and public.is_admin());
drop policy if exists "public upload registration logos" on storage.objects;
create policy "public upload registration logos" on storage.objects for insert to anon with check(bucket_id='agri-media' and (storage.foldername(name))[1]='submissions');
drop policy if exists "admins update agri media" on storage.objects;
create policy "admins update agri media" on storage.objects for update to authenticated using(bucket_id='agri-media' and public.is_admin()) with check(bucket_id='agri-media' and public.is_admin());
drop policy if exists "admins delete agri media" on storage.objects;
create policy "admins delete agri media" on storage.objects for delete to authenticated using(bucket_id='agri-media' and public.is_admin());
-- After creating the admin in Authentication > Users, replace the email below and run it once:
-- insert into public.admin_users(email) values ('YOUR_ADMIN_EMAIL') on conflict do nothing;
