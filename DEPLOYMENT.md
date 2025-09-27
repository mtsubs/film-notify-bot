# Film Notify Bot 部署指南

**Film Notify Bot** 是一个 Telegram 机器人，用于自动监控最新数字发行电影，并将结构化消息发送到指定频道或群组。本文档将指导你完成前期准备、部署与运行。

## 目录

1. [前期准备](#前期准备)
2. [GitHub Actions 部署](#github-actions-部署)
3. [本地 / 私有服务器部署](#本地--私有服务器部署)
4. [注意事项](#注意事项)

---

## 前期准备

在部署之前，需要先获取相关 API Key、创建自定义电影列表，并确定 Bot 的消息目标。

### 1. 创建自定义电影列表

1. 打开 [MDBList 官网](https://mdblist.com/) 并登录。  
2. 在首页设置过滤选项，如「Ratings」、「Additional filters」、「Lists」、「Streaming Services」、「Cast」等。  
3. 示例规则（蒙太奇字幕组推荐）：
   - 「Released」设置为 `d:14`：过去 14 天数字发行电影。  
   - 「Upcoming」设置为 `1`：未来 1 天的电影。  
   - 「Release date」从 `2025-01-01` 起，排除重置版电影。  
   - 「IMDb Rating」设置 `7.0-10`，至少 1000 投票。  
4. 点击「Search」查看结果，确认符合预期后点击「Create List」，填写描述。  

> 新列表可能需要 30 分钟至 1 小时填充完成，请耐心等待。

### 2. 获取 MDBList API Key

1. 点击右上角用户名 → 「Preferences」 → 页面底部「API Access」。  
2. 创建新的 API Key，并记录备用。

### 3. 获取 TMDB API Key

1. 打开 [TMDB 官网](https://www.themoviedb.org/) 并登录。  
2. 点击头像 → 「Settings」 → 「API」 → 「Create」申请 Developer API Key。  
3. 填写应用名称、摘要及个人信息（使用英语），提交后记录「API Key」。

### 4. 获取 Telegram Bot Token

1. 打开 Telegram，搜索 [@BotFather](https://t.me/BotFather)。  
2. 发送 `/newbot`，按照指示设置 Bot 名称和唯一用户名（必须以 Bot 结尾）。  
3. 保存 BotFather 返回的 Token。

### 5. 获取 Telegram Chat ID

1. 将 Bot 添加到目标群组或频道（频道需管理员权限）或直接与 Bot 聊天。  
2. 访问以下链接（将 `<Bot Token>` 替换为你的 Bot Token）：  
   ```text
   https://api.telegram.org/bot<Bot Token>/getUpdates
   ```
3. 查找对应字段：
   - 群组/频道： `"chat":{"id":-100XXXXXXXXX, ...}`  
   - 个人账户： `"from":{"id":XXXXXXXX, ...}`  
4. 保存这些 ID，后续脚本配置使用。注意群组和频道 ID 带前缀负号 `-`。

### 6. 获取 MDBList 列表 ID

1. 获取用户 ID：  
   ```text
   https://api.mdblist.com/user?apikey=<API Key>
   ```
   记录 `"user_id": XXXXX`。  
2. 获取列表 ID：  
   ```text
   https://api.mdblist.com/lists/user/<XXXXX>?apikey=<API Key>
   ```
   记录 `"id": YYYYY`，用于脚本配置。

---

## GitHub Actions 部署

1. **Fork 仓库**  
   将官方仓库 fork 到自己的 GitHub 账号。  

2. **设置 Secrets**  
   在 **Settings → Secrets and variables → Actions → New repository secret** 添加：
   - `MDBLIST_API_KEY`  
   - `MDBLIST_LIST_ID`  
   - `TMDB_API_KEY`  
   - `TELEGRAM_BOT_TOKEN`  
   - `TELEGRAM_CHAT_IDS`（多个用空格分隔）  

3. **清理历史数据文件**  
   删除或清空 `film-notify-bot/scripts/sent_tmdb_ids.txt`，避免重复通知。  

4. **修改脚本 Source 信息**  
   ```bash
   # Source: https://github.com/<你的用户名>/film-notify-bot/
   ```

5. **启动 Workflow**  
   在 **Actions** 页面找到 `Film Notify Bot`，点击 **Run workflow** 测试运行。后续按计划自动执行。

---

## 本地 / 私有服务器部署

1. **环境要求**  
   - bash v4.0+（兼容 busybox shell）  
   - jq  
   - curl  

2. **获取脚本**  
   下载 `film-notify-bot/scripts/film_notify_bot.sh` 文件到本地。

3. **修改配置**  
   ```bash
   # Source: https://github.com/<你的用户名>/film-notify-bot/
   MDBLIST_API_KEY="${MDBLIST_API_KEY}"
   MDBLIST_LIST_ID="${MDBLIST_LIST_ID}"        # Watchlist ID
   TMDB_API_KEY="${TMDB_API_KEY}"
   TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
   TELEGRAM_CHAT_IDS="${TELEGRAM_CHAT_IDS}"  # 多个用空格分隔
   ```

4. **运行脚本**  
   ```bash
   bash film_notify_bot.sh
   ```
   - 会在同目录生成 `sent_tmdb_ids.txt` 用于去重。  
   - 文件会自动删除超过一年的历史记录，无需手动管理。

---

## 注意事项

- **MDBList 免费账号限制**：每日 API 请求上限 1000 次。  
- **账号活跃度**：
  - 超过 90 天未登录，列表更新暂停。  
  - 超过 120 天未登录，服务可能终止。  
- **支持 MDBList**：建议通过赞助 2-5 欧元支持 MDBList 开发与维护，可避免限制影响。  
  详情请参考：[MDBList Supporter](https://docs.mdblist.com/docs/supporter)
