package com.mobileai.stickerapp

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.File


/** WhatsappStickersPlugin */
public class WhatsappStickersPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var context: Context? = null
  private var stickerPackList: List<StickerPack>? = null
  private var activity: Activity? = null
  private var result: Result? = null
  val ADD_PACK = 200

  private val EXTRA_STICKER_PACK_ID = "sticker_pack_id"
  private val EXTRA_STICKER_PACK_AUTHORITY = "sticker_pack_authority"
  private val EXTRA_STICKER_PACK_NAME = "sticker_pack_name"
  private val EXTRA_STICKER_PACK_ANIMATED = "animated_sticker_pack"

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "whatsapp_stickers")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    private const val EXTRA_STICKER_PACK_ID = "sticker_pack_id"
    private const val EXTRA_STICKER_PACK_AUTHORITY = "sticker_pack_authority"
    private const val EXTRA_STICKER_PACK_NAME = "sticker_pack_name"
    private const val EXTRA_STICKER_PACK_ANIMATED = "animated_sticker_pack"
    @JvmStatic
    fun getContentProviderAuthorityURI(context: Context): Uri{
      return Uri.Builder().scheme(ContentResolver.SCHEME_CONTENT).authority(getContentProviderAuthority(context)).appendPath(StickerContentProvider.METADATA).build()
    }

    @JvmStatic
    fun getContentProviderAuthority(context: Context): String {
      return context.packageName + ".stickercontentprovider"
    }
    
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    this.result = result
    when (call.method) {
      "getPlatformVersion" ->
        result.success("Android " + android.os.Build.VERSION.RELEASE)
      "isWhatsAppInstalled" ->
        result.success(context?.let { WhitelistCheck.isWhatsAppInstalled(it) });
      "isWhatsAppConsumerAppInstalled" ->
        result.success(WhitelistCheck.isWhatsAppConsumerAppInstalled(context?.packageManager));
      "isWhatsAppSmbAppInstalled" ->
        result.success(WhitelistCheck.isWhatsAppSmbAppInstalled(context?.packageManager));
      "isStickerPackInstalled" -> {
        val stickerPackIdentifier = call.argument<String>("identifier");
        if (stickerPackIdentifier != null && context != null) {
          val installed = WhitelistCheck.isWhitelisted(context!!, stickerPackIdentifier)
          result.success(installed);
        }
      }
      "sendToWhatsApp" -> {
        try{
          val safeContext = context
          val safeActivity = activity
          if (safeContext == null || safeActivity == null) {
            result.error("no_activity", "Activity is not attached yet.", null)
            return
          }
          val stickerPack: StickerPack = ConfigFileManager.fromMethodCall(safeContext, call)
          // update json file
          ConfigFileManager.addNewPack(safeContext, stickerPack)
          StickerPackValidator.verifyStickerPackValidity(safeContext, stickerPack);
          // send intent to whatsapp
          val ws = WhitelistCheck.isWhatsAppConsumerAppInstalled(safeContext.packageManager)
          if(!(ws || WhitelistCheck.isWhatsAppSmbAppInstalled(safeContext.packageManager))){
            throw InvalidPackException(InvalidPackException.OTHER, "WhatsApp is not installed on target device!")
          }
          val whatsAppPackage = if(ws) WhitelistCheck.CONSUMER_WHATSAPP_PACKAGE_NAME else WhitelistCheck.SMB_WHATSAPP_PACKAGE_NAME
          val stickerPackIdentifier = stickerPack.identifier
          val stickerPackName = stickerPack.name
          val isAnimated = stickerPack.avoidCache
          val authority: String? = getContentProviderAuthority(safeContext)

          val intent = createIntentToAddStickerPack(authority, stickerPackIdentifier, stickerPackName, isAnimated)

          try {
            safeActivity.startActivityForResult(Intent.createChooser(intent, "ADD Sticker"), ADD_PACK)
          } catch (e: ActivityNotFoundException) {
            throw InvalidPackException(InvalidPackException.FAILED, "Sticker pack not added. If you'd like to add it, make sure you update to the latest version of WhatsApp.")
          }

        } catch (e: InvalidPackException){
          result.error(e.code, e.message, null)
        }
      }
      "setWebpLoopCount" -> {
        try {
          val filePath = call.argument<String>("filePath")
          val loopCount = call.argument<Int>("loopCount") ?: 0
          
          if (filePath == null) {
            result.error("INVALID_ARGUMENTS", "filePath is required", null)
            return
          }
          
          val success = WebpLoopHandler.setLoopCount(filePath, loopCount)
          if (success) {
            result.success(true)
          } else {
            result.error("FAILED", "Failed to set loop count", null)
          }
        } catch (e: Exception) {
          Log.e("WhatsappStickersPlugin", "Error setting WebP loop count", e)
          result.error("EXCEPTION", e.message, null)
        }
      }
      else -> result.notImplemented()
    }
  }

  fun createIntentToAddStickerPack(authority: String?, identifier: String?, stickerPackName: String?, isAnimated: Boolean = false): Intent? {
    val intent = Intent()
    intent.action = "com.whatsapp.intent.action.ENABLE_STICKER_PACK"
    intent.putExtra(this.EXTRA_STICKER_PACK_ID, identifier)
    intent.putExtra(this.EXTRA_STICKER_PACK_AUTHORITY, authority)
    intent.putExtra(this.EXTRA_STICKER_PACK_NAME, stickerPackName)
    if (isAnimated) {
      intent.putExtra(this.EXTRA_STICKER_PACK_ANIMATED, true)
    }
    
    // Debug logging
    Log.d("WhatsAppStickers", "Creating intent for pack: $stickerPackName")
    Log.d("WhatsAppStickers", "  ID: $identifier")
    Log.d("WhatsAppStickers", "  Authority: $authority")
    Log.d("WhatsAppStickers", "  Animated: $isAnimated")
    
    return intent
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == ADD_PACK) {
      when (resultCode) {
        Activity.RESULT_CANCELED -> {
          val validationError = data?.getStringExtra("validation_error")
          if (!validationError.isNullOrEmpty()) {
            this.result?.error("validation_error", validationError, null)
          } else {
            // User cancelled - trả về success với giá trị "cancelled" thay vì error
            this.result?.success("cancelled")
          }
        }
        Activity.RESULT_OK -> {
          val bundle = data?.extras
          when {
            bundle?.containsKey("add_successful") == true -> {
              this.result?.success("add_successful")
            }
            bundle?.containsKey("already_added") == true -> {
              this.result?.success("already_added")
            }
            else -> {
              this.result?.success("success")
            }
          }
        }
        else -> {
          this.result?.success("unknown")
        }
      }
      // Reset result để tránh gọi lại
      this.result = null
    }
    return true
  }
}
