// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_parse_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(urlParseEngine)
final urlParseEngineProvider = UrlParseEngineProvider._();

final class UrlParseEngineProvider
    extends $FunctionalProvider<UrlParseEngine, UrlParseEngine, UrlParseEngine>
    with $Provider<UrlParseEngine> {
  UrlParseEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlParseEngineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlParseEngineHash();

  @$internal
  @override
  $ProviderElement<UrlParseEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UrlParseEngine create(Ref ref) {
    return urlParseEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UrlParseEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UrlParseEngine>(value),
    );
  }
}

String _$urlParseEngineHash() => r'187a07b1f7221fc22deead85e113458758914417';
