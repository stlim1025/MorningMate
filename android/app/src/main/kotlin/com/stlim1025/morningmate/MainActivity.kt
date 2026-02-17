package com.stlim1025.morningmate

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import android.app.KeyguardManager
import android.content.Context
import android.view.WindowManager
import android.util.Base64
import android.util.Log
import android.content.pm.PackageManager
import java.security.MessageDigest

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        printKeyHash()

        // 잠금 화면에서 알람을 표시하기 위한 설정
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "high_importance_channel",
                "High Importance Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "중요 알림을 표시하기 위한 채널입니다."
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }
    private fun printKeyHash() {
        try {
            val pm = packageManager

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = pm.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                val signingInfo = info.signingInfo
                // signingInfo가 null일 수 있어서 안전 처리
                signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                val info = pm.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                @Suppress("DEPRECATION")
                info.signatures
            }

            if (signatures == null) {
                Log.e("KAKAO_KEYHASH", "signatures is null")
                return
            }

            for (sig in signatures) {
                val md = MessageDigest.getInstance("SHA-1")
                md.update(sig.toByteArray())
                val keyHash = Base64.encodeToString(md.digest(), Base64.NO_WRAP)
                Log.d("KAKAO_KEYHASH", keyHash)
            }
        } catch (e: Exception) {
            Log.e("KAKAO_KEYHASH", "error", e)
        }
    }
}
