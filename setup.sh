#!/bin/bash
# 明道云 MCP 初始化脚本
# 交互式输入凭据，获取首次 token，并配置 Claude Code MCP

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

echo "========================================="
echo "  明道云 MCP for Claude Code - 初始化"
echo "========================================="
echo ""

# 检查依赖
for cmd in curl jq python3; do
    if ! command -v $cmd &>/dev/null; then
        echo "错误: 缺少依赖 '$cmd'，请先安装"
        echo "  brew install $cmd"
        exit 1
    fi
done

# 如果 .env 已存在，提示是否覆盖
if [ -f "$ENV_FILE" ]; then
    echo "检测到已有配置文件 (.env)"
    read -p "是否重新配置？(y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    echo ""
fi

echo "请输入以下参数（从管理员处获取 CLIENT_ID 和 CLIENT_SECRET）："
echo ""

# 读取 CLIENT_ID
read -p "CLIENT_ID: " CLIENT_ID
if [ -z "$CLIENT_ID" ]; then
    echo "错误: CLIENT_ID 不能为空"
    exit 1
fi

# 读取 CLIENT_SECRET
read -p "CLIENT_SECRET: " CLIENT_SECRET
if [ -z "$CLIENT_SECRET" ]; then
    echo "错误: CLIENT_SECRET 不能为空"
    exit 1
fi

# 读取 REFRESH_TOKEN
echo ""
echo "REFRESH_TOKEN 需要通过 OAuth 授权获取。"
echo "如果你已有 REFRESH_TOKEN，直接输入即可。"
echo "如果没有，请联系管理员完成授权流程后获取。"
echo ""
read -p "REFRESH_TOKEN: " REFRESH_TOKEN
if [ -z "$REFRESH_TOKEN" ]; then
    echo "错误: REFRESH_TOKEN 不能为空"
    exit 1
fi

echo ""
echo "正在验证凭据..."

# 验证：用 refresh_token 换取 access_token
RESPONSE=$(curl -s -X POST "https://api2.mingdao.com/v3/oauth/token" \
    -H "Content-Type: application/json" \
    -d "{
        \"grant_type\": \"refresh_token\",
        \"refresh_token\": \"$REFRESH_TOKEN\",
        \"client_id\": \"$CLIENT_ID\",
        \"client_secret\": \"$CLIENT_SECRET\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

if [ "$SUCCESS" != "true" ]; then
    echo "错误: 凭据验证失败"
    echo "API 返回: $(echo "$RESPONSE" | jq -r '.error_msg // .message // "未知错误"')"
    echo "请检查参数是否正确"
    exit 1
fi

ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.access_token')
NEW_REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.data.refresh_token')

# 写入 .env
cat > "$ENV_FILE" << EOF
CLIENT_ID=$CLIENT_ID
CLIENT_SECRET=$CLIENT_SECRET
REFRESH_TOKEN=$NEW_REFRESH_TOKEN
EOF

echo "凭据验证成功，已写入 .env"

# 配置 Claude Code MCP
CLAUDE_JSON="$HOME/.claude.json"
MCP_URL="https://api2.mingdao.com/mcp?Authorization=Bearer%20${ACCESS_TOKEN}"

if [ -f "$CLAUDE_JSON" ]; then
    python3 -c "
import json, sys
with open('$CLAUDE_JSON', 'r') as f:
    cfg = json.load(f)
if 'mcpServers' not in cfg:
    cfg['mcpServers'] = {}
cfg['mcpServers']['mingdao'] = {'type': 'http', 'url': sys.argv[1]}
with open('$CLAUDE_JSON', 'w') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
" "$MCP_URL"
    echo "Claude Code MCP 配置已更新"
else
    echo "警告: ~/.claude.json 不存在，请确认已安装 Claude Code"
    echo "安装后手动运行: bash $SCRIPT_DIR/refresh.sh"
fi

echo ""
echo "========================================="
echo "  初始化完成！"
echo "========================================="
echo ""
echo "下一步：安装自动刷新定时任务"
echo "  bash $SCRIPT_DIR/install.sh"
echo ""
echo "或手动刷新 token："
echo "  bash $SCRIPT_DIR/refresh.sh"
