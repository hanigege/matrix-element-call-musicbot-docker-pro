# Matrix Element Call MusicBot Docker Pro

> 中文说明在前，English below.

一个可直接部署的 Matrix / Element Call 音乐机器人 Docker 项目，基于上游镜像 [`SultanAlburaq/matrix-element-call-musicbot`](https://github.com/SultanAlburaq/matrix-element-call-musicbot)，并通过挂载增强版 `patches/bot.py` 增加更适合日常使用的功能。

适合放在自己的 Matrix 群组里当“共享背景音乐/电台/播客播放器”：学习时放 LoFi，吃饭时放 Jazz，开语音房时播 Podcast。

## 功能

- Docker Compose 一键启动
- 支持 Element Call 语音房播放
- 支持 `!play <URL 或搜索词>`
- 支持直播电台短别名，例如 `study1`、`relax1`、`dinner1`
- 支持 Podcast RSS 短别名，例如 `blg`、`blg 3`
- 支持 `!stations` 查看电台别名
- 支持 `!podcasts` 查看播客别名
- 支持房间白名单，避免陌生房间抢占播放
- 直播流切换走专门逻辑，避免把直播流当普通文件下载导致卡住
- 默认较安静，适合家庭/小群长期运行

## 重要注意事项

### 单实例只有一个播放器

一个 `matrix-musicbot` 容器只有一个全局播放器。多个房间、多个用户共用同一个实例时，任何有权限的人都可以：

- 切换当前播放
- `!stop` 停止播放
- `!skip` 跳过
- 改变队列

所以生产环境强烈建议设置：

```dotenv
MATRIX_ALLOWED_ROOM_ID=!roomid:example.com
```

如果要给多个互不影响的房间使用，建议为每个房间部署一个独立 bot 实例，使用不同的 bot 账号、容器名、数据目录和房间白名单。

### `!join` 只让机器人进通话

`!join` 或播放命令会让机器人加入 Element Call，但不会让你的 Element 客户端自动进通话。你仍然需要在 Element 里点击“加入”按钮才能听到声音。

### Spotify / 网页播放器链接通常不能直接播

Bot 需要实际可播放的音频流或 yt-dlp 能解析的媒体源。Spotify playlist、网页播放器页面、普通网页通常不能直接播放。电台请使用 MP3/AAC/HLS 直链，Podcast 请使用 RSS enclosure 音频链接。

找电台可以用 [Radio Browser](https://www.radio-browser.info/)，优先选 `lastcheckok=1` 且 `url_resolved` 是直连音频流的条目。

## 部署要求

- Docker 和 Docker Compose
- 已可用的 Matrix homeserver
- 已可用的 Element Call / LiveKit 环境
- 一个 Matrix bot 账号和 access token
- 一个能访问 Matrix / LiveKit 相关服务的 Docker 网络，默认叫 `matrix`

## 快速开始

```bash
git clone https://github.com/hanigege/matrix-element-call-musicbot-docker-pro.git
cd matrix-element-call-musicbot-docker-pro
cp .env.example .env
```

编辑 `.env`：

```dotenv
MATRIX_HOMESERVER=https://matrix.example.com
MATRIX_USER_ID=@musicbot:example.com
MATRIX_ACCESS_TOKEN=replace-me
MATRIX_ALLOWED_ROOM_ID=!roomid:example.com
MATRIX_DOCKER_NETWORK=matrix
```

启动：

```bash
chmod +x scripts/*.sh
./scripts/install.sh
```

查看日志：

```bash
docker logs --tail=120 matrix-musicbot
```

看到下面两行基本就正常了：

```text
Startup checks passed
Bot ready
```

## 创建 bot 账号和 token

Synapse 常见方式：

```bash
docker exec matrix-synapse register_new_matrix_user \
  -u musicbot \
  -p 'replace-with-a-long-password' \
  --no-admin \
  --exists-ok \
  -c /data/homeserver.yaml \
  http://localhost:8008
```

然后登录获取 token：

```bash
curl -X POST 'https://matrix.example.com/_matrix/client/v3/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "m.login.password",
    "identifier": {"type": "m.id.user", "user": "musicbot"},
    "password": "replace-with-a-long-password",
    "initial_device_display_name": "matrix-musicbot"
  }'
```

把返回的 `access_token` 填入 `.env`。不要提交 `.env` 或 `config/config.toml`。

## 电台别名

运行时文件：

```text
data/radio_aliases.json
```

首次运行会从示例文件生成：

```text
data/radio_aliases.example.json
```

示例：

```json
{
  "study1": "http://stream.zeno.fm/0r0xa792kwzuv",
  "relax1": "http://stream.srg-ssr.ch/m/rsc_de/mp3_128",
  "dinner1": "http://stream.srg-ssr.ch/m/rsj/mp3_128"
}
```

Matrix 房间里使用：

```text
!stations
study1
!relax1
```

电台别名会立即切台：停止当前播放、清空队列、必要时加入 Element Call，然后播放新直播流。

## Podcast 播客别名

运行时文件：

```text
data/podcast_aliases.json
```

示例：

```json
{
  "blg": "https://example.com/podcast/rss.xml"
}
```

RSS 必须有音频 enclosure：

```xml
<enclosure url="https://example.com/episode.mp3" type="audio/mpeg" />
```

Matrix 房间里使用：

```text
!podcasts
blg
blg 3
```

`blg` 播放最新一集，`blg 3` 播放第 3 新的一集。

## 常用命令

```text
!help
!join
!leave
!play <url-or-query>
!stop
!skip
!queue
!nowplaying
!stations
!podcasts
!status
```

## 验证

```bash
./scripts/validate.sh
```

在容器里短测直播流：

```bash
docker exec matrix-musicbot ffprobe -hide_banner -loglevel error \
  -show_entries format=format_name \
  -of default=nw=1:nk=1 \
  -rw_timeout 8000000 \
  'http://stream.srg-ssr.ch/m/rsj/mp3_128'
```

## 项目结构

```text
.
├── config/config.toml.example
├── data/radio_aliases.example.json
├── data/podcast_aliases.example.json
├── docker-compose.yaml
├── patches/bot.py
└── scripts/
```

`patches/bot.py` 会被挂载到容器里的 `/app/bot.py`，这是本项目的主要增强逻辑。

## English

Docker deployment kit for Matrix / Element Call music playback, based on [`SultanAlburaq/matrix-element-call-musicbot`](https://github.com/SultanAlburaq/matrix-element-call-musicbot), with a patched `bot.py` mounted into the upstream container.

It is meant for a self-hosted Matrix room where people want shared background music, live radio, and podcast playback inside Element Call.

### Features

- Docker Compose deployment
- Element Call playback
- `!play <URL or search query>`
- live radio aliases such as `study1`, `relax1`, `dinner1`
- podcast RSS aliases such as `blg` or `blg 3`
- `!stations` to list radio aliases
- `!podcasts` to list podcast aliases
- room whitelist for safer shared usage
- safer live-stream switching, avoiding download/queue hangs for endless streams
- quiet defaults for small private rooms

### Important Notes

One bot container has one global player. If multiple rooms or multiple users control the same instance, they all control the same playback state. Anyone allowed to use the bot can stop, skip, replace, or queue tracks.

For production, set:

```dotenv
MATRIX_ALLOWED_ROOM_ID=!roomid:example.com
```

If you need independent playback in multiple rooms, run one bot instance per room with a different bot account, container name, data directory, and whitelist.

`!join` only makes the bot join the Element Call. Human users still need to click Element's join button to hear audio.

Spotify playlists and web player pages usually cannot be played directly. Use direct MP3/AAC/HLS stream URLs for radio, and RSS feeds with audio enclosures for podcasts.

### Quick Start

```bash
git clone https://github.com/hanigege/matrix-element-call-musicbot-docker-pro.git
cd matrix-element-call-musicbot-docker-pro
cp .env.example .env
```

Edit `.env`:

```dotenv
MATRIX_HOMESERVER=https://matrix.example.com
MATRIX_USER_ID=@musicbot:example.com
MATRIX_ACCESS_TOKEN=replace-me
MATRIX_ALLOWED_ROOM_ID=!roomid:example.com
MATRIX_DOCKER_NETWORK=matrix
```

Start:

```bash
chmod +x scripts/*.sh
./scripts/install.sh
```

Check logs:

```bash
docker logs --tail=120 matrix-musicbot
```

Expected:

```text
Startup checks passed
Bot ready
```

### Radio Aliases

Runtime file:

```text
data/radio_aliases.json
```

Use direct audio stream URLs, not web player pages. [Radio Browser](https://www.radio-browser.info/) is a good source; prefer stations with successful recent checks and direct `url_resolved` streams.

Commands:

```text
!stations
study1
!relax1
```

### Podcast Aliases

Runtime file:

```text
data/podcast_aliases.json
```

The RSS feed must expose audio via `<enclosure type="audio/...">`.

Commands:

```text
!podcasts
blg
blg 3
```

`blg` plays the newest episode. `blg 3` plays the third newest episode.

### Security

Never commit `.env`, `config/config.toml`, Matrix access tokens, bot passwords, private room IDs, logs, or caches.

Use `MATRIX_ALLOWED_ROOM_ID` for production deployments.
