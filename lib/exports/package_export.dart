/// Third-party dependency exports.
///
/// Feature code imports flutter/dio/riverpod through this file instead of
/// repeating package imports; name clashes are resolved with hide clauses here.
library;

// Flutter
export 'package:flutter/material.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';

// State management / dependency injection
export 'package:flutter_riverpod/flutter_riverpod.dart';

// 网络
export 'package:dio/dio.dart';

// Model generation
export 'package:freezed_annotation/freezed_annotation.dart';

// Collections and routing (collection binarySearch clashes with foundation)
export 'package:collection/collection.dart' hide binarySearch, mergeSort;
export 'package:go_router/go_router.dart';

// Localization and screen scaling (intl TextDirection is hidden)
export 'package:easy_localization/easy_localization.dart' hide TextDirection;
export 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
