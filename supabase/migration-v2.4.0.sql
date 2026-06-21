-- ======================================
-- 阿旺小厨房 v2.4.0 数据库迁移脚本
-- 请在 Supabase SQL Editor 中执行
-- ======================================

-- 1. settings 表：添加功能开关字段（默认开启）
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_menu_enabled BOOLEAN DEFAULT true;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_history_enabled BOOLEAN DEFAULT true;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_roll_enabled BOOLEAN DEFAULT true;
ALTER TABLE settings ADD COLUMN IF NOT EXISTS tab_note_enabled BOOLEAN DEFAULT true;
