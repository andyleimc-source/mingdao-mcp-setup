# 明道云 MCP for Claude Code

让 Claude Code 通过 MCP 连接明道云，自动管理 Token 刷新。

## 前提条件

- macOS
- [Claude Code](https://claude.ai/claude-code) 已安装
- `curl`、`jq`、`python3`（macOS 自带或通过 Homebrew 安装）

## 一键安装

```bash
git clone https://github.com/andyleimc-source/mingdao-mcp-setup.git ~/.config/mingdao-mcp && bash ~/.config/mingdao-mcp/setup.sh
```

按提示输入三个参数：

| 参数 | 说明 |
|------|------|
| `CLIENT_ID` | OAuth 客户端 ID（联系管理员获取） |
| `CLIENT_SECRET` | OAuth 客户端密钥（联系管理员获取） |
| `REFRESH_TOKEN` | 刷新令牌（通过 OAuth 授权流程获取） |

脚本会自动：验证凭据 → 配置 Claude Code MCP → 安装定时刷新任务。

安装完成后：
- 每 20 小时自动刷新 token（access_token 有效期 24 小时）
- 开机 / 唤醒后立即刷新
- 刷新失败会弹出 macOS 通知提醒

## 卸载

```bash
bash ~/.config/mingdao-mcp/install.sh uninstall
```

## 手动刷新

```bash
bash refresh.sh
```

## Token 有效期

| Token | 有效期 | 过期后 |
|-------|--------|--------|
| access_token | 24 小时 | 自动刷新 |
| refresh_token | 14 天 | 需重新运行 `bash setup.sh` |

如果超过 14 天未开机，refresh_token 会过期，届时会收到 macOS 通知，重新运行 `setup.sh` 即可。

## 文件说明

```
├── setup.sh       # 初始化配置（交互式输入凭据）
├── refresh.sh     # Token 刷新脚本
├── install.sh     # 安装 / 卸载定时任务
├── .env           # 凭据存储（不会被提交到 Git）
├── .gitignore
└── README.md
```

## 日志

刷新日志位于项目目录下的 `refresh.log`。
