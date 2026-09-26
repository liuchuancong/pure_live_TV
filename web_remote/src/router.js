import { createRouter, createWebHashHistory } from 'vue-router'

const DashboardView = () => import('./views/Dashboard.vue')
const MovieRemoteView = () => import('./views/MovieRemote.vue')
const SearchRemoteView = () => import('./views/SearchRemote.vue')
const CookieRemoteView = () => import('./views/CookieRemote.vue')
const AccountCookieView = () => import('./views/cookies/AccountCookie.vue')
const BilibiliCookieView = () => import('./views/cookies/BilibiliCookie.vue')
const DouyuCookieView = () => import('./views/cookies/DouyuCookie.vue')
const DouyinCookieView = () => import('./views/cookies/DouyinCookie.vue')
const SyncRemoteView = () => import('./views/SyncRemote.vue')
const LogRemoteView = () => import('./views/LogRemote.vue')
const AboutRemoteView = () => import('./views/AboutRemote.vue')
const DanmakuFilterView = () => import('./views/DanmakuFilter.vue')
const IptvRemoteView = () => import('./views/IptvRemote.vue')
const ProxyRemoteView = () => import('./views/ProxyRemote.vue')
const TagRemoteView = () => import('./views/TagRemote.vue')
const DonateView = () => import('./views/Donate.vue')
const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: DashboardView,
    meta: { title: '纯粹直播' }
  },
  {
    path: '/movie',
    component: MovieRemoteView,
    meta: { title: '链接解析' }
  },
  {
    path: '/search',
    component: SearchRemoteView,
    meta: { title: '搜索页面' }
  },
  {
    path: '/cookie',
    component: CookieRemoteView,
    meta: { title: '各平台 Cookie 管理' },
    children: [
      { path: 'bilibili', component: BilibiliCookieView, meta: { title: '哔哩哔哩Cookie' } },
      { path: 'huya', component: AccountCookieView, props: { site: 'huya', siteName: '虎牙' }, meta: { title: '虎牙Cookie' } },
      { path: 'douyu', component: DouyuCookieView, meta: { title: '斗鱼Cookie' } },
      { path: 'douyin', component: DouyinCookieView, meta: { title: '抖音Cookie' } },
      { path: 'kuaishou', component: AccountCookieView, props: { site: 'kuaishou', siteName: '快手' }, meta: { title: '快手Cookie' } },
      { path: 'yy', component: AccountCookieView, props: { site: 'yy', siteName: 'YY' }, meta: { title: 'YY Cookie' } },
      { path: 'soop', component: AccountCookieView, props: { site: 'soop', siteName: 'SOOP' }, meta: { title: 'SOOP Cookie' } },
      { path: 'twitch', component: AccountCookieView, props: { site: 'twitch', siteName: 'Twitch' }, meta: { title: 'Twitch Cookie' } }
    ]
  },
  {
    path: '/danmaku',
    component: DanmakuFilterView,
    meta: { title: '弹幕关键词过滤' }
  },
  {
    path: '/iptv',
    component: IptvRemoteView,
    meta: { title: 'IPTV 直播源' }
  },
  {
    path: '/proxy',
    component: ProxyRemoteView,
    meta: { title: '网络代理' }
  },
  {
    path: '/tags',
    component: TagRemoteView,
    meta: { title: '标签管理' }
  },
  {
    path: '/sync',
    component: SyncRemoteView,
    meta: { title: '数据导入与导出' }
  },
  {
    path: '/log',
    component: LogRemoteView,
    meta: { title: '系统日志查看与下载' }
  },
  {
    path: '/about',
    component: AboutRemoteView,
    meta: { title: '关于程序' }
  },
  {
    path: '/donate',
    component: DonateView,
    meta: { title: '开发者捐赠支持' }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

export const router = createRouter({
  history: createWebHashHistory(),
  routes
})
