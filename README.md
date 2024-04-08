
<h1 align="center">
  <br>
  <img src="https://github.com/liuchuancong/pure_live/blob/master/assets/icons/icon.png" width="150"/>
  <br>
  纯粹直播
  <br>
</h1>
<h4 align="center">第三方直播播放器</h4>
<h4 align="center">A Third-party Live Stream Player</h4>
<p align="center">
	<img alt="Using GPL-v3" src="https://img.shields.io/github/license/liuchuancong/pure_live">
	<img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/liuchuancong/pure_live">
  <img alt="GitHub Star" src="https://img.shields.io/github/stars/liuchuancong/pure_live">
  <h4 align="center">本软件仅供学习交流使用  请勿用于其他用途</h4>
	<h4 align="center">下载后请在24小时内删除</h4>
</p>

## 支持平台

***哔哩哔哩***/***虎牙***/***斗鱼***/***快手***/***抖音***/***网易cc***/***M38自定义源***
可以选择喜爱的分区展示，或者全隐藏，只看关注，节省流量与内存
## 功能

- [X] 使用[supabase](https://supabase.com/) 完成登录注册功能,邮箱为真实邮箱  ***白名单使用（发送注册账号到我的邮箱认证 - 点击联系）*** 您可自己fork项目去supabase控制台生成远程服务，具体不在赘述，只提供表字段。
- [X] **平台管理** 多种平台选择喜欢的展示
- [X] 已实现**Android**/**TV**/**Windows**（TV bug较多，光标比较难用，建议使用鼠标或WebServer。）
- [X] 已实现**WevServer**（局域网连接使用手机可控制设备，切勿连点影响程序正常使用）  
- [X] 已实现倒计时关闭应用
- [X] **Android** 端多种播放器随意切换
- [X] **M3u8** 自定义导入网络/本地直播源，可直接使用APP打开,观看自定义内容。（导入请先打开App） 设置-本地导入-导入m3u源 部分资源请云盘自行导入 [123云盘](https://www.123pan.com/s/Jucxjv-NwYYd.html)
- [X] 弹幕过滤，弹幕合并

## 下载

请使用 123云盘 进行下载
下载地址 [纯粹直播](https://www.123pan.com/s/Jucxjv-NwYYd.html)

蓝奏云已不在维护

下载地址 [纯粹直播](https://wwvr.lanzouw.com/b01f6rqab)

密码 **40l9** (英文小写**L**不是数字**1**)

注意：在windows第一次安装时请审查安装说明`readme.txt`以及`keyboard.txt`文件，如安装失败则代表不支持该系统，请升级win11后重试，后续更新仅需下载版本包即可，采用非强制更新，更新提示可以在设置中关闭.

手机尽量下载**v8a**的安装包，适配新机器，老机器以及TV下载**v7a**，不知道的可以搜一下自己机器的CPU架构，X86模拟器使用，部分TV无法登陆或者光标显示不全可以用**鼠标**连接盒子或电视USB操作。

## 声明

本软件非盈利性软件,且遵循 [**GPL-v3**](LICENSE) 协议,请勿将此软件用于商业用途.

本软件**不提供** VIP  视频破解等服务, 如需高清播放，你需要在对应平台取得相应身份才能进行播放

所有内容资源 (包括但不限于音源，视频, 图片等) 版权归各平台所有

本软件仅学习交流使用. 如有侵权,请发 Issue 提出.

## 隐私策略

本App为开源项目,无广告，无病毒，若安装时出现病毒误报，可自行斟酌。

## 相关说明
###
由于其他原因，华为手机用起来比较卡，框架限制暂不支持优化，希望谅解。
### 关于播放器

本软件Android内置了*ExoPlayer*,*Ijkplayer*,*Mpvplayer*,只有*ExoPlayer*支持后台播放，如果*ExoPlayer*闪退，请在设置中关闭后台播放以及更换播放器重试。

字幕：手机端您可打开手机自带的字幕工具观看字幕，windows: 任务栏搜索*Live captions*使用微软官方工具查看字幕
### Cookie

由于第三方限制，观看b站高清直播需要登陆，您可点击三方认证即可获取cookie,本软件只是代理获取拿到**cookie**,不会获取用户的任何信息，用户信息仍由第三方管理

### M3u源
您可点击设置-备份与还原-导入M3u源（一些网络电视，电影轮训等）。[直播源转换](https://guihet.com/tvlistconvert.html)
暂不支持其他目录保存
* Android端在缓存内清除缓存即可删除
* Windows 在目录`C:/Users/用户名/AppData/Local/com.example/pure_live`下`categories.json`内修改以及删除导入的源以及定义
### 意见
[ExoPlayer](https://github.com/liuchuancong/better_player/tree/media3)由本人维护,点击进行PR以及建议。
> 如有许可协议使用不当请发 Issue 或者 Pull Request
>
> If any of the licenses are not being used correctly, please submit a new issue.
### 软件更新

因为作者忙于工作,通常只会在周末处理相关事情,目前没有mac电脑无法使用Xcode打包IOS以及MAC，有合作者可与我联系。
## 代码参考

* dart_simple_live [dart_simple_live](https://github.com/xiaoyaocz/dart_simple_live)
* pure_live [pure_live](https://github.com/Jackiu1997/pure_live)
## supabase表结构
由于是开源项目，目前很多配置文件暴露在外，导致大量机器循环调用，消耗内存以及流量，警告： 在创建项目时请结合 [https://zuplo.com/](https://zuplo.com/)使用，权限表添加允许创建的账户修改数据库。
配置在assets文件中打包的时候依然可以通过逆向解压可以查看该配置，最好写成dart代码引入，上传时忽略。
![image](https://github.com/liuchuancong/pure_live/assets/36957912/4e4fefb8-20bb-4a1f-a224-f581de3d95ec)

## 开发者

* 主开发者: [liuchuancong](https://github.com/liuchuancong)


[![Stargazers over time](https://starchart.cc/liuchuancong/pure_live.svg)](https://starchart.cc/liuchuancong/pure_live)

## 捐助

<img alt="wechat" width="250" src="https://github.com/liuchuancong/pure_live/blob/master/assets/images/wechat.png">


感谢您的支持!


