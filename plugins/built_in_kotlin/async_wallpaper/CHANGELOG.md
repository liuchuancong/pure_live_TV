## 3.3.0

Android reliability release. The public API is unchanged, but rotation now needs HTTPS URLs and no longer uses a foreground service. See [doc/migration.md](doc/migration.md#from-32-to-33).

- Android 11+: the plugin manifest now declares `<queries>` for the live-wallpaper, chooser, set-wallpaper, and crop-and-set intents. Without them package visibility hid the system wallpaper apps, so `getCapabilities()` reported live, OpenGL, and picker support as unavailable, and the video, OpenGL, picker, cropper, and chooser flows failed with `unsupported` or `system-ui-unavailable` on devices that had them.
- Wallpaper rotation no longer runs a foreground service. The interval and charging triggers use `WorkManager` and the time-of-day trigger uses one inexact alarm re-armed after each delivery, which removes the `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, and `SCHEDULE_EXACT_ALARM` permissions and keeps charging/time-of-day rotation working on Android 14+ and Android 15+.
- `downloadWallpaper` on Android 9 and older: saving to the gallery there needs `WRITE_EXTERNAL_STORAGE`, which the plugin does not declare, so the call always failed with a `SecurityException` after downloading the image. It now fails before downloading, logs the reason, and the README and Android guide explain what the host app must declare and request.
- Rotation sources now load through the same bounded loader as static wallpapers, so rotation URLs must be HTTPS and inherit the redirect, content-type, encoded-size, and decoded-pixel limits. This removes the Picasso dependency, which otherwise pulled OkHttp 3 into consumer release builds and broke R8 minification.
- `systemCropper` now reports an unreadable content URI as `source-unavailable` and a non-image one as `invalid-content-type`, the same codes the direct path uses. Before, Android's crop-intent lookup failed on the missing image type and the result was a generic `system-ui-failed`.
- Video live wallpapers keep an unconfirmed candidate separate from the active asset. A prepared candidate is promoted only when the plugin opens the live-wallpaper preview, so a candidate that is never previewed no longer replaces the active video. Once the system preview is open, Android owns the outcome; the plugin cannot detect that the user cancelled.
- The video scale mode is persisted with the active asset instead of being held in a process-global field, so `fitCenter` survives process death and cannot be applied to a different video.
- Static wallpapers and rotation now draw onto the display size instead of the launcher's desired size. That size is a wide virtual canvas (for example 4800x2400 on a 1080x2400 phone), and Android shows its left edge, so `fitCenter` and `center` produced an all-black screen and the other modes showed only a zoomed-in left strip of the image.
- Charging rotation now applies at most once per configured interval while the device is charging instead of once per plug-in event. Overnight active-hour windows (for example `22` to `6`) are supported, equal start/end hours mean a full-day window, and alarm scheduling no longer drifts by the window length.
- Starting a rotation no longer applies twice. WorkManager ran the new periodic request at once, right after start had applied the first wallpaper, so the playlist skipped ahead. The first scheduled run now waits one interval.
- A rejected rotation start (for example every source failing to load) no longer deletes the cache of the rotation that is still running. Before, that rotation kept reporting "running" but every later rotation failed.
- `WallpaperRotationStatus.totalCount` now counts the requested sources and `cachedCount` the ones that loaded, so a source that failed to load is visible instead of both numbers matching.
- `startWallpaperRotation`, `stopWallpaperRotation`, `rotateWallpaperNow`, and `getWallpaperRotationStatus` now return an `unsupported` result / a not-running status off Android instead of falling through to a platform call.
- `getWallpaperRotationStatus()` no longer throws when the platform call fails; it returns a not-running status with `lastError` set instead.
- Results decided in Dart (unsupported platform, invalid input, transport exception) now fill `home`/`lock` for each requested target, the same way Android does, instead of leaving them null.
- An unsupported video scale mode (`center`, `fill`, `stretch`) now returns `unsupported` with `video-scale-unsupported`, as documented and as Android reports it. The Dart pre-check returned `failed` with `invalid-input`.
- OpenGL live wallpaper: an unexpected I/O error while reading a texture source during configuration is now reported as `texture-source-unavailable` instead of `configuration-store-failed`, matching what the renderer reports for the same failure.
- Video and OpenGL live wallpapers now reload when the user sets the plugin's wallpaper again over itself. Android keeps the running engine for the same component and only sends it a reapply command, which the engines ignored, so the home screen kept the previous video or shader until the process restarted. On Android 10 and older the running engine picks up the new content only when its surface is recreated.
- Internal: removed unused legacy platform-channel endpoints and dead pre-Android 7 code paths.
- Example (Android 12+): the example keeps one `FlutterEngine` for the process. A new wallpaper changes the dynamic colors, Android relaunches the Activity, and the default `FlutterActivity` destroyed its engine, so the example restarted and never showed the `applyWallpaper` result. The Android compatibility guide now explains this relaunch and how a host app can keep its result.
- Example: the example exposes every public API (download, chooser, legacy set, Material You, platform version, rotation) and its default inputs work out of the box.
- Docs: the README is shorter and shows current screenshots. Migration notes moved to [doc/migration.md](doc/migration.md).

## 3.2.0

- Add structured Android static-wallpaper requests with URL, file-path, content-URI, and byte sources.
- Add explicit image scale modes and direct/system-cropper/system-picker/automatic apply strategies.
- Add truthful `WallpaperOperationResult` and per-target home/lock outcomes instead of treating a UI launch as an applied wallpaper.
- Add `getCapabilities()` for static, live, OpenGL, target, picker, foreground, OEM, and GLES availability checks.
- Add typed video preparation and live-preview APIs; preparation and Android user confirmation are now distinct statuses.
- Add bounded OpenGL ES 2.0 live-wallpaper support with shader validation and typed OpenGL requests.
- Serialize native wallpaper operations, preserve partial both-target results, and make direct static application safe for headless/background execution.
- Retain `goToHome` request fields for source compatibility while removing package-side automatic navigation.
- Make the live-wallpaper manifest feature optional, remove broad media/storage permissions, and expose overrideable live-wallpaper branding resources.
- Keep 3.1 APIs source-compatible; mark the legacy live-wallpaper shortcut deprecated in favor of structured results.
- Refresh the example, migration/API docs, Android compatibility notes, and the 3.2 issue-resolution ledger.
- OpenGL/video live-wallpaper flows are syntax- and state-machine-tested; GPU compile/link and OEM preview target selection still require physical device verification (see doc/android-compatibility.md).

## 3.1.0

- Add Android wallpaper rotation APIs: start, stop, status, and rotate now.
- Add mixed rotation playlist support for URL and file sources with local caching.
- Add rotation order modes: sequential and shuffle.
- Add rotation triggers for interval, charging connected, and time-of-day windows.
- Enforce minimum rotation interval of 15 minutes.
- Add active hours configuration for time-of-day trigger.
- Add basic iOS support with download-only capability (save wallpaper to Photos).
- Add cross-platform `downloadWallpaper(...)` API (iOS + Android).
- Add iOS plugin implementation using Swift + Pigeon host bindings.
- Existing apply/live/chooser operations now return typed `unsupported` on iOS.
- Add iOS example runner and Photos permission usage description for demo app.
- Update example app and docs with rotation controls.

## 3.0.0

- Upgrade baseline to Flutter 3.41.4 via FVM.
- Migrate Android host implementation from Java to Kotlin.
- Upgrade Android build stack to AGP 8.11.1, Gradle 8.14, Kotlin plugin 2.2.20, Java 17.
- Raise Android minimum SDK to 24.
- Regenerate platform channel bindings using Pigeon Kotlin host output.
- Breaking API redesign:
  - Replace integer location constants with enums.
  - Replace bool-focused APIs with typed request/result models.
  - Remove package-owned toast behavior and `fluttertoast` dependency.
- Refresh example app to use the v3 typed API.

## 2.1.0

- Fix Android 14 crash in apply methods
- Add method to open native wallpaper chooser
- Update to Flutter v3.22.1
- Update dependencies

## 2.0.3

- Fix native external apply methods not working
- Update dependencies

## 2.0.2

- Add fluttertoast package to show success/failure toasts
- Add timeout of 2 seconds in goToHome method to prevent it looking like a crash

## 2.0.1

- Add support for Flutter 3.3.3
- Update dependencies

## 2.0.0

- Add support for Android 13
- Add a new bool parameter `goToHome` to all methods
- Breaking change - All methods now return a bool instead of String, to make error handling easier
- Breaking change - All methods now accept named parameters instead of positional parameters
- Fixed documentation

## 1.0.1

- Add support for Android 12
- Fixed documentation

## 1.0.0+1

- Fixed documentation
- Add example gif, and screenshot

## 1.0.0

- Initial release
- Supports setting wallpaper from file/url
- Supports video live wallpapers (.mp4)
