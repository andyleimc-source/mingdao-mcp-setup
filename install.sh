#!/bin/bash
# 安装 / 卸载 macOS LaunchAgent 定时刷新任务

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_LABEL="com.mingdao.token-refresh"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"

install() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        echo "错误: 请先运行 setup.sh 完成初始化"
        exit 1
    fi

    # 卸载已有的
    launchctl unload "$PLIST_PATH" 2>/dev/null || true

    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>exec /bin/bash "${SCRIPT_DIR}/refresh.sh"</string>
    </array>
    <key>StartInterval</key>
    <integer>72000</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${SCRIPT_DIR}/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>${SCRIPT_DIR}/launchd.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>
</dict>
</plist>
EOF

    launchctl load "$PLIST_PATH"
    echo "定时刷新任务已安装"
    echo "  - 每 20 小时自动刷新一次"
    echo "  - 开机 / 唤醒后立即刷新"
    echo "  - 日志: $SCRIPT_DIR/refresh.log"
}

uninstall() {
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "定时刷新任务已卸载"
}

case "${1:-install}" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "用法: bash install.sh [install|uninstall]"
        exit 1
        ;;
esac
