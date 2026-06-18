import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: DpadRegion(
        memoryKey: 'settings/donate_page',
        horizontalEdge: DpadEdgeBehavior.stop,
        verticalEdge: DpadEdgeBehavior.stop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                  Text("帮助与支持", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "感谢您的使用！",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "如果您觉得有更好的建议或者意见，欢迎您联系我们。",
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 24),
                  context.buildGroupTitle("官方交流通道"),
                  context.buildModernCard([
                    DpadFocusable(
                      effects: [
                        DpadScaleEffect(scale: 1.02),
                        DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ],
                      builder: (context, state, child) {
                        return Container(
                          color: state.focused ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.group_outlined,
                                    color: state.focused
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "QQ交流群",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "920447827",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: state.focused ? theme.colorScheme.primary : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const SizedBox.shrink(),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WechatItem extends StatelessWidget {
  const WechatItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300.w,
        padding: const EdgeInsets.all(12),
        child: Image.asset('assets/images/wechat.png', fit: BoxFit.contain),
      ),
    );
  }
}
