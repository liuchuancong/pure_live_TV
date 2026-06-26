// import 'package:flutter/material.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:pure_live/theme/tv_theme_x.dart';
// import 'package:pure_live/widgets/tv_button.dart';
// import 'package:pure_live/theme/styles/styles.dart';
// import 'package:pure_live/theme/tv_theme_data.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:pure_live/theme/styles/app_styles.dart';
// import 'package:native_textfield_tv/native_textfield_tv.dart';
// import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

// class MoviePlaybackPage extends ConsumerStatefulWidget {
//   const MoviePlaybackPage({super.key});

//   @override
//   ConsumerState<MoviePlaybackPage> createState() => _MoviePlaybackPageState();
// }

// class _MoviePlaybackPageState extends ConsumerState<MoviePlaybackPage> {
//   final TextEditingController _urlController = TextEditingController();
//   final FocusNode _inputFocusNode = FocusNode();

//   @override
//   void dispose() {
//     _urlController.dispose();
//     _inputFocusNode.dispose();
//     super.dispose();
//   }

//   void _parseUrl(String url) {
//     if (url.trim().isEmpty) return;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentTvTheme = context.tvTheme;
//     final serverUrl = ref.watch(fullServerUrlProvider);

//     return Column(
//       children: [
//         AppStyle.vGap32,
//         _buildHeader(currentTvTheme, serverUrl),
//         Expanded(
//           child: Row(
//             children: [
//               _buildQRCodeSection(currentTvTheme, serverUrl),
//               Container(
//                 width: 2.sp,
//                 height: 300.sp,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Colors.transparent,
//                       currentTvTheme.primaryTextColor.withValues(alpha: 0.12),
//                       Colors.transparent,
//                     ],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                 ),
//               ),
//               _buildInputSection(currentTvTheme),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHeader(TvThemeData currentTvTheme, String serverUrl) {
//     final hasServer = serverUrl.isNotEmpty;
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 48.sp),
//       child: Row(
//         children: [
//           Text(
//             "链接解析",
//             style: AppTextStyles.t28W600.copyWith(
//               fontSize: 38.sp,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 2,
//               color: currentTvTheme.primaryTextColor,
//             ),
//           ),
//           const Spacer(),
//           Container(
//             padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
//             decoration: BoxDecoration(
//               color: hasServer ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(20.sp),
//             ),
//             child: Text(
//               hasServer ? "局域网服务已启动" : "服务未启动",
//               style: TextStyle(color: hasServer ? Colors.greenAccent : Colors.redAccent, fontSize: 20.sp),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQRCodeSection(TvThemeData currentTvTheme, String serverUrl) {
//     return Expanded(
//       flex: 4,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (serverUrl.isNotEmpty) ...[
//             Container(
//                   padding: EdgeInsets.all(20.sp),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(24.sp),
//                     boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20.sp, offset: const Offset(0, 10))],
//                   ),
//                   child: QrImageView(
//                     data: serverUrl,
//                     version: QrVersions.auto,
//                     size: 320.sp,
//                     eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
//                     dataModuleStyle: const QrDataModuleStyle(
//                       dataModuleShape: QrDataModuleShape.square,
//                       color: Colors.black,
//                     ),
//                   ),
//                 )
//                 .animate()
//                 .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
//                 .scale(
//                   begin: const Offset(0.9, 0.9),
//                   end: const Offset(1.0, 1.0),
//                   duration: 350.ms,
//                   curve: Curves.easeOutBack,
//                 ),
//             AppStyle.vGap32,
//             Text(
//               "扫码远程录入",
//               style: AppTextStyles.t24W600.copyWith(
//                 fontSize: 30.sp,
//                 fontWeight: FontWeight.bold,
//                 color: currentTvTheme.primaryTextColor,
//               ),
//             ),
//             AppStyle.vGap12,
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
//               decoration: BoxDecoration(color: currentTvTheme.cardColor, borderRadius: BorderRadius.circular(8.sp)),
//               child: Text(
//                 serverUrl,
//                 style: TextStyle(color: currentTvTheme.secondaryTextColor, fontSize: 28.sp, fontFamily: "monospace"),
//               ),
//             ),
//           ] else
//             const CircularProgressIndicator(),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputSection(TvThemeData currentTvTheme) {
//     return Expanded(
//       flex: 6,
//       child: Padding(
//         padding: EdgeInsets.all(48.sp),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "在此粘贴或输入地址",
//               style: AppTextStyles.t18W500.copyWith(fontSize: 28.sp, color: currentTvTheme.secondaryTextColor),
//             ),
//             AppStyle.vGap24,
//             AndroidTVTextField(
//               focusNode: _inputFocusNode,
//               controller: _urlController,
//               hint: "等待手机扫码同步或点击输入...",
//               textColor: currentTvTheme.primaryTextColor,
//               maxLines: 3,
//               height: 160.sp,
//               backgroundColor: currentTvTheme.cardColor,
//               onSubmitted: (e) => _parseUrl(e),
//             ),
//             AppStyle.vGap40,
//             Row(
//               children: [
//                 SizedBox(
//                   width: 200.sp,
//                   child: TvButton(
//                     title: "开始解析",
//                     icon: Icon(Icons.rocket_launch_rounded, size: 28.sp),
//                     iconPosition: TvIconPosition.left,
//                     size: TvButtonSize.medium,
//                     onTap: () => _parseUrl(_urlController.text),
//                   ),
//                 ),
//                 AppStyle.hGap24,
//                 SizedBox(
//                   width: 150.sp,
//                   child: TvButton(
//                     title: "清空",
//                     icon: Icon(Icons.cleaning_services_rounded, size: 28.sp),
//                     iconPosition: TvIconPosition.left,
//                     size: TvButtonSize.medium,
//                     isSecondary: true,
//                     onTap: () => _urlController.clear(),
//                   ),
//                 ),
//               ],
//             ),
//             AppStyle.vGap48,
//             _buildSupportInfo(currentTvTheme),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSupportInfo(TvThemeData currentTvTheme) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(20.sp),
//       decoration: BoxDecoration(
//         color: currentTvTheme.cardColor.withValues(alpha: 0.5),
//         borderRadius: BorderRadius.circular(16.sp),
//         border: Border.all(color: currentTvTheme.cardColor.withValues(alpha: 0.2)),
//       ),
//       child: Wrap(
//         spacing: 16.sp,
//         runSpacing: 8.sp,
//         children: ["Bilibili", "Douyu", "Huya", "Douyin", "Kuaishou", "CC"]
//             .map(
//               (e) => Text(
//                 e,
//                 style: AppTextStyles.t18W600.copyWith(
//                   color: currentTvTheme.secondaryTextColor.withValues(alpha: 0.5),
//                   fontSize: 25.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             )
//             .toList(),
//       ),
//     );
//   }
// }
