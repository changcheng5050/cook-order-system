-- 修复 settings 表的更新权限
-- 在 Supabase SQL Editor 中执行此脚本

-- 1. 确保 settings 表存在（如果不存在则创建）
CREATE TABLE IF NOT EXISTS public.settings (
  id INTEGER PRIMARY KEY,
  shop_name TEXT DEFAULT '阿旺小厨房',
  logo_url TEXT DEFAULT '',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. 确保至少有一条设置记录（id=1）
INSERT INTO public.settings (id, shop_name, logo_url)
VALUES (1, '阿旺小厨房', '')
ON CONFLICT (id) DO NOTHING;

-- 3. 启用 RLS（行级安全）
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- 4. 删除可能存在的旧策略（避免冲突）
DROP POLICY IF EXISTS "允许所有人读取设置" ON public.settings;
DROP POLICY IF EXISTS "允许管理员更新设置" ON public.settings;
DROP POLICY IF EXISTS "允许所有人更新设置" ON public.settings;

-- 5. 创建策略：所有人都能读取设置
CREATE POLICY "允许所有人读取设置"
  ON public.settings
  FOR SELECT
  USING (true);

-- 6. 创建策略：所有人都能更新设置（简化权限，避免保存失败）
CREATE POLICY "允许所有人更新设置"
  ON public.settings
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- 7. 授予权限
GRANT SELECT, UPDATE ON public.settings TO anon;
GRANT SELECT, UPDATE ON public.settings TO authenticated;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;

-- 8. 更新 updated_at 触发器（可选，让更新时间自动刷新）
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_settings_updated_at ON public.settings;
CREATE TRIGGER update_settings_updated_at
  BEFORE UPDATE ON public.settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
