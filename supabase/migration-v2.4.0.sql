-- ======================================
-- 阿旺小厨房 v2.4.0 数据库迁移脚本
-- 请在 Supabase SQL Editor 中执行
-- ======================================

-- 1. settings 表：添加功能开关字段（默认开启）
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_menu_enabled BOOLEAN DEFAULT true;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_history_enabled BOOLEAN DEFAULT true;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_roll_enabled BOOLEAN DEFAULT true;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_note_enabled BOOLEAN DEFAULT true;

-- 2. access_logs 表：添加地区+详情字段
ALTER TABLE access_logs ADD COLUMN IF NOT EXISTS location TEXT DEFAULT '';
ALTER TABLE access_logs ADD COLUMN IF NOT EXISTS detail TEXT DEFAULT '';

-- 3. Edge Function部署说明
-- 部署IP地区查询函数（终端执行）：
--   cd supabase
--   supabase functions deploy ipinfo
-- 函数位置：supabase/functions/ipinfo/index.ts
-- 功能：根据客户端IP查询城市/省份/国家，返回 { ip, city, region, country, location }
-- 注意事项：
--   - 需要在 Supabase 控制台 -> Edge Functions 启用
--   - 默认情况下匿名用户可调用（Anon key 已授权）
--   - 如果遇到 404，检查是否已部署
