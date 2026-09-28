# Modules

Feature modules with hard boundaries. Data, providers and Hive keys are
per-module; nothing leaks across.

    modules/media/      shared bilibili UGC core (api/ models/ controllers/ widgets/ pages/)
    modules/music/      bmsc-style listening  (controllers/<domain>/  pages/<domain>/  services/)
    modules/video/      newBV-style watching  (api/ models/ controllers/playback/  pages/<domain>/  widgets/)

## media/ — shared core

Owns everything both modes read, and nothing module-specific:

- `api/` — `bilibili_music_api` (archive feed / popular / ranking / view /
  playurl / search) and `bilibili_ugc_api` (account, fav folders, cloud
  history, watch later, dynamics, comments, like/coin/triple, user space,
  subtitle, online count). Risk-control lessons: playurl stays on the plain
  non-WBI endpoint; guest requests carry the try_look params.
- `models/` — response models; archives flow through `MusicArchive` so both
  modes share one card/queue shape.
- `controllers/` — the VOD player engine (`music_player_controller`): one
  queue, play modes, quality switching, DASH dual-stream via mpv's
  `audio-file`. Modules inject hooks (`modulePlayUrlResolver` for PGC
  episodes) instead of media importing them.
- `pages/` — surfaces both modes mount: comments, user space, dynamics.
- `widgets/` — the login gate and the shared video card.

## music/ — bmsc feature set

- `controllers/library/` — local favorites + recents (Hive `musicFavorites`
  / `musicRecents`).
- `controllers/playlist/` — synced playlists: bilibili fav folders cached to
  Hive `musicSyncFolders` / `musicSyncFolderTracks` / `musicSyncTimes`, plus
  排除分P (`musicExcludedParts`). This is the 同步歌单 core.
- `pages/playback/` — the full-screen lyric player and the archive track
  list; `pages/playlist/` — the synced-playlist shelf and a folder's track
  table; `pages/discover/` — cloud history (dynamics lives in media, shared).
- `services/` — the lyric chain (B站 BGM → LRC APIs → 网易云 fallback).

## video/ — newBV feature set

- `pages/` by domain: `archive/` (detail with the interaction row and parts),
  `playback/` (the player: subtitles, danmaku settings, aspect, viewer count,
  watch-progress recording + heartbeat), `discover/` (region tabs, PGC
  seasons + season detail, full-type search with hotwords), `personal/`
  (fav folders / cloud history / watch later over the account).
- `api/` + `models/` — the PGC layer (feed, season detail, pgc playurl).
- `controllers/playback/` — `videoProgressController`, Hive
  `videoWatchProgress`: card progress bars and resume.
- `widgets/` — `VideoCard` with the watched-progress bar.

## Rules

1. `music` and `video` import `media`, never each other.
2. The live domain (`features/`, `platforms/`) must not import `modules/`.
   Only the app shell (home page mode switch, router) may.
3. Each module owns its Hive keys; shared UGC logic goes to `media/`.
4. New state is `@Riverpod` codegen; page-level state models are `@freezed`.
