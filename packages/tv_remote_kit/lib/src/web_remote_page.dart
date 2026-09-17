/// The page the phone opens after scanning the QR — no build step, no CDN, one file.
///
/// It talks to the same HTTP API the mobile app uses (`/api/channel/<name>`,
/// `/api/search/streamer`, …), so a browser becomes a second client of the LAN sync
/// service: cookies, IPTV playlists with their request headers, WebDAV, the network
/// proxy, danmaku filters and tags are all typed on the phone and land in the TV's own
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
  body { margin:0; background:var(--bg); color:var(--fg); font:16px/1.5 -apple-system,"PingFang SC","Microsoft YaHei",system-ui,sans-serif; padding:16px 14px 48px; }
  h1 { font-size:20px; margin:4px 0 2px; }
  .sub { color:var(--muted); font-size:13px; margin-bottom:16px; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:16px; padding:14px; margin-bottom:14px; }
  .card h2 { font-size:15px; margin:0 0 10px; color:var(--accent); font-weight:600; }
  label { display:block; font-size:13px; color:var(--muted); margin:10px 0 4px; }
  input, textarea, select { width:100%; background:#0d1015; color:var(--fg); border:1px solid var(--line); border-radius:10px; padding:11px 12px; font-size:15px; font-family:inherit; }
  textarea { min-height:88px; resize:vertical; }
  .row { display:flex; gap:10px; }
  .row > * { flex:1; }
  button { width:100%; margin-top:12px; background:var(--accent); color:#04121d; border:0; border-radius:12px; padding:13px; font-size:16px; font-weight:700; }
  button.ghost { background:#232a36; color:var(--fg); font-weight:600; }
  button:active { opacity:.75; }
  .grid2 { display:grid; grid-template-columns:1fr 1fr; gap:10px; }
  #toast { position:fixed; left:50%; bottom:24px; transform:translateX(-50%) translateY(120%); background:#111827; border:1px solid var(--line); color:var(--fg); padding:12px 18px; border-radius:999px; font-size:14px; transition:transform .25s ease; max-width:92vw; text-align:center; }
  #toast.show { transform:translateX(-50%) translateY(0); }
  #toast.ok { border-color:var(--ok); } #toast.err { border-color:var(--err); }
  .hint { font-size:12px; color:var(--muted); margin-top:6px; }
  details { margin-top:10px; } summary { color:var(--muted); font-size:13px; }
</style>
</head>
<body>
<h1>PureLive 局域网同步</h1>
<div class="sub" id="status">正在连接电视…</div>

<div class="card">
  <h2>搜索 / 推送</h2>
  <label>主播或关键词（推送到电视的搜索框）</label>
  <input id="streamer" placeholder="例如：张大仙" autocomplete="off">
  <button onclick="send('streamer')">推送到搜索框</button>
  <details>
    <summary>房间号 / 影视链接</summary>
    <label>直播间号或链接</label>
    <input id="room" placeholder="房间号或直播间链接" autocomplete="off">
    <button class="ghost" onclick="send('room')">推送房间</button>
    <label>影视名称或链接</label>
    <input id="movie" placeholder="影视名称或播放链接" autocomplete="off">
    <button class="ghost" onclick="send('movie')">推送影视</button>
  </details>
</div>

<div class="card">
  <h2>平台 Cookie</h2>
  <div class="grid2">
    <div><label>哔哩哔哩</label><input id="c_bilibili" autocomplete="off"></div>
    <div><label>虎牙</label><input id="c_huya" autocomplete="off"></div>
    <div><label>抖音</label><input id="c_douyin" autocomplete="off"></div>
    <div><label>快手</label><input id="c_kuaishou" autocomplete="off"></div>
    <div><label>YY</label><input id="c_yy" autocomplete="off"></div>
    <div><label>SOOP</label><input id="c_soop" autocomplete="off"></div>
    <div><label>Twitch</label><input id="c_twitch" autocomplete="off"></div>
  </div>
  <div class="hint">留空的平台不会被修改。</div>
  <button onclick="saveCookies()">保存 Cookie</button>
</div>

<div class="card">
  <h2>IPTV 直播源</h2>
  <label>播放列表地址（m3u / txt）</label>
  <input id="iptv_url" placeholder="http://…/playlist.m3u" autocomplete="off">
  <label>名称</label>
  <input id="iptv_name" placeholder="留空则用地址命名" autocomplete="off">
  <label>请求头（每行一个，key: value）</label>
  <textarea id="iptv_headers" placeholder="user-agent: okhttp/3.12&#10;referer: http://example.com/&#10;cookie: a=b"></textarea>
  <div class="hint">导入后这些请求头会写到该源的每个频道上。</div>
  <button onclick="saveIptv()">导入到电视</button>
</div>

<div class="card">
  <h2>WebDAV 备份</h2>
  <label>名称</label>
  <input id="dav_name" placeholder="我的网盘" autocomplete="off">
  <label>地址</label>
  <input id="dav_address" placeholder="https://dav.example.com/dav/" autocomplete="off">
  <div class="row">
    <div><label>用户名</label><input id="dav_user" autocomplete="off"></div>
    <div><label>密码</label><input id="dav_pass" type="password" autocomplete="off"></div>
  </div>
  <button onclick="saveWebdav()">保存到电视</button>
</div>

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
  <button onclick="saveProxy()">保存代理</button>
</div>

<div class="card">
  <h2>弹幕屏蔽词</h2>
  <label>每行一个</label>
  <textarea id="filters" placeholder="加群&#10;广告"></textarea>
  <button onclick="saveFilters()">替换屏蔽词</button>
</div>

<div class="card">
  <h2>标签</h2>
  <label>每行一个，可写「名称: 说明」</label>
  <textarea id="tags" placeholder="电竞: 比赛&#10;音乐"></textarea>
  <button onclick="saveTags()">添加标签</button>
</div>

<div class="card">
  <h2>完整设置</h2>
  <button class="ghost" onclick="exportSettings()">读取电视设置</button>
  <textarea id="settings" placeholder='{"settings": …}' style="margin-top:10px"></textarea>
  <button onclick="importSettings()">写入电视设置</button>
  <div class="hint">用于整机备份/恢复，格式与「备份与恢复」一致。</div>
</div>

<div id="toast"></div>
<script>
const $ = (id) => document.getElementById(id);
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
  try { await post('/api/channel/' + name, data); toast(done || '已同步到电视', 'ok'); }
  catch (e) { toast('失败：' + e.message, 'err'); }
}
async function send(kind) {
  const value = $(kind).value.trim();
  if (!value) { toast('请先输入内容', 'err'); return; }
  try {
    await post('/api/search/' + kind, value);
    toast('已推送到电视', 'ok');
  } catch (e) { toast('失败：' + e.message, 'err'); }
}
const sites = ['bilibili','huya','douyin','kuaishou','yy','soop','twitch'];
async function saveCookies() {
  const current = (await channel('cookie')) || {};
  const changed = {};
  const cleared = {};
  for (const site of sites) {
    const value = $('c_' + site).value.trim();
    if (!value) continue;
    const previous = (current[site] || '').trim();
    if (previous === value) continue;
    // The channel applies one site per request; a leading "!" clears it.
    changed[site] = value;
    cleared[site] = previous;
  }
  const names = Object.keys(changed);
  if (!names.length) { toast('没有需要保存的改动', 'err'); return; }
  let ok = 0;
  for (const site of names) {
    try { await post('/api/channel/cookie', { site: site, data: changed[site] }); ok++; }
    catch (e) { toast(site + ' 保存失败：' + e.message, 'err'); }
  }
  if (ok) toast('已保存 ' + ok + ' 个平台的 Cookie', 'ok');
  loadCookies();
}
async function loadCookies() {
  const data = (await channel('cookie')) || {};
  for (const site of sites) {
    if (data[site]) $('c_' + site).value = data[site];
  }
}
function parseHeaders(text) {
  const headers = {};
  for (const line of text.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const at = trimmed.indexOf(':');
    if (at <= 0) continue;
    headers[trimmed.slice(0, at).trim()] = trimmed.slice(at + 1).trim();
  }
  return headers;
}
async function saveIptv() {
  const url = $('iptv_url').value.trim();
  if (!url) { toast('请填写播放列表地址', 'err'); return; }
  try {
    await post('/api/channel/iptv', { url: url, name: $('iptv_name').value.trim(), headers: parseHeaders($('iptv_headers').value) });
    toast('已开始导入直播源', 'ok');
  } catch (e) { toast('失败：' + e.message, 'err'); }
}
async function saveWebdav() {
  const address = $('dav_address').value.trim();
  if (!address) { toast('请填写 WebDAV 地址', 'err'); return; }
  await saveChannel('webdav', {
    name: $('dav_name').value.trim() || 'WebDAV',
    address: address,
    username: $('dav_user').value.trim(),
    password: $('dav_pass').value,
  }, 'WebDAV 已保存');
}
async function loadProxy() {
  const data = (await channel('proxy')) || {};
  $('p_enable').value = String(!!data.enableProxy);
  $('p_host').value = data.proxyHost || '';
  $('p_port').value = data.proxyPort || '';
  $('p_enable_app').value = String(!!data.enableAppProxy);
  $('p_app_host').value = data.appProxyHost || '';
  $('p_app_port').value = data.appProxyPort || '';
}
async function saveProxy() {
  await saveChannel('proxy', {
    enableProxy: $('p_enable').value === 'true',
    proxyHost: $('p_host').value.trim(),
    proxyPort: parseInt($('p_port').value, 10) || 7897,
    enableAppProxy: $('p_enable_app').value === 'true',
    appProxyHost: $('p_app_host').value.trim(),
    appProxyPort: parseInt($('p_app_port').value, 10) || 7897,
  }, '代理已保存');
}
async function saveFilters() {
  const filters = $('filters').value.split('\n').map((line) => line.trim()).filter(Boolean);
  await saveChannel('danmaku_filter', { filters: filters }, '屏蔽词已替换');
}
async function saveTags() {
  const tags = $('tags').value.split('\n').map((line) => line.trim()).filter(Boolean).map((line) => {
    const at = line.indexOf(':');
    return at > 0 ? { name: line.slice(0, at).trim(), description: line.slice(at + 1).trim() } : { name: line, description: '' };
  });
  if (!tags.length) { toast('请先输入标签', 'err'); return; }
  await saveChannel('tags', { tags: tags }, '标签已同步');
}
async function exportSettings() {
  try {
    const data = await api('/api/remote-sync/settings');
    $('settings').value = JSON.stringify(data, null, 2);
    toast('已读取电视设置', 'ok');
  } catch (e) { toast('失败：' + e.message, 'err'); }
}
async function importSettings() {
  let parsed;
  try { parsed = JSON.parse($('settings').value); } catch (e) { toast('JSON 格式不正确', 'err'); return; }
  try {
    await post('/api/remote-sync/settings', { settings: parsed });
    toast('设置已写入电视', 'ok');
  } catch (e) { toast('失败：' + e.message, 'err'); }
}
(async function boot() {
  try {
    const status = await api('/api/remote-sync/status');
    $('status').textContent = '已连接：' + status.name + '（' + status.ip + ':' + status.port + '）';
  } catch (e) {
    $('status').textContent = '连接电视失败，请确认手机与电视在同一局域网。';
  }
  loadCookies();
  loadProxy();
})();
</script>
</body>
</html>
''';
