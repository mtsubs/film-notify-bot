
# 部署指南

本文档介绍如何在不同环境下部署 **Film Notify Bot**。无论是在 GitHub Actions 上运行，还是在本地或私有服务器运行，都需要先完成一些统一的前期准备工作，例如申请 API Key 和配置环境变量。



## 前期准备（必须步骤）

在开始部署之前，您必须先获取并配置 MDBList、TMDB 和 Telegram 相关信息。

### 1. 创建你的自定义电影列表

1. 打开 [MDBList 官网](https://mdblist.com/) 并通过右上角「Login」使用第三方账号登录。
2. 登录后在首页设置 「**Ratings**」、「**Additional filters**」、「**Lists**」、「**Streaming Services**」、「**Cast**」 等选项，创建自定义规则列表。

   蒙太奇字幕组示例规则（监控过去 14 天内数字发行的高分新电影）：

   - 「Released」设置为 `d:14`：仅包含数字发行过去 14 天的电影。
   - 「Upcoming」设置为 `1`：只纳入未来 1 天发布的电影。
   - 「Release date」从 `2025-01-01` 起，避免重置版电影进入列表。
   - 「IMDb Rating」设置为 `7.0-10` 分，With at least `1000` votes。

   你也可以自由创建其他规则，包括语言、国家、片商的包含或排除，使用多个平台设置评分限制，甚至根据演员自定义列表。

3. 规则设置完成后，点击下方「Search」查看过滤结果，确认符合预期后，点击「Create List」并填写描述创建列表。

> **说明**：新列表可能需要 30 分钟至 1 小时填充完成，请耐心等待。如果没有符合条件的电影，列表将为空。

### 2. 获取 MDBList API Key

1. 点击右上角用户名 → 「**Preferences**」→ 页面底部「**API Access**」。
2. 创建新的 API Key，并记录该 Key，在后续脚本配置中使用。

### 3. 获取 TMDB API Key

1. 打开 [TMDB 官网](https://www.themoviedb.org/) 并注册账号，或使用已有账号登录。
2. 登录后点击右上角头像，进入「Settings」 → 「API」。
3. 点击「Create」申请 Developer API Key，并按照页面指示填写必要信息，包括应用名称、摘要和个人信息（请使用英语填写）。
4. 提交后，在「API Overview」页面最下方找到「API Key」字段（注意：不是 API Read Access Token），记录该 Key，后续配置中使用。

### 4. 获取 Telegram Bot Token

1. 打开 Telegram，搜索 [@BotFather](https://t.me/BotFather) 并与该 Bot 创建聊天。
2. 发送 `/newbot` 并按照指示设置 Bot 名称和用户名（用户名必须唯一，以`Bot`结尾）。
3. 创建完成后，BotFather 会返回一个 Bot Token，请妥善保存，后续配置中使用。

### 5. 获取 Telegram Chat ID

要让 Bot 正确发送消息，需要获取目标群组、频道或个人账户的 Chat ID：

1. 将 Bot 添加到目标群组或频道（频道中需设置为管理员）。如果希望 Bot 发送消息给个人账户，请先与 Bot 聊天并点击「Start」。
2. 在浏览器中访问以下链接（将 `<Bot Token>` 替换为你的 Bot Token），查看返回的 JSON 信息：
   ```https://api.telegram.org/bot<Bot Token>/getUpdates```

   - 对于群组或频道，查找 `"chat":{"id":-100XXXXXXXXX, ...}` 字段。
   - 对于个人账户，查找 `"from":{"id":XXXXXXXX, ...}` 字段。

   记录该 ID，该 ID 将作为 Bot 消息发送的目标。群组和频道的 ID 有别于个人账户 ID，复制时请包含前面的负号`-`。

3. 妥善保存这些 chat ID，后续在脚本配置中使用。

### 6. 获取 MDBList 列表 ID

当你在 MDBList 创建的列表超过 30 分钟并填充完成后，即可通过 API 获取列表 ID。若获取失败，说明列表尚未准备好，请耐心等待。

1. 使用以下链接获取你的用户 ID（将 `<API Key>` 替换为你的 MDBList API Key）：
   ```https://api.mdblist.com/user?apikey=<API Key>```

   返回结果中 `"user_id": XXXXX` 即为你的用户 ID，记录该数字。

2. 使用你的用户 ID 获取列表信息：
   ```https://api.mdblist.com/lists/user/<XXXXX>?apikey=<API Key>```

   返回结果中 `"id": YYYYY` 即为你创建的列表 ID，记录该 ID，后续脚本配置中使用。



## GitHub Actions 部署

使用 GitHub Actions 可以实现自动化运行 Bot，无需自行管理服务器或计划任务。部署步骤如下：


1. **Fork 仓库**  
   将官方仓库 fork 到自己的 GitHub 账号。

2. **设置 Secrets**  
   在仓库页面依次进入 **Settings → Secrets and variables → Actions → New repository secret**，添加以下变量：
   
   - `MDBLIST_API_KEY`：第 2 步获取的 MDBList API Key  
   - `MDBLIST_LIST_ID`：第 6 步获取的 MDBList 列表 ID  
   - `TMDB_API_KEY`：第 3 步获取的 TMDB API Key  
   - `TELEGRAM_BOT_TOKEN`：第 4 步获取的 Telegram Bot Token  
   - `TELEGRAM_CHAT_IDS`：第 5 步获取的目标 Chat ID，可填写多个，用空格分隔  


3. **清理历史数据文件**  
   仓库中原有的 `film-notify-bot/scripts/sent_tmdb_ids.txt` 文件记录了官方示范频道已发送的电影列表。  
   - 请删除或清空该文件，以避免 Bot 重复发送已发送电影。  
   - 尤其如果你希望你的频道接收完整的通知，不受官方示范列表限制。

4. **修改脚本 Source 信息**  
   脚本会在请求 API 时创建 UserAgent，为了确保来源正确，请修改 `film_notify_bot.sh` 文件顶部的 Source 字段为你自己的仓库地址，例如：  
```
# Source: https://github.com/<你的用户名>/film-notify-bot/
```

5. **启动 Workflow**  
   在 **Actions** 页面找到 `Film Notify Bot`，并点击页面右侧 Run workflow 手动触发一次运行，确保配置正确。  
   - 后续 GitHub Actions 将按设定计划自动运行 Bot。

## 本地 / 私有服务器部署

如果希望在自己的服务器或本地机器上运行 Bot，可按以下步骤操作：

1. **环境要求**  
   - `bash`（建议 v4.0+，兼容 busybox shell）  
   - `jq`（解析 JSON 数据）  
   - `curl`（用于请求 API）

2. **获取脚本**  
   下载 `film-notify-bot/scripts/film_notify_bot.sh` 文件到本地。

3. **修改配置**  
    使用文本编辑器打开脚本，将以下占位符替换为你自己的 Key/Token，并修改 Source 为你自己的仓库地址：  

```bash
# Source: https://github.com/<你的用户名>/film-notify-bot/
MDBLIST_API_KEY="${MDBLIST_API_KEY}"
MDBLIST_LIST_ID="${MDBLIST_LIST_ID}"                            # 监控的列表 ID / Watchlist ID
TMDB_API_KEY="${TMDB_API_KEY}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_IDS="${TELEGRAM_CHAT_IDS}"                        # 支持多个，用空格分隔 / Multiple chat IDs
```

4. **运行脚本**  
   在脚本所在目录运行：

```bash
bash film_notify_bot.sh
```

脚本运行后将在同目录生成 `sent_tmdb_ids.txt` 文件，用于记录已发送的电影，避免重复发送。

文件会自动删除超过一年的历史记录，无需手动管理。







## 常见问题与提示

- **MDBList 免费 API 限制**  
  MDBList 免费账号每日 API 请求上限为 1000 次。超过该限制时，API 请求将返回失败。对于本项目的日常使用，这一限制通常是足够的。

- **账号活跃度要求**  
  - 如果 MDBList 账号超过 90 天未在网站登录，将被视为不活跃，列表更新会暂停。  
  - 超过 120 天未登录，可能会彻底终止服务。  

- **支持 MDBList**  
  为了保证持续稳定的服务，并支持 MDBList 的开发与维护，建议通过赞助 2-5 欧元支持他们。赞助可以避免 API 请求和账号活跃度限制带来的影响。  
  详细信息请参考官方文档：[MDBList Supporter](https://docs.mdblist.com/docs/supporter)

