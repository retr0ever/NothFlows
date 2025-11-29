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
    private val APP_INTEGRATION_CHANNEL = "com.nothflows/app_integration"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // System control channel
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

                // ============================================================
                // ACCESSIBILITY NATIVE METHODS
                // ============================================================

                "setTextSize" -> {
                    val size = call.argument<String>("size") ?: "medium"
                    val scale = when(size) {
                        "small" -> 0.85f
                        "medium" -> 1.0f
                        "large" -> 1.15f
                        "max" -> 1.3f
                        else -> 1.0f
                    }
                    try {
                        Settings.System.putFloat(contentResolver, Settings.System.FONT_SCALE, scale)
                        android.util.Log.d("NothFlows", "Set text size to $size (scale: $scale)")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to set text size", e)
                        result.error("FAILED", "Cannot set text size", null)
                    }
                }

                "setHighContrast" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            // Prefer high-contrast text where available
                            try {
                                Settings.Secure.putInt(
                                    contentResolver,
                                    "high_text_contrast_enabled",
                                    1,
                                )
                                android.util.Log.d("NothFlows", "Enabled high text contrast")
                            } catch (inner: Exception) {
                                android.util.Log.w(
                                    "NothFlows",
                                    "High text contrast setting not available, falling back to inversion: $inner",
                                )
                            }

                            // Fallback: enable display inversion as a visible contrast aid
                            try {
                                Settings.Secure.putInt(
                                    contentResolver,
                                    Settings.Secure.ACCESSIBILITY_DISPLAY_INVERSION_ENABLED,
                                    1,
                                )
                                android.util.Log.d("NothFlows", "Enabled display inversion for contrast")
                            } catch (inner: Exception) {
                                android.util.Log.w(
                                    "NothFlows",
                                    "Failed to toggle display inversion: $inner",
                                )
                            }

                            result.success(true)
                        } else {
                            result.error("UNSUPPORTED", "High contrast requires Android N+", null)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to set high contrast", e)
                        result.error("FAILED", "Cannot set high contrast: ${e.message}", null)
                    }
                }

                "setAnimationScale" -> {
                    val scale = call.argument<Double>("scale")?.toFloat() ?: 1.0f
                    try {
                        Settings.Global.putFloat(contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, scale)
                        Settings.Global.putFloat(contentResolver, Settings.Global.TRANSITION_ANIMATION_SCALE, scale)
                        Settings.Global.putFloat(contentResolver, Settings.Global.WINDOW_ANIMATION_SCALE, scale)
                        android.util.Log.d("NothFlows", "Set animation scale to $scale")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to set animation scale", e)
                        result.error("FAILED", "Cannot set animation scale: ${e.message}", null)
                    }
                }

                "enableVoiceTyping" -> {
                    try {
                        // Try dedicated voice input settings first, then fall back
                        val intents = listOf(
                            Intent(Settings.ACTION_VOICE_INPUT_SETTINGS),
                            Intent("com.google.android.settings.VOICE_INPUT"),
                            Intent(Settings.ACTION_INPUT_METHOD_SETTINGS),
                        )

                        var launched = false
                        for (intent in intents) {
                            try {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                launched = true
                                android.util.Log.d("NothFlows", "Opened voice typing settings via ${intent.action}")
                                break
                            } catch (ignored: Exception) {
                                // Try next intent
                            }
                        }

                        if (launched) {
                            result.success(true)
                        } else {
                            android.util.Log.e("NothFlows", "No available intent for voice typing settings")
                            result.error("FAILED", "Voice typing settings not available on this device", null)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to open input settings", e)
                        result.error("FAILED", "Cannot open input settings", null)
                    }
                }

                "enableCaptions" -> {
                    try {
                        // First try to toggle system captioning directly (requires WRITE_SECURE_SETTINGS)
                        var succeeded = false
                        try {
                            Settings.Secure.putInt(
                                contentResolver,
                                "accessibility_captioning_enabled",
                                1,
                            )
                            android.util.Log.d("NothFlows", "Enabled system captions via secure setting")
                            succeeded = true
                        } catch (inner: Exception) {
                            android.util.Log.w(
                                "NothFlows",
                                "Direct caption toggle failed (likely missing WRITE_SECURE_SETTINGS): $inner",
                            )
                        }

                        if (!succeeded) {
                            // Fallback: open system caption settings so the user can enable manually
                            try {
                                val intent = Intent(Settings.ACTION_CAPTIONING_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                android.util.Log.d("NothFlows", "Opened captioning settings UI")
                                result.success(true)
                                return@setMethodCallHandler
                            } catch (inner: Exception) {
                                android.util.Log.w(
                                    "NothFlows",
                                    "Caption settings intent failed, falling back to accessibility settings: $inner",
                                )
                                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                android.util.Log.d("NothFlows", "Opened general accessibility settings UI")
                                result.success(true)
                                return@setMethodCallHandler
                            }
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to enable captions", e)
                        result.error("FAILED", "Cannot enable captions: ${e.message}", null)
                    }
                }

                "enableFlashAlerts" -> {
                    try {
                        var succeeded = false

                        // Try device-specific global setting if available
                        try {
                            Settings.System.putInt(contentResolver, "flash_notification", 1)
                            android.util.Log.d("NothFlows", "Enabled flash alerts via system setting")
                            succeeded = true
                        } catch (inner: Exception) {
                            android.util.Log.w(
                                "NothFlows",
                                "Direct flash alert toggle failed (likely OEM/permission): $inner",
                            )
                        }

                        if (!succeeded) {
                            // Fallback: open notification / accessibility settings where flash alerts usually live
                            try {
                                val intent = Intent("android.settings.NOTIFICATION_ASSISTANT_LIST")
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                android.util.Log.d("NothFlows", "Opened notification assistant settings for flash alerts")
                                result.success(true)
                            } catch (inner: Exception) {
                                android.util.Log.w(
                                    "NothFlows",
                                    "Notification assistant intent failed, opening accessibility settings: $inner",
                                )
                                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                android.util.Log.d("NothFlows", "Opened accessibility settings as flash alert fallback")
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to enable flash alerts", e)
                        result.error("FAILED", "Cannot enable flash alerts: ${e.message}", null)
                    }
                }

                "setHapticStrength" -> {
                    val strength = call.argument<String>("strength") ?: "medium"
                    val intensity = when(strength) {
                        "light" -> 50
                        "medium" -> 100
                        "strong" -> 255
                        else -> 100
                    }
                    try {
                        var succeeded = false

                        // Try to set system haptic intensity (may require privileged permission)
                        try {
                            Settings.System.putInt(
                                contentResolver,
                                "haptic_feedback_intensity",
                                intensity,
                            )
                            android.util.Log.d("NothFlows", "Set haptic strength to $strength (intensity: $intensity)")
                            succeeded = true
                        } catch (inner: Exception) {
                            android.util.Log.w(
                                "NothFlows",
                                "Direct haptic intensity change failed (likely missing permission): $inner",
                            )
                        }

                        if (!succeeded) {
                            // Fallback: open sound and vibration settings so the user can adjust vibration strength
                            try {
                                val intent = Intent(Settings.ACTION_SOUND_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                android.util.Log.d("NothFlows", "Opened sound settings for haptic configuration")
                                result.success(true)
                            } catch (inner: Exception) {
                                android.util.Log.e(
                                    "NothFlows",
                                    "Failed to open sound settings for haptics: $inner",
                                )
                                result.error(
                                    "FAILED",
                                    "Cannot set haptic strength: ${inner.message}",
                                    null,
                                )
                            }
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Failed to set haptic strength", e)
                        result.error("FAILED", "Cannot set haptic strength: ${e.message}", null)
                    }
                }

                "enableOneHandedMode" -> {
                    try {
                        // One-handed mode settings (manufacturer-specific)
                        val intent = Intent("android.settings.GESTURE_SETTINGS")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        android.util.Log.d("NothFlows", "Opened gesture settings for one-handed mode")
                        result.success(true)
                    } catch (e: Exception) {
                        // Fallback to general settings
                        try {
                            val intent = Intent(Settings.ACTION_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            android.util.Log.e("NothFlows", "Failed to open one-handed mode settings", e)
                            result.error("FAILED", "Cannot enable one-handed mode", null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        // App integration channel for launching external apps
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_INTEGRATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    try {
                        val isEnabled = NothFlowsAccessibilityService.isEnabled()
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Error checking accessibility status", e)
                        result.success(false)
                    }
                }

                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        android.util.Log.d("NothFlows", "Opened accessibility settings")
                        result.success(true)
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Error opening accessibility settings", e)
                        result.error("FAILED", "Cannot open settings: ${e.message}", null)
                    }
                }

                "readScreenContent" -> {
                    try {
                        // Use accessibility service to read content from any app
                        val service = NothFlowsAccessibilityService.getInstance()
                        if (service != null) {
                            val content = service.readCurrentScreen()
                            result.success(content)
                        } else {
                            result.error("NOT_ENABLED", "Accessibility service is not enabled", null)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Error reading screen content", e)
                        result.error("FAILED", "Cannot read screen: ${e.message}", null)
                    }
                }

                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("INVALID_ARGS", "Missing packageName", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val intent = packageManager.getLaunchIntentForPackage(packageName)
                        if (intent != null) {
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            android.util.Log.d("NothFlows", "Launched app: $packageName")
                            result.success(true)
                        } else {
                            android.util.Log.w("NothFlows", "App not found: $packageName")
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Error launching app: $packageName", e)
                        result.error("FAILED", "Cannot launch app: ${e.message}", null)
                    }
                }

                "launchGmailApp" -> {
                    try {
                        // Try to launch Gmail with ACTION_MAIN
                        val intent = packageManager.getLaunchIntentForPackage("com.google.android.gm")
                        if (intent != null) {
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            android.util.Log.d("NothFlows", "Launched Gmail app")
                            result.success(true)
                        } else {
                            // Gmail not installed, try generic email intent
                            val emailIntent = Intent(Intent.ACTION_MAIN)
                            emailIntent.addCategory(Intent.CATEGORY_APP_EMAIL)
                            emailIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            try {
                                startActivity(emailIntent)
                                android.util.Log.d("NothFlows", "Launched default email app")
                                result.success(true)
                            } catch (e: Exception) {
                                android.util.Log.e("NothFlows", "No email app found", e)
                                result.success(false)
                            }
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Error launching Gmail", e)
                        result.error("FAILED", "Cannot launch Gmail: ${e.message}", null)
                    }
                }

                "launchWeatherApp" -> {
                    try {
                        // Try common weather app packages (Nothing, Google, etc.)
                        val weatherPackages = listOf(
                            "com.nothing.weather",           // Nothing Weather
                            "com.google.android.apps.weather", // Google Weather
                            "com.weather.Weather",            // Generic Weather
                            "com.android.settings.weather"    // Settings Weather Widget
                        )

                        var launched = false
                        for (packageName in weatherPackages) {
                            try {
                                val intent = packageManager.getLaunchIntentForPackage(packageName)
                                if (intent != null) {
                                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    startActivity(intent)
                                    android.util.Log.d("NothFlows", "Launched weather app: $packageName")
                                    launched = true
                                    break
                                }
                            } catch (e: Exception) {
                                continue
                            }
                        }

                        if (!launched) {
                            // Fallback: open weather via web browser
                            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/search?q=weather"))
                            webIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            try {
                                startActivity(webIntent)
                                android.util.Log.d("NothFlows", "Opened weather via browser")
                                launched = true
                            } catch (e: Exception) {
                                android.util.Log.e("NothFlows", "Failed to open weather via browser", e)
                            }
                        }

                        result.success(launched)
                    } catch (e: Exception) {
                        android.util.Log.e("NothFlows", "Error launching weather app", e)
                        result.error("FAILED", "Cannot launch weather app: ${e.message}", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun convertToNothingBrightness(userPercent: Int): Int {
        // Nothing OS brightness slider doesn't match Android system values linearly
        // This lookup table maps user-requested percentages to values that show correctly on Nothing's slider
        // Calibrated through testing to match slider visual feedback

        val percent = userPercent.coerceIn(0, 100)

        // Empirical mapping table for Nothing OS
        // These values were determined by observing what system brightness produces which slider position
        val androidValue = when {
            percent == 0 -> 1       // Minimum (not 0, to avoid screen off)
            percent <= 10 -> 13     // ~5%  slider
            percent <= 20 -> 38     // ~15% slider
            percent <= 30 -> 64     // ~25% slider
            percent <= 40 -> 89     // ~35% slider
            percent <= 50 -> 115    // ~45% slider (close to 50%)
            percent <= 60 -> 140    // ~55% slider
            percent <= 70 -> 166    // ~65% slider
            percent <= 80 -> 191    // ~75% slider
            percent <= 90 -> 217    // ~85% slider
            else -> 255             // 100% slider (maximum)
        }

        android.util.Log.d("NothFlows", "Nothing brightness lookup: $userPercent% user → $androidValue/255 Android (calibrated for Nothing slider)")
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
