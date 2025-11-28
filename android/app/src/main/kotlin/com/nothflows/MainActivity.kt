package com.nothflows

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nothflows/system"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBrightness" -> {
                    val brightness = call.argument<Int>("brightness") ?: 50
                    if (setBrightness(brightness)) {
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Cannot modify system settings", null)
                    }
                }
                "setVolume" -> {
                    val level = call.argument<Int>("level") ?: 50
                    if (setVolume(level)) {
                        result.success(true)
                    } else {
                        result.error("FAILED", "Cannot set volume", null)
                    }
                }
                "requestWriteSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.System.canWrite(this)) {
                            val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                            intent.data = Uri.parse("package:$packageName")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "canWriteSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.System.canWrite(this))
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun convertToNothingBrightness(userPercent: Int): Int {
        // Nothing OS uses a non-linear brightness curve
        // User wants 0-100%, but Nothing's scale is heavily weighted toward the high end
        // We need to apply an exponential curve to match user expectations

        val percent = userPercent.coerceIn(0, 100)

        // Apply exponential curve: brightness = (percent/100)^2.2 * 255
        // This makes lower values darker and spreads out the useful range
        val normalized = percent / 100.0
        val gamma = 2.2 // Typical display gamma
        val curved = Math.pow(normalized, gamma)
        val androidValue = (curved * 255).toInt().coerceIn(1, 255)

        android.util.Log.d("NothFlows", "Nothing brightness conversion: $userPercent% -> $androidValue/255 (gamma curve applied)")
        return androidValue
    }

    private fun setBrightness(brightness: Int): Boolean {
        android.util.Log.d("NothFlows", "setBrightness called with value: $brightness")
        return try {
            // Read current brightness first
            val currentBrightness = try {
                Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, -1)
            } catch (e: Exception) {
                -1
            }
            android.util.Log.d("NothFlows", "Current system brightness before change: $currentBrightness/255 (${(currentBrightness * 100 / 255.0).toInt()}%)")

            val brightnessValue = brightness.coerceIn(0, 100)

            // Convert using Nothing-specific curve
            val androidBrightness = convertToNothingBrightness(brightnessValue)
            val normalized = androidBrightness / 255.0

            android.util.Log.d("NothFlows", "Converted: $brightnessValue% -> androidBrightness=$androidBrightness/255 (with gamma correction)")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val canWrite = Settings.System.canWrite(this)
                android.util.Log.d("NothFlows", "Can write system settings: $canWrite")

                if (canWrite) {
                    // On modern Android we should set the system brightness
                    return trySetSystemBrightness(androidBrightness, normalized)
                } else {
                    // Fallback: adjust only this window's brightness (no permission needed)
                    android.util.Log.w("NothFlows", "No write permission, using window-level brightness fallback")
                    return setWindowBrightness(normalized.toFloat())
                }
            } else {
                Settings.System.putInt(
                    contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS,
                    androidBrightness
                )
                Settings.System.putInt(
                    contentResolver,
                    Settings.System.SCREEN_BRIGHTNESS_MODE,
                    Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
                )
                true
            }
        } catch (e: Exception) {
            android.util.Log.e("NothFlows", "Exception in setBrightness", e)
            e.printStackTrace()
            // As a last resort, try window-level brightness so we don't fail completely
            val normalized = (brightness.coerceIn(0, 100) / 100.0).toFloat()
            return setWindowBrightness(normalized)
        }
    }

    private fun trySetSystemBrightness(androidBrightness: Int, normalized: Double): Boolean {
        android.util.Log.d("NothFlows", "trySetSystemBrightness: androidBrightness=$androidBrightness, normalized=$normalized")
        return try {
            // First, ensure we're in manual brightness mode
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )
            android.util.Log.d("NothFlows", "Set SCREEN_BRIGHTNESS_MODE to MANUAL")

            // Set the brightness value (0-255 scale)
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                androidBrightness
            )
            android.util.Log.d("NothFlows", "Set SCREEN_BRIGHTNESS to $androidBrightness")

            // Verify what was actually written to system settings
            val actualSystemBrightness = Settings.System.getInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                -1
            )
            android.util.Log.d("NothFlows", "Verified system brightness value: $actualSystemBrightness/255 (${(actualSystemBrightness * 100 / 255.0).toInt()}%) - expected: $androidBrightness/255 (${(androidBrightness * 100 / 255.0).toInt()}%)")

            if (actualSystemBrightness != androidBrightness) {
                android.util.Log.w("NothFlows", "WARNING: System brightness mismatch! Requested $androidBrightness but got $actualSystemBrightness. Nothing OS may be enforcing limits.")
            }

            // Broadcast a brightness change intent to notify system components
            val intent = android.content.Intent("android.intent.action.SCREEN_BRIGHTNESS_CHANGED")
            intent.putExtra("brightness", androidBrightness)
            sendBroadcast(intent)
            android.util.Log.d("NothFlows", "Broadcast brightness change intent")

            // Reset window brightness to use system default (-1.0 means use system setting)
            runOnUiThread {
                try {
                    val lp = window?.attributes
                    if (lp != null) {
                        lp.screenBrightness = -1.0f  // Use system brightness setting
                        window?.attributes = lp
                        android.util.Log.d("NothFlows", "Reset window to use system brightness")
                    }
                } catch (e: Exception) {
                    android.util.Log.e("NothFlows", "Error resetting window brightness", e)
                    e.printStackTrace()
                }
            }

            android.util.Log.d("NothFlows", "Brightness set successfully")
            true
        } catch (e: Exception) {
            android.util.Log.e("NothFlows", "Error in trySetSystemBrightness", e)
            e.printStackTrace()
            false
        }
    }

    private fun setWindowBrightness(brightness: Float): Boolean {
        android.util.Log.w("NothFlows", "Using fallback window-level brightness (app-only, not system-wide)")
        return try {
            val lp = window?.attributes ?: return false
            lp.screenBrightness = brightness
            window?.attributes = lp
            android.util.Log.d("NothFlows", "Set window brightness to $brightness (affects app only)")
            true
        } catch (e: Exception) {
            android.util.Log.e("NothFlows", "Error in setWindowBrightness", e)
            e.printStackTrace()
            false
        }
    }

    private fun setVolume(level: Int): Boolean {
        android.util.Log.d("NothFlows", "setVolume called with level: $level%")
        return try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
            val volumeLevel = (level / 100.0 * maxVolume).toInt().coerceIn(0, maxVolume)

            android.util.Log.d("NothFlows", "Volume calculation: $level% -> $volumeLevel/$maxVolume")

            audioManager.setStreamVolume(
                AudioManager.STREAM_MUSIC,
                volumeLevel,
                AudioManager.FLAG_SHOW_UI  // Show volume UI to confirm change
            )

            // Verify the volume was actually set
            val actualVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
            android.util.Log.d("NothFlows", "Volume set result: requested=$volumeLevel, actual=$actualVolume")

            true
        } catch (e: Exception) {
            android.util.Log.e("NothFlows", "Error in setVolume", e)
            e.printStackTrace()
            false
        }
    }
}
