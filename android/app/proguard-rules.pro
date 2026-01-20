# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# App code - Giữ nguyên tất cả class trong package
-keep class com.mobileai.stickerapp.** { *; }

# ContentProvider - Bắt buộc cho WhatsApp integration
-keep class com.mobileai.stickerapp.StickerContentProvider { *; }
-keepclassmembers class com.mobileai.stickerapp.StickerContentProvider {
    public static final *;
}

# Parcelable classes - Cần giữ nguyên để serialize/deserialize
-keep class com.mobileai.stickerapp.StickerPack implements android.os.Parcelable {
    *;
    public static final android.os.Parcelable$Creator CREATOR;
}
-keep class com.mobileai.stickerapp.Sticker implements android.os.Parcelable {
    *;
    public static final android.os.Parcelable$Creator CREATOR;
}

# TensorFlow Lite - Giữ nguyên native methods và classes
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.mobileai.stickerapp.** {
    native <methods>;
}

# FFmpeg Kit - Giữ nguyên native code (plugin dùng package com.antonkarpenko.ffmpegkit)
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.ffmpegkit.**

# Kotlin - Giữ nguyên reflection và coroutines
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# GetX - Giữ nguyên reflection nếu có
-keep class com.jonataslaw.** { *; }
-dontwarn com.jonataslaw.**

# Photo Manager & Image Processing
-keep class top.kikt.** { *; }
-dontwarn top.kikt.**
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# JSON parsing - Giữ nguyên nếu dùng reflection
-keepclassmembers class * {
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
}