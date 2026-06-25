// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paging_core.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PagingCore)
final pagingCoreProvider = PagingCoreFamily._();

final class PagingCoreProvider<T>
    extends $NotifierProvider<PagingCore<T>, BasePagedState<T>> {
  PagingCoreProvider._({
    required PagingCoreFamily super.from,
    required PagingParam<T> super.argument,
  }) : super(
         retry: null,
         name: r'pagingCoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pagingCoreHash();

  @override
  String toString() {
    return r'pagingCoreProvider'
        '<${T}>'
        '($argument)';
  }

  @$internal
  @override
  PagingCore<T> create() => PagingCore<T>();

  $R _captureGenerics<$R>($R Function<T>() cb) {
    return cb<T>();
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BasePagedState<T> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BasePagedState<T>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PagingCoreProvider &&
        other.runtimeType == runtimeType &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, argument);
  }
}

String _$pagingCoreHash() => r'39dd22acf7504c19a99d9bcf6d94f06ba2b04f85';

final class PagingCoreFamily extends $Family {
  PagingCoreFamily._()
    : super(
        retry: null,
        name: r'pagingCoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PagingCoreProvider<T> call<T>(PagingParam<T> pParam) =>
      PagingCoreProvider<T>._(argument: pParam, from: this);

  @override
  String toString() => r'pagingCoreProvider';

  /// {@macro riverpod.override_with}
  Override overrideWith(PagingCore<T> Function<T>() create) => $FamilyOverride(
    from: this,
    createElement: (pointer) {
      final provider = pointer.origin as PagingCoreProvider;
      return provider._captureGenerics(<T>() {
        provider as PagingCoreProvider<T>;
        return provider.$view(create: create<T>).$createElement(pointer);
      });
    },
  );

  /// {@macro riverpod.override_with_build}
  Override overrideWithBuild(
    BasePagedState<T> Function<T>(Ref ref, PagingCore<T> notifier) build,
  ) => $FamilyOverride(
    from: this,
    createElement: (pointer) {
      final provider = pointer.origin as PagingCoreProvider;
      return provider._captureGenerics(<T>() {
        provider as PagingCoreProvider<T>;
        return provider
            .$view(runNotifierBuildOverride: build<T>)
            .$createElement(pointer);
      });
    },
  );
}

abstract class _$PagingCore<T> extends $Notifier<BasePagedState<T>> {
  late final _$args = ref.$arg as PagingParam<T>;
  PagingParam<T> get pParam => _$args;

  BasePagedState<T> build(PagingParam<T> pParam);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BasePagedState<T>, BasePagedState<T>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BasePagedState<T>, BasePagedState<T>>,
              BasePagedState<T>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
