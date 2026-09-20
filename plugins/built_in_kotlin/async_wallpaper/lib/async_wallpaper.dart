import 'dart:convert';

import 'package:async_wallpaper/pigeon_impl_api.dart';
import 'package:flutter/foundation.dart';

import 'src/models.dart';
import 'src/wallpaper_client.dart';

export 'src/models.dart';

/// Public facade for Android wallpaper operations.
class AsyncWallpaper {
  AsyncWallpaper._();

  // Mirror the Android-side limits so both sides change together: see
  // WallpaperSourceLoader.DEFAULT_MAX_ENCODED_BYTES and
  // ShaderProgramValidator.MAX_FRAGMENT_SHADER_BYTES /
  // MAX_TEXTURE_COUNT / MAX_TEXTURE_SOURCE_BYTES.
  static const int _maxSourceBytes = 32 * 1024 * 1024;
  static const int _maxVideoSourceBytes = 256 * 1024 * 1024;
  static const int _maxOpenGlTextureBytes = 8 * 1024 * 1024;
  static const int _maxOpenGlTextures = 4;
  static const int _maxFragmentShaderBytes = 64 * 1024;

  static const int _minRotationIntervalMinutes = 15;
  static const int _maxRotationSources = 100;

  static final WallpaperApi _api = WallpaperApi();
  static final WallpaperClient _defaultClient = PigeonWallpaperClient(
    api: _api,
  );
  static WallpaperClient _client = _defaultClient;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static const WallpaperResult _unsupportedResult = WallpaperResult.failure(
    WallpaperError(
      code: WallpaperErrorCode.unsupported,
      message: 'This operation is not supported on this platform.',
    ),
  );

  static const WallpaperCapabilities _unsupportedCapabilities =
      WallpaperCapabilities(manufacturer: 'Unsupported on this platform');

  static WallpaperRotationStatus _notRunningRotationStatus({
    String? lastError,
  }) => WallpaperRotationStatus(
    isRunning: false,
    nextRunEpochMs: 0,
    currentIndex: 0,
    cachedCount: 0,
    totalCount: 0,
    effectiveIntervalMinutes: 0,
    lastError: lastError,
  );

  /// The host platform version.
  ///
  /// This retains the legacy channel behavior and can throw a platform error.
  static Future<String> get platformVersion => _api.getPlatformVersion();

  /// Overrides the platform client for tests.
  @visibleForTesting
  static void debugSetClient(WallpaperClient client) {
    _client = client;
  }

  /// Restores the default platform client after a test override.
  @visibleForTesting
  static void debugResetClient() {
    _client = _defaultClient;
  }

  /// Returns Material You availability on Android.
  static Future<MaterialYouSupport> checkMaterialYouSupport() async {
    if (!_isAndroid) {
      return const MaterialYouSupport(
        isSupported: false,
        androidVersion: 'Unsupported on this platform',
        sdkInt: 0,
      );
    }

    try {
      final data = await _api.checkMaterialYouSupport();
      return MaterialYouSupport(
        isSupported: data.isSupported == true,
        androidVersion: data.androidVersion ?? 'Unknown',
        sdkInt: data.sdkInt ?? 0,
      );
    } catch (_) {
      return const MaterialYouSupport(
        isSupported: false,
        androidVersion: 'Unknown',
        sdkInt: 0,
      );
    }
  }

  /// Returns the host's current wallpaper capabilities.
  ///
  /// Unsupported platforms and unavailable transports return a conservative
  /// all-false snapshot instead of surfacing a channel exception.
  static Future<WallpaperCapabilities> getCapabilities() async {
    if (!_isAndroid) {
      return _unsupportedCapabilities;
    }

    try {
      return await _client.getCapabilities();
    } catch (_) {
      return _unsupportedCapabilities;
    }
  }

  /// Applies a static wallpaper and reports the per-target outcome Android
  /// confirmed.
  static Future<WallpaperOperationResult> applyWallpaper(
    StaticWallpaperRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedOperation(request.target);
    }

    final validationError = _validateSource(request.source, label: 'Wallpaper');
    if (validationError != null) {
      return _invalidOperation(request.target, validationError);
    }

    return _runOperation(
      target: request.target,
      operation: 'applying wallpaper',
      call: () => _client.applyWallpaper(request),
    );
  }

  /// Prepares a video live wallpaper without claiming that it has been set.
  ///
  /// A successful result normally has [WallpaperOperationStatus
  /// .awaitingUserConfirmation]; call [openLiveWallpaperPreview] to open the
  /// Android confirmation UI.
  static Future<WallpaperOperationResult> setVideoWallpaper(
    VideoWallpaperRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedOperation(request.target);
    }

    final unsupportedScale = _unsupportedVideoScale(request);
    if (unsupportedScale != null) {
      return unsupportedScale;
    }
    final validationError = _validateVideoWallpaperRequest(request);
    if (validationError != null) {
      return _invalidOperation(request.target, validationError);
    }

    return _runOperation(
      target: request.target,
      operation: 'preparing video wallpaper',
      call: () => _client.prepareVideoWallpaper(request),
    );
  }

  /// Opens Android's live-wallpaper preview flow for a video request.
  static Future<WallpaperOperationResult> openLiveWallpaperPreview(
    VideoWallpaperRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedOperation(request.target);
    }

    final unsupportedScale = _unsupportedVideoScale(request);
    if (unsupportedScale != null) {
      return unsupportedScale;
    }
    final validationError = _validateVideoWallpaperRequest(request);
    if (validationError != null) {
      return _invalidOperation(request.target, validationError);
    }

    return _runOperation(
      target: request.target,
      operation: 'opening live wallpaper preview',
      call: () => _client.openLiveWallpaperPreview(request),
    );
  }

  /// Applies a shader-based OpenGL live wallpaper.
  static Future<WallpaperOperationResult> setOpenGlLiveWallpaper(
    OpenGlLiveWallpaperRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedOperation(request.target);
    }

    final validationError = _validateOpenGlWallpaperRequest(request);
    if (validationError != null) {
      return _invalidOperation(request.target, validationError);
    }

    return _runOperation(
      target: request.target,
      operation: 'setting OpenGL live wallpaper',
      call: () => _client.applyOpenGlWallpaper(request),
    );
  }

  /// Applies a legacy static wallpaper request through [applyWallpaper].
  static Future<WallpaperResult> setWallpaper(WallpaperRequest request) async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }

    final structuredRequest = _legacyStaticWallpaperRequest(request);
    final validationError = _validateSource(
      structuredRequest.source,
      label: 'Wallpaper',
    );
    if (validationError != null) {
      return _legacyInvalidInput(validationError);
    }

    final operation = await _runOperation(
      target: request.target,
      operation: 'setting wallpaper',
      call: () => _client.applyWallpaper(structuredRequest),
    );
    return _legacyResultFromOperation(
      operation,
      fallbackMessage: 'Failed to set wallpaper on Android.',
    );
  }

  /// Sets a Material You wallpaper through the legacy Android endpoint.
  static Future<WallpaperResult> setMaterialYouWallpaper(
    MaterialYouWallpaperRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }
    if (!_isHttpsUrl(request.url)) {
      return _legacyInvalidInput(
        'Material You wallpaper URL must be a valid HTTPS URL.',
      );
    }

    return _runLegacyBooleanOperation(
      call: () => _api.setMaterialYouWallpaper(request.url),
      failureMessage: 'Failed to set Material You wallpaper.',
      exceptionMessage:
          'Unexpected exception while setting Material You wallpaper.',
    );
  }

  /// Opens the video live-wallpaper UI for a legacy file-path request.
  ///
  /// The old boolean result meant that Android accepted opening its UI, not
  /// that the user had confirmed a wallpaper. New callers should use
  /// [setVideoWallpaper] and [openLiveWallpaperPreview] to keep those states
  /// distinct.
  @Deprecated(
    'Use setVideoWallpaper and openLiveWallpaperPreview for per-target results.',
  )
  static Future<WallpaperResult> setLiveWallpaper(
    LiveWallpaperRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }

    final structuredRequest = VideoWallpaperRequest(
      source: WallpaperSource.filePath(request.filePath),
      goToHome: request.goToHome,
    );
    final validationError = _validateSource(
      structuredRequest.source,
      label: 'Video wallpaper',
    );
    if (validationError != null) {
      return _legacyInvalidInput(validationError);
    }

    final operation = await _runOperation(
      target: structuredRequest.target,
      operation: 'opening live wallpaper preview',
      call: () => _client.openLiveWallpaperPreview(structuredRequest),
    );
    return _legacyResultFromOperation(
      operation,
      fallbackMessage: 'Failed to open live wallpaper preview.',
      uiOpeningOperation: true,
    );
  }

  /// Opens Android's system wallpaper chooser.
  static Future<WallpaperResult> openWallpaperChooser() async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }
    return _runLegacyBooleanOperation(
      call: _api.openWallpaperChooser,
      failureMessage: 'Failed to open wallpaper chooser.',
      exceptionMessage: 'Unexpected exception while opening wallpaper chooser.',
    );
  }

  /// Downloads a wallpaper to the device's supported media library.
  static Future<WallpaperResult> downloadWallpaper(
    DownloadWallpaperRequest request,
  ) async {
    if (!_isAndroid && !_isIOS) {
      return _unsupportedResult;
    }
    if (!_isHttpsUrl(request.url)) {
      return _legacyInvalidInput('Wallpaper URL must be a valid HTTPS URL.');
    }

    return _runLegacyBooleanOperation(
      call: () => _api.downloadWallpaper(request.url),
      failureMessage: 'Failed to download wallpaper.',
      exceptionMessage: 'Unexpected exception while downloading wallpaper.',
    );
  }

  /// Starts wallpaper rotation with the provided playlist and trigger settings.
  static Future<WallpaperResult> startWallpaperRotation(
    WallpaperRotationRequest request,
  ) async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }
    if (request.sources.isEmpty) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message: 'Rotation sources cannot be empty.',
        ),
      );
    }
    if (request.sources.length > _maxRotationSources) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message:
              'Rotation sources must not exceed $_maxRotationSources entries.',
        ),
      );
    }
    final hasInvalidSource = request.sources.any(
      (source) => source.source.trim().isEmpty,
    );
    if (hasInvalidSource) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message: 'Rotation source entries cannot be empty.',
        ),
      );
    }
    final hasInvalidUrl = request.sources.any(
      (source) =>
          source.sourceType == WallpaperSourceType.url &&
          !_isHttpsUrl(source.source),
    );
    if (hasInvalidUrl) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message: 'Rotation URL sources must be valid HTTPS URLs.',
        ),
      );
    }
    if (request.intervalMinutes < _minRotationIntervalMinutes) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message:
              'Rotation interval must be at least $_minRotationIntervalMinutes minutes.',
        ),
      );
    }
    if (request.triggers.isEmpty) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message: 'At least one rotation trigger is required.',
        ),
      );
    }
    // Overnight windows and equal start/end full-day windows are allowed.
    if (request.activeHoursStart < 0 ||
        request.activeHoursStart > 23 ||
        request.activeHoursEnd < 0 ||
        request.activeHoursEnd > 23) {
      return const WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.invalidInput,
          message: 'Rotation active hours must be between 0 and 23.',
        ),
      );
    }

    final config = WallpaperRotationConfigData(
      sources: request.sources
          .map(
            (source) => RotationSourceData(
              source: source.source,
              sourceType: rotationSourceTypeToData(source.sourceType),
            ),
          )
          .toList(),
      target: wallpaperTargetToData(request.target),
      intervalMinutes: request.intervalMinutes,
      enableIntervalTrigger: request.triggers.contains(
        WallpaperRotationTrigger.interval,
      ),
      enableChargingTrigger: request.triggers.contains(
        WallpaperRotationTrigger.charging,
      ),
      enableTimeOfDayTrigger: request.triggers.contains(
        WallpaperRotationTrigger.timeOfDay,
      ),
      activeHoursStart: request.activeHoursStart,
      activeHoursEnd: request.activeHoursEnd,
      orderType: rotationOrderToData(request.order),
    );
    return _runLegacyBooleanOperation(
      call: () => _api.startWallpaperRotation(config),
      failureMessage: 'Failed to start wallpaper rotation.',
      exceptionMessage:
          'Unexpected exception while starting wallpaper rotation.',
    );
  }

  /// Stops wallpaper rotation and cancels configured background triggers.
  static Future<WallpaperResult> stopWallpaperRotation() async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }
    return _runLegacyBooleanOperation(
      call: _api.stopWallpaperRotation,
      failureMessage: 'Failed to stop wallpaper rotation.',
      exceptionMessage:
          'Unexpected exception while stopping wallpaper rotation.',
    );
  }

  /// Returns the current wallpaper rotation status.
  ///
  /// Off Android this returns a not-running snapshot. If the platform call
  /// throws, it returns the same snapshot with
  /// [WallpaperRotationStatus.lastError] set instead of surfacing the
  /// exception.
  static Future<WallpaperRotationStatus> getWallpaperRotationStatus() async {
    if (!_isAndroid) {
      return _notRunningRotationStatus();
    }

    try {
      final data = await _api.getWallpaperRotationStatus();
      return WallpaperRotationStatus(
        isRunning: data.isRunning == true,
        nextRunEpochMs: data.nextRunEpochMs ?? 0,
        currentIndex: data.currentIndex ?? 0,
        cachedCount: data.cachedCount ?? 0,
        totalCount: data.totalCount ?? 0,
        effectiveIntervalMinutes: data.effectiveIntervalMinutes ?? 0,
        lastError: data.lastError,
      );
    } catch (_) {
      return _notRunningRotationStatus(
        lastError: 'Failed to get wallpaper rotation status.',
      );
    }
  }

  /// Immediately rotates to the next wallpaper in the current playlist.
  static Future<WallpaperResult> rotateWallpaperNow() async {
    if (!_isAndroid) {
      return _unsupportedResult;
    }
    return _runLegacyBooleanOperation(
      call: _api.rotateWallpaperNow,
      failureMessage: 'Failed to rotate wallpaper now.',
      exceptionMessage: 'Unexpected exception while rotating wallpaper now.',
    );
  }

  static Future<WallpaperOperationResult> _runOperation({
    required WallpaperTarget target,
    required String operation,
    required Future<WallpaperOperationResult> Function() call,
  }) async {
    try {
      return await call();
    } catch (error) {
      return _localResult(
        target,
        status: WallpaperOperationStatus.failed,
        targetStatus: WallpaperTargetStatus.failed,
        errorCode: 'unknown',
        errorMessage: 'Unexpected exception while $operation.',
        errorDetails: error.toString(),
      );
    }
  }

  /// Runs a legacy boolean host call, mapping its outcome to [WallpaperResult].
  static Future<WallpaperResult> _runLegacyBooleanOperation({
    required Future<bool> Function() call,
    required String failureMessage,
    required String exceptionMessage,
  }) async {
    try {
      final success = await call();
      return success
          ? const WallpaperResult.success()
          : WallpaperResult.failure(
              WallpaperError(
                code: WallpaperErrorCode.platformFailure,
                message: failureMessage,
              ),
            );
    } catch (error) {
      return WallpaperResult.failure(
        WallpaperError(
          code: WallpaperErrorCode.unknown,
          message: exceptionMessage,
          details: error,
        ),
      );
    }
  }

  static WallpaperOperationResult _unsupportedOperation(
    WallpaperTarget target,
  ) {
    return _localResult(
      target,
      status: WallpaperOperationStatus.unsupported,
      targetStatus: WallpaperTargetStatus.unsupported,
      errorCode: 'unsupported',
      errorMessage: 'This operation is not supported on this platform.',
    );
  }

  static WallpaperOperationResult _invalidOperation(
    WallpaperTarget target,
    String message,
  ) {
    return _localResult(
      target,
      status: WallpaperOperationStatus.failed,
      targetStatus: WallpaperTargetStatus.failed,
      errorCode: 'invalid-input',
      errorMessage: message,
    );
  }

  /// Builds a result decided in Dart with the same per-target shape Android
  /// reports: every requested target carries the outcome.
  static WallpaperOperationResult _localResult(
    WallpaperTarget target, {
    required WallpaperOperationStatus status,
    required WallpaperTargetStatus targetStatus,
    required String errorCode,
    required String errorMessage,
    String? errorDetails,
  }) {
    final targetResult = WallpaperTargetResult(
      status: targetStatus,
      errorCode: errorCode,
      errorMessage: errorMessage,
      errorDetails: errorDetails,
    );
    return WallpaperOperationResult(
      status: status,
      requestedTarget: target,
      home: target == WallpaperTarget.lock ? null : targetResult,
      lock: target == WallpaperTarget.home ? null : targetResult,
      errorCode: errorCode,
      errorMessage: errorMessage,
      errorDetails: errorDetails,
    );
  }

  static WallpaperResult _legacyInvalidInput(String message) {
    return WallpaperResult.failure(
      WallpaperError(code: WallpaperErrorCode.invalidInput, message: message),
    );
  }

  static StaticWallpaperRequest _legacyStaticWallpaperRequest(
    WallpaperRequest request,
  ) {
    final source = switch (request.sourceType) {
      WallpaperSourceType.url => WallpaperSource.url(request.source),
      WallpaperSourceType.file => WallpaperSource.filePath(request.source),
    };
    return StaticWallpaperRequest(
      source: source,
      target: request.target,
      goToHome: request.goToHome,
    );
  }

  static String? _validateOpenGlWallpaperRequest(
    OpenGlLiveWallpaperRequest request,
  ) {
    if (request.fragmentShader.trim().isEmpty) {
      return 'Fragment shader cannot be empty.';
    }
    if (utf8.encode(request.fragmentShader).length > _maxFragmentShaderBytes) {
      return 'Fragment shader must not exceed $_maxFragmentShaderBytes UTF-8 bytes.';
    }
    if (request.frameRate < 1 || request.frameRate > 60) {
      return 'Frame rate must be between 1 and 60.';
    }
    if (request.textures.length > _maxOpenGlTextures) {
      return 'At most $_maxOpenGlTextures textures may be supplied.';
    }

    for (var index = 0; index < request.textures.length; index++) {
      final validationError = _validateSource(
        request.textures[index],
        label: 'Texture $index',
        maxBytes: _maxOpenGlTextureBytes,
      );
      if (validationError != null) {
        return validationError;
      }
    }
    return null;
  }

  /// Mirrors Android's `video-scale-unsupported` result without a platform call.
  static WallpaperOperationResult? _unsupportedVideoScale(
    VideoWallpaperRequest request,
  ) {
    if (request.scaleMode == WallpaperScaleMode.centerCrop ||
        request.scaleMode == WallpaperScaleMode.fitCenter) {
      return null;
    }
    return _localResult(
      request.target,
      status: WallpaperOperationStatus.unsupported,
      targetStatus: WallpaperTargetStatus.unsupported,
      errorCode: 'video-scale-unsupported',
      errorMessage:
          'Video live wallpapers support only centerCrop and fitCenter scaling.',
    );
  }

  static String? _validateVideoWallpaperRequest(VideoWallpaperRequest request) {
    return _validateSource(
      request.source,
      label: 'Video wallpaper',
      maxBytes: _maxVideoSourceBytes,
    );
  }

  static String? _validateSource(
    WallpaperSource source, {
    required String label,
    int maxBytes = _maxSourceBytes,
  }) {
    final url = source.url;
    final filePath = source.filePath;
    final contentUri = source.contentUri;
    final bytes = source.bytes;
    final valueCount = [url, filePath, contentUri, bytes].nonNulls.length;
    if (valueCount != 1) {
      return '$label source must contain exactly one value.';
    }

    if (url != null) {
      return _isHttpsUrl(url) ? null : '$label URL must be a valid HTTPS URL.';
    }
    if (filePath != null) {
      return filePath.trim().isNotEmpty
          ? null
          : '$label file path cannot be empty.';
    }
    if (contentUri != null) {
      return _isContentUri(contentUri)
          ? null
          : '$label content URI must be a valid content:// URI.';
    }
    if (bytes == null || bytes.isEmpty) {
      return '$label bytes cannot be empty.';
    }
    if (bytes.length > maxBytes) {
      return '$label bytes must not exceed $maxBytes bytes.';
    }
    return null;
  }

  static bool _isHttpsUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed != value) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.isAbsolute &&
        uri.scheme.toLowerCase() == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  static bool _isContentUri(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed != value) {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme.toLowerCase() == 'content' &&
        uri.host.isNotEmpty;
  }

  static WallpaperResult _legacyResultFromOperation(
    WallpaperOperationResult operation, {
    required String fallbackMessage,
    bool uiOpeningOperation = false,
  }) {
    if (_isLegacySuccess(operation, uiOpeningOperation: uiOpeningOperation)) {
      return const WallpaperResult.success();
    }

    return WallpaperResult.failure(
      WallpaperError(
        code: _legacyErrorCodeFor(operation),
        message: operation.errorMessage ?? fallbackMessage,
        details: operation.errorDetails ?? operation.errorCode,
      ),
    );
  }

  /// Maps a native error code to a legacy [WallpaperErrorCode]: `unsupported`
  /// and `not-implemented` become [WallpaperErrorCode.unsupported]; any
  /// `invalid-*` code becomes [WallpaperErrorCode.invalidInput]; anything
  /// else defaults to [WallpaperErrorCode.platformFailure].
  static WallpaperErrorCode _legacyErrorCodeFor(
    WallpaperOperationResult operation,
  ) {
    final errorCode = operation.errorCode?.toLowerCase();
    if (operation.status == WallpaperOperationStatus.unsupported ||
        errorCode == 'unsupported' ||
        errorCode == 'not-implemented') {
      return WallpaperErrorCode.unsupported;
    }
    if (errorCode == 'unknown') {
      return WallpaperErrorCode.unknown;
    }
    if (errorCode?.startsWith('invalid-') == true) {
      return WallpaperErrorCode.invalidInput;
    }
    return WallpaperErrorCode.platformFailure;
  }

  /// Only `applied` (with every requested target applied), `previewOpened`,
  /// and `awaitingUserConfirmation` (for UI-opening operations) count as
  /// success under the legacy boolean contract.
  static bool _isLegacySuccess(
    WallpaperOperationResult operation, {
    required bool uiOpeningOperation,
  }) {
    switch (operation.status) {
      case WallpaperOperationStatus.applied:
        return hasAppliedEveryRequestedTarget(
          operation.requestedTarget,
          operation.home,
          operation.lock,
        );
      case WallpaperOperationStatus.previewOpened:
      case WallpaperOperationStatus.awaitingUserConfirmation:
        return uiOpeningOperation;
      case WallpaperOperationStatus.cancelled:
      case WallpaperOperationStatus.failed:
      case WallpaperOperationStatus.unsupported:
      case WallpaperOperationStatus.foregroundRequired:
        return false;
    }
  }
}
