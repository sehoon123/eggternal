package com.dts.eggciting

import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.Context
import android.os.Binder
import android.os.IBinder
import android.os.Bundle
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.lifecycle.ViewModelProvider
import com.google.android.gms.location.LocationServices
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import android.content.SharedPreferences
import android.os.Build
import android.app.NotificationChannel
import android.app.PendingIntent
import org.json.JSONObject
import android.location.Location



class LocationService(): Service() {
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var locationClient: LocationClient
    private val sharedPreferences: SharedPreferences by lazy {
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    private val notificationPreferences: SharedPreferences by lazy {
        getSharedPreferences("NotificationPreferences", Context.MODE_PRIVATE)
    }

    private val binder = LocalBinder()
    private var locationCallback: LocationCallback? = null

    inner class LocalBinder : Binder() {
        fun getService(): LocationService = this@LocationService
    }

    override fun onBind(intent: Intent): IBinder? {
        return binder
    }

    fun setLocationCallback(callback: LocationCallback) {
        locationCallback = callback
    }

    override fun onCreate() {
        super.onCreate()
        locationClient = DefaultLocationClient(
            applicationContext,
            LocationServices.getFusedLocationProviderClient(applicationContext)
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when(intent?.action) {
            ACTION_START -> start()
            ACTION_STOP -> stop()
        }
        return super.onStartCommand(intent, flags, startId)
    }

    private fun start() {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, pendingIntentFlags)

        val notification = NotificationCompat.Builder(this, "location")
            .setContentTitle("Tracking Eggs")
            .setContentText("Finding eggs near you...")
            .setContentIntent(pendingIntent)
            .setSmallIcon(R.drawable.launch_background)
            .setOngoing(true)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        locationClient
            .getLocationUpdates(10000L)
            .catch { e -> e.printStackTrace() }
            .onEach { location ->
                val lat = location.latitude
                val long = location.longitude
                // Log.i("data", "Location: $lat, $long")
                locationCallback?.onLocationUpdated(lat, long)

                // val trash = sharedPreferences.all.filterKeys { it.contains("notification")}
                // trash.forEach { (key, value) ->
                //     sharedPreferences.edit().remove(key).apply()
                // }

                // Log.i("SharedPreferences", "All entries: ${sharedPreferences.all}")

                // val allPostDetails = sharedPreferences.all.filterKeys { it.startsWith("flutter.postDetails") }
                // allPostDetails.forEach { (key, value) ->
                //     val postDetails = JSONObject(value.toString())
                //     val storedLocation = postDetails.getString("location").split(",")
                //     val storedLat = storedLocation[0].toDouble()
                //     val storedLong = storedLocation[1].toDouble()
                //     val distance = location.distanceTo(Location("").apply {
                //         latitude = storedLat
                //         longitude = storedLong
                //     })

                //     // Check if a notification has already been shown for this post
                //     val notificationShownKey = "$key.notificationShown"
                //     val notificationTimestampKey = "$key.notificationTimestamp"

                //     // Check if the keys exist in SharedPreferences
                //     val notificationShownExists = notificationPreferences.contains(notificationShownKey)
                //     val notificationTimestampExists = notificationPreferences.contains(notificationTimestampKey)

                //     // Retrieve the values only if the keys exist
                //     val notificationShown = if (notificationShownExists) {
                //         notificationPreferences.getBoolean(notificationShownKey, false)
                //     } else {
                //         false // Default value if the key does not exist
                //     }

                //     val notificationTimestamp = if (notificationTimestampExists) {
                //         notificationPreferences.getLong(notificationTimestampKey, 0)
                //     } else {
                //         0 // Default value if the key does not exist
                //     }

                //     val currentTime = System.currentTimeMillis()
                //     val timeDifference = currentTime - notificationTimestamp

                //     if (distance < 200 && (!notificationShown || timeDifference >= 7200000)) {
                //         triggerNotification("You are near a post ${postDetails.getString("title")}!")

                //         // Update the flag and timestamp in SharedPreferences
                //         notificationPreferences.edit()
                //             .putBoolean(notificationShownKey, true)
                //             .putLong(notificationTimestampKey, currentTime)
                //             .apply()
                //     }

                    // Log.i("postDetails", "postDetails: $postDetails")
                    // Log.i("notificationPreferences", "notificationPreferences: ${notificationPreferences.all}")
            }
            .launchIn(serviceScope)

        startForeground(1, notification.build())
    }

    private fun stop() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
    }

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
    }

    private fun triggerNotification(message: String) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "location_notification_channel"
        val channelName = "Location Notifications"
        val importance = NotificationManager.IMPORTANCE_HIGH

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationChannel = NotificationChannel(channelId, channelName, importance)
            notificationManager.createNotificationChannel(notificationChannel)
        }

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, pendingIntentFlags)

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Location Notification")
            .setContentText(message)
            .setSmallIcon(R.drawable.background) // Replace with your notification icon
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(1, notification)
    }
}
