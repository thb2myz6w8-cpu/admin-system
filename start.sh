#!/usr/bin/env bash
set -euo pipefail

# start.sh - Quick start script with admin account setup

PORT=${PORT:-3000}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     🚀 Admin System - 启动并创建管理员账号               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
  echo "❌ 错误：Node.js 未安装"
  echo "请访问 https://nodejs.org 下载安装"
  exit 1
fi

echo "✅ Node.js 已安装: $(node -v)"
echo ""

# Generate admin account
echo "📝 生成管理员账号信息..."
ADMIN_USER="admin"
ADMIN_PASS=$(openssl rand -base64 12 2>/dev/null || python3 -c "import secrets; print(secrets.token_urlsafe(12))" 2>/dev/null || echo "Admin@2026")
ADMIN_EMAIL="admin@admin-system.local"

cat > .admin.config <<EOF
# 管理员账号配置文件
# 生成时间：$(date '+%Y-%m-%d %H:%M:%S')

管理员用户名: $ADMIN_USER
管理员密码: $ADMIN_PASS
管理员邮箱: $ADMIN_EMAIL
服务器端口: $PORT
访问地址: http://localhost:$PORT

重要提示：
1. 首次访问时，系统会要求设置密码
2. 第一次加载页面需要创建管理员账号
3. 推荐密码至少 6 位，避免使用弱密码（如：123456, password）
4. 数据保存在浏览器 localStorage，清除浏览器数据会丢失
EOF

echo "✅ 管理员账号已生成"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 账号信息："
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  用户名: $ADMIN_USER"
echo "  密码:   $ADMIN_PASS"
echo "  邮箱:   $ADMIN_EMAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔄 正在启动 Node.js 服务器..."
echo ""

# Start server
PORT=$PORT node server.js
