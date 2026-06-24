// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CategoryTab)
final categoryTabProvider = CategoryTabProvider._();

final class CategoryTabProvider extends $NotifierProvider<CategoryTab, int> {
  CategoryTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryTabProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryTabHash();

  @$internal
  @override
  CategoryTab create() => CategoryTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$categoryTabHash() => r'12d2b1050e9f80bc623a61d43093131ce45938b7';

abstract class _$CategoryTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(getSiteCategories)
final getSiteCategoriesProvider = GetSiteCategoriesFamily._();

final class GetSiteCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LiveCategory>>,
          List<LiveCategory>,
          FutureOr<List<LiveCategory>>
        >
    with
        $FutureModifier<List<LiveCategory>>,
        $FutureProvider<List<LiveCategory>> {
  GetSiteCategoriesProvider._({
    required GetSiteCategoriesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getSiteCategoriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getSiteCategoriesHash();

  @override
  String toString() {
    return r'getSiteCategoriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LiveCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LiveCategory>> create(Ref ref) {
    final argument = this.argument as String;
    return getSiteCategories(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetSiteCategoriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getSiteCategoriesHash() => r'2dc333d8208d5d3ed1c86d4c5ff558a0bdf6ff20';

final class GetSiteCategoriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<LiveCategory>>, String> {
  GetSiteCategoriesFamily._()
    : super(
        retry: null,
        name: r'getSiteCategoriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetSiteCategoriesProvider call(String siteId) =>
      GetSiteCategoriesProvider._(argument: siteId, from: this);

  @override
  String toString() => r'getSiteCategoriesProvider';
}
