-- 阿旺小厨房 数据库升级 SQL
-- 在 Supabase SQL Editor 里执行（在原有 schema.sql 基础上执行）

-- =============================================
-- 5. 客户表（白名单机制）
-- =============================================
create table if not exists public.customers (
  id serial primary key,
  name text unique not null,
  phone text default '',
  address text default '',
  note text default '',
  created_at timestamp with time zone default now()
);

alter table public.customers enable row level security;

create policy "customers_public_read"
  on public.customers
  for select
  using (true);

create policy "customers_admin_all"
  on public.customers
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- =============================================
-- 6. orders 表新增字段
-- =============================================
alter table public.orders
  add column if not exists expected_time timestamp with time zone;

-- =============================================
-- 开放 orders 表的 public insert 权限（匿名用户提交订单）
-- =============================================
drop policy if exists "orders_customer_insert" on public.orders;
create policy "orders_public_insert"
  on public.orders
  for insert
  with check (true);

-- 允许匿名用户查看订单（管理员后台需要）
drop policy if exists "orders_admin_read" on public.orders;
create policy "orders_public_read"
  on public.orders
  for select
  using (true);
