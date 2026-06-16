-- 阿旺小厨房 数据库升级脚本
-- 功能：给 dishes 表增加 sort_order 字段（用于手动排序）
-- 执行方式：在 Supabase SQL Editor 里执行整个文件

-- =============================================
-- 1. 给 dishes 表增加 sort_order 字段
-- =============================================
ALTER TABLE public.dishes
  ADD COLUMN IF NOT EXISTS sort_order integer DEFAULT 0;

-- 给 sort_order 建索引（加快排序查询）
CREATE INDEX IF NOT EXISTS idx_dishes_sort_order
  ON public.dishes(sort_order);

-- =============================================
-- 2. 初始化已有数据的 sort_order
-- =============================================
-- 如果已有菜品，给它们设置初始排序（按创建时间倒序，新的排前面）
-- 这样不会影响你现有的显示顺序
WITH ranked AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY created_at DESC) AS rn
  FROM public.dishes
  WHERE sort_order = 0 OR sort_order IS NULL
)
UPDATE public.dishes
SET sort_order = ranked.rn
FROM ranked
WHERE dishes.id = ranked.id;

-- =============================================
-- 完成提示
-- =============================================
-- 执行成功后，你会看到 dishes 表现在有 sort_order 字段了
-- 默认值都是 1, 2, 3...（按创建时间倒序）
-- 接下来上传 v2.0.17 代码，就能用排序功能了！
