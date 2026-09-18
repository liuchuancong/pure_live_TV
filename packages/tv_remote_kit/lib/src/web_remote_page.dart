/// The pages the phone opens after scanning the QR — no build step, no CDN, one file.
///
/// The page used to be one long form holding every feature at once; it is a small
/// hash-routed app now (`WebRemoteRouter`'s routes): 首页, 搜索, Cookie (per
/// platform), IPTV, 代理, 弹幕, 标签, 配置. Each route owns its DOM and its
/// lifecycle — entering a page builds and loads it, leaving tears it down — so a
/// page's fetches and timers never outlive it and no feature leaks into another.
///
/// It talks to the same HTTP API the mobile app uses (`/api/channel/<name>`,
/// `/api/search/streamer`, …), so a browser becomes a second client of the LAN sync
/// service: cookies, IPTV playlists with their request headers, the network proxy,
/// danmaku filters and tags are all typed on the phone and land in the TV's own
/// settings pages.
const String kWebRemotePage = r'''<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>PureLive 局域网同步</title>
<style>
  :root { color-scheme: dark; --bg:#0f1115; --card:#191d24; --line:#2a3040; --fg:#eef2f8; --muted:#94a3b8; --accent:#00a1ff; --ok:#22c55e; --err:#f87171; }
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body { margin:0; background:var(--bg); color:var(--fg); font:16px/1.5 -apple-system,"PingFang SC","Microsoft YaHei",system-ui,sans-serif; padding:0 0 calc(76px + env(safe-area-inset-bottom)); }
  header { position:sticky; top:0; z-index:10; display:flex; align-items:center; gap:10px; background:var(--bg); border-bottom:1px solid var(--line); padding:12px 14px; }
  header .back { width:34px; height:34px; border-radius:10px; background:var(--card); border:1px solid var(--line); display:flex; align-items:center; justify-content:center; font-size:18px; color:var(--fg); text-decoration:none; }
  header h1 { font-size:17px; margin:0; flex:1; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  #dot { width:8px; height:8px; border-radius:50%; background:var(--err); flex:none; }
  #dot.ok { background:var(--ok); }
  main { padding:16px 14px; max-width:640px; margin:0 auto; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:16px; padding:14px; margin-bottom:14px; }
  .card h2 { font-size:15px; margin:0 0 10px; color:var(--accent); font-weight:600; }
  label { display:block; font-size:13px; color:var(--muted); margin:10px 0 4px; }
  input, textarea, select { width:100%; background:#0d1015; color:var(--fg); border:1px solid var(--line); border-radius:10px; padding:11px 12px; font-size:15px; font-family:inherit; }
  textarea { min-height:120px; resize:vertical; }
  button { width:100%; margin-top:12px; background:var(--accent); color:#04121d; border:0; border-radius:12px; padding:13px; font-size:16px; font-weight:700; }
  button.ghost { background:#232a36; color:var(--fg); font-weight:600; }
  button.danger { background:#3a1d20; color:var(--err); font-weight:600; }
  button:active { opacity:.75; }
  .grid2 { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
  .hint { font-size:12px; color:var(--muted); margin-top:6px; }
  .tiles { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
  .tile { display:flex; flex-direction:column; gap:4px; background:var(--card); border:1px solid var(--line); border-radius:14px; padding:14px; color:var(--fg); text-decoration:none; }
  .tile b { font-size:15px; } .tile span { font-size:12px; color:var(--muted); }
  .item { display:flex; align-items:center; gap:10px; background:#0d1015; border:1px solid var(--line); border-radius:12px; padding:12px; margin-bottom:8px; color:var(--fg); text-decoration:none; }
  .item .name { flex:1; font-size:15px; } .item .arr { color:var(--muted); }
  #toast { position:fixed; left:50%; bottom:calc(86px + env(safe-area-inset-bottom)); transform:translateX(-50%) translateY(150%); background:#111827; border:1px solid var(--line); color:var(--fg); padding:12px 18px; border-radius:999px; font-size:14px; transition:transform .25s ease; max-width:92vw; text-align:center; z-index:20; }
  #toast.show { transform:translateX(-50%) translateY(0); }
  #toast.ok { border-color:var(--ok); } #toast.err { border-color:var(--err); }
  nav { position:fixed; left:0; right:0; bottom:0; background:var(--bg); border-top:1px solid var(--line); display:flex; justify-content:space-around; padding:8px 4px calc(8px + env(safe-area-inset-bottom)); z-index:15; }
  nav a { display:flex; flex-direction:column; align-items:center; gap:2px; color:var(--muted); text-decoration:none; font-size:11px; min-width:44px; }
  nav a i { font-style:normal; font-size:19px; }
  nav a.active { color:var(--accent); }
</style>
</head>
<body>
<header>
  <a class="back" id="back" href="#/" aria-label="返回">‹</a>
  <h1 id="title">PureLive 局域网同步</h1>
  <span id="dot" title="连接状态"></span>
</header>
<main id="view"></main>

<nav id="nav"></nav>
<div id="toast"></div>
<script>
// ---------------------------------------------------------------------------
// Shell: hash router, each page owns its DOM and its mount/unmount lifecycle.
// ---------------------------------------------------------------------------
const $ = (id) => document.getElementById(id);
const view = $('view');
let toastTimer;
function toast(message, kind) {
  const el = $('toast');
  el.textContent = message;
  el.className = 'show ' + (kind || '');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.className = ''; }, 2600);
}
async function api(path, options) {
  const response = await fetch(path, options);
  const text = await response.text();
  let body = null;
  try { body = text ? JSON.parse(text) : null; } catch (e) { body = null; }
  if (!response.ok || (body && body.code && body.code !== 200)) {
    throw new Error((body && body.msg) || ('HTTP ' + response.status));
  }
  return body ? body.data : null;
}
function post(path, data) {
  return api(path, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) });
}
async function channel(name) {
  try { return await api('/api/channel/' + name); } catch (e) { return null; }
}
async function saveChannel(name, data, done) {
  try { await post('/api/channel/' + name, data); toast(done || '已同步到电视', 'ok'); return true; }
  catch (e) { toast('失败：' + e.message, 'err'); return false; }
}
function send(kind) {
  const value = $(kind).value.trim();
  if (!value) { toast('请先输入内容', 'err'); return; }
  post('/api/search/' + kind, value).then(() => toast('已推送到电视', 'ok')).catch((e) => toast('失败：' + e.message, 'err'));
}
function h(html) { const t = document.createElement('template'); t.innerHTML = html.trim(); return t.content.firstChild; }
function wire(root) {
  root.querySelectorAll('[data-send]').forEach((b) => b.addEventListener('click', () => send(b.dataset.send)));
  root.querySelectorAll('[data-act]').forEach((b) => b.addEventListener('click', () => actions[b.dataset.act](b)));
}

// Every page: { title, icon, nav?, render(): DOM, mount?(): async load, unmount?() }.
// `mount` runs after the page is on screen (data loads belong to the page being
// open); `unmount` runs before the next page replaces it. A token guards async
// loads so a slow fetch can never write into a page the user already left.
let pageToken = 0;
const sites = [
  ['bilibili', '哔哩哔哩'], ['huya', '虎牙'], ['douyin', '抖音'], ['kuaishou', '快手'],
  ['yy', 'YY'], ['soop', 'SOOP'], ['twitch', 'Twitch'],
];

const pages = {
  '/': {
    title: 'PureLive 局域网同步',
    render() {
      return h(`<div>
        <div class="card">
          <h2>选择功能</h2>
          <div class="tiles">
            <a class="tile" href="#/search"><b>🔍 搜索推送</b><span>把主播、房间或影视推到电视</span></a>
            <a class="tile" href="#/cookie"><b>🍪 平台 Cookie</b><span>逐个平台粘贴登录凭证</span></a>
            <a class="tile" href="#/iptv"><b>📺 IPTV 直播源</b><span>播放列表地址与请求头</span></a>
            <a class="tile" href="#/proxy"><b>🌐 网络代理</b><span>接口与播放代理</span></a>
            <a class="tile" href="#/danmaku"><b>💬 弹幕屏蔽词</b><span>每行一个关键词</span></a>
            <a class="tile" href="#/tags"><b>🏷 标签</b><span>自定义房间标签</span></a>
            <a class="tile" href="#/sync"><b>⚙️ 配置管理</b><span>读取 / 写入 / 下载 / 清除</span></a>
          </div>
        </div>
        <div class="card"><h2>电视</h2><div class="hint" id="tvinfo">正在连接电视…</div></div>
      </div>`);
    },
    async mount(root) {
      const token = pageToken;
      try {
        const status = await api('/api/remote-sync/status');
        if (token !== pageToken) return;
        $('dot').classList.add('ok');
        $('tvinfo').textContent = '已连接：' + status.name + '（' + status.ip + ':' + status.port + '）';
      } catch (e) {
        if (token !== pageToken) return;
        $('tvinfo').textContent = '连接电视失败，请确认手机与电视在同一局域网。';
      }
    },
  },

  '/search': {
    title: '搜索 / 推送',
    nav: true,
    render() {
      return h(`<div>
        <div class="card">
          <h2>搜索</h2>
          <label>主播或关键词（推送到电视的搜索框）</label>
          <input id="streamer" placeholder="例如：张大仙" autocomplete="off">
          <button data-send="streamer">推送到搜索框</button>
        </div>
        <div class="card">
          <h2>直接打开</h2>
          <label>直播间号或链接</label>
          <input id="room" placeholder="房间号或直播间链接" autocomplete="off">
          <button class="ghost" data-send="room">推送房间</button>
          <label>影视名称或链接</label>
          <input id="movie" placeholder="影视名称或播放链接" autocomplete="off">
          <button class="ghost" data-send="movie">推送影视</button>
        </div>
      </div>`);
    },
  },

  '/cookie': {
    title: '平台 Cookie',
    nav: true,
    render() {
      const items = sites.map(([id, name]) =>
        '<a class="item" href="#/cookie/' + id + '"><span class="name">' + name + '</span><span class="arr">›</span></a>').join('');
      return h('<div><div class="card"><h2>选择平台</h2>' + items +
        '<div class="hint">逐个平台粘贴 Cookie，互不影响。</div></div></div>');
    },
  },

  '/iptv': {
    title: 'IPTV 直播源',
    nav: true,
    render() {
      return h(`<div>
        <div class="card">
          <h2>导入直播源</h2>
          <label>播放列表地址（m3u / txt）</label>
          <input id="iptv_url" placeholder="http://…/playlist.m3u" autocomplete="off">
          <label>名称</label>
          <input id="iptv_name" placeholder="留空则用地址命名" autocomplete="off">
          <label>请求头（每行一个，key: value）</label>
          <textarea id="iptv_headers" placeholder="user-agent: okhttp/3.12&#10;referer: http://example.com/&#10;cookie: a=b"></textarea>
          <div class="hint">导入后这些请求头会写到该源的每个频道上。</div>
          <button data-act="saveIptv">导入到电视</button>
        </div>
      </div>`);
    },
  },

  '/proxy': {
    title: '网络代理',
    nav: true,
    async mount(root) {
      const token = pageToken;
      const data = (await channel('proxy')) || {};
      if (token !== pageToken || !root.isConnected) return;
      $('p_enable').value = String(!!data.enableProxy);
      $('p_host').value = data.proxyHost || '';
      $('p_port').value = data.proxyPort || '';
      $('p_enable_app').value = String(!!data.enableAppProxy);
      $('p_app_host').value = data.appProxyHost || '';
      $('p_app_port').value = data.appProxyPort || '';
    },
    render() {
      return h(`<div>
        <div class="card">
          <h2>网络代理</h2>
          <div class="grid2">
            <div><label>接口请求代理</label><select id="p_enable"><option value="false">关闭</option><option value="true">开启</option></select></div>
            <div><label>代理地址</label><input id="p_host" placeholder="127.0.0.1" autocomplete="off"></div>
            <div><label>端口</label><input id="p_port" inputmode="numeric" placeholder="7897"></div>
            <div><label>播放代理</label><select id="p_enable_app"><option value="false">关闭</option><option value="true">开启</option></select></div>
            <div><label>播放代理地址</label><input id="p_app_host" placeholder="127.0.0.1" autocomplete="off"></div>
            <div><label>播放代理端口</label><input id="p_app_port" inputmode="numeric" placeholder="7897"></div>
          </div>
          <button data-act="saveProxy">保存代理</button>
        </div>
      </div>`);
    },
  },

  '/danmaku': {
    title: '弹幕屏蔽词',
    nav: true,
    async mount(root) {
      const token = pageToken;
      const data = (await channel('danmaku_filter')) || {};
      if (token !== pageToken || !root.isConnected) return;
      $('filters').value = Array.isArray(data) ? data.join('\n') : (data.filters || []).join('\n');
    },
    render() {
      return h(`<div>
        <div class="card">
          <h2>弹幕屏蔽词</h2>
          <label>每行一个（保存后整体替换）</label>
          <textarea id="filters" placeholder="加群&#10;广告"></textarea>
          <button data-act="saveFilters">保存屏蔽词</button>
        </div>
      </div>`);
    },
  },

  '/tags': {
    title: '标签',
    nav: true,
    async mount(root) {
      const token = pageToken;
      const data = (await channel('tags')) || {};
      if (token !== pageToken || !root.isConnected) return;
      const list = Array.isArray(data) ? data : (data.tags || []);
      $('tags_existing').textContent = list.length
        ? '已有：' + list.map((t) => t && t.name ? t.name : t).join('、')
        : '还没有自定义标签。';
    },
    render() {
      return h(`<div>
        <div class="card">
          <h2>添加标签</h2>
          <label>每行一个，可写「名称: 说明」</label>
          <textarea id="tags" placeholder="电竞: 比赛&#10;音乐"></textarea>
          <button data-act="saveTags">添加标签</button>
          <div class="hint" id="tags_existing"></div>
        </div>
      </div>`);
    },
  },

  '/sync': {
    title: '配置管理',
    nav: true,
    render() {
      return h(`<div>
        <div class="card">
          <h2>电视配置</h2>
          <textarea id="settings" placeholder='点「读取电视配置」，或在这里粘贴配置 JSON'></textarea>
          <div class="grid2">
            <button class="ghost" data-act="loadSettings">读取电视配置</button>
            <button class="ghost" data-act="downloadSettings">下载配置文件</button>
            <button data-act="importSettings">写入电视配置</button>
            <button class="danger" data-act="clearData">清除同步数据</button>
          </div>
          <label>从手机选择配置文件</label>
          <input type="file" id="settings_file" accept=".txt,.json">
          <div class="hint">配置文件格式与「备份与恢复」一致（.txt 内是 JSON），可存到手机或再写回电视。「清除同步数据」只清 Cookie 和弹幕屏蔽词，其余设置不动。</div>
        </div>
      </div>`);
    },
  },
};

// /cookie/<site> pages are generated, one per platform.
for (const [siteId, siteName] of sites) {
  pages['/cookie/' + siteId] = {
    title: siteName + ' Cookie',
    async mount(root) {
      const token = pageToken;
      const data = (await channel('cookie')) || {};
      if (token !== pageToken || !root.isConnected) return;
      $('site_cookie').value = data[siteId] || '';
    },
    render() {
      return h(`<div>
        <div class="card">
          <h2>${siteName}</h2>
          <label>Cookie</label>
          <textarea id="site_cookie" placeholder="粘贴 ${siteName} 的 Cookie" autocomplete="off"></textarea>
          <div class="grid2">
            <button data-act="saveSiteCookie">保存</button>
            <button class="ghost" data-act="clearSiteCookie">清除</button>
          </div>
          <div class="hint">「清除」会把电视上这一平台的 Cookie 置空。</div>
        </div>
      </div>`);
    },
  };
}

// ---------------------------------------------------------------------------
// Actions shared by pages (bound through data-act).
// ---------------------------------------------------------------------------
let currentSite = null;
const actions = {
  async saveIptv() {
    const url = $('iptv_url').value.trim();
    if (!url) { toast('请填写播放列表地址', 'err'); return; }
    const headers = {};
    for (const line of $('iptv_headers').value.split('\n')) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      const at = trimmed.indexOf(':');
      if (at <= 0) continue;
      headers[trimmed.slice(0, at).trim()] = trimmed.slice(at + 1).trim();
    }
    const ok = await saveChannel('iptv', { url: url, name: $('iptv_name').value.trim(), headers: headers }, '已开始导入直播源');
    if (ok) location.hash = '#/iptv';
  },
  async saveProxy() {
    await saveChannel('proxy', {
      enableProxy: $('p_enable').value === 'true',
      proxyHost: $('p_host').value.trim(),
      proxyPort: parseInt($('p_port').value, 10) || 7897,
      enableAppProxy: $('p_enable_app').value === 'true',
      appProxyHost: $('p_app_host').value.trim(),
      appProxyPort: parseInt($('p_app_port').value, 10) || 7897,
    }, '代理已保存');
  },
  async saveFilters() {
    const filters = $('filters').value.split('\n').map((line) => line.trim()).filter(Boolean);
    await saveChannel('danmaku_filter', { filters: filters }, '屏蔽词已保存');
  },
  async saveTags() {
    const tags = $('tags').value.split('\n').map((line) => line.trim()).filter(Boolean).map((line) => {
      const at = line.indexOf(':');
      return at > 0 ? { name: line.slice(0, at).trim(), description: line.slice(at + 1).trim() } : { name: line, description: '' };
    });
    if (!tags.length) { toast('请先输入标签', 'err'); return; }
    if (await saveChannel('tags', { tags: tags }, '标签已同步')) {
      $('tags').value = '';
      const list = (await channel('tags')) || [];
      const names = (Array.isArray(list) ? list : list.tags || []).map((t) => t && t.name ? t.name : t);
      $('tags_existing').textContent = names.length ? '已有：' + names.join('、') : '还没有自定义标签。';
    }
  },
  async saveSiteCookie() {
    const value = $('site_cookie').value.trim();
    if (!value) { toast('请先粘贴 Cookie', 'err'); return; }
    if (await saveChannel('cookie', { site: currentSite, data: value }, 'Cookie 已保存')) location.hash = '#/cookie';
  },
  async clearSiteCookie() {
    if (!confirm('清除电视上这一平台的 Cookie？')) return;
    if (await saveChannel('cookie', { site: currentSite, data: '' }, '已清除')) location.hash = '#/cookie';
  },
  async loadSettings() {
    try {
      const data = await api('/api/remote-sync/settings');
      $('settings').value = JSON.stringify(data, null, 2);
      toast('已读取电视配置', 'ok');
    } catch (e) { toast('失败：' + e.message, 'err'); }
  },
  downloadSettings() {
    let text = $('settings').value;
    if (!text.trim()) { toast('请先读取电视配置', 'err'); return; }
    const blob = new Blob([text], { type: 'text/plain' });
    const a = document.createElement('a');
    const now = new Date();
    const pad = (n) => String(n).padStart(2, '0');
    a.href = URL.createObjectURL(blob);
    a.download = 'purelive_' + now.getFullYear() + '-' + pad(now.getMonth() + 1) + '-' + pad(now.getDate()) +
      'T' + pad(now.getHours()) + '_' + pad(now.getMinutes()) + '_' + pad(now.getSeconds()) + '.txt';
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 4000);
    toast('配置文件已下载', 'ok');
  },
  async importSettings() {
    let parsed;
    try { parsed = JSON.parse($('settings').value); } catch (e) { toast('JSON 格式不正确', 'err'); return; }
    const body = (parsed && parsed.settings) ? parsed : { settings: parsed };
    try {
      await post('/api/remote-sync/settings', body);
      toast('配置已写入电视', 'ok');
    } catch (e) { toast('失败：' + e.message, 'err'); }
  },
  async clearData() {
    if (!confirm('清除电视上的 Cookie 和弹幕屏蔽词？其他设置不受影响。')) return;
    let ok = 0;
    for (const [site] of sites) {
      try { await post('/api/channel/cookie', { site: site, data: '' }); ok++; } catch (e) {}
    }
    try { await post('/api/channel/danmaku_filter', { filters: [] }); ok++; } catch (e) {}
    toast(ok ? '已清除（Cookie + 屏蔽词）' : '清除失败', ok ? 'ok' : 'err');
  },
};

// File → textarea, for writing a downloaded config back from #/sync.
document.addEventListener('change', (event) => {
  const file = event.target.files && event.target.files[0];
  const target = $('settings');
  if (!file || !target) return;
  const reader = new FileReader();
  reader.onload = () => { target.value = reader.result; toast('已读取文件', 'ok'); };
  reader.readAsText(file);
});

// ---------------------------------------------------------------------------
// Router: leaving a page unmounts it (its DOM and pending loads die with it);
// entering one renders it fresh and runs its own load.
// ---------------------------------------------------------------------------
const navEntries = [
  ['#/', '首页', '🏠'], ['#/search', '搜索', '🔍'], ['#/cookie', 'Cookie', '🍪'],
  ['#/iptv', '直播源', '📺'], ['#/proxy', '代理', '🌐'], ['#/sync', '配置', '⚙️'],
];
const nav = $('nav');
for (const [href, label, icon] of navEntries) {
  const a = document.createElement('a');
  a.href = href;
  a.dataset.target = href.slice(1);
  a.innerHTML = '<i>' + icon + '</i>' + label;
  nav.appendChild(a);
}

function route() {
  let path = location.hash.replace(/^#/, '') || '/';
  if (path === '/index.html' || path === '/remote') path = '/';
  const page = pages[path] || pages[path.replace(/\/$/, '')] || null;
  pageToken++;
  view.innerHTML = '';
  if (!page) { location.hash = '#/'; return; }

  document.title = page.title + ' · PureLive';
  $('title').textContent = page.title;
  $('back').href = path === '/cookie' || path === '/' ? '#/' : '#/';
  $('back').style.visibility = path === '/' ? 'hidden' : 'visible';
  for (const a of nav.querySelectorAll('a')) {
    a.classList.toggle('active', a.dataset.target === path || (path.startsWith('/cookie') && a.dataset.target === '/cookie'));
  }

  if (path.startsWith('/cookie/')) currentSite = path.split('/')[2];

  const root = page.render();
  view.appendChild(root);
  wire(root);
  if (page.mount) page.mount(root);
}

window.addEventListener('hashchange', route);
route();

// Connection dot: green once the TV answers, red until then.
api('/api/remote-sync/status').then(() => $('dot').classList.add('ok')).catch(() => {});
</script>
</body>
</html>
''';
