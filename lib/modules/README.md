# Architecture

Layer-first core, feature-first domains.

    lib/
      app/          composition root: bootstrap, router (app_router +
                    settings_routes), theme wiring. No business logic.
      core/         business-free infrastructure: network (http client, proxy
                    and header policies), storage (hive prefs), player shell
                    (media_core facade, FLV relay), UI kit (Tv* widgets,
                    theme, i18n), models shared platform-wide, utils.
      domains/      device/ — LAN device sync + remote control + web receiver
                    (moved out of modules/live: it serves every mode).
      modules/      business domains, feature-first inside:
        vod/        shared bilibili VOD engine both music and video mount
                    (api/ controllers/ models/ pages/ widgets/)
        live/       live mode (playback/ hot/ areas/ favorite/ favorite_areas/
                    history/ iptv/ movie_playback/ search/)
        music/      bmsc-style listening
        video/      newBV-style watching
      features/     pure app shell: home / settings / wallpaper / agreement.
                    No domain models, no repositories — may use domains.
      platforms/    live-site implementations (one folder per platform, one
                    Site class each); only modules/live and features/home read
                    them.

Dependency rules:

    App -> Core, modules, features
    modules -> Core (never each other; vod is the shared hub music/video read)
    features -> Core, modules (shell glue only)
    Core imports nothing from app/modules/features.
    platforms -> Core; read only by modules/live.

State ownership: global / domain-lifetime providers live next to their
controller file inside the domain; page-level notifiers and UI controllers
live in the page's own folder and are never registered globally. Widget
events flow up via callbacks; widgets never reach into a Notifier directly.

Naming: XxxPage / XxxPageNotifier / XxxState / XxxHelper (domain helper) /
App* (global utility). Generated files (*.g.dart, *.freezed.dart) sit beside
their sources.

---

# Modules

Feature modules with hard boundaries. Data, providers and Hive keys are
per-module; nothing leaks across.

    modules/vod/      shared bilibili core (api/ models/ controllers/ widgets/ pages/)
    modules/live/     live mode (playback/ hot/ areas/ favorite/ favorite_areas/
                      history/ iptv/ movie_playback/ remote/ search/)
    modules/music/    bmsc-style listening  (controllers/<domain>/  pages/<domain>/  services/)
    modules/video/    newBV-style watching  (controllers/playback/  pages/<domain>/  widgets/)

## vod/ — shared core

Owns everything both modes read, and nothing module-specific:

- `api/` — every bilibili web endpoint the vod modes read, one file per
  domain, plus the request plumbing they share:
  `bilibili_api_client` (the stored QR-login cookie + referer headers, csrf,
  WBI signing — the cookie rides on every bilibili call, logged in or not),
  `bilibili_music_api` (archive feed / popular / ranking / view / playurl /
  search), `bilibili_ugc_api` (account, fav folders, cloud history, watch
  later, dynamics, comments, like/coin/triple, user space, subtitle, online
  count), `bilibili_pgc_api` (season feed, season detail, episode playurl),
  `bilibili_danmaku_api` (segmented protobuf reads, the one-shot XML
  fallback, send), `bilibili_lyric_api` (the BGM lyric chain) and
  `third_party_lyric_api` (lrc.cx / rangotec / netease). Pages never build
  URLs; they call these. Risk-control lessons: playurl stays on the plain
  non-WBI endpoint; guest requests carry the try_look params.
- `models/` — response models, one folder per model behind
  `models/models.dart` (`@freezed`; json_serializable codegen where the JSON
  shape is flat, hand-written mapping beside the generated constructor for
  the adversarial shapes — bit flags, dual-key fields, deep nesting).
  Archives flow through `MusicArchive` so both modes share one card/queue
  shape.
- `controllers/` — the VOD player engine (`music_player_controller`): one
  queue, play modes, quality switching, DASH dual-stream via mpv's
  `audio-file`. Modules inject hooks (`modulePlayUrlResolver` for PGC
  episodes) instead of vod importing them.
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
  table; `pages/discover/` — cloud history (dynamics lives in vod, shared).
- `services/` — the lyric chain's policy layer (caching, title cleaning,
  title verification); the endpoints themselves live in vod/api.

## video/ — newBV feature set

- `pages/` by domain: `archive/` (detail with the interaction row and parts),
  `playback/` (the player: subtitles, danmaku settings, aspect, viewer count,
  watch-progress recording + heartbeat), `discover/` (region tabs, PGC
  seasons + season detail, full-type search with hotwords), `personal/`
  (fav folders / cloud history / watch later over the account).
- `controllers/playback/` — `videoProgressController`, Hive
  `videoWatchProgress`: card progress bars and resume.
- `widgets/` — `VideoCard` with the watched-progress bar.

## Rules

1. `music` and `video` import `vod`, never each other.
2. The live domain (`features/`, `platforms/`) must not import `modules/`.
   Only the app shell (home page mode switch, router) may.
3. Each module owns its Hive keys; shared UGC logic goes to `vod/`.
4. New state is `@Riverpod` codegen; page-level state models are `@freezed`.
