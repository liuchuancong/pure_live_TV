import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/modules/auth/utils/constants.dart';
import 'package:pure_live/modules/shield/danmu_shield_controller.dart';

class DanmuShieldPage extends GetView<DanmuShieldController> {
  const DanmuShieldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("弹幕关键词屏蔽"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          TextField(
            keyboardType: TextInputType.text,
            controller: controller.textEditingController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12.0),
              border: OutlineInputBorder(borderSide: BorderSide(color: controller.themeColor)),
              hintText: "请输入关键词",
              suffixIcon: TextButton.icon(
                onPressed: controller.add,
                icon: const Icon(Icons.add),
                label: const Text("添加"),
              ),
            ),
            onSubmitted: (e) {
              controller.add();
            },
          ),
          spacer(12.0),
          Obx(
            () => Text(
              "已添加${controller.settingsController.shieldList.length}个关键词（点击移除）",
              style: Get.textTheme.titleMedium,
            ),
          ),
          spacer(12.0),
          Obx(
            () => Wrap(
              runSpacing: 12,
              spacing: 12,
              children: controller.settingsController.shieldList
                  .map(
                    (item) => InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                      onTap: () {
                        var index = controller.settingsController.shieldList.indexWhere((element) => element == item);
                        controller.remove(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).primaryColor),
                          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                        ),
                        padding: const EdgeInsets.only(top: 10, bottom: 10, left: 8, right: 8),
                        child: Text(
                          item,
                          style: Get.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
