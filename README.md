# 阿旺小厨房 - 上门厨师点餐系统

## 项目结构

```
cook-order-system/
├── src/
│   ├── views/
│   │   ├── Menu.vue          ← 客户点餐页
│   │   ├── History.vue       ← 客户历史记录页
│   │   ├── AdminLogin.vue   ← 管理员登录/注册页
│   │   ├── AdminDishes.vue  ← 管理员菜品管理页
│   │   ├── AdminOrders.vue  ← 管理员订单查看页
│   │   └── AdminSettings.vue ← 系统设置页（店铺名、Logo）
│   ├── lib/
│   │   ├── supabase.js      ← Supabase 连接配置
│   │   └── cart.js         ← 购物车状态管理
│   ├── router/index.js      ← 路由配置
│   ├── assets/global.css    ← 全局样式
│   └── main.js             ← 入口文件
├── supabase/schema.sql      ← 数据库建表 SQL
├── .env                     ← 环境变量（需填写）
├── vite.config.js
└── vercel.json              ← Vercel 部署配置
```

## 部署步骤

### 第一步：创建 Supabase 项目

1. 打开 https://supabase.com 注册/登录
2. 点击 "New Project" 创建新项目
3. 记下 Project URL 和 anon public key（在 Project Settings → API 里）

### 第二步：执行数据库建表 SQL

1. 在 Supabase 后台，进入 SQL Editor
2. 复制 `supabase/schema.sql` 的全部内容
3. 粘贴到 SQL Editor，点击 "Run"
4. 这会自动创建：settings 表、dishes 表、orders 表，并插入示例菜品

### 第三步：创建图片存储桶

1. 在 Supabase 后台，进入 Storage
2. 点击 "Create a new bucket"
3. 名称填写：`dish-images`
4. 勾选 "Public bucket"（公开访问）
5. 创建后，点击 bucket 右侧 "..." → Policies → 添加策略：
   - SELECT：允许 public（所有人可读）
   - INSERT：允许 authenticated（登录用户可上传）

### 第四步：创建管理员账号

1. 在 Supabase 后台，进入 Authentication → Users
2. 点击 "Invite a user" 或直接用注册页注册
3. 也可以本地启动项目后，在 `/admin` 页面点击"注册"自行注册

### 第五步：填写环境变量

编辑 `.env` 文件，填入你的 Supabase 信息：

```
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 第六步：推送到 GitHub + 部署到 Vercel

1. 在 GitHub 新建一个仓库（如 `cook-order-system`）
2. 将代码推送到 GitHub：
   ```bash
   git init
   git add .
   git commit -m "init"
   git remote add origin https://github.com/你的用户名/cook-order-system.git
   git push -u origin main
   ```
3. 打开 https://vercel.com 注册/登录
4. 点击 "Add New..." → "Project"
5. 选择刚才推送的 GitHub 仓库
6. 在 "Environment Variables" 里填入：
   - `VITE_SUPABASE_URL` = 你的 Supabase URL
   - `VITE_SUPABASE_ANON_KEY` = 你的 anon key
7. 点击 "Deploy"，等待部署完成
8. 记下 Vercel 给你的域名（如 `xxx.vercel.app`）

### 第七步：测试

1. 打开 Vercel 域名，应该看到点餐页
2. 访问 `/admin`，注册/登录管理员账号
3. 在 `/admin/settings` 修改店铺名称和 Logo
4. 在 `/admin/dishes` 添加/编辑菜品
5. 回到首页，测试点餐 → 加入购物车 → 提交订单
6. 访问 `/history` 查看历史记录

## 本地开发

```bash
npm install
npm run dev
```

访问 http://localhost:5173

## 注意事项

- Supabase 免费额度：数据库 500MB，图片存储 1GB，够用
- Vercel 免费额度：个人项目无限带宽，够用
- 客户姓名存在浏览器 localStorage，清缓存后需重新输入
- 若客户同名，历史记录会混在一起（可在订单备注里写房号/电话区分）
- 图片建议压缩后再上传（每张 < 200KB），节省存储
