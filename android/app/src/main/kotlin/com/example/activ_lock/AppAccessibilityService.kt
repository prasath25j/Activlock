package com.example.activ_lock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.content.SharedPreferences
import android.util.Log

class AppAccessibilityService : AccessibilityService() {
    private var nativeLockedApps: List<String> = emptyList()

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("ActivLock", "Accessibility Service Connected")
        loadLockedApps()
    }

    private fun loadLockedApps() {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawList = prefs.getString("flutter.native_locked_apps", "") ?: ""
        nativeLockedApps = if (rawList.isNotEmpty()) rawList.split(",") else emptyList()
    }

    private fun isAppTemporarilyUnlocked(packageName: String): Boolean {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val expiry = prefs.getLong("flutter.unlock_expiry_$packageName", 0L)
        return System.currentTimeMillis() < expiry
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && 
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return
        if (packageName == getPackageName()) return

        loadLockedApps()

        if (nativeLockedApps.contains(packageName)) {
            if (isAppTemporarilyUnlocked(packageName)) {
                return 
            }

            Log.d("ActivLock", "Locking package: $packageName")
            
            val intent = Intent(this, MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            
            intent.putExtra("locked_package", packageName)
            intent.putExtra("route", "/lock_screen")
            
            startActivity(intent)
        }
    }

    override fun onInterrupt() {}
}
