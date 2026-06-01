package com.pbm.safe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.view.WindowManager
import android.os.Build
import android.content.Intent
import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.pbm.safe/app_retriever"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        turnScreenOnAndShow()
    }

    private fun turnScreenOnAndShow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "bringToForeground") {
                try {
                    // Try bringing to foreground using ActivityManager moveTaskToFront (needs REORDER_TASKS permission)
                    val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                    val tasks = activityManager.runningAppProcesses
                    var taskBroughtToFront = false
                    
                    // We can also reorder using getRunningTasks (deprecated but works for our own package)
                    @Suppress("DEPRECATION")
                    val runningTasks = activityManager.getRunningTasks(10)
                    for (task in runningTasks) {
                        if (task.baseActivity?.packageName == packageName) {
                            activityManager.moveTaskToFront(task.id, ActivityManager.MOVE_TASK_WITH_HOME)
                            taskBroughtToFront = true
                            break
                        }
                    }

                    // Always trigger launch intent to ensure the activity state is refreshed/launched properly
                    val intent = packageManager.getLaunchIntentForPackage(packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or 
                                        Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        applicationContext.startActivity(intent)
                    } else {
                        val fallbackIntent = Intent(this, MainActivity::class.java)
                        fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or 
                                                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or 
                                                Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        applicationContext.startActivity(fallbackIntent)
                    }

                    // Turn on screen and dismiss keyguard
                    turnScreenOnAndShow()
                    result.success(true)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
