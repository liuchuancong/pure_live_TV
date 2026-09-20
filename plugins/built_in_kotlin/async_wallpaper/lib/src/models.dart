import 'dart:typed_data';

/// Target location where a static wallpaper should be applied.
enum WallpaperTarget { home, lock, both }

/// Input type for legacy static wallpaper operations.
enum WallpaperSourceType { url, file }

/// Error category surfaced by the legacy package API.
enum WallpaperErrorCode { invalidInput, platformFailure, unsupported, unknown }

/// Input kind for a wallpaper asset.
///
/// Byte sources defensively copy their input and return a new copy on access.
/// This keeps an operation request stable if a caller later mutates its buffer.
/// For large images prefer filePath/contentUri; bytes is intended for small,
/// thumbnail, or ephemeral in-memory assets (bounded by 32 MiB direct / 8 MiB
/// per OpenGL texture). Each access copies the buffer, so holding large bytes
/// in memory can increase GC/OOM risk on low-RAM devices.
class WallpaperSource {
  /// Creates a network URL source.
  const WallpaperSource.url(String value)
    : url = value,
      filePath = null,
      contentUri = null,
      _bytes = null;

  /// Creates a local file-path source.
  const WallpaperSource.filePath(String value)
    : url = null,
      filePath = value,
      contentUri = null,
      _bytes = null;

  /// Creates an Android content URI source.
  const WallpaperSource.contentUri(String value)
    : url = null,
      filePath = null,
      contentUri = value,
      _bytes = null;

  /// Creates an in-memory byte source.
  WallpaperSource.bytes(Uint8List value)
    : url = null,
      filePath = null,
      contentUri = null,
      _bytes = Uint8List.fromList(value);

  /// The URL value when this is a URL source.
  final String? url;

  /// The path value when this is a file source.
  final String? filePath;

  /// The URI value when this is a content URI source.
  final String? contentUri;

  final Uint8List? _bytes;

  /// A defensive copy of the byte value when this is a byte source.
  Uint8List? get bytes {
    final value = _bytes;
    return value == null ? null : Uint8List.fromList(value);
  }
}

/// How a static wallpaper image should fill a display.
enum WallpaperScaleMode { centerCrop, fitCenter, center, fill, stretch }

/// How Android should attempt to apply a wallpaper.
enum WallpaperApplyStrategy { direct, systemCropper, systemPicker, automatic }

/// Outcome for an entire wallpaper operation.
enum WallpaperOperationStatus {
  applied,
  previewOpened,
  awaitingUserConfirmation,
  cancelled,
  failed,
  unsupported,
  foregroundRequired,
}

/// Outcome for an individual wallpaper target.
enum WallpaperTargetStatus { applied, failed, unsupported, notAttempted }

/// Typed input for legacy static wallpaper operations.
class WallpaperRequest {
  const WallpaperRequest({
    required this.target,
    required this.sourceType,
    required this.source,
    this.goToHome = false,
  });

  final WallpaperTarget target;
  final WallpaperSourceType sourceType;
  final String source;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool goToHome;
}

/// Typed request for the structured static wallpaper API.
class StaticWallpaperRequest {
  const StaticWallpaperRequest({
    required this.source,
    required this.target,
    this.scaleMode = WallpaperScaleMode.centerCrop,
    this.strategy = WallpaperApplyStrategy.automatic,
    this.goToHome = false,
  });

  final WallpaperSource source;
  final WallpaperTarget target;
  final WallpaperScaleMode scaleMode;
  final WallpaperApplyStrategy strategy;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool goToHome;
}

/// Typed input for Material You wallpaper operations.
class MaterialYouWallpaperRequest {
  const MaterialYouWallpaperRequest({
    required this.url,
    this.goToHome = false,
    this.enableEffects = false,
  });

  final String url;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool goToHome;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool enableEffects;
}

/// Typed input for legacy live wallpaper operations.
class LiveWallpaperRequest {
  const LiveWallpaperRequest({required this.filePath, this.goToHome = false});

  final String filePath;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool goToHome;
}

/// Typed input for download-only operations.
class DownloadWallpaperRequest {
  const DownloadWallpaperRequest({required this.url});

  final String url;
}

/// Error returned by legacy package operations.
class WallpaperError {
  const WallpaperError({
    required this.code,
    required this.message,
    this.details,
  });

  final WallpaperErrorCode code;
  final String message;
  final Object? details;
}

/// Typed legacy operation result.
class WallpaperResult {
  const WallpaperResult._({required this.isSuccess, this.error});

  const WallpaperResult.success() : this._(isSuccess: true);

  const WallpaperResult.failure(WallpaperError error)
    : this._(isSuccess: false, error: error);

  final bool isSuccess;
  final WallpaperError? error;
}

/// Structured Material You support information.
class MaterialYouSupport {
  const MaterialYouSupport({
    required this.isSupported,
    required this.androidVersion,
    required this.sdkInt,
  });

  final bool isSupported;
  final String androidVersion;
  final int sdkInt;
}

/// Result details for one requested display target.
class WallpaperTargetResult {
  const WallpaperTargetResult({
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.errorDetails,
  });

  final WallpaperTargetStatus status;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDetails;
}

/// Result details for a wallpaper operation, including per-target outcomes.
class WallpaperOperationResult {
  const WallpaperOperationResult({
    required this.status,
    required this.requestedTarget,
    this.home,
    this.lock,
    this.errorCode,
    this.errorMessage,
    this.errorDetails,
    this.fallbackUsed = false,
    this.fallbackStrategy,
  });

  final WallpaperOperationStatus status;
  final WallpaperTarget requestedTarget;
  final WallpaperTargetResult? home;
  final WallpaperTargetResult? lock;
  final String? errorCode;
  final String? errorMessage;
  final String? errorDetails;
  final bool fallbackUsed;
  final WallpaperApplyStrategy? fallbackStrategy;
}

/// Capability snapshot reported by the platform implementation.
class WallpaperCapabilities {
  const WallpaperCapabilities({
    this.supportsStaticWallpaper = false,
    this.supportsLiveWallpaper = false,
    this.supportsOpenGlLiveWallpaper = false,
    this.supportsHomeWallpaper = false,
    this.supportsLockWallpaper = false,
    this.supportsBothWallpapers = false,
    this.canSetWallpaper = false,
    this.hasSystemWallpaperPicker = false,
    this.requiresForeground = false,
    this.manufacturer = 'Unknown',
    this.sdkInt = 0,
    this.openGlVersion,
    this.openGlRenderer,
  });

  final bool supportsStaticWallpaper;
  final bool supportsLiveWallpaper;
  final bool supportsOpenGlLiveWallpaper;
  final bool supportsHomeWallpaper;
  final bool supportsLockWallpaper;
  final bool supportsBothWallpapers;
  final bool canSetWallpaper;
  final bool hasSystemWallpaperPicker;
  final bool requiresForeground;
  final String manufacturer;
  final int sdkInt;
  final String? openGlVersion;
  final String? openGlRenderer;
}

/// Typed request for a video live wallpaper.
class VideoWallpaperRequest {
  const VideoWallpaperRequest({
    required this.source,
    this.target = WallpaperTarget.home,
    this.scaleMode = WallpaperScaleMode.centerCrop,
    this.goToHome = false,
  });

  final WallpaperSource source;
  final WallpaperTarget target;
  final WallpaperScaleMode scaleMode;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool goToHome;
}

/// Typed request for a shader-based OpenGL live wallpaper.
class OpenGlLiveWallpaperRequest {
  OpenGlLiveWallpaperRequest({
    required this.fragmentShader,
    List<WallpaperSource> textures = const <WallpaperSource>[],
    this.target = WallpaperTarget.home,
    this.frameRate = 60,
    this.goToHome = false,
  }) : _textures = List<WallpaperSource>.unmodifiable(textures);

  final String fragmentShader;
  final List<WallpaperSource> _textures;
  final WallpaperTarget target;
  final int frameRate;

  /// Retained only for source compatibility since 3.2.0; ignored by the engine.
  final bool goToHome;

  /// Immutable texture sources in the order exposed to the shader.
  List<WallpaperSource> get textures => _textures;
}

/// Rotation ordering strategy.
enum WallpaperRotationOrder { sequential, shuffle }

/// Triggers that can drive rotation.
enum WallpaperRotationTrigger { interval, charging, timeOfDay }

/// Single source entry in a rotation playlist.
class WallpaperRotationSource {
  const WallpaperRotationSource({
    required this.sourceType,
    required this.source,
  });

  final WallpaperSourceType sourceType;
  final String source;
}

/// Typed input for wallpaper rotation operations.
class WallpaperRotationRequest {
  const WallpaperRotationRequest({
    required this.sources,
    required this.target,
    required this.intervalMinutes,
    this.order = WallpaperRotationOrder.sequential,
    this.triggers = const <WallpaperRotationTrigger>{
      WallpaperRotationTrigger.interval,
    },
    this.activeHoursStart = 6,
    this.activeHoursEnd = 23,
  });

  final List<WallpaperRotationSource> sources;
  final WallpaperTarget target;
  final int intervalMinutes;
  final WallpaperRotationOrder order;
  final Set<WallpaperRotationTrigger> triggers;
  final int activeHoursStart;
  final int activeHoursEnd;
}

/// Current status of wallpaper rotation.
class WallpaperRotationStatus {
  const WallpaperRotationStatus({
    required this.isRunning,
    required this.nextRunEpochMs,
    required this.currentIndex,
    required this.cachedCount,
    required this.totalCount,
    required this.effectiveIntervalMinutes,
    this.lastError,
  });

  final bool isRunning;
  final int nextRunEpochMs;
  final int currentIndex;
  final int cachedCount;
  final int totalCount;
  final int effectiveIntervalMinutes;
  final String? lastError;
}
