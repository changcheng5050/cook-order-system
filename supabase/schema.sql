-- 阿旺小厨房 数据库 Schema
-- 在 Supabase SQL Editor 里执行

-- =============================================
-- 1. 系统设置表（店铺名称、Logo等）
-- =============================================
create table if not exists public.settings (
  id integer primary key generated always as identity,
  shop_name text not null default '阿旺小厨房',
  logo_url text default '',
  updated_at timestamp with time zone default now()
);

alter table public.settings enable row level security;

create policy "settings_public_read"
  on public.settings
  for select
  using (true);

-- 插入默认设置
insert into public.settings (shop_name, logo_url)
values ('阿旺小厨房', '')
on conflict do nothing;

-- =============================================
-- 2. 菜品表
-- =============================================
create table if not exists public.dishes (
  id integer primary key generated always as identity,
  name text not null,
  image_url text default '',
  cook_time integer not null default 0,
  ingredients jsonb not null default '[]',
  seasonings jsonb not null default '[]',
  flavor text[] not null default '{}',
  category text not null default '荤菜',
  temperature text not null default '热菜',
  notes text default '',
  is_active boolean not null default true,
  created_at timestamp with time zone default now()
);

alter table public.dishes enable row level security;

create policy "dishes_public_read"
  on public.dishes
  for select
  using (true);

create policy "dishes_admin_all"
  on public.dishes
  for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- =============================================
-- 3. 订单表
-- =============================================
create table if not exists public.orders (
  id integer primary key generated always as identity,
  customer_name text not null,
  dishes jsonb not null default '[]',
  total_time integer not null default 0,
  note text default '',
  created_at timestamp with time zone default now()
);

alter table public.orders enable row level security;

create policy "orders_customer_insert"
  on public.orders
  for insert
  with check (true);

create policy "orders_admin_read"
  on public.orders
  for select
  using (auth.role() = 'authenticated');

-- =============================================
-- 4. 存储桶（用于菜品图片）
-- =============================================
-- 在 Supabase Storage 后台手动创建 bucket：dish-images
-- 设置为 public（公开访问）
-- RLS policy：所有人可读，登录用户可上传

-- =============================================
-- 示例数据（可选，方便测试）
-- =============================================
insert into public.dishes
  (name, image_url, cook_time, ingredients, seasonings, flavor, category, temperature, notes, is_active)
values
  (
    '红烧肉',
    '',
    45,
    cast('[{"name":"五花肉","amount":"300g"},{"name":"冰糖","amount":"20g"}]' as jsonb),
    cast('[{"name":"生抽","amount":"2勺"},{"name":"老抽","amount":"1勺"}]' as jsonb),
    '{咸鲜,微甜}',
    '荤菜',
    '热菜',
    '含葱姜蒜，忌口请提前告知',
    true
  ),
  (
    '蒜蓉菜心',
    '',
    10,
    cast('[{"name":"菜心","amount":"300g"},{"name":"大蒜","amount":"3瓣"}]' as jsonb),
    cast('[{"name":"盐","amount":"适量"},{"name":"蚝油","amount":"1勺"}]' as jsonb),
    '{清淡,蒜香}',
    '素菜',
    '热菜',
    '',
    true
  ),
  (
    '凉拌黄瓜',
    '',
    5,
    cast('[{"name":"黄瓜","amount":"2根"}]' as jsonb),
    cast('[{"name":"香醋","amount":"1勺"},{"name":"香油","amount":"少许"}]' as jsonb),
    '{酸爽,清凉}',
    '素菜',
    '凉菜',
    '',
    true
  ),
  (
    '番茄蛋花汤',
    '',
    15,
    cast('[{"name":"番茄","amount":"2个"},{"name":"鸡蛋","amount":"2个"}]' as jsonb),
    cast('[{"name":"盐","amount":"适量"},{"name":"香油","amount":"几滴"}]' as jsonb),
    '{清淡,鲜美}',
    '汤类',
    '热菜',
    '',
    true
  ),
  (
    '牛肉炒河粉',
    '',
    20,
    cast('[{"name":"河粉","amount":"200g"},{"name":"牛肉","amount":"100g"},{"name":"豆芽","amount":"50g"}]' as jsonb),
    cast('[{"name":"生抽","amount":"2勺"},{"name":"老抽","amount":"半勺"}]' as jsonb),
    '{咸鲜,浓郁}',
    '粉面类',
    '热菜',
    '含葱姜蒜',
    true
  )
on conflict do nothing;
