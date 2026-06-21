-- ======================================
-- 阿旺小厨房 v2.3.0 数据库迁移脚本
-- 请在 Supabase SQL Editor 中执行
-- ======================================

-- 1. customers 表：添加 status 字段（pending/approved）
ALTER TABLE customers ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'approved';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS applied_at TIMESTAMPTZ;

-- 2. customers 表：允许匿名用户插入申请（status = pending）
DROP POLICY IF EXISTS "Anyone can insert pending customers" ON customers;
CREATE POLICY "Anyone can insert pending customers" ON customers
  FOR INSERT WITH CHECK (status = 'pending');

-- 3. customers 表：允许所有人都能查询
DROP POLICY IF EXISTS "Anyone can read customers" ON customers;
CREATE POLICY "Anyone can read customers" ON customers
  FOR SELECT USING (true);

-- 4. settings 表：添加 announcement 字段
ALTER TABLE settings ADD COLUMN IF NOT EXISTS announcement TEXT DEFAULT '';
ALTER TABLE settings ADD COLUMN IF NOT EXISTS announcement_enabled BOOLEAN DEFAULT false;

-- 5. 创建 messages 表（递小纸条）
CREATE TABLE IF NOT EXISTS messages (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_name TEXT NOT NULL,
  sender TEXT NOT NULL CHECK (sender IN ('customer', 'admin')),
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 给 messages 表加索引
CREATE INDEX IF NOT EXISTS idx_messages_customer_name ON messages(customer_name);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);

-- 7. messages 表 RLS 策略
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on messages" ON messages;
CREATE POLICY "Allow all on messages" ON messages
  FOR ALL USING (true) WITH CHECK (true);

-- 8. 创建访问日志表
CREATE TABLE IF NOT EXISTS access_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_name TEXT NOT NULL,
  action TEXT NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. 访问日志索引
CREATE INDEX IF NOT EXISTS idx_access_logs_customer ON access_logs(customer_name);
CREATE INDEX IF NOT EXISTS idx_access_logs_created ON access_logs(created_at DESC);

-- 10. 访问日志 RLS
ALTER TABLE access_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on access_logs" ON access_logs;
CREATE POLICY "Allow all on access_logs" ON access_logs
  FOR ALL USING (true) WITH CHECK (true);
