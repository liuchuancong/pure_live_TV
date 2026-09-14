/// 第三方依赖公共出口。
///
/// 业务文件不再逐个 import flutter/dio/riverpod 等包，统一从这里引入；
/// 出现同名符号时（例如 intl 与 flutter 的 TextDirection）在本文件用 hide 收敛。
library;

// Flutter
export 'package:flutter/material.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';

// 状态管理 / 依赖注入
export 'package:flutter_riverpod/flutter_riverpod.dart';

// 网络
export 'package:dio/dio.dart';

// 模型生成
export 'package:freezed_annotation/freezed_annotation.dart';

// 集合与路由（collection 的 binarySearch 与 flutter foundation 同名）
export 'package:collection/collection.dart' hide binarySearch, mergeSort;
export 'package:go_router/go_router.dart';

// 多语言与屏幕适配（hide 掉与 Flutter 冲突的 TextDirection）
export 'package:easy_localization/easy_localization.dart' hide TextDirection;
export 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
