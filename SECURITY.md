# Security

- Do not commit `.env`, `config/config.toml`, Matrix access tokens, bot passwords, room IDs for private rooms, or logs.
- Use `access.allowed_rooms` in production so a single bot instance cannot be controlled from arbitrary rooms.
- Treat radio and podcast URLs as untrusted input. Use direct audio streams from reputable sources and validate them with `ffprobe` before adding them.
- This bot joins calls and plays audio. Do not invite it to rooms where any member should not be able to control playback.
