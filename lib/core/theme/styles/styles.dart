import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/core/theme/typography/app_font_scale.dart';

/// The semantic type scale.
///
/// Every tier resolves through [_t] — the ONE place where the user's font
/// scale ([AppFontScale.user]) meets the screen adaptation (.sp).
///
/// Pages never multiply by hand: pick a tier and [.copyWith] the properties
/// that need to be customized.
///
/// A missing size gets added here, never multiplied at the call site.
class AppTextStyles {
  AppTextStyles._();

  /// Widgets that install an [AppTextStyles] style as a `DefaultTextStyle`
  /// (TvButton, TvTabBar, …) *replace* the inherited style, so a null family
  /// here would drop the applied font for exactly those widgets — plain Text
  /// inherits it, these do not.
  static String? fontFamily;

  /// The single entry point for creating an application text style.
  ///
  /// [size] is the design size before user scaling.
  /// [weight] controls the font weight.
  static TextStyle _t(
    num size, {
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontSize: (size * AppFontScale.user).sp,
      fontWeight: weight,
      fontFamily: fontFamily,
    );
  }

  /// Creates a text style for a custom size.
  ///
  /// Use this when the predefined type scale does not contain the size
  /// required by a specific component.
  static TextStyle of(
    num size, {
    FontWeight weight = FontWeight.w400,
  }) {
    return _t(
      size,
      weight: weight,
    );
  }

  // ==================== 14sp ====================

  static TextStyle get t14 => _t(14);

  // ==================== 15sp ====================

  static TextStyle get t15 => _t(15);

  // ==================== 16sp ====================

  static TextStyle get t16 => _t(16);

  // ==================== 17sp ====================

  static TextStyle get t17 => _t(17);

  // ==================== 18sp ====================

  static TextStyle get t18 => _t(18);

  // ==================== 19sp ====================

  static TextStyle get t19 => _t(19);

  // ==================== 20sp ====================

  static TextStyle get t20 => _t(20);

  // ==================== 22sp ====================

  static TextStyle get t22 => _t(22);

  // ==================== 24sp ====================

  static TextStyle get t24 => _t(24);

  // ==================== 25sp ====================

  static TextStyle get t25 => _t(25);

  // ==================== 26sp ====================

  static TextStyle get t26 => _t(26);

  // ==================== 28sp ====================

  static TextStyle get t28 => _t(28);

  // ==================== 30sp ====================

  static TextStyle get t30 => _t(30);

  // ==================== 32sp ====================

  static TextStyle get t32 => _t(32);

  // ==================== 34sp ====================

  static TextStyle get t34 => _t(34);

  // ==================== 40sp ====================

  static TextStyle get t40 => _t(40);
}
