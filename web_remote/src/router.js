import { createRouter, createWebHashHistory } from 'vue-router'

const DashboardView = () => import('./views/Dashboard.vue')
const MovieRemoteView = () => import('./views/MovieRemote.vue')
const SearchRemoteView = () => import('./views/SearchRemote.vue')
const CookieRemoteView = () => import('./views/CookieRemote.vue')
const WebDavSettingsRemoteView = () => import('./views/WebDavSettingsRemote.vue')
const SyncRemoteView = () => import('./views/SyncRemote.vue')
const LogRemoteView = () => import('./views/LogRemote.vue')
const AboutRemoteView = () => import('./views/AboutRemote.vue')
const DanmakuFilterView = () => import('./views/DanmakuFilter.vue')
const BilibiliCookieView = () => import('./views/cookies/BilibiliCookie.vue')
const DouyuCookieView = () => import('./views/cookies/DouyuCookie.vue')
const HuyaCookieView = () => import('./views/cookies/HuyaCookie.vue')
const DouyinCookieView = () => import('./views/cookies/DouyinCookie.vue')
const KuaishouCookieView = () => import('./views/cookies/KuaishouCookie.vue')
const CcCookieView = () => import('./views/cookies/CcCookie.vue')
const DonateView = () => import('./views/Donate.vue')
const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: DashboardView,
    meta: { title: 'PureLive TV' }
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
      { path: 'douyu', component: DouyuCookieView, meta: { title: '斗鱼Cookie' } },
      { path: 'huya', component: HuyaCookieView, meta: { title: '虎牙Cookie' } },
      { path: 'douyin', component: DouyinCookieView, meta: { title: '抖音Cookie' } },
      { path: 'kuaishou', component: KuaishouCookieView, meta: { title: '快手Cookie' } },
      { path: 'cc', component: CcCookieView, meta: { title: '网易CC Cookie' } }
    ]
  },
  {
    path: '/webdav_settings',
    component: WebDavSettingsRemoteView,
    meta: { title: 'WebDav 设置' }
  },
  {
    path: '/danmaku',
    component: DanmakuFilterView,
    meta: { title: '弹幕关键词过滤' }
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
