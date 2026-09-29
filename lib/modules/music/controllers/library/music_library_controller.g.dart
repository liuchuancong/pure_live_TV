// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_library_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MusicLibraryController)
final musicLibraryControllerProvider = MusicLibraryControllerProvider._();

final class MusicLibraryControllerProvider
    extends $NotifierProvider<MusicLibraryController, MusicLibraryState> {
  MusicLibraryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'musicLibraryControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$musicLibraryControllerHash();

  @$internal
  @override
  MusicLibraryController create() => MusicLibraryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MusicLibraryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MusicLibraryState>(value),
    );
  }
}

String _$musicLibraryControllerHash() =>
    r'c5cd3701f4654ae6158d3ac9c3a086d511d820d2';

abstract class _$MusicLibraryController extends $Notifier<MusicLibraryState> {
  MusicLibraryState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MusicLibraryState, MusicLibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MusicLibraryState, MusicLibraryState>,
              MusicLibraryState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
