package com.dts.eggciting

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel


class MainActivity: FlutterFragmentActivity(), LocationCallback {

    private val REQUIRED_PERMISSIONS = mutableListOf(
        android.Manifest.permission.ACCESS_FINE_LOCATION,
        android.Manifest.permission.ACCESS_COARSE_LOCATION
    ).apply {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            add(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        }
    }.toTypedArray()

    private val networkEventChannel = "com.dts.eggciting/location"
    private var attachEvent: EventChannel.EventSink? = null

    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { isGranted ->
        Log.i("isGranted", isGranted.toString())
        if (isGranted.containsValue(false)) {
            Toast.makeText(this, "Location permission denied", Toast.LENGTH_SHORT).show()
        } else {
            val locationManager =
                getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val isEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) || locationManager.isProviderEnabled(
                LocationManager.NETWORK_PROVIDER
            )
            if (isEnabled) {
                val serviceIntent = Intent(this, LocationService::class.java).apply {
                    action = LocationService.ACTION_START
                }
                startService(serviceIntent)
                bindService(serviceIntent, serviceConnection, Context.BIND_AUTO_CREATE)
            } else {
                val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                startActivity(intent)
                Toast.makeText(this@MainActivity, "Please enable GPS", Toast.LENGTH_LONG)
                    .show()
            }
        }
    }

    private var locationService: LocationService? = null
    private var isServiceBound = false

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as LocationService.LocalBinder
            locationService = binder.getService()
            locationService?.setLocationCallback(this@MainActivity)
            isServiceBound = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            locationService = null
            isServiceBound = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "location",
                "Location",
                NotificationManager.IMPORTANCE_LOW
            )
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine : FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            networkEventChannel
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    Log.w("TAG_NAME", "Adding listener")
                    attachEvent = events
                }

                override fun onCancel(arguments: Any) {
                    Log.w("TAG_NAME", "Removing listener")
                    attachEvent = null
                    println("StreamHandler onCancel")
                }
            }
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "locationPlatform"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocation" -> {
                    requestPermissionLauncher.launch(REQUIRED_PERMISSIONS)
                }

                "stopLocation" -> {
                    val serviceIntent = Intent(this, LocationService::class.java).apply {
                        action = LocationService.ACTION_STOP
                        startService(this)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onLocationUpdated(latitude: Double, longitude: Double) {
        runOnUiThread {
            Log.i("attachevent", "${attachEvent}",)
            // Toast.makeText(this, "Location: ${latitude}, ${longitude}", Toast.LENGTH_SHORT).show()

            attachEvent?.success("${latitude}, ${longitude}")
        }
    }
}
