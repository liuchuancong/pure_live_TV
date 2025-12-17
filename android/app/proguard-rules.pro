## 1. Flutter 引擎基礎規則
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## 2. 保持原生 MethodChannel 通訊不被混淆
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

## 3. 處理 AndroidX 和支援庫
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class androidx.** { *; }
-dontwarn androidx.**

## 4. 針對 Flutter 3.x 特定的引擎入口
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterFragment { *; }
-keep class io.flutter.embedding.android.FlutterView { *; }

## 5. 常見第三方插件兼容 (如需使用 Firebase 或 OkHttp)
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class com.fasterxml.jackson.** { *; }
-keepnames class com.google.api.** { *; }

## 6. 避免壓縮掉 Native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

-keep class tv.danmaku.ijk.media.player.** {*; }
-dontwarn tv.danmaku.ijk.media.**
-keep interface tv.danmaku.ijk.media.player.** { *; }