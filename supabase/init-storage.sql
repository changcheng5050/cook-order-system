-- ============================================================
-- Supabase Storage 初始化脚本（v2.0.5）
-- 执行方法：Supabase Dashboard → SQL Editor → 粘贴 → Run
-- ============================================================

-- 1. 创建菜品图片存储桶（如果不存在）
insert into storage.buckets (id, name, public)
values ('dish-images', 'dish-images', true)
on conflict (id) do nothing;

-- 2. 设置存储桶公开读取策略（任何人可查看图片）
CREATE POLICY "Public read access" ON storage.objects FOR SELECT
USING (bucket_id = 'dish-images');

-- 3. 设置已认证用户可上传策略（管理员登录后才能上传图片）
CREATE POLICY "Authenticated upload access" ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'dish-images'
  AND auth.role() = 'authenticated'
);

-- 4. 设置已认证用户可更新/替换策略
CREATE POLICY "Authenticated update access" ON storage.objects FOR UPDATE
USING (
  bucket_id = 'dish-images'
  AND auth.role() = 'authenticated'
);

-- ============================================================
-- 执行完成后，刷新页面即可正常上传图片
-- 如果报错 "policy already exists"，说明之前已经创建过，忽略即可
-- ============================================================
