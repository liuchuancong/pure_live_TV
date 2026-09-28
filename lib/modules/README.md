# Modules

Feature modules with hard boundaries. Data, providers and Hive keys are
per-module; nothing leaks across.

- `media/` — shared bilibili UGC core for music AND video: the archive API,
  models, the VOD playback engine (queue, play modes, quality) and the login
  gate. Owns no library data of its own.
- `music/` — QQ-music-style listening: favorites/recent library (Hive keys
  `musicFavorites` / `musicRecents`), lyric chain, section UI, mini bar,
  full-screen lyric player.
- `video/` — newBV-style watching: recommend/popular/chart/search sections,
  archive detail with parts + related, full-screen player (danmaku, quality,
  speed, seek acceleration). Browsing only; keeps no local library.

Rules:
1. `music` and `video` import `media`, never each other.
2. The live domain (`features/`, `platforms/`) must not import `modules/`.
   Only the app shell (home page mode switch, router) may.
3. New shared B站 UGC logic goes to `media/`; anything module-specific stays
   in its module (own controllers, own Hive keys, own i18n `music_*` /
   `video_*` prefixes).
