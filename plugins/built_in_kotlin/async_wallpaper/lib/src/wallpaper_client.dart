import 'dart:typed_data';

import 'package:async_wallpaper/pigeon_impl_api.dart';

import 'models.dart';

/// Converts a domain source into its Pigeon transport representation.
WallpaperSourceData wallpaperSourceToData(WallpaperSource source) {
  final url = source.url;
  if (url != null) {
    return WallpaperSourceData(kind: WallpaperSourceKindData.url, url: url);
  }

  final filePath = source.filePath;
  if (filePath != null) {
    return WallpaperSourceData(
      kind: WallpaperSourceKindData.filePath,
      filePath: filePath,
    );
  }

  final contentUri = source.contentUri;
  if (contentUri != null) {
    return WallpaperSourceData(
      kind: WallpaperSourceKindData.contentUri,
      contentUri: contentUri,
    );
  }

  final bytes = source.bytes;
  if (bytes != null) {
    return WallpaperSourceData(
      kind: WallpaperSourceKindData.bytes,
      bytes: Uint8List.fromList(bytes),
    );
  }

  throw StateError('WallpaperSource does not contain a supported source kind.');
}

/// Converts a requested target into its Pigeon transport representation.
WallpaperTargetData wallpaperTargetToData(WallpaperTarget target) =>
    switch (target) {
      WallpaperTarget.home => WallpaperTargetData.home,
      WallpaperTarget.lock => WallpaperTargetData.lock,
      WallpaperTarget.both => WallpaperTargetData.both,
    };

/// Converts a Pigeon target into its domain representation.
WallpaperTarget wallpaperTargetFromData(WallpaperTargetData? data) =>
    switch (data) {
      WallpaperTargetData.home => WallpaperTarget.home,
      WallpaperTargetData.lock => WallpaperTarget.lock,
      WallpaperTargetData.both => WallpaperTarget.both,
      null => throw const FormatException(
        'Platform did not return a wallpaper target.',
      ),
    };

/// Converts a scale mode into its Pigeon transport representation.
WallpaperScaleModeData wallpaperScaleModeToData(WallpaperScaleMode mode) =>
    switch (mode) {
      WallpaperScaleMode.centerCrop => WallpaperScaleModeData.centerCrop,
      WallpaperScaleMode.fitCenter => WallpaperScaleModeData.fitCenter,
      WallpaperScaleMode.center => WallpaperScaleModeData.center,
      WallpaperScaleMode.fill => WallpaperScaleModeData.fill,
      WallpaperScaleMode.stretch => WallpaperScaleModeData.stretch,
    };

/// Converts an apply strategy into its Pigeon transport representation.
WallpaperApplyStrategyData wallpaperApplyStrategyToData(
  WallpaperApplyStrategy strategy,
) => switch (strategy) {
  WallpaperApplyStrategy.direct => WallpaperApplyStrategyData.direct,
  WallpaperApplyStrategy.systemCropper =>
    WallpaperApplyStrategyData.systemCropper,
  WallpaperApplyStrategy.systemPicker =>
    WallpaperApplyStrategyData.systemPicker,
  WallpaperApplyStrategy.automatic => WallpaperApplyStrategyData.automatic,
};

/// Converts a Pigeon apply strategy into its domain representation.
WallpaperApplyStrategy wallpaperApplyStrategyFromData(
  WallpaperApplyStrategyData? data,
) => switch (data) {
  WallpaperApplyStrategyData.direct => WallpaperApplyStrategy.direct,
  WallpaperApplyStrategyData.systemCropper =>
    WallpaperApplyStrategy.systemCropper,
  WallpaperApplyStrategyData.systemPicker =>
    WallpaperApplyStrategy.systemPicker,
  WallpaperApplyStrategyData.automatic => WallpaperApplyStrategy.automatic,
  null => throw const FormatException(
    'Platform did not return a wallpaper apply strategy.',
  ),
};

/// Converts a Pigeon operation status into its domain representation.
WallpaperOperationStatus wallpaperOperationStatusFromData(
  OperationStatusData? data,
) => switch (data) {
  OperationStatusData.applied => WallpaperOperationStatus.applied,
  OperationStatusData.previewOpened => WallpaperOperationStatus.previewOpened,
  OperationStatusData.awaitingUserConfirmation =>
    WallpaperOperationStatus.awaitingUserConfirmation,
  OperationStatusData.cancelled => WallpaperOperationStatus.cancelled,
  OperationStatusData.failed => WallpaperOperationStatus.failed,
  OperationStatusData.unsupported => WallpaperOperationStatus.unsupported,
  OperationStatusData.foregroundRequired =>
    WallpaperOperationStatus.foregroundRequired,
  null => throw const FormatException(
    'Platform did not return a wallpaper operation status.',
  ),
};

/// Converts a rotation source type into its Pigeon transport representation.
RotationSourceTypeData rotationSourceTypeToData(WallpaperSourceType type) =>
    switch (type) {
      WallpaperSourceType.url => RotationSourceTypeData.url,
      WallpaperSourceType.file => RotationSourceTypeData.file,
    };

/// Converts a rotation order into its Pigeon transport representation.
RotationOrderData rotationOrderToData(WallpaperRotationOrder order) =>
    switch (order) {
      WallpaperRotationOrder.sequential => RotationOrderData.sequential,
      WallpaperRotationOrder.shuffle => RotationOrderData.shuffle,
    };

/// Converts and validates a per-target Pigeon result.
WallpaperTargetResult targetResultFromData(TargetResultData data) {
  return WallpaperTargetResult(
    status: _targetStatusFromData(data.status),
    errorCode: data.errorCode,
    errorMessage: data.errorMessage,
    errorDetails: data.errorDetails,
  );
}

/// Converts a complete Pigeon operation result without allowing malformed
/// transport data to become a successful domain outcome.
WallpaperOperationResult operationResultFromData(OperationResultData data) {
  WallpaperTarget? target;
  WallpaperTargetResult? home;
  WallpaperTargetResult? lock;

  try {
    final status = wallpaperOperationStatusFromData(data.status);
    target = wallpaperTargetFromData(data.requestedTarget);
    home = data.home == null ? null : targetResultFromData(data.home!);
    lock = data.lock == null ? null : targetResultFromData(data.lock!);
    final fallbackStrategy = data.fallbackStrategy == null
        ? null
        : wallpaperApplyStrategyFromData(data.fallbackStrategy);

    if (status == WallpaperOperationStatus.applied &&
        !hasAppliedEveryRequestedTarget(target, home, lock)) {
      return _malformedOperationResult(
        data,
        target: target,
        home: home,
        lock: lock,
        reason: 'An applied result omitted an applied requested target.',
      );
    }

    return WallpaperOperationResult(
      status: status,
      requestedTarget: target,
      home: home,
      lock: lock,
      errorCode: data.errorCode,
      errorMessage: data.errorMessage,
      errorDetails: data.errorDetails,
      fallbackUsed: data.fallbackUsed ?? false,
      fallbackStrategy: fallbackStrategy,
    );
  } on FormatException catch (error) {
    return _malformedOperationResult(
      data,
      target: target,
      home: home,
      lock: lock,
      reason: error.message,
    );
  }
}

/// Converts a nullable Pigeon capability snapshot using conservative defaults.
WallpaperCapabilities capabilitiesFromData(WallpaperCapabilitiesData data) {
  return WallpaperCapabilities(
    supportsStaticWallpaper: data.supportsStaticWallpaper ?? false,
    supportsLiveWallpaper: data.supportsLiveWallpaper ?? false,
    supportsOpenGlLiveWallpaper: data.supportsOpenGlLiveWallpaper ?? false,
    supportsHomeWallpaper: data.supportsHomeWallpaper ?? false,
    supportsLockWallpaper: data.supportsLockWallpaper ?? false,
    supportsBothWallpapers: data.supportsBothWallpapers ?? false,
    canSetWallpaper: data.canSetWallpaper ?? false,
    hasSystemWallpaperPicker: data.hasSystemWallpaperPicker ?? false,
    requiresForeground: data.requiresForeground ?? false,
    manufacturer: data.manufacturer ?? 'Unknown',
    sdkInt: data.sdkInt ?? 0,
    openGlVersion: data.openGlVersion,
    openGlRenderer: data.openGlRenderer,
  );
}

/// Converts a structured static request into Pigeon transport data.
StaticWallpaperRequestData staticWallpaperRequestToData(
  StaticWallpaperRequest request,
) {
  return StaticWallpaperRequestData(
    source: wallpaperSourceToData(request.source),
    target: wallpaperTargetToData(request.target),
    scaleMode: wallpaperScaleModeToData(request.scaleMode),
    strategy: wallpaperApplyStrategyToData(request.strategy),
  );
}

/// Converts a domain video request into Pigeon transport data.
VideoWallpaperRequestData videoWallpaperRequestToData(
  VideoWallpaperRequest request,
) {
  return VideoWallpaperRequestData(
    source: wallpaperSourceToData(request.source),
    target: wallpaperTargetToData(request.target),
    scaleMode: wallpaperScaleModeToData(request.scaleMode),
  );
}

/// Converts a domain OpenGL request into Pigeon transport data.
OpenGlWallpaperRequestData openGlWallpaperRequestToData(
  OpenGlLiveWallpaperRequest request,
) {
  return OpenGlWallpaperRequestData(
    fragmentShader: request.fragmentShader,
    textures: request.textures
        .map<WallpaperSourceData?>(wallpaperSourceToData)
        .toList(growable: false),
    target: wallpaperTargetToData(request.target),
    frameRate: request.frameRate,
  );
}

/// Internal seam between the public facade and platform transport.
abstract interface class WallpaperClient {
  /// Returns the platform's wallpaper capability snapshot.
  Future<WallpaperCapabilities> getCapabilities();

  /// Applies a structured static wallpaper request.
  Future<WallpaperOperationResult> applyWallpaper(
    StaticWallpaperRequest request,
  );

  /// Prepares a video live wallpaper without claiming it was applied.
  Future<WallpaperOperationResult> prepareVideoWallpaper(
    VideoWallpaperRequest request,
  );

  /// Opens the system live-wallpaper preview flow.
  Future<WallpaperOperationResult> openLiveWallpaperPreview(
    VideoWallpaperRequest request,
  );

  /// Applies a shader-based OpenGL live wallpaper.
  Future<WallpaperOperationResult> applyOpenGlWallpaper(
    OpenGlLiveWallpaperRequest request,
  );
}

/// Default Pigeon-backed client for structured wallpaper operations.
class PigeonWallpaperClient implements WallpaperClient {
  PigeonWallpaperClient({WallpaperApi? api}) : _api = api ?? WallpaperApi();

  final WallpaperApi _api;

  @override
  Future<WallpaperCapabilities> getCapabilities() async {
    return capabilitiesFromData(await _api.getCapabilities());
  }

  @override
  Future<WallpaperOperationResult> applyWallpaper(
    StaticWallpaperRequest request,
  ) async {
    return operationResultFromData(
      await _api.applyWallpaper(staticWallpaperRequestToData(request)),
    );
  }

  @override
  Future<WallpaperOperationResult> prepareVideoWallpaper(
    VideoWallpaperRequest request,
  ) async {
    return operationResultFromData(
      await _api.prepareVideoWallpaper(videoWallpaperRequestToData(request)),
    );
  }

  @override
  Future<WallpaperOperationResult> openLiveWallpaperPreview(
    VideoWallpaperRequest request,
  ) async {
    return operationResultFromData(
      await _api.openLiveWallpaperPreview(videoWallpaperRequestToData(request)),
    );
  }

  @override
  Future<WallpaperOperationResult> applyOpenGlWallpaper(
    OpenGlLiveWallpaperRequest request,
  ) async {
    return operationResultFromData(
      await _api.applyOpenGlWallpaper(openGlWallpaperRequestToData(request)),
    );
  }
}

WallpaperTargetStatus _targetStatusFromData(TargetStatusData? data) =>
    switch (data) {
      TargetStatusData.applied => WallpaperTargetStatus.applied,
      TargetStatusData.failed => WallpaperTargetStatus.failed,
      TargetStatusData.unsupported => WallpaperTargetStatus.unsupported,
      TargetStatusData.notAttempted => WallpaperTargetStatus.notAttempted,
      null => throw const FormatException(
        'Platform did not return a wallpaper target status.',
      ),
    };

/// Returns whether an applied result covers every target it claims to.
///
/// Shared by [operationResultFromData], which rejects malformed transport
/// data, and the facade's legacy success mapping.
bool hasAppliedEveryRequestedTarget(
  WallpaperTarget target,
  WallpaperTargetResult? home,
  WallpaperTargetResult? lock,
) {
  switch (target) {
    case WallpaperTarget.home:
      return home?.status == WallpaperTargetStatus.applied;
    case WallpaperTarget.lock:
      return lock?.status == WallpaperTargetStatus.applied;
    case WallpaperTarget.both:
      return home?.status == WallpaperTargetStatus.applied &&
          lock?.status == WallpaperTargetStatus.applied;
  }
}

WallpaperOperationResult _malformedOperationResult(
  OperationResultData data, {
  required WallpaperTarget? target,
  required WallpaperTargetResult? home,
  required WallpaperTargetResult? lock,
  required Object? reason,
}) {
  final nativeDetails = data.errorDetails ?? data.errorMessage;
  final details = <String>[
    ?nativeDetails,
    if (reason != null) reason.toString(),
  ].join('; ');
  return WallpaperOperationResult(
    status: WallpaperOperationStatus.failed,
    requestedTarget: target ?? _targetOrHome(data.requestedTarget),
    home: home,
    lock: lock,
    errorCode: 'malformed-transport',
    errorMessage: 'The platform returned an incomplete wallpaper result.',
    errorDetails: details.isEmpty ? null : details,
  );
}

WallpaperTarget _targetOrHome(WallpaperTargetData? data) =>
    data == null ? WallpaperTarget.home : wallpaperTargetFromData(data);
