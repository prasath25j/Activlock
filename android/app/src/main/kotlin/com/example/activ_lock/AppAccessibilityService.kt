package com.example.activ_lock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.content.SharedPreferences

class AppAccessibilityService : AccessibilityService() {
    private var nativeLockedApps: List<String> = emptyList()

    override fun onServiceConnected() {
        super.onServiceConnected()
        loadLockedApps()
    }

    private fun loadLockedApps() {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawList = prefs.getString("flutter.native_locked_apps", "") ?: ""
        nativeLockedApps = if (rawList.isNotEmpty()) rawList.split(",") else emptyList()
    }

    private var lastLockTime: Long = 0
    private val LOCK_TIMEOUT = 1000L // 1 second cooldown

    private fun isAppTemporarilyUnlocked(packageName: String): Boolean {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val expiry = prefs.getLong("flutter.unlock_expiry_$packageName", 0L)
        return System.currentTimeMillis() < expiry
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Always reload the list before checking
        loadLockedApps()

        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && 
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // Skip if it's our own app
        if (packageName == "com.example.activ_lock") return

        // Deduplicate rapid firing events
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastLockTime < LOCK_TIMEOUT) return

        if (nativeLockedApps.contains(packageName)) {
            // CHECK EXPIRY: If app is still within its temporary unlock window, don't lock
            if (isAppTemporarilyUnlocked(packageName)) {
                return 
            }

            // App is locked or expiry reached! Launch our lock screen
            lastLockTime = currentTime
            android.util.Log.d("ActivLock", "Locking package: $packageName")
            
            val intent = Intent(this, MainActivity::class.java)
            // Critical Flags for Background Launch
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION or 
                    Intent.FLAG_ACTIVITY_NO_HISTORY
            
            intent.putExtra("locked_package", packageName)
            intent.putExtra("route", "/lock_screen")
            
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Required method
    }
}
