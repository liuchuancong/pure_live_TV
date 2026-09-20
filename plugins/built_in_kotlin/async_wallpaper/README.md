# async_wallpaper

[![pub package](https://img.shields.io/pub/v/async_wallpaper.svg)](https://pub.dev/packages/async_wallpaper)

Flutter plugin to set wallpapers on Android and save them to Photos on iOS.

- Static wallpaper from a URL, file path, content URI, or bytes
- Home, lock, or both targets, with a separate result for each
- Video and OpenGL live wallpapers
- Scheduled wallpaper rotation
- Capability checks before you show an action

## Screenshots

| Static wallpaper | Capabilities | More APIs | iOS |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/codenameakshay/async_wallpaper/728b374826493dfccb4f7cba1357e38e47b522b2/screenshots/android-static.png" width="200"> | <img src="https://raw.githubusercontent.com/codenameakshay/async_wallpaper/728b374826493dfccb4f7cba1357e38e47b522b2/screenshots/android-capabilities.png" width="200"> | <img src="https://raw.githubusercontent.com/codenameakshay/async_wallpaper/728b374826493dfccb4f7cba1357e38e47b522b2/screenshots/android-more-apis.png" width="200"> | <img src="https://raw.githubusercontent.com/codenameakshay/async_wallpaper/728b374826493dfccb4f7cba1357e38e47b522b2/screenshots/ios-download.png" width="200"> |

**Video live wallpaper:** home screen before, the system preview, and the applied video.

<img src="https://raw.githubusercontent.com/codenameakshay/async_wallpaper/728b374826493dfccb4f7cba1357e38e47b522b2/screenshots/video-live-wallpaper.png" width="600">

**Scale modes:** `centerCrop`, `fitCenter`, `center`, `fill`, and `stretch` on a 1080x2400 phone.

<img src="https://raw.githubusercontent.com/codenameakshay/async_wallpaper/728b374826493dfccb4f7cba1357e38e47b522b2/screenshots/scale-modes.png" width="600">

## Requirements

- Flutter `>=3.41.4`, Dart `>=3.9.0`
- Android `minSdk 24`
- iOS `13.0+` (download only)

## Installation

```yaml
dependencies:
  async_wallpaper: ^3.3.0
```

```dart
import 'package:async_wallpaper/async_wallpaper.dart';
```

## Usage

### Check capabilities

```dart
final c = await AsyncWallpaper.getCapabilities();
if (c.supportsStaticWallpaper && c.canSetWallpaper) {
  // Show the action.
}
```

### Static wallpaper

```dart
final result = await AsyncWallpaper.applyWallpaper(
  const StaticWallpaperRequest(
    source: WallpaperSource.url('https://example.com/wallpaper.jpg'),
    target: WallpaperTarget.both,
    scaleMode: WallpaperScaleMode.centerCrop,
    strategy: WallpaperApplyStrategy.direct,
  ),
);
if (result.status == WallpaperOperationStatus.applied) {
  // For `both`, read `result.home` and `result.lock`.
}
```

Sources: `WallpaperSource.url` (HTTPS), `filePath`, `contentUri`, `bytes`.

### Video live wallpaper

```dart
final req = VideoWallpaperRequest(
  source: WallpaperSource.filePath('/storage/emulated/0/Download/loop.mp4'),
  target: WallpaperTarget.home,
);
final prepared = await AsyncWallpaper.setVideoWallpaper(req);
if (prepared.status == WallpaperOperationStatus.awaitingUserConfirmation) {
  await AsyncWallpaper.openLiveWallpaperPreview(req);
}
```

`previewOpened` means the system preview opened, not that the user applied it.

### OpenGL live wallpaper

Check `supportsOpenGlLiveWallpaper` first, then call `setOpenGlLiveWallpaper` with a GLSL ES 1.00 fragment shader (1-60 FPS).

### Wallpaper rotation

```dart
await AsyncWallpaper.startWallpaperRotation(
  const WallpaperRotationRequest(
    sources: <WallpaperRotationSource>[
      WallpaperRotationSource(sourceType: WallpaperSourceType.url, source: 'https://example.com/1.jpg'),
      WallpaperRotationSource(sourceType: WallpaperSourceType.file, source: '/storage/emulated/0/Download/2.jpg'),
    ],
    target: WallpaperTarget.both,
    intervalMinutes: 60,
    order: WallpaperRotationOrder.shuffle,
    triggers: <WallpaperRotationTrigger>{
      WallpaperRotationTrigger.interval,
      WallpaperRotationTrigger.charging,
      WallpaperRotationTrigger.timeOfDay,
    },
    activeHoursStart: 6,
    activeHoursEnd: 23,
  ),
);
await AsyncWallpaper.getWallpaperRotationStatus();
await AsyncWallpaper.rotateWallpaperNow();
await AsyncWallpaper.stopWallpaperRotation();
```

The minimum interval is 15 minutes. URLs must be HTTPS. Rotation uses `WorkManager` and needs no foreground service.

### Download

```dart
await AsyncWallpaper.downloadWallpaper(
  const DownloadWallpaperRequest(url: 'https://example.com/wallpaper.jpg'),
);
```

- iOS: add `NSPhotoLibraryAddUsageDescription` to `Info.plist`.
- Android 9 and older: declare `WRITE_EXTERNAL_STORAGE` with `android:maxSdkVersion="28"` and request it before you call `downloadWallpaper`.

## Platform support

| | Android | iOS | Web/desktop |
|---|---|---|---|
| Static, live, OpenGL, rotation | Yes | `unsupported` | `unsupported` |
| Download | Yes | Yes | `unsupported` |

- Background work (for example `WorkManager`): use `WallpaperApplyStrategy.direct`. The cropper, picker, and live previews need a foreground Activity and return `foregroundRequired` otherwise.
- The plugin shows no toasts and does not navigate. Your app shows its own UI from the result.

## Docs

- [Example app](example/README.md)
- [Android compatibility](doc/android-compatibility.md)
- [Migration guide](doc/migration.md)
- [Changelog](CHANGELOG.md)

## Contributing

Report bugs with the [bug report template](https://github.com/codenameakshay/async_wallpaper/issues/new?template=bug_report.md) and include the device model, Android version, and steps to reproduce. Request features with the [feature request template](https://github.com/codenameakshay/async_wallpaper/issues/new?template=feature_request.md). Read [CONTRIBUTING.md](CONTRIBUTING.md) before you open a PR.

## License

MIT
