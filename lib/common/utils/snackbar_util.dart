import 'package:get/get.dart';

class SnackBarUtil {
  static void success(String text) {
    Get.snackbar(
      'Success',
      text,
      duration: const Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.surfaceVariant,
      colorText: Get.theme.colorScheme.onSurfaceVariant,
      snackPosition: SnackPosition.bottom,
    );
  }

  static void error(String text) {
    Get.snackbar(
      'Error',
      text,
      duration: const Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.errorContainer,
      colorText: Get.theme.colorScheme.onErrorContainer,
      snackPosition: SnackPosition.bottom,
    );
  }
}
