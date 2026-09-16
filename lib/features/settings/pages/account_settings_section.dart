import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 三方认证 — one row per platform, each opening that platform's own page.
///
/// The rows are the mobile account page's list, minus 斗鱼 (disabled there too:
/// no site implementation reads a Douyu cookie). Bilibili keeps its account row
/// with the signed-in name, and every other platform shows whether a cookie is
/// set. The per-platform pages carry both ways in (扫码 and 手动输入).
class AccountSettingsSectionPage extends ConsumerWidget {
  const AccountSettingsSectionPage({super.key});

  static List<CookieSite> get sites => <CookieSite>[
    CookieSite(
      titleKey: 'site_huya',
      route: AppRoutes.kSettingsAccountHuya,
      hintKey: 'huya_cookie_hint',
      read: (cookies) => cookies.huyaCookie,
      apply: (controller, value) => controller.setHuyaCookie(value),
      webPath: WebRemoteRouter.cookieHuya,
    ),
    CookieSite(
      titleKey: 'site_yy',
      route: AppRoutes.kSettingsAccountYy,
      hintKey: 'cookie_hint',
      read: (cookies) => cookies.yyCookie,
      apply: (controller, value) => controller.setYyCookie(value),
    ),
    CookieSite(
      titleKey: 'site_douyin',
      route: AppRoutes.kSettingsAccountDouyin,
      hintKey: 'douyin_cookie_hint',
      read: (cookies) => cookies.douyinCookie,
      apply: (controller, value) => controller.setDouyinCookie(value),
      webPath: WebRemoteRouter.cookieDouyin,
    ),
    CookieSite(
      titleKey: 'site_kuaishou',
      route: AppRoutes.kSettingsAccountKuaishou,
      hintKey: 'kuaishou_cookie_hint',
      read: (cookies) => cookies.kuaishouCookie,
      apply: (controller, value) => controller.setKuaishouCookie(value),
      webPath: WebRemoteRouter.cookieKuaishou,
    ),
    CookieSite(
      titleKey: 'site_twitch',
      route: AppRoutes.kSettingsAccountTwitch,
      hintKey: 'twitch_cookie_hint',
      read: (cookies) => cookies.twitchCookie,
      apply: (controller, value) => controller.setTwitchCookie(value),
    ),
    CookieSite(
      titleKey: 'site_soop',
      route: AppRoutes.kSettingsAccountSoop,
      hintKey: 'soop_cookie_hint',
      read: (cookies) => cookies.soopCookie,
      apply: (controller, value) => controller.setSoopCookie(value),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CookieModel cookies = ref.watch(cookieControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('third_party_auth')),
        TvSettingsCard(
          children: [
            // Bilibili first, as on the mobile page: it has a real account
            // (name and uid) rather than just a cookie.
            TvSettingsNavTile(
              title: i18n('site_bilibili'),
              subtitle: cookies.bilibiliCookie.isEmpty
                  ? i18n('not_logged_in')
                  : (cookies.bilibiliUid <= 0 ? i18n('logined') : 'UID ${cookies.bilibiliUid}'),
              icon: Icons.live_tv_rounded,
              onTap: () => context.push(AppRoutes.kSettingsAccountBilibili),
            ),
            for (final CookieSite site in sites)
              TvSettingsNavTile(
                title: i18n(site.titleKey),
                subtitle: site.read(cookies).isEmpty
                    ? i18n('not_set')
                    : i18n('cookie_state_set', args: {'count': '${site.read(cookies).length}'}),
                icon: Icons.cookie_outlined,
                onTap: () => context.push(site.route),
              ),
          ],
        ),
        SizedBox(height: 16.h),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('clear_all_cookies'),
              subtitle: i18n('clear_all_cookies_desc'),
              icon: Remix.delete_bin_6_line,
              options: [i18n('clear')],
              index: 0,
              onChanged: (_) => _clearAll(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('clear_all_cookies'),
      message: i18n('clear_all_cookies_desc'),
      confirmText: i18n('clear'),
      cancelText: i18n('cancel'),
    );
    if (confirmed != true) return;
    ref.read(cookieControllerProvider.notifier).clearAllCookies();
  }
}

/// One platform in the account list: its labels, its store access and the route
/// of its own page.
class CookieSite {
  const CookieSite({
    required this.titleKey,
    required this.route,
    required this.hintKey,
    required this.read,
    required this.apply,
    this.webPath,
  });

  final String titleKey;
  final String route;
  final String hintKey;
  final String Function(CookieModel) read;
  final void Function(CookieController controller, String value) apply;

  /// Phone page for this platform; null when the bundled phone pages have none.
  final String? webPath;
}
