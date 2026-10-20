-- Run once in Supabase SQL Editor. Never put service-role keys in your website.
create extension if not exists pgcrypto;
create table public.admins (user_id uuid primary key references auth.users(id) on delete cascade);
create table public.profiles (
 id uuid primary key default gen_random_uuid(), owner_id uuid unique not null references auth.users(id) on delete cascade,
 slug text unique not null default encode(gen_random_bytes(12),'hex'),
 name text not null default '', title text default '', company text default '', bio text default '',
 phone text default '', email text default '', avatar_url text default '',
 instagram text default '', tiktok text default '', snapchat text default '', facebook text default '',
 linkedin text default '', whatsapp text default '', website text default '',
 published boolean not null default false, created_at timestamptz not null default now()
);
create table public.cards (
 id uuid primary key default gen_random_uuid(), token text unique not null default encode(gen_random_bytes(16),'hex'),
 profile_id uuid references public.profiles(id) on delete set null, active boolean not null default false,
 created_at timestamptz not null default now()
);
create index cards_profile_idx on public.cards(profile_id);
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.admins where user_id=(select auth.uid()));
$$;
revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;
alter table public.admins enable row level security;
alter table public.profiles enable row level security;
alter table public.cards enable row level security;
create policy admin_self on public.admins for select to authenticated using (user_id=(select auth.uid()));
create policy profile_owner_read on public.profiles for select to authenticated using (owner_id=(select auth.uid()));
create policy profile_owner_insert on public.profiles for insert to authenticated with check (owner_id=(select auth.uid()));
create policy profile_owner_update on public.profiles for update to authenticated using (owner_id=(select auth.uid())) with check (owner_id=(select auth.uid()));
create policy admin_cards_read on public.cards for select to authenticated using ((select public.is_admin()));
-- Public views expose only published profiles. For strong isolation use RPCs below with explicit access checks.
create function public.get_public_profile(p_slug text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r public.profiles%rowtype;
begin
 select * into r from public.profiles where slug=p_slug and published=true;
 if not found then return null; end if;
 return jsonb_build_object('name',r.name,'title',r.title,'company',r.company,'bio',r.bio,'phone',r.phone,'email',r.email,'avatar_url',r.avatar_url,'instagram',r.instagram,'tiktok',r.tiktok,'snapchat',r.snapchat,'facebook',r.facebook,'linkedin',r.linkedin,'whatsapp',r.whatsapp,'website',r.website);
end $$;
create function public.get_public_card(p_token text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare r public.cards%rowtype;
begin
 select * into r from public.cards where token=p_token and active=true;
 if not found or r.profile_id is null then return null; end if;
 return (select public.get_public_profile(p.slug) from public.profiles p where p.id=r.profile_id);
end $$;
revoke all on function public.get_public_profile(text),public.get_public_card(text) from public;
grant execute on function public.get_public_profile(text),public.get_public_card(text) to anon,authenticated;
create function public.admin_create_card() returns text language plpgsql security definer set search_path='' as $$
declare t text;
begin
 if not public.is_admin() then raise exception 'Not authorized'; end if;
 insert into public.cards default values returning token into t;
 return t;
end $$;
create function public.admin_assign_card(p_card_id uuid,p_customer_email text) returns void language plpgsql security definer set search_path='' as $$
declare pid uuid;
begin
 if not public.is_admin() then raise exception 'Not authorized'; end if;
 select p.id into pid from public.profiles p join auth.users u on u.id=p.owner_id where lower(u.email)=lower(trim(p_customer_email));
 if pid is null then raise exception 'Customer must register and create a profile first'; end if;
 update public.cards set profile_id=pid,active=true where id=p_card_id;
 if not found then raise exception 'Card not found'; end if;
end $$;
create function public.admin_set_card_active(p_card_id uuid,p_active boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_admin() then raise exception 'Not authorized'; end if;
 update public.cards set active=p_active where id=p_card_id;
end $$;
revoke all on function public.admin_create_card(),public.admin_assign_card(uuid,text),public.admin_set_card_active(uuid,boolean) from public;
grant execute on function public.admin_create_card(),public.admin_assign_card(uuid,text),public.admin_set_card_active(uuid,boolean) to authenticated;
-- AFTER registering your own account, run this separately in SQL editor, replacing the email:
-- insert into public.admins(user_id) select id from auth.users where email='YOUR_ADMIN_EMAIL';
