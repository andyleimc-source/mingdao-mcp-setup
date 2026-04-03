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

---

## 多设备共享 Token（iCloud 方案）

明道云 OAuth 采用旋转式 Refresh Token 机制：每次刷新后旧 token 立即作废，新 token 替代。这意味着如果两台设备各自维护一份 `.env`，谁先刷新谁就会让另一台失效。

**解决方案**：让多台设备的 `.env` 通过软链接指向同一个 iCloud Drive 同步文件，共享同一份 Refresh Token。

### 第一台设备

```bash
# 1. clone 仓库并完成初始化
git clone https://github.com/andyleimc-source/mingdao-mcp-setup.git
cd mingdao-mcp-setup
bash setup.sh

# 2. 把 .env 移到 iCloud 同步目录，建立软链接
SHARE_DIR=~/Documents/asset/mcp/mingdao-mcp-share-token
mkdir -p "$SHARE_DIR"
mv .env "$SHARE_DIR/.env"
ln -s "$SHARE_DIR/.env" .env
```

### 第二台（及更多）设备

```bash
# 1. clone 仓库（不要运行 setup.sh）
git clone https://github.com/andyleimc-source/mingdao-mcp-setup.git
cd mingdao-mcp-setup

# 2. 等待 iCloud 同步完成后，建立软链接
SHARE_DIR=~/Documents/asset/mcp/mingdao-mcp-share-token
ln -s "$SHARE_DIR/.env" .env

# 3. 直接刷新，写入本机 ~/.claude.json
bash refresh.sh

# 4. 安装本机定时任务
bash install.sh
```

### 工作原理

- 所有设备读写同一个 `$SHARE_DIR/.env`
- 任意设备刷新后，新 Refresh Token 通过 iCloud 同步到其他设备
- 每台设备的 `~/.claude.json` 独立维护各自的 access_token，互不干扰
- 定时任务（每 20 小时）确保各设备在 token 旋转后都能及时更新

> **注意**：`$SHARE_DIR` 路径可根据你的 iCloud 同步设置自行调整，Dropbox 等其他同步方案同理。
