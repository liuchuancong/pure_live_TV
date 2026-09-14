// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlatformTab)
final platformTabProvider = PlatformTabProvider._();

final class PlatformTabProvider
    extends $NotifierProvider<PlatformTab, PlatformTabState> {
  PlatformTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformTabHash();

  @$internal
  @override
  PlatformTab create() => PlatformTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlatformTabState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlatformTabState>(value),
    );
  }
}

String _$platformTabHash() => r'cb71e081bd20f1ad30796352071ee43853ea56d4';

abstract class _$PlatformTab extends $Notifier<PlatformTabState> {
  PlatformTabState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlatformTabState, PlatformTabState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlatformTabState, PlatformTabState>,
              PlatformTabState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
