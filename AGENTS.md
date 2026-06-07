# AGENTS.md

This file is written for AI coding agents and automation bots. Follow it when a user gives you this repository and asks you to deploy Matrix Element Call MusicBot Docker Pro.

中文在前，English below.

## 给机器人看的部署规则

### 目标

把本仓库部署成一个可用的 Matrix / Element Call 音乐机器人。部署完成后，用户可以在 Matrix 房间里使用：

```text
!help
!stations
!podcasts
study1
blg
```

### 先确认前置条件

部署前必须向用户确认或自行检查：

- 目标服务器可以运行 Docker 和 Docker Compose
- Matrix homeserver 已经可用
- Element Call / LiveKit 已经可用
- 已有或可以创建一个 Matrix bot 账号
- 有 bot 的 Matrix access token
- 目标 Docker 网络名，默认通常是 `matrix`
- 允许控制 bot 的 Matrix 房间 ID，例如 `!roomid:example.com`

如果用户还没有 bot token，不要编造。按 README 的 Synapse 示例帮用户创建账号并通过 `/login` 获取 token。

### 绝对不要做

- 不要把 `.env`、`config/config.toml`、access token、bot 密码、私有房间 ID、日志、缓存提交到 Git。
- 不要在最终回复中打印真实 access token。
- 不要把网页播放器 URL 当成电台流地址。
- 不要承诺 Spotify playlist 可以直接播放。通常不可以。
- 不要让多个互不相关的房间共享同一个 bot 实例，除非用户明确接受播放会互相抢占。

### 推荐部署步骤

```bash
git clone https://github.com/hanigege/matrix-element-call-musicbot-docker-pro.git
cd matrix-element-call-musicbot-docker-pro
cp .env.example .env
```

编辑 `.env`，填入：

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

验证：

```bash
docker compose ps
docker logs --tail=120 matrix-musicbot
```

必须看到：

```text
Startup checks passed
Bot ready
```

### 多用户 / 多房间注意事项

一个容器只有一个全局播放器。多个用户在同一个房间控制是正常的；多个房间共用同一个实例会互相影响。

如果用户需要多个房间互不干扰，部署多个实例：

- 使用不同 bot 账号
- 使用不同容器名
- 使用不同目录，例如 `matrix-musicbot-room-a`、`matrix-musicbot-room-b`
- 每个实例设置不同 `MATRIX_ALLOWED_ROOM_ID`
- 避免共享同一个 `data/` 和 `cache/`

### 电台别名

电台别名文件是：

```text
data/radio_aliases.json
```

只放直连音频流，例如 MP3、AAC、HLS。不要放网页播放器页面。

推荐从 Radio Browser 找源：

```text
https://www.radio-browser.info/
```

优先选择：

- `lastcheckok=1`
- `codec` 是 MP3/AAC
- `url_resolved` 是可直接播放的流

用 `ffprobe` 短测：

```bash
docker exec matrix-musicbot ffprobe -hide_banner -loglevel error \
  -show_entries format=format_name \
  -of default=nw=1:nk=1 \
  -rw_timeout 8000000 \
  'STREAM_URL'
```

### Podcast 播客别名

播客别名文件是：

```text
data/podcast_aliases.json
```

RSS 必须包含音频 enclosure：

```xml
<enclosure url="https://example.com/episode.mp3" type="audio/mpeg" />
```

用户命令：

```text
!podcasts
blg
blg 3
```

### Element Call 行为

`!join` 或播放命令只会让机器人加入通话。用户本人仍然必须在 Element 客户端里点击“加入”才能听到声音。

### 故障排查

如果机器人启动失败：

1. 看 `docker logs --tail=200 matrix-musicbot`
2. 检查 `.env` 是否渲染成 `config/config.toml`
3. 检查 homeserver URL 是否能从容器内访问
4. 检查 access token 是否有效
5. 检查 bot 是否在允许房间内
6. 检查 Element Call / LiveKit 本身是否正常
7. 运行 `./scripts/validate.sh`

如果直播电台卡住：

- 确认使用的是直连音频流
- 不要用网页播放器地址
- 换一个 Radio Browser 中最近检测成功的源
- 用 `ffprobe` 短测 URL

## English Instructions For Agents

### Goal

Deploy this repository as a working Matrix / Element Call music bot. After deployment, the user should be able to run:

```text
!help
!stations
!podcasts
study1
blg
```

### Required Inputs

Before deployment, confirm or discover:

- Docker and Docker Compose are available
- Matrix homeserver is working
- Element Call / LiveKit is working
- A Matrix bot account exists or can be created
- A Matrix access token is available
- Docker network name, usually `matrix`
- Allowed Matrix room ID, for example `!roomid:example.com`

If the user has no bot token, do not invent one. Help create a bot account and call Matrix `/login` as described in README.

### Never Do This

- Never commit `.env`, `config/config.toml`, access tokens, bot passwords, private room IDs, logs, or caches.
- Never print the real access token in the final answer.
- Never treat a web player page as a radio stream URL.
- Never promise direct Spotify playlist playback. It usually does not work.
- Never let unrelated rooms share one bot instance unless the user accepts shared playback control.

### Deployment

```bash
git clone https://github.com/hanigege/matrix-element-call-musicbot-docker-pro.git
cd matrix-element-call-musicbot-docker-pro
cp .env.example .env
```

Fill `.env`:

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

Verify:

```bash
docker compose ps
docker logs --tail=120 matrix-musicbot
```

Required log lines:

```text
Startup checks passed
Bot ready
```

### Multi-User And Multi-Room Warning

One container has one global player. Multiple users in the same room are fine. Multiple unrelated rooms sharing the same instance will interrupt each other.

For independent rooms, deploy multiple instances with:

- different bot accounts
- different container names
- different directories
- different `MATRIX_ALLOWED_ROOM_ID` values
- separate `data/` and `cache/`

### Radio Sources

Use direct MP3/AAC/HLS stream URLs in:

```text
data/radio_aliases.json
```

Radio Browser is recommended:

```text
https://www.radio-browser.info/
```

Prefer stations with `lastcheckok=1` and direct `url_resolved` streams.

### Podcast Sources

Use RSS feeds with audio enclosures in:

```text
data/podcast_aliases.json
```

The RSS item must include:

```xml
<enclosure url="https://example.com/episode.mp3" type="audio/mpeg" />
```

### Final Response Checklist

When done, tell the user:

- where the repo was deployed
- whether the container is healthy
- whether logs show `Startup checks passed` and `Bot ready`
- what commands to try in Matrix
- what was not verified, if anything
