#!/usr/bin/env bash
# ============================================================================
# Name: film_notify_bot.sh
# Version: 1.3.2
# Organization: MontageSubs (蒙太奇字幕组)
# Contributors: Meow P (小p)
# License: MIT License
# Source: https://github.com/MontageSubs/film_notify_bot/
#
# Description / 描述:
#   This script monitors new digital movie releases for the MontageSubs
#   subtitles group, fetches detailed information from TMDB and MDblist APIs,
#   formats the data into structured messages, and sends notifications via
#   Telegram. It also maintains a deduplication record to avoid sending
#   repeated notifications.
#   
#   本脚本用于监控蒙太奇字幕组关注的新数字电影发行，调用 TMDB 与
#   MDblist API 获取电影详细信息，将数据格式化为结构化消息，并通过
#   Telegram 发送通知。同时维护去重记录，避免重复发送消息。
#
# Features / 功能:
#   - Fetches daily new movie releases based on IMDb rating thresholds.
#   - Retrieves detailed movie information from TMDB (Chinese/English titles,
#     release year, overview, genres, runtime, production companies, etc.)
#   - Retrieves aggregated ratings (IMDb, Letterboxd, Metacritic, RogerEbert)
#   - Formats messages in a structured, human-readable format
#   - Maintains a deduplication file to prevent repeated notifications
#     每日获取 IMDb 评分阈值以上的新电影发行列表。
#     获取 TMDB 详细信息（中英文片名、上映年份、简介、类型、时长、
#     制作公司等）。
#     获取综合评分（IMDb、Letterboxd、Metacritic、RogerEbert）。
#     将信息格式化为结构化、易读的消息。
#     维护去重文件以防重复通知。
#
# Dependencies / 依赖:
#   - bash (>= 4.0)
#   - curl
#   - jq
#   - git (if committing deduplication file back to repository)
#
# Usage / 用法:
#   ./film_notify_bot.sh
#
# Output / 输出:
#   - Structured movie messages printed to stdout (or sent via Telegram)
#   - Updates 'sent_tmdb_ids.txt' with already processed movie IDs
#     格式化电影消息打印到 stdout（或通过 Telegram 发送）
#     更新 'sent_tmdb_ids.txt' 文件，记录已处理的电影 ID


# ---------------- 配置 / Configuration ----------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEDUP_FILE="$SCRIPT_DIR/sent_tmdb_ids.txt"          # 去重文件 / Deduplication file
DATE_STR=$(TZ="Asia/Shanghai" date +"%m月%d日")      # 当前日期 / Current date

MDBLIST_API_KEY="${MDBLIST_API_KEY}"
MDBLIST_LIST_ID="${MDBLIST_LIST_ID}"                # 监控的列表 ID / Watchlist ID
TMDB_API_KEY="${TMDB_API_KEY}"
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_IDS="${TELEGRAM_CHAT_IDS}"            # 支持多个，用空格分隔 / Multiple chat IDs

MAX_OVERVIEW_LEN="500"                              # 简介最大长度，默认500 / Max overview length, Default: 500

# 确保去重文件存在 / Ensure dedup file exists
[ ! -f "$DEDUP_FILE" ] && touch "$DEDUP_FILE"

# ---------------- 日志函数 / Logging ----------------
log_info() { printf "[INFO] %s\n" "$1"; }           # 普通信息 / General info
log_warn() { printf "[WARN] %s\n" "$1"; }           # 警告信息 / Warning
log_error() { printf "[ERROR] %s\n" "$1" >&2; }     # 错误信息 / Error

# ---------------- 语言映射 / Language Mapping ----------------
# 功能: 将 TMDB ISO 语言代码转换为中文描述
# Function: Convert TMDB ISO language code to Chinese name
lang_map() {
    case "$1" in
        ar) echo "阿拉伯语" ;;
        as) echo "阿萨姆语" ;;
        bg) echo "保加利亚语" ;;
        bn) echo "孟加拉语" ;;
        cs) echo "捷克语" ;;
        da) echo "丹麦语" ;;
        de) echo "德语" ;;
        el) echo "希腊语" ;;
        en) echo "英语" ;;
        es) echo "西班牙语" ;;
        fa) echo "波斯语" ;;
        fi) echo "芬兰语" ;;
        fr) echo "法语" ;;
        gu) echo "古吉拉特语" ;;
        he) echo "希伯来语" ;;
        hi) echo "印地语" ;;
        hr) echo "克罗地亚语" ;;
        hu) echo "匈牙利语" ;;
        id) echo "印尼语" ;;
        is) echo "冰岛语" ;;
        it) echo "意大利语" ;;
        ja) echo "日语" ;;
        kn) echo "卡纳达语" ;;
        ko) echo "韩语" ;;
        ml) echo "马拉雅拉姆语" ;;
        mr) echo "马拉地语" ;;
        nl) echo "荷兰语" ;;
        no) echo "挪威语" ;;
        or) echo "奥里亚语" ;;
        pa) echo "旁遮普语" ;;
        pl) echo "波兰语" ;;
        pt) echo "葡萄牙语" ;;
        ro) echo "罗马尼亚语" ;;
        ru) echo "俄语" ;;
        sa) echo "梵语" ;;
        sk) echo "斯洛伐克语" ;;
        sl) echo "斯洛文尼亚语" ;;
        sr) echo "塞尔维亚语" ;;
        sv) echo "瑞典语" ;;
        ta) echo "泰米尔语" ;;
        te) echo "泰卢固语" ;;
        th) echo "泰语" ;;
        tr) echo "土耳其语" ;;
        uk) echo "乌克兰语" ;;
        ur) echo "乌尔都语" ;;
        vi) echo "越南语" ;;
        zh) echo "中文" ;;
        *) echo "$1" ;;
    esac
}

# ---------------- 国家映射 / Country Mapping ----------------
# 功能: 将 TMDB 国家代码转换为中文描述
# Function: Convert TMDB country code to Chinese name
country_map() {
    case "$1" in
        AR) echo "阿根廷" ;;
        AT) echo "奥地利" ;;
        AU) echo "澳大利亚" ;;
        BE) echo "比利时" ;;
        BR) echo "巴西" ;;
        CA) echo "加拿大" ;;
        CH) echo "瑞士" ;;
        CL) echo "智利" ;;
        CN) echo "中国" ;;
        CZ) echo "捷克" ;;
        DE) echo "德国" ;;
        DK) echo "丹麦" ;;
        EG) echo "埃及" ;;
        ES) echo "西班牙" ;;
        FI) echo "芬兰" ;;
        FR) echo "法国" ;;
        GB|UK) echo "英国" ;;
        GR) echo "希腊" ;;
        HK) echo "香港" ;;
        HU) echo "匈牙利" ;;
        IE) echo "爱尔兰" ;;
        IL) echo "以色列" ;;
        IN) echo "印度" ;;
        IR) echo "伊朗" ;;
        IT) echo "意大利" ;;
        JP) echo "日本" ;;
        KR) echo "韩国" ;;
        MA) echo "摩洛哥" ;;
        MX) echo "墨西哥" ;;
        NL) echo "荷兰" ;;
        NO) echo "挪威" ;;
        NZ) echo "新西兰" ;;
        PL) echo "波兰" ;;
        PT) echo "葡萄牙" ;;
        RO) echo "罗马尼亚" ;;
        RU) echo "俄罗斯" ;;
        SA) echo "沙特阿拉伯" ;;
        SE) echo "瑞典" ;;
        SG) echo "新加坡" ;;
        TH) echo "泰国" ;;
        TN) echo "突尼斯" ;;
        TR) echo "土耳其" ;;
        TW) echo "台湾" ;;
        UA) echo "乌克兰" ;;
        US) echo "美国" ;;
        ZA) echo "南非" ;;
        *) echo "$1" ;;
    esac
}

# ---------------- 公司映射 / Company Mapping ----------------
# 功能: 将 TMDB 制片公司名称转换为中文描述
# Function: Convert TMDB production company name to Chinese
company_map() {
    case "$1" in
        "20th Century Fox"|"20th Century Studios") echo "二十世纪影业 (20th Century Studios)" ;;
        "A24") echo "A24 影业" ;;
        "Amazon Studios") echo "亚马逊影业 (Amazon Studios)" ;;
        "Apple Studios"|"Apple Original Films") echo "苹果影业 (Apple Studios)" ;;
        "BBC Films") echo "BBC 电影" ;;
        "Blumhouse Productions") echo "恐怖工厂 (Blumhouse Productions)" ;;
        "CJ Entertainment") echo "CJ 娱乐 (CJ Entertainment)" ;;
        "Columbia Pictures") echo "哥伦比亚影业 (Columbia Pictures)" ;;
        "Constantin Film") echo "康斯坦丁影业 (Constantin Film)" ;;
        "DC Films"|"DC Studios") echo "DC 影业 (DC Studios)" ;;
        "Disney"|"Walt Disney Pictures") echo "迪士尼 (Disney)" ;;
        "DreamWorks"|"DreamWorks Animation") echo "梦工厂 (DreamWorks)" ;;
        "Eros International") echo "Eros 国际 (Eros International)" ;;
        "Focus Features") echo "焦点影业 (Focus Features)" ;;
        "Gaumont") echo "高蒙 (Gaumont)" ;;
        "HBO Films") echo "HBO 影业" ;;
        "Kadokawa") echo "角川 (Kadokawa)" ;;
        "Legendary Pictures") echo "传奇影业 (Legendary Pictures)" ;;
        "Lionsgate") echo "狮门影业 (Lionsgate)" ;;
        "Marvel Studios") echo "漫威影业 (Marvel Studios)" ;;
        "Metro-Goldwyn-Mayer"|"MGM") echo "米高梅 (MGM)" ;;
        "Mosfilm") echo "莫斯科电影制片厂 (Mosfilm)" ;;
        "Neon") echo "Neon 影业" ;;
        "Netflix") echo "奈飞 (Netflix)" ;;
        "New Line Cinema") echo "新线影业 (New Line Cinema)" ;;
        "Paramount Pictures") echo "派拉蒙影业 (Paramount Pictures)" ;;
        "Pathé") echo "百代 (Pathé)" ;;
        "Pixar") echo "皮克斯动画 (Pixar)" ;;
        "Shochiku") echo "松竹 (Shochiku)" ;;
        "Sony Pictures"|"Sony Pictures Entertainment") echo "索尼影业 (Sony Pictures)" ;;
        "STX Entertainment") echo "STX 娱乐 (STX Entertainment)" ;;
        "StudioCanal") echo "StudioCanal 影业" ;;
        "Studio Ghibli") echo "吉卜力工作室 (Studio Ghibli)" ;;
        "Toho") echo "东宝 (Toho)" ;;
        "TriStar Pictures") echo "三星影业 (TriStar Pictures)" ;;
        "Universal Pictures") echo "环球影业 (Universal Pictures)" ;;
        "Warner Bros."|"Warner Bros. Pictures") echo "华纳兄弟 (Warner Bros.)" ;;
        "Working Title Films") echo "Working Title 电影公司" ;;
        *) echo "$1" ;;
    esac
}

# ---------------- 工具函数 / Utility Functions ----------------
# 功能: 格式化评分，支持不同来源
# Function: Format score according to provider
format_score() {
    SCORE="$1"
    PROVIDER="$2"
    if [ "$SCORE" = "N/A" ] || [ -z "$SCORE" ]; then
        echo "暂无评分"
    else
        case "$PROVIDER" in
            imdb) echo "$SCORE / 10" ;;
            letterboxd) echo "$SCORE / 5" ;;
            metacritic) echo "$SCORE / 100" ;;
            rogerebert) echo "$SCORE / 4" ;;
            avg) echo "$SCORE / 100" ;;
            *) echo "$SCORE" ;;
        esac
    fi
}

# 功能: 发送消息到 Telegram
# Function: Send message via Telegram bot
send_telegram() {
    MSG="$1"
    for CHAT_ID in $TELEGRAM_CHAT_IDS; do
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="$CHAT_ID" \
            -d text="$MSG" \
            -d parse_mode="HTML" >/dev/null
    done
}

# ---------------- Token 检测 / Token Check ----------------
# 功能: 检查 API Token 是否有效
# Function: Verify API token validity
token_check_errors=""
check_tokens() {
    MDB_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "https://api.mdblist.com/user?apikey=${MDBLIST_API_KEY}&format=json")
    [ "$MDB_HTTP" != "200" ] && token_check_errors="$token_check_errors MDBLIST_API_KEY:$MDB_HTTP"
    TMDB_HTTP=$(curl -s -o /dev/null -w "%{http_code}" "https://api.themoviedb.org/3/configuration?api_key=${TMDB_API_KEY}")
    [ "$TMDB_HTTP" != "200" ] && token_check_errors="$token_check_errors TMDB_API_KEY:$TMDB_HTTP"
    if [ -n "$token_check_errors" ]; then
        ERR_MSG="⚠️ API Token 错误: $token_check_errors"
        log_error "$ERR_MSG"
        send_telegram "$ERR_MSG"
        exit 1
    fi
}

# ---------------- 数据获取 / Data Retrieval ----------------
# 功能: 获取今日电影列表
# Function: Fetch today's movie list from MDBList
get_movie_list() {
    MOVIE_ITEMS_JSON=$(curl -s "https://api.mdblist.com/lists/${MDBLIST_LIST_ID}/items?apikey=${MDBLIST_API_KEY}&format=json&limit=100&order=asc&sort=releasedigital&unified=true")
}

# 功能: 判断是否重复
# Function: Check if TMDB ID is already sent
is_duplicate() {
    grep -q "^$1 " "$DEDUP_FILE"
}

# 功能: 获取 TMDB 电影详细信息
# Function: Fetch TMDB movie details
get_tmdb_info() {
    TMDB_ID="$1"
    TMDB_JSON=$(curl -s "https://api.themoviedb.org/3/movie/${TMDB_ID}?api_key=${TMDB_API_KEY}&language=zh-CN")
}

# 功能: 获取各评分
# Function: Fetch IMDb, Letterboxd, Metacritic, RogerEbert, average scores
get_ratings() {
    TMDB_ID="$1"
    RATING_IMDB=$(curl -s -X POST "https://api.mdblist.com/rating/movie/imdb?apikey=${MDBLIST_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{ \"ids\": [${TMDB_ID}], \"provider\": \"tmdb\" }" | jq -r '.ratings[0].rating // "N/A"')
    RATING_LETTERBOXD=$(curl -s -X POST "https://api.mdblist.com/rating/movie/letterboxd?apikey=${MDBLIST_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{ \"ids\": [${TMDB_ID}], \"provider\": \"tmdb\" }" | jq -r '.ratings[0].rating // "N/A"')
    RATING_METACRITIC=$(curl -s -X POST "https://api.mdblist.com/rating/movie/metacritic?apikey=${MDBLIST_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{ \"ids\": [${TMDB_ID}], \"provider\": \"tmdb\" }" | jq -r '.ratings[0].rating // "N/A"')
    RATING_ROGEREBERT=$(curl -s -X POST "https://api.mdblist.com/rating/movie/rogerebert?apikey=${MDBLIST_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{ \"ids\": [${TMDB_ID}], \"provider\": \"tmdb\" }" | jq -r '.ratings[0].rating // "N/A"')
    AVG_SCORE=$(curl -s -X POST "https://api.mdblist.com/rating/movie/score_average?apikey=${MDBLIST_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{ \"ids\": [\"${TMDB_ID}\"], \"provider\": \"tmdb\" }" | jq -r '.ratings[0].rating // "N/A"')
}

# ---------------- 消息生成与发送 / Message Generation and Sending ----------------
# Function: generate_and_send_msg
# 功能：生成电影信息的完整消息，并发送到 Telegram
# Description: Generate a complete message containing movie details and send it via Telegram
generate_and_send_msg() {
    # 获取中文和英文电影标题 / Get movie titles in Chinese and English
    TITLE_CN="$(echo "$TMDB_JSON" | jq -r '.title')"
    TITLE_EN="$(echo "$TMDB_JSON" | jq -r '.original_title')"

    # 从上映日期提取年份 / Extract release year from release date
    RELEASE_YEAR="$(echo "$TMDB_JSON" | jq -r '.release_date' | cut -d- -f1)"

    # 获取电影简介 / Get movie overview
    OVERVIEW="$(echo "$TMDB_JSON" | jq -r '.overview')"
    [ ${#OVERVIEW} -gt $MAX_OVERVIEW_LEN ] && OVERVIEW="${OVERVIEW:0:$MAX_OVERVIEW_LEN}..."

    # 获取电影时长（分钟） / Get movie runtime in minutes
    RUNTIME="$(echo "$TMDB_JSON" | jq -r '.runtime')"

    # 获取电影类型 / Get movie genres
    GENRES="$(echo "$TMDB_JSON" | jq -r '[.genres[].name] | join(" / ")')"

    # 获取电影语言 / Get spoken languages
    LANGS="$(echo "$TMDB_JSON" | jq -r '.spoken_languages[].iso_639_1')"
    LANG_CN=""
    for l in $LANGS; do
        LANG_CN="$LANG_CN$(lang_map "$l") / "
    done
    LANG_CN="$(echo "$LANG_CN" | sed 's: / $::')"

    # 获取制作国家 / Get production countries
    COUNTRIES="$(echo "$TMDB_JSON" | jq -r '.production_countries[].iso_3166_1')"
    COUNTRIES_CN=""
    for c in $COUNTRIES; do
        COUNTRIES_CN="$COUNTRIES_CN$(country_map "$c") / "
    done
    COUNTRIES_CN="$(echo "$COUNTRIES_CN" | sed 's: / $::')"

    # 获取制作公司 / Get production companies
    COMPANIES_CN="$(echo "$TMDB_JSON" | jq -r '.production_companies[].name' | while IFS= read -r co; do
        echo -n "$(company_map "$co") / "
    done)"
    COMPANIES_CN="$(echo "$COMPANIES_CN" | sed 's: / $::')"
 
 # 构造 IMDb 链接 / Construct IMDb URL
    IMDB_ID="$(echo "$TMDB_JSON" | jq -r '.imdb_id')"
    IMDB_URL="https://www.imdb.com/title/${IMDB_ID}"

    # 获取美国可租/可买平台 / Get US rent/buy providers
    ONLINE_STREAMS="$(curl -s "https://api.themoviedb.org/3/movie/${TMDB_ID}/watch/providers?api_key=${TMDB_API_KEY}" \
        | jq -r '[.results.US.rent[]?.provider_name, .results.US.buy[]?.provider_name] | unique | join(" / ")')"
    [ -z "$ONLINE_STREAMS" ] && ONLINE_STREAMS="已上线，暂无法确定提供平台"

    # 将各类评分格式化显示 / Format different scores
    RATING_IMDB_F="$(format_score "$RATING_IMDB" "imdb")"
    RATING_LETTERBOXD_F="$(format_score "$RATING_LETTERBOXD" "letterboxd")"
    RATING_METACRITIC_F="$(format_score "$RATING_METACRITIC" "metacritic")"
    RATING_ROGEREBERT_F="$(format_score "$RATING_ROGEREBERT" "rogerebert")"
    AVG_SCORE_F="$(format_score "$AVG_SCORE" "avg")"

    # 将所有信息拼接为一条消息 / Combine all info into one message
    MSG="$DATE_STR - 《$TITLE_CN （$TITLE_EN）》 （$RELEASE_YEAR） 已上线

简介：$OVERVIEW

语言：$LANG_CN
国家：$COUNTRIES_CN
类型：$GENRES
时长：$RUNTIME 分钟
发行商：$COMPANIES_CN
在线发行：$ONLINE_STREAMS

综合评价：$AVG_SCORE_F
网友评分：IMDb $RATING_IMDB_F | Letterboxd $RATING_LETTERBOXD_F
专业评分：Metacritic $RATING_METACRITIC_F | RogerEbert $RATING_ROGEREBERT_F

IMDb：$IMDB_URL"
    log_info "$MSG"
    send_telegram "$MSG" # 调用发送函数 / Call send function
}

# 功能: 清理一年以前的去重记录
# Function: Remove deduplication records older than one year
clean_old_dedup() {
    [ ! -f "$DEDUP_FILE" ] && touch "$DEDUP_FILE"

    NOW_TS=$(date +%s)
    YEAR_AGO=$((NOW_TS - 31536000))

    sed -i -e '/^[[:space:]]*$/d' -e 's/[[:space:]]*$//' "$DEDUP_FILE"

    TMP_FILE="/tmp/sent_tmdb_ids.tmp"
    
    awk -v cutoff="$YEAR_AGO" '{
        if ($2 >= cutoff) data[$1] = $0
    }
    END {
        for (id in data) print data[id]
    }' "$DEDUP_FILE" | sort -k2,2n > "$TMP_FILE"

    mv "$TMP_FILE" "$DEDUP_FILE"
}

# ---------------- 主流程 / Main Flow ----------------
check_tokens
clean_old_dedup
get_movie_list

MOVIE_COUNT=$(echo "$MOVIE_ITEMS_JSON" | jq 'length')
if [ "$MOVIE_COUNT" -eq 0 ]; then
    log_info "今日无新电影，脚本退出 / No new movies today, exiting."
    exit 0
fi

for TMDB_ID in $(echo "$MOVIE_ITEMS_JSON" | jq -r '.[].id'); do
    if ! is_duplicate "$TMDB_ID"; then
        get_tmdb_info "$TMDB_ID"
        get_ratings "$TMDB_ID"
        generate_and_send_msg
        NOW_TS=$(date +%s)
        echo "$TMDB_ID $NOW_TS" >> "$DEDUP_FILE"
    fi
done

log_info "全部电影消息已发送完成 / All movie notifications sent."
