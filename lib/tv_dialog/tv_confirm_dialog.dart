import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/get/get.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/tv_dialog/tv_dialog.dart';

class TvConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onConfirm;

  const TvConfirmDialog({super.key, required this.title, this.message, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null) Text(message!),
          const SizedBox(height: 32),
          DpadRegion(
            horizontalEdge: DpadEdgeBehavior.stop,
            verticalEdge: DpadEdgeBehavior.stop,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TvButton(title: "取消", onTap: Get.back),
                const SizedBox(width: 24),
                TvButton(
                  title: "确定",
                  autofocus: true,
                  onTap: () {
                    Get.back();
                    onConfirm?.call();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
