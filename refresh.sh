#!/bin/bash
# 明道云 MCP Token 自动刷新脚本
# 刷新 access_token 并直接更新 ~/.claude.json 中的 MCP URL

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOG_FILE="$SCRIPT_DIR/refresh.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ ! -f "$ENV_FILE" ]; then
    log "ERROR: .env 文件不存在: $ENV_FILE"
    osascript -e 'display notification "找不到 .env 文件，请检查配置" with title "明道云 MCP" subtitle "Token 刷新失败"'
    exit 1
fi

source "$ENV_FILE"

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ] || [ -z "$REFRESH_TOKEN" ]; then
    log "ERROR: .env 缺少必要变量 (CLIENT_ID / CLIENT_SECRET / REFRESH_TOKEN)"
    exit 1
fi

log "开始刷新 token..."

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
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error_msg // .message // "未知错误"')
    log "ERROR: 刷新失败 - $ERROR_MSG"
    log "Refresh token 可能已过期（14天有效期），需要重新授权"
    osascript -e 'display notification "Refresh Token 已过期，请重新授权获取新 Token" with title "明道云 MCP" subtitle "Token 刷新失败"'
    exit 1
fi

NEW_ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.data.access_token')
NEW_REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.data.refresh_token')

if [ -z "$NEW_ACCESS_TOKEN" ] || [ "$NEW_ACCESS_TOKEN" = "null" ]; then
    log "ERROR: 返回数据异常，无法提取 access_token"
    exit 1
fi

# 更新 .env 中的 refresh_token
cat > "$ENV_FILE" << EOF
CLIENT_ID=$CLIENT_ID
CLIENT_SECRET=$CLIENT_SECRET
REFRESH_TOKEN=$NEW_REFRESH_TOKEN
EOF

log "新 refresh_token 已写入 .env"

# 直接更新 ~/.claude.json 中的 MCP URL（不依赖 claude CLI）
CLAUDE_JSON="$HOME/.claude.json"
NEW_URL="https://api2.mingdao.com/mcp?Authorization=Bearer%20${NEW_ACCESS_TOKEN}"

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
" "$NEW_URL"

    if [ $? -eq 0 ]; then
        log "SUCCESS: MCP 配置已更新，新 token 生效"
        osascript -e 'display notification "Token 刷新成功，MCP 已更新" with title "明道云 MCP"'
    else
        log "WARNING: ~/.claude.json 更新失败"
    fi
else
    log "ERROR: ~/.claude.json 不存在"
    exit 1
fi
