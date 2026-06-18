import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/modules/area_rooms/area_rooms_controller.dart';

class AreasRoomPage extends GetView<AreaRoomsController> {
  const AreasRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DpadFocusable(
                    autofocus: true,
                    effects: [
                      DpadScaleEffect(scale: 1.05),
                      DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ],
                    onSelect: () async => Navigator.of(Get.context!).pop(),
                    builder: (context, state, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: state.focused
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.primaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 18,
                              color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "返回",
                              style: TextStyle(
                                color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    controller.subCategory.areaName ?? '',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Obx(
                    () => Visibility(
                      visible: controller.loadding.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  DpadFocusable(
                    effects: [
                      DpadScaleEffect(scale: 1.05),
                      DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                    ],
                    onSelect: () async => controller.refreshData(),
                    builder: (context, state, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: state.focused
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 18,
                              color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "刷新",
                              style: TextStyle(
                                color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.list.isEmpty && controller.loadding.value) {
                return const Center(child: SizedBox.shrink());
              }
              return DpadRegion(
                memoryKey: 'areas/room_grid_${controller.subCategory.areaId}',
                horizontalEdge: DpadEdgeBehavior.stop,
                verticalEdge: DpadEdgeBehavior.stop,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  controller: controller.scrollController,
                  itemCount: controller.list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemBuilder: (context, i) {
                    final item = controller.list[i];
                    return RoomCard(
                      room: item,
                      dense: true,
                      focusNode: item.focusNode,
                      roomTypePage: EnterRoomTypePage.areasRoomPage,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
