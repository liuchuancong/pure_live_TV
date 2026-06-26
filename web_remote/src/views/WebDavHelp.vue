<template>
  <div class="page-container">
    <!-- 顶部标题栏 -->
    <header class="page-header">
      <h1 class="header-title">坚果云 WebDAV 绑定教程</h1>
    </header>

    <div class="scroll-body">
      <!-- 一、前言 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <BookOpen class="title-icon" />
          一、前言（必看）
        </h2>
        <div class="card">
          <p class="desc-text">
            坚果云是目前国内最稳定、支持WebDAV免费同步的云盘。
            <br />
            <br />
            免费用户权益：
            <br />
            • 永久存储空间：3GB
            <br />
            • 每月上传流量：1GB（次月刷新）
            <br />
            <br />
            WebDAV用途：给各类播放器、笔记、APP、配置文件做云同步、云备份。
          </p>
        </div>
      </section>

      <!-- 二、核心参数 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <Pin class="title-icon" />
          二、WebDAV三项核心参数（点击复制）
        </h2>
        <div class="card param-card">
          <div class="param-row">
            <div class="param-left">
              <Link2 class="param-icon primary" />
              <div class="param-text">
                <div class="param-label">WebDAV 服务器地址</div>
                <div class="param-link" @click="openUrl(davUrl)">
                  {{ davUrl }}
                </div>
              </div>
            </div>
            <div class="copy-btn" @click="copyText(davUrl)">
              <Copy size="18" />
            </div>
          </div>
          <div class="divider"></div>
          <div class="param-row">
            <div class="param-left">
              <Mail class="param-icon primary" />
              <div class="param-text">
                <div class="param-label">用户名</div>
                <div class="param-sub">坚果云注册邮箱（禁止填写手机号）</div>
              </div>
            </div>
          </div>
          <div class="divider"></div>
          <div class="param-row">
            <div class="param-left">
              <Lock class="param-icon primary" />
              <div class="param-text">
                <div class="param-label">WebDAV应用密码</div>
                <div class="param-sub">16位第三方应用密码≠账号登录密码</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- 三、注册教程 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <FileText class="title-icon" />
          三、坚果云账号注册教程（新手从零开始）
        </h2>
        <StepCard
          :step-content="['1. 进入官网：浏览器打开 https://www.jianguoyun.com', '2. 点击右上角【注册】，推荐邮箱注册（WebDAV必须依赖邮箱账号）', '3. 填写常用邮箱、设置登录密码、绑定手机号收验证码', '⚠️ 注册完成后，前往邮箱点击验证链接激活账号']"
          :img-src="img00"
          @preview="previewImage(img00)"
        />
        <div class="space"></div>
        <StepCard :step-content="['补充：注册页填写邮箱与个人信息']" :img-src="img02" @preview="previewImage(img02)" />
      </section>

      <!-- 四、网页登录 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <Shield class="title-icon" />
          四、网页端登录教程
        </h2>
        <StepCard :step-content="['1. WebDAV密码仅能在网页端生成，必须浏览器网页登录', '2. 账号填注册邮箱 + 网页登录密码完成登录']" :img-src="img03" @preview="previewImage(img03)" />
      </section>

      <!-- 五、生成应用密码 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <KeyRound class="title-icon" />
          五、关键步骤：生成WebDAV第三方应用密码
        </h2>
        <StepCard :step-content="['1. 网页右上角头像 → 点击【账户信息】']" :img-src="img01" @preview="previewImage(img01)" />
        <div class="space"></div>
        <StepCard :step-content="['2. 左侧菜单栏打开【安全选项】']" :img-src="img04" @preview="previewImage(img04)" />
        <div class="space"></div>
        <StepCard :step-content="['3. 下拉找到【第三方应用与设备管理】', '4. 点击【添加应用密码】，自定义名称如PureLive，权限默认读写']" :img-src="img05" @preview="previewImage(img05)" />
        <div class="space"></div>
        <StepCard :step-content="['5. 生成16位随机密码，立刻复制保存，密码仅展示一次，丢失需重开']" :img-src="img06" @preview="previewImage(img06)" />
      </section>

      <!-- 六、通用绑定 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <Settings class="title-icon" />
          六、任意软件WebDAV通用绑定教程
        </h2>
        <div class="card">
          <p class="desc-text">
            所有APP统一填写规则：
            <br />
            • 服务器：https://dav.jianguoyun.com/dav/
            <br />
            • 账号：坚果云注册邮箱
            <br />
            • 密码：生成的第三方应用密码
            <br />
            <br />
            可选子目录分类（推荐）：
            <br />
            示例播放器专用：https://dav.jianguoyun.com/dav/purelive/
            <br />
            填写后云端自动创建文件夹，文件分类不乱
          </p>
        </div>
      </section>

      <!-- 七、常见报错 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <HelpCircle class="title-icon" />
          七、常见报错与解决
        </h2>
        <div class="card qa-card">
          <div v-for="(item, idx) in qaList" :key="idx" class="qa-item">
            <div class="q">{{ item.q }}</div>
            <div class="a">{{ item.a }}</div>
          </div>
        </div>
      </section>

      <!-- 八、懒人总结 -->
      <section class="section-wrap">
        <h2 class="section-title">
          <CheckCircle class="title-icon" />
          八、快速总结（懒人复制版）
        </h2>
        <div class="card">
          <p class="desc-text">
            WebDAV 地址：https://dav.jianguoyun.com/dav/
            <br />
            账号：坚果云注册邮箱
            <br />
            密码：网页端生成的第三方应用密码
          </p>
        </div>
        <div class="bottom-space"></div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { useNativeClipboard } from '@/composables/useNativeClipboard.js'
import { useToastStore } from '@/store/toast.js'
import StepCard from '@/components/StepCard.vue'
import { getCurrentInstance } from 'vue'

// Lucide 图标导入
import { BookOpen, Pin, Link2, Copy, Mail, Lock, FileText, Shield, KeyRound, Settings, HelpCircle, CheckCircle } from 'lucide-vue-next'
const { proxy } = getCurrentInstance()
// 图片统一 import 引入（按要求）
import img00 from '@/assets/webdav/00_home.png'
import img01 from '@/assets/webdav/01_avatar_menu.png'
import img02 from '@/assets/webdav/02_register.png'
import img03 from '@/assets/webdav/03_login.png'
import img04 from '@/assets/webdav/04_security.png'
import img05 from '@/assets/webdav/05_add_app.png'
import img06 from '@/assets/webdav/06_get_pwd.png'

// 常量
const davUrl = 'https://dav.jianguoyun.com/dav/'
const toast = useToastStore()
const { copy } = useNativeClipboard()

// FAQ 列表
const qaList = [
  {
    q: '1.提示账号密码错误？',
    a: '用户名必须填注册邮箱，禁止手机号；密码为16位应用密码，不能填登录密码'
  },
  {
    q: '2.浏览器打开WebDAV地址解析失败？',
    a: '正常拦截！WebDAV为接口协议，仅软件调用、不支持浏览器访问，不影响APP绑定；检查末尾斜杠/、关闭代理'
  },
  {
    q: '3.无法上传、同步失败？',
    a: '免费每月1G上传流量用完次月刷新；关闭全局代理/VPN；确认应用权限为读写'
  },
  {
    q: '4.连接超时频繁断开？',
    a: '更换DNS：114.114.114.114 / 223.5.5.5；核对地址末尾必须带/'
  },
  {
    q: '5.关闭授权/重置密码？',
    a: '网页端第三方应用管理删除对应应用，授权立刻失效，需重新生成密码绑定'
  }
]

// 复制文本
const copyText = async text => {
  await copy(text)
  toast.show('复制成功，已存入剪贴板', { position: 'bottom' })
}

// 跳转网页
const openUrl = url => {
  window.open(url, '_blank')
}

const previewImage = src => {
  proxy.$preview(0, [src])
}
</script>

<style scoped>
.page-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--bg-color, #fff);
  color: var(--text-color, #333);
}
.page-header {
  padding: 16px;
  text-align: center;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}
.header-title {
  font-size: 18px;
  font-weight: 600;
  margin: 0;
}
.scroll-body {
  flex: 1;
  padding: 12px 16px;
  overflow-y: auto;
}
.section-wrap {
  margin-bottom: 24px;
}
.section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 16px;
  font-weight: 600;
  margin: 0 0 10px 4px;
}
.title-icon {
  width: 18px;
  height: 18px;
}
.card {
  padding: 16px;
  border-radius: 20px;
  background: rgba(120, 120, 120, 0.08);
  border: 0.5px solid rgba(120, 120, 120, 0.08);
}
.desc-text {
  font-size: 13.5px;
  line-height: 1.6;
  margin: 0;
}
.param-card .param-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 0;
}
.param-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.param-icon {
  width: 22px;
  height: 22px;
  color: var(--primary, #409eff);
}
.param-text {
  display: flex;
  flex-direction: column;
}
.param-label {
  font-size: 14px;
  font-weight: 600;
}
.param-sub {
  font-size: 12px;
  color: #888;
}
.param-link {
  font-size: 13px;
  color: #0066cc;
  text-decoration: underline;
  cursor: pointer;
}
.copy-btn {
  padding: 4px;
  cursor: pointer;
  opacity: 0.7;
}
.copy-btn:hover {
  opacity: 1;
}
.divider {
  height: 0.6px;
  background: rgba(120, 120, 120, 0.15);
  margin: 0 16px;
}
.space {
  height: 16px;
}
.bottom-space {
  height: 40px;
}
.qa-item {
  padding: 7px 0;
}
.q {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--primary, #409eff);
}
.a {
  font-size: 12.5px;
  line-height: 1.5;
  color: #666;
  margin-top: 5px;
}
</style>
