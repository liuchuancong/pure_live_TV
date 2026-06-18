import 'dart:io';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/modules/agreement/agreement_page_controller.dart';

class AgreementPage extends GetView<AgreementPageController> {
  const AgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: Center(
        child: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  "使用须知",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "欢迎使用纯粹直播 TV，请在使用前仔细阅读以下内容：",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "1. 本软件为开源软件，仅供学习交流使用，禁止用于任何商业用途。",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                "2. 本软件不提供任何直播内容，所有直播内容均来自网络。",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                "3. 本软件完全基于您个人意愿使用，您应该对自己的使用行为和所有结果承担全部责任。",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                "4. 如果本软件存在侵犯您的合法权益的情况，请及时与作者联系，作者将会及时删除有关内容。",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                "如您继续使用本软件即代表您已完全理解并同意上述内容。",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 36),
              DpadRegion(
                horizontalEdge: DpadEdgeBehavior.stop,
                verticalEdge: DpadEdgeBehavior.stop,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DpadFocusable(
                      autofocus: true,
                      effects: [
                        DpadScaleEffect(scale: 1.05),
                        DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                      ],
                      onSelect: () {
                        SettingsService.to.startup.isFirstInApp.value = false;
                        Get.offAllNamed(RoutePath.kInitial);
                      },
                      builder: (context, state, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: state.focused
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "已阅读并同意",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: state.focused ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                            ),
                          ),
                        );
                      },
                      child: const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 24),
                    DpadFocusable(
                      effects: [
                        DpadScaleEffect(scale: 1.05),
                        DpadGlowEffect(color: Colors.red.withOpacity(0.3)),
                      ],
                      onSelect: () => exit(0),
                      builder: (context, state, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: state.focused ? Colors.red : theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "退出应用",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: state.focused ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
