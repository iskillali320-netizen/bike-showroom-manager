-- Bike Showroom Manager — database setup
-- Run this whole file in Supabase: SQL Editor → New query → paste → Run.
-- It is safe to run again after updates (it only adds or replaces; it never deletes your data).
-- Every table is locked by Row Level Security: a user only sees rows of showrooms they belong to.

-- gen_random_uuid() is built into Postgres 13+ (Supabase uses 15+).

-- ---------- Tables ----------
create table if not exists public.showrooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text default '',
  phone text default '',
  ntn text default '',
  strn text default '',
  tax_rate numeric not null default 18,
  prefix text not null default 'INV-',
  created_at timestamptz not null default now()
);

create table if not exists public.members (
  showroom_id uuid not null references public.showrooms(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text default '',
  role text not null default 'staff' check (role in ('owner','staff')),
  created_at timestamptz not null default now(),
  primary key (showroom_id, user_id)
);

create table if not exists public.invites (
  id uuid primary key default gen_random_uuid(),
  showroom_id uuid not null references public.showrooms(id) on delete cascade,
  email text not null,
  role text not null default 'staff' check (role in ('owner','staff')),
  created_at timestamptz not null default now(),
  unique (showroom_id, email)
);

create table if not exists public.parties (
  id uuid primary key default gen_random_uuid(),
  showroom_id uuid not null references public.showrooms(id) on delete cascade,
  type text not null default 'customer' check (type in ('dealer','customer')),
  name text not null,
  phone text default '',
  cnic text default '',
  ntn text default '',
  address text default '',
  created_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  showroom_id uuid not null references public.showrooms(id) on delete cascade,
  no text not null,
  date date not null default current_date,
  party_id uuid references public.parties(id) on delete restrict,
  party_name text default '',
  party_type text default 'customer',
  buyer_cnic text default '',
  buyer_ntn text default '',
  fbr_no text default '',
  items jsonb not null default '[]'::jsonb,
  subtotal numeric not null default 0,
  tax_rate numeric not null default 0,
  tax numeric not null default 0,
  further_rate numeric not null default 0,
  further_tax numeric not null default 0,
  total numeric not null default 0,
  plan text not null default 'full' check (plan in ('full','instalment')),
  down numeric,
  months int,
  start_date date,
  notes text default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  unique (showroom_id, no)
);

create table if not exists public.bikes (
  id uuid primary key default gen_random_uuid(),
  showroom_id uuid not null references public.showrooms(id) on delete cascade,
  received_date date default current_date,
  model text not null default '',
  colour text default '',
  engine text default '',
  chassis text default '',
  challan text default '',
  cost numeric default 0,
  status text not null default 'in_stock' check (status in ('in_stock','sold')),
  invoice_id uuid references public.invoices(id) on delete set null,
  sold_to uuid references public.parties(id) on delete set null,
  sold_date date,
  created_at timestamptz not null default now()
);
create unique index if not exists bikes_chassis_unique on public.bikes (showroom_id, upper(chassis)) where chassis <> '';

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  showroom_id uuid not null references public.showrooms(id) on delete cascade,
  party_id uuid references public.parties(id) on delete cascade,
  invoice_id uuid references public.invoices(id) on delete cascade,
  amount numeric not null check (amount > 0),
  date date not null default current_date,
  method text default 'Cash',
  ref text default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);

create index if not exists bikes_shop on public.bikes(showroom_id);
create index if not exists parties_shop on public.parties(showroom_id);
create index if not exists invoices_shop on public.invoices(showroom_id);
create index if not exists payments_shop on public.payments(showroom_id);
create index if not exists members_user on public.members(user_id);

-- ---------- Access helpers ----------
create or replace function public.is_member(sid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members where showroom_id = sid and user_id = auth.uid());
$$;

create or replace function public.is_owner(sid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from members where showroom_id = sid and user_id = auth.uid() and role = 'owner');
$$;

-- ---------- Row Level Security ----------
alter table public.showrooms enable row level security;
alter table public.members   enable row level security;
alter table public.invites   enable row level security;
alter table public.parties   enable row level security;
alter table public.invoices  enable row level security;
alter table public.bikes     enable row level security;
alter table public.payments  enable row level security;

drop policy if exists showrooms_read on public.showrooms;
create policy showrooms_read on public.showrooms for select using (public.is_member(id));
drop policy if exists showrooms_update on public.showrooms;
create policy showrooms_update on public.showrooms for update using (public.is_owner(id)) with check (public.is_owner(id));

drop policy if exists members_read on public.members;
create policy members_read on public.members for select using (user_id = auth.uid() or public.is_member(showroom_id));
drop policy if exists members_delete on public.members;
create policy members_delete on public.members for delete using (public.is_owner(showroom_id) and user_id <> auth.uid());

drop policy if exists invites_owner on public.invites;
create policy invites_owner on public.invites for all using (public.is_owner(showroom_id)) with check (public.is_owner(showroom_id));

-- parties, bikes, payments: members read/add/change; only owners delete
do $$
declare t text;
begin
  foreach t in array array['parties','bikes','payments'] loop
    execute format('drop policy if exists %1$s_read on public.%1$s', t);
    execute format('create policy %1$s_read on public.%1$s for select using (public.is_member(showroom_id))', t);
    execute format('drop policy if exists %1$s_insert on public.%1$s', t);
    execute format('create policy %1$s_insert on public.%1$s for insert with check (public.is_member(showroom_id))', t);
    execute format('drop policy if exists %1$s_update on public.%1$s', t);
    execute format('create policy %1$s_update on public.%1$s for update using (public.is_member(showroom_id)) with check (public.is_member(showroom_id))', t);
    execute format('drop policy if exists %1$s_delete on public.%1$s', t);
    execute format('create policy %1$s_delete on public.%1$s for delete using (public.is_owner(showroom_id))', t);
  end loop;
end $$;

-- invoices: created and deleted only through the functions below; members may edit (e.g. FBR number)
drop policy if exists invoices_read on public.invoices;
create policy invoices_read on public.invoices for select using (public.is_member(showroom_id));
drop policy if exists invoices_update on public.invoices;
create policy invoices_update on public.invoices for update using (public.is_member(showroom_id)) with check (public.is_member(showroom_id));

-- ---------- Functions the app calls ----------
create or replace function public.create_showroom(p_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
  if auth.uid() is null then raise exception 'Please sign in first'; end if;
  if coalesce(trim(p_name),'') = '' then raise exception 'Enter the showroom name'; end if;
  insert into showrooms(name) values (trim(p_name)) returning id into sid;
  insert into members(showroom_id, user_id, email, role) values (sid, auth.uid(), coalesce(auth.jwt()->>'email',''), 'owner');
  return sid;
end $$;

create or replace function public.accept_invites() returns int
language plpgsql security definer set search_path = public as $$
declare n int := 0; my_email text;
begin
  if auth.uid() is null then return 0; end if;
  -- Use the email stored on the account, and only once it has been confirmed,
  -- so nobody can claim an invite by signing up with someone else's address.
  select lower(email) into my_email from auth.users where id = auth.uid() and email_confirmed_at is not null;
  if coalesce(my_email,'') = '' then return 0; end if;
  insert into members(showroom_id, user_id, email, role)
    select showroom_id, auth.uid(), my_email, role from invites where lower(email) = my_email
    on conflict (showroom_id, user_id) do nothing;
  get diagnostics n = row_count;
  delete from invites where lower(email) = my_email;
  return n;
end $$;

-- Creates an invoice with the next number, marks its bikes sold and records money received, all in one step.
create or replace function public.create_invoice(p jsonb, pay jsonb default null) returns public.invoices
language plpgsql security definer set search_path = public as $$
declare
  sid uuid := (p->>'showroom_id')::uuid;
  v_prefix text; v_max int; v_no text; inv invoices; item jsonb; n int; pr parties;
begin
  if not is_member(sid) then raise exception 'You are not a member of this showroom'; end if;
  if jsonb_array_length(coalesce(p->'items','[]'::jsonb)) = 0 then raise exception 'Add at least one bike'; end if;
  select * into pr from parties where id = (p->>'party_id')::uuid and showroom_id = sid;
  if pr.id is null then raise exception 'Choose a dealer or customer'; end if;
  perform pg_advisory_xact_lock(hashtext(sid::text));
  select prefix into v_prefix from showrooms where id = sid;
  select coalesce(max((substring(no from '(\d+)\s*$'))::int), 0) into v_max from invoices where showroom_id = sid;
  v_no := coalesce(v_prefix,'INV-') || lpad((v_max + 1)::text, 4, '0');
  insert into invoices(showroom_id, no, date, party_id, party_name, party_type, buyer_cnic, buyer_ntn, fbr_no, items,
                       subtotal, tax_rate, tax, further_rate, further_tax, total, plan, down, months, start_date, notes)
  values (sid, v_no, coalesce((p->>'date')::date, current_date), pr.id, pr.name, pr.type, coalesce(pr.cnic,''), coalesce(pr.ntn,''),
          coalesce(p->>'fbr_no',''), p->'items',
          coalesce((p->>'subtotal')::numeric,0), coalesce((p->>'tax_rate')::numeric,0), coalesce((p->>'tax')::numeric,0),
          coalesce((p->>'further_rate')::numeric,0), coalesce((p->>'further_tax')::numeric,0), coalesce((p->>'total')::numeric,0),
          coalesce(p->>'plan','full'), nullif(p->>'down','')::numeric, nullif(p->>'months','')::int, nullif(p->>'start_date','')::date,
          coalesce(p->>'notes',''))
  returning * into inv;
  for item in select * from jsonb_array_elements(p->'items') loop
    update bikes set status = 'sold', invoice_id = inv.id, sold_to = pr.id, sold_date = inv.date
      where id = (item->>'bikeId')::uuid and showroom_id = sid and status = 'in_stock';
    get diagnostics n = row_count;
    if n = 0 then raise exception 'Bike % is no longer in stock', coalesce(item->>'engine', item->>'bikeId'); end if;
  end loop;
  if pay is not null and coalesce((pay->>'amount')::numeric, 0) > 0 then
    insert into payments(showroom_id, party_id, invoice_id, amount, date, method, ref)
    values (sid, pr.id, inv.id, (pay->>'amount')::numeric, inv.date, coalesce(pay->>'method','Cash'), coalesce(pay->>'ref','At sale'));
  end if;
  return inv;
end $$;

-- Deletes an invoice and its payments and returns its bikes to stock (owners only).
create or replace function public.delete_invoice(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
  select showroom_id into sid from invoices where id = p_id;
  if sid is null then raise exception 'Invoice not found'; end if;
  if not is_owner(sid) then raise exception 'Only the owner can delete invoices'; end if;
  update bikes set status = 'in_stock', invoice_id = null, sold_to = null, sold_date = null where invoice_id = p_id;
  delete from payments where invoice_id = p_id;
  delete from invoices where id = p_id;
end $$;

revoke all on function public.create_showroom(text), public.accept_invites(), public.create_invoice(jsonb, jsonb), public.delete_invoice(uuid) from public, anon;
grant execute on function public.create_showroom(text), public.accept_invites(), public.create_invoice(jsonb, jsonb), public.delete_invoice(uuid) to authenticated;
grant execute on function public.is_member(uuid), public.is_owner(uuid) to authenticated;

-- ---------- Hardening ----------
-- Linked rows must belong to the same showroom (stops pointing a payment or bike at another showroom's records).
create or replace function public.check_same_showroom() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.invoice_id is not null and not exists (select 1 from invoices where id = new.invoice_id and showroom_id = new.showroom_id) then
    raise exception 'Invoice belongs to another showroom';
  end if;
  if tg_table_name = 'payments' then
    if new.party_id is not null and not exists (select 1 from parties where id = new.party_id and showroom_id = new.showroom_id) then
      raise exception 'Dealer/customer belongs to another showroom';
    end if;
  elsif tg_table_name = 'bikes' then
    if new.sold_to is not null and not exists (select 1 from parties where id = new.sold_to and showroom_id = new.showroom_id) then
      raise exception 'Dealer/customer belongs to another showroom';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists payments_same_showroom on public.payments;
create trigger payments_same_showroom before insert or update on public.payments for each row execute function public.check_same_showroom();
drop trigger if exists bikes_same_showroom on public.bikes;
create trigger bikes_same_showroom before insert or update on public.bikes for each row execute function public.check_same_showroom();

-- Explicit table privileges (RLS still applies on top of these). Signed-out visitors get nothing.
revoke all on public.showrooms, public.members, public.invites, public.parties, public.invoices, public.bikes, public.payments from anon;
revoke all on public.showrooms, public.members, public.invites, public.parties, public.invoices, public.bikes, public.payments from authenticated;
grant select on public.showrooms to authenticated;
grant update (name, address, phone, ntn, strn, tax_rate, prefix) on public.showrooms to authenticated;
grant select, delete on public.members to authenticated;
grant select, insert, delete on public.invites to authenticated;
grant select, insert, update, delete on public.parties, public.bikes, public.payments to authenticated;
-- Invoices are created/deleted only by the functions; in the app only the FBR number and notes can be edited.
grant select on public.invoices to authenticated;
grant update (fbr_no, notes) on public.invoices to authenticated;

revoke all on function public.is_member(uuid), public.is_owner(uuid), public.check_same_showroom() from public, anon;
grant execute on function public.is_member(uuid), public.is_owner(uuid) to authenticated;

-- ---------- Live updates ----------
do $$
declare t text;
begin
  foreach t in array array['showrooms','parties','invoices','bikes','payments'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;
