import 'package:pure_live/services/index.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// third-party auth — one row per platform, each opening that platform's own page.
///
/// The rows are the mobile account page's list, minus douyu (disabled there too:
/// no site implementation reads a Douyu cookie). Bilibili keeps its account row
/// with the signed-in name, and every other platform shows whether a cookie is
/// set. The per-platform pages carry both ways in (QR sign-in and manual input).
class AccountSettingsSectionPage extends ConsumerWidget {
  const AccountSettingsSectionPage({super.key});

  static List<CookieSite> get sites => <CookieSite>[
    CookieSite(
      siteId: Sites.bilibiliSite,
      titleKey: 'site_bilibili',
      route: AppRoutes.kSettingsAccountBilibili,
      hintKey: 'cookie_hint',
      read: (cookies) => cookies.bilibiliCookie,
      apply: (controller, value) => controller.setBilibiliCookie(value),
    ),
    CookieSite(
      siteId: Sites.huyaSite,
      titleKey: 'site_huya',
      route: AppRoutes.kSettingsAccountHuya,
      hintKey: 'huya_cookie_hint',
      read: (cookies) => cookies.huyaCookie,
      apply: (controller, value) => controller.setHuyaCookie(value),
    ),
    CookieSite(
      siteId: Sites.douyuSite,
      titleKey: 'site_douyu',
      route: AppRoutes.kSettingsAccountDouyu,
      hintKey: 'cookie_hint',
      read: (cookies) => cookies.douyuCookie,
      apply: (controller, value) => controller.setDouyuCookie(value),
    ),
    CookieSite(
      siteId: Sites.yySite,
      titleKey: 'site_yy',
      route: AppRoutes.kSettingsAccountYy,
      hintKey: 'cookie_hint',
      read: (cookies) => cookies.yyCookie,
      apply: (controller, value) => controller.setYyCookie(value),
    ),
    CookieSite(
      siteId: Sites.douyinSite,
      titleKey: 'site_douyin',
      route: AppRoutes.kSettingsAccountDouyin,
      hintKey: 'douyin_cookie_hint',
      read: (cookies) => cookies.douyinCookie,
      apply: (controller, value) => controller.setDouyinCookie(value),
    ),
    CookieSite(
      siteId: Sites.kuaishouSite,
      titleKey: 'site_kuaishou',
      route: AppRoutes.kSettingsAccountKuaishou,
      hintKey: 'kuaishou_cookie_hint',
      read: (cookies) => cookies.kuaishouCookie,
      apply: (controller, value) => controller.setKuaishouCookie(value),
    ),
    CookieSite(
      siteId: Sites.twitchSite,
      titleKey: 'site_twitch',
      route: AppRoutes.kSettingsAccountTwitch,
      hintKey: 'twitch_cookie_hint',
      read: (cookies) => cookies.twitchCookie,
      apply: (controller, value) => controller.setTwitchCookie(value),
    ),
    CookieSite(
      siteId: Sites.soopSite,
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
    // Nickname first (loaded from the account endpoint), UID as the fallback.
    final BilibiliAccountModel account = ref.watch(bilibiliAccountControllerProvider);
    final CookieSite bilibili = sites.first;

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
                  : (account.name.isNotEmpty
                        ? account.name
                        : (cookies.bilibiliUid <= 0 ? i18n('not_logged_in') : 'UID ${cookies.bilibiliUid}')),
              leading: SiteLogo(siteId: bilibili.siteId),
              onTap: () => settingsSectionRoutes[bilibili.route]?.push(context),
            ),
            for (final CookieSite site in sites.skip(1))
              TvSettingsNavTile(
                title: i18n(site.titleKey),
                subtitle: site.read(cookies).isEmpty
                    ? i18n('not_set')
                    : i18n('cookie_state_set', args: {'count': '${site.read(cookies).length}'}),
                leading: SiteLogo(siteId: site.siteId),
                onTap: () => settingsSectionRoutes[site.route]?.push(context),
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
    ref.read(cookieControllerProvider.notifier).setBilibiliCookie('');
    await BilibiliAccountService.instance.logout();
  }
}

/// One platform in the account list: its labels, its store access and the route
/// of its own page.
class CookieSite {
  const CookieSite({
    required this.siteId,
    required this.titleKey,
    required this.route,
    required this.hintKey,
    required this.read,
    required this.apply,
  });

  /// Platform id in [Sites], used to resolve the bundled logo.
  final String siteId;

  final String titleKey;
  final String route;
  final String hintKey;
  final String Function(CookieModel) read;
  final void Function(CookieController controller, String value) apply;
}

/// The platform's own logo from the central registry (`assets/images`), sized
/// for a settings row's leading slot.
class SiteLogo extends StatelessWidget {
  const SiteLogo({super.key, required this.siteId, this.size = 34});

  final String siteId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.sp),
      child: Image.asset(
        Sites.logoOf(siteId),
        width: size.sp,
        height: size.sp,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.cookie_outlined, size: size.sp, color: context.tvTheme.secondaryTextColor),
      ),
    );
  }
}
