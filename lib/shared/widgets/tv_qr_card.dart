import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvQrCodeCard extends StatelessWidget {
  const TvQrCodeCard({super.key, required this.qrData, this.urlText, this.qrSize = 240});

  final String qrData;

  /// Code side in design pixels; pages with room (device sync) pass a larger
  /// code, compact panels keep the default.
  final double qrSize;

  /// Plain text under the code; hidden when empty so a TV screen does not
  /// broadcast the address.
  final String? urlText;

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
            // Shadow only, no border: this card is usually embedded in another
            // framed surface (settings card, player panel), and its own accent
            // outline read as a second border stacked inside the first.
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 12.sp, offset: Offset(0, 4.sp)),
            ],
          ),
          padding: EdgeInsets.all(8.sp),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.sp),
            child: QrImageView(
              data: qrData,
              size: qrSize.sp,
              padding: EdgeInsets.all(8.0.sp),
              version: QrVersions.auto,
              // A QR must stay a fixed dark-on-white pattern: themeing the modules
              // painted them in focusedCardColor, which is white on every light
              // preset — an invisible code on a white card.
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF101014)),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF101014),
              ),
            ),
          ),
        ),
        if (urlText?.isNotEmpty ?? false) ...[
          SizedBox(height: 10.sp),
          // scaleDown over the full card width: a long label (hash-route URLs
          // ran ~40 chars at 24sp) used to overflow the line and clip off the
          // edge of the screen, so the address and port were never visible.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  urlText!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: AppTextStyles.t24W600.copyWith(color: tvTheme.primaryTextColor),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
