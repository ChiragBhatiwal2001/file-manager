package com.example.file_manager

//import android.content.Intent
//import android.net.Uri
//import android.os.Environment
//import android.os.Build
import android.os.Environment
//import android.provider.Settings
//import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
//import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.file_manager/storage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getInternalStoragePath") {
                val path = Environment.getExternalStorageDirectory().absolutePath
                result.success(path)
            } else {
                result.notImplemented()
            }
//            when (call.method) {
//                "getInternalStoragePath" -> {
//                    val path = Environment.getExternalStorageDirectory().absolutePath
//                    result.success(path)
//                }
//
//                "getAndroidDataPath" -> {
//                    val path =
//                        File(Environment.getExternalStorageDirectory(), "Android/data").absolutePath
//                    result.success(path)
//                }
//
//                "hasAllFilesPermission" -> {
//                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
//                        result.success(Environment.isExternalStorageManager())
//                    } else {
//                        result.success(true)
//                    }
//                }
//
//                "requestAllFilesPermission" -> {
//                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
//                        try {
//                            val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
//                            intent.data = Uri.parse("package:$packageName")
//                            startActivity(intent)
//                            result.success(true)
//                        } catch (e: Exception) {
//                            e.printStackTrace()
//                            result.error(
//                                "PERMISSION_ERROR",
//                                "Failed to request MANAGE_EXTERNAL_STORAGE",
//                                null
//                            )
//                        }
//                    } else {
//                        result.success(true)
//                    }
//                }
//
//                else -> result.notImplemented()
//            }
        }
    }
}

