package com.mystyle.purelive

import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import com.alizda.better_player.PlaybackService
class MainActivity: FlutterActivity() {

  private var isServiceRunning = false

  override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startNotificationService()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopNotificationService()
    }
    private fun startNotificationService() {
        if (!isServiceRunning) {
            val intent = Intent(this, PlaybackService::class.java)
            startForegroundService(intent)
            isServiceRunning = true
        }
    }
    private fun stopNotificationService() {
        stopService(Intent(this, PlaybackService::class.java))
        isServiceRunning = false
    }
}
