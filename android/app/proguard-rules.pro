# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WhatsApp Sticker specific rules
-keep class com.mobileai.stickerapp.** { *; }
-keep class com.mobileai.stickerapp.StickerContentProvider { *; }
-keep class com.mobileai.stickerapp.StickerPack { *; }
-keep class com.mobileai.stickerapp.Sticker { *; }
-keep class com.mobileai.stickerapp.StickerPackLoader { *; }
-keep class com.mobileai.stickerapp.ContentFileParser { *; }
-keep class com.mobileai.stickerapp.ConfigFileManager { *; }
-keep class com.mobileai.stickerapp.StickerPackValidator { *; }
-keep class com.mobileai.stickerapp.WhatsappStickersPlugin { *; }

# Keep all model classes that might be serialized
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep SQLite related classes
-keep class * extends android.database.sqlite.SQLiteOpenHelper { *; }

# Keep ContentProvider classes
-keep class * extends android.content.ContentProvider { *; }

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Gson rules (if using Gson)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp rules (if using OkHttp)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Glide rules (if using Glide)
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
 <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}
-keep class com.bumptech.glide.load.data.ParcelFileDescriptorRewinder$InternalRewinder {
  *** rewind();
}

# GetX rules (if using GetX)
-keep class * extends io.flutter.embedding.android.FlutterActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity { *; }

# Image picker and photo manager rules
-keep class com.flutter.plugins.** { *; }
-keep class com.baseflow.** { *; }

# Permission handler rules
-keep class com.baseflow.permissionhandler.** { *; }

# Share_plus rules
-keep class io.flutter.plugins.** { *; }

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
    public static *** i(...);
}

# Keep all implementation of Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class androidx.annotation.Keep { *; }
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}

# Play Core library rules for Flutter Play Store Split Compatibility
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**
