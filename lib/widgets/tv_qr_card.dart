import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvQrCodeCard extends StatelessWidget {
  const TvQrCodeCard({super.key, required this.qrData, required this.urlText});

  final String qrData;

  final String urlText;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(color: tvTheme.focusColor.withValues(alpha: .75), blurRadius: 4.sp, spreadRadius: 4.sp),
            ],
            border: Border.all(color: tvTheme.focusColor, width: 1.sp),
          ),
          padding: EdgeInsets.all(6.sp),
          child: QrImageView(
            data: qrData,
            size: 240.sp,
            padding: EdgeInsets.all(6.0.sp),
            version: QrVersions.auto,
            backgroundColor: tvTheme.cardColor,
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: tvTheme.focusedCardColor),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: tvTheme.focusedCardColor,
            ),
          ),
        ),
        SizedBox(height: 10.sp),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.sp),
          child: Text(
            urlText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: AppTextStyles.t24W600.copyWith(color: tvTheme.primaryTextColor),
          ),
        ),
      ],
    );
  }
}
