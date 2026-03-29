package com.example.safelink_n

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.safelink.sms/native"
    private val SMS_PERMISSION_CODE = 101
    private val CALL_PERMISSION_CODE = 102
    private var pendingResult: MethodChannel.Result? = null
    private var pendingPhone: String? = null
    private var pendingMessage: String? = null
    private var pendingCallResult: MethodChannel.Result? = null
    private var pendingCallPhone: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val phoneNumber = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    
                    if (phoneNumber != null && message != null) {
                        if (checkSmsPermission()) {
                            sendSMS(phoneNumber, message, result)
                        } else {
                            // Store pending SMS to send after permission granted
                            pendingResult = result
                            pendingPhone = phoneNumber
                            pendingMessage = message
                            requestSmsPermission()
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number or message is null", null)
                    }
                }
                "makeCall" -> {
                    val phoneNumber = call.argument<String>("phone")
                    
                    if (phoneNumber != null) {
                        if (checkCallPermission()) {
                            makeCall(phoneNumber, result)
                        } else {
                            // Store pending call to make after permission granted
                            pendingCallResult = result
                            pendingCallPhone = phoneNumber
                            requestCallPermission()
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number is null", null)
                    }
                }
                "checkSmsPermission" -> {
                    result.success(checkSmsPermission())
                }
                "checkCallPermission" -> {
                    result.success(checkCallPermission())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkCallPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestSmsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.SEND_SMS),
            SMS_PERMISSION_CODE
        )
    }

    private fun requestCallPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CALL_PHONE),
            CALL_PERMISSION_CODE
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        when (requestCode) {
            SMS_PERMISSION_CODE -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // Permission granted - send pending SMS if any
                    if (pendingResult != null && pendingPhone != null && pendingMessage != null) {
                        sendSMS(pendingPhone!!, pendingMessage!!, pendingResult!!)
                        clearPendingSms()
                    }
                } else {
                    // Permission denied
                    pendingResult?.error("PERMISSION_DENIED", "User denied SMS permission", null)
                    clearPendingSms()
                }
            }
            CALL_PERMISSION_CODE -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // Permission granted - make pending call if any
                    if (pendingCallResult != null && pendingCallPhone != null) {
                        makeCall(pendingCallPhone!!, pendingCallResult!!)
                        clearPendingCall()
                    }
                } else {
                    // Permission denied
                    pendingCallResult?.error("PERMISSION_DENIED", "User denied CALL_PHONE permission", null)
                    clearPendingCall()
                }
            }
        }
    }

    private fun clearPendingSms() {
        pendingResult = null
        pendingPhone = null
        pendingMessage = null
    }

    private fun clearPendingCall() {
        pendingCallResult = null
        pendingCallPhone = null
    }

    private fun sendSMS(phoneNumber: String, message: String, result: MethodChannel.Result) {
        try {
            // Use modern SmsManager API for Android 12+ (API 31+)
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                this.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
            
            // Split message if too long (160 chars limit per SMS)
            val parts = smsManager.divideMessage(message)
            
            if (parts.size > 1) {
                // Send as multipart SMS for long messages
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            } else {
                // Send as single SMS
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            }
            
            result.success("SMS sent to $phoneNumber")
        } catch (e: SecurityException) {
            result.error("PERMISSION_ERROR", "SMS permission denied: ${e.message}", null)
        } catch (e: Exception) {
            result.error("SMS_FAILED", "Failed to send SMS: ${e.message}", null)
        }
    }

    private fun makeCall(phoneNumber: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$phoneNumber")
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            
            result.success("Call initiated to $phoneNumber")
        } catch (e: SecurityException) {
            result.error("PERMISSION_ERROR", "Call permission denied: ${e.message}", null)
        } catch (e: Exception) {
            result.error("CALL_FAILED", "Failed to make call: ${e.message}", null)
        }
    }
}
