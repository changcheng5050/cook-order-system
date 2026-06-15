-- ============================================
-- v2.0.0 升级 SQL：修复 customers 表 RLS 问题
-- ============================================

-- 1. 确保 customers 表存在
create table if not exists public.customers (
  id serial primary key,
  name text unique not null,
  phone text,
  address text,
  note text,
  created_at timestamp default now()
);

-- 2. orders 表新增 expected_time 字段
alter table public.orders add column if not exists expected_time timestamp;

-- 3. 开启 customers 表的 RLS
alter table public.customers enable row level security;

-- 4. 删除旧策略（如有），避免冲突
drop policy if exists "允许匿名用户查看客户" on public.customers;
drop policy if exists "允许匿名用户新增客户" on public.customers;
drop policy if exists "允许匿名用户更新客户" on public.customers;
drop policy if exists "允许匿名用户删除客户" on public.customers;

-- 5. 新建正确策略
-- 查看：允许所有人（含未登录）
create policy "允许查看客户"
  on public.customers
  for select
  to anon, authenticated
  using (true);

-- 新增：只允许已登录管理员
create policy "允许新增客户"
  on public.customers
  for insert
  to authenticated
  with check (true);

-- 更新：只允许已登录管理员
create policy "允许更新客户"
  on public.customers
  for update
  to authenticated
  using (true)
  with check (true);

-- 删除：只允许已登录管理员
create policy "允许删除客户"
  on public.customers
  for delete
  to authenticated
  using (true);

-- ============================================
-- 同时修正 orders 表的策略（如不存在则创建）
-- ============================================
alter table public.orders enable row level security;

drop policy if exists "允许匿名用户查看订单" on public.orders;
drop policy if exists "允许匿名用户插入订单" on public.orders;

create policy "允许查看订单"
  on public.orders
  for select
  to anon, authenticated
  using (true);

create policy "允许插入订单"
  on public.orders
  for insert
  to anon, authenticated
  with check (true);
