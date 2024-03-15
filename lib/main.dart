import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/screens/home/payment_screen.dart';
import 'package:eggciting/screens/adding/post_success_screen.dart';
import 'package:eggciting/services/location_provider.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:eggciting/screens/signin/agreement_screen.dart';
import 'package:eggciting/screens/home/home_screen.dart';
import 'package:eggciting/screens/home/list_screen.dart';
import 'package:eggciting/screens/signin/login_screen.dart';
import 'package:eggciting/screens/adding/map_selection_screen.dart';
import 'package:eggciting/screens/signin/nickname_screen.dart';
import 'package:eggciting/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// request permissions
Future<void> requestPermissions() async {
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  } else if (await Permission.location.isPermanentlyDenied) {
    await openAppSettings();
  } else if (await Permission.locationWhenInUse.isDenied) {
    await Permission.locationWhenInUse.request();
  } else if (await Permission.locationWhenInUse.isPermanentlyDenied) {
    await openAppSettings();
  }

  await Permission.camera.request();
  await Permission.notification.request();
  await Permission.microphone.request();
  await Permission.photos.request();
}

void main() async {
  await dotenv.load();

  await requestPermissions();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  await LineSDK.instance.setup(dotenv.env['lineChannelId']!).then((_) {
    // debugPrint('LineSDK Prepared');
  });

  // String apiKey = dotenv.env['kakaoNativeAppKey']!;
  // debugPrint('API Key: $apiKey');

  KakaoSdk.init(
    nativeAppKey: dotenv.env['kakaoNativeAppKey']!,
    javaScriptAppKey: dotenv.env['kakaoJavaScriptAppKey']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              PostsProvider(), // Create instance of PostsProvider
        ),
        ChangeNotifierProvider(
          create: (context) =>
              LocationProvider(), // Create instance of LocationProvider
        ),
      ],
      child: MyApp(firestore: firestore),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.firestore});
  final FirebaseFirestore firestore;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const locationChannel = MethodChannel('locationPlatform');

  final _eventChannel = const EventChannel('com.dts.eggciting/location');

  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
    // _notificationService.monitorLocationAndTriggerNotification();
    Provider.of<LocationProvider>(context, listen: false)
        .startTrackingLocation();

    subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        debugPrint('Flutter Received: $event');
      },
      onError: (Object obj, StackTrace stackTrace) {
        debugPrint('Error: $obj');
        debugPrint('Stack: $stackTrace');
      },
    );

    try {
      locationChannel.invokeMethod('getLocation');
    } on PlatformException catch (e) {
      debugPrint('Error: ${e.message}');
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eggciting',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF67280),
        ).copyWith(
          primary: const Color(0xFFF67280),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginPage(firestore: widget.firestore),
        '/home': (context) => HomeScreen(firestore: widget.firestore),
        '/agreement': (context) => AgreementScreen(firestore: widget.firestore),
        '/nickname': (context) => NicknameScreen(firestore: widget.firestore),
        '/mapSelection': (context) => const MapSelectionScreen(),
        '/list': (context) => const ListScreen(),
        '/postSuccess': (context) => const PostSuccessScreen(
              imageAssetPaths: ['assets/images/logo.png'],
            ),
        '/payment': (context) => const PaymentScreen(),
      },
    );
  }
}
