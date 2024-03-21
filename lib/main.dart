import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/models/global_location_data.dart';
import 'package:eggciting/models/post.dart';
import 'package:eggciting/screens/home/map_screen.dart';
import 'package:eggciting/screens/home/payment_screen.dart';
import 'package:eggciting/screens/adding/post_success_screen.dart';
import 'package:eggciting/screens/opening/post_details_screen.dart';
import 'package:eggciting/services/notification_service.dart';
import 'package:eggciting/services/post_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  // await Permission.camera.request();
  await Permission.notification.request();
  // await Permission.microphone.request();
  // await Permission.photos.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBranchSdk.init(
    useTestKey: false,
    enableLogging: true,
  );

  await dotenv.load();

  await requestPermissions();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  await LineSDK.instance.setup(dotenv.env['lineChannelId']!).then((_) {
    // debugPrint('LineSDK Prepared');
  });

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

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? subscription;

  void _locationStream() {
    NotificationService notificationService = NotificationService();
    subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        debugPrint('Flutter Received: $event');
        final parts = event.toString().split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null) {
            GlobalLocationData().currentLocation = LatLng(lat, lng);
            notificationService.monitorLocationAndTriggerNotification();
          }
        }
      },
      onError: (Object obj, StackTrace stackTrace) {
        debugPrint('Error: $obj');
        debugPrint('Stack: $stackTrace');
      },
    );
  }

  void _initialization() async {
    AndroidInitializationSettings android =
        const AndroidInitializationSettings("@mipmap/ic_launcher");
    DarwinInitializationSettings ios = const DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    InitializationSettings settings =
        InitializationSettings(android: android, iOS: ios);
    await _local.initialize(settings);
  }

  @override
  void initState() {
    super.initState();
    _locationStream();
    _initialization();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Listen for deep link events
    FlutterBranchSdk.listSession().listen((linkData) async {
      // Extract the post ID from the link data
      String? postId = linkData['postId'];
      if (postId != null) {
        // Fetch the current user's ID
        String? currentUserId = FirebaseAuth.instance.currentUser!.uid;
        debugPrint('Current User ID in main.dart: $currentUserId');
        // Fetch the post from Firestore
        DocumentSnapshot postSnapshot =
            await widget.firestore.collection('posts').doc(postId).get();

        if (postSnapshot.exists) {
          // Convert the post document to a Post object
          Post post =
              Post.fromJson(postSnapshot.data() as Map<String, dynamic>);

          // Check if the current user is already in the sharedUser list
          if (!post.sharedUser.contains(currentUserId)) {
            // Add the current user to the sharedUser list
            post.sharedUser.add(currentUserId);

            // Save the updated post back to Firestore
            await widget.firestore
                .collection('posts')
                .doc(postId)
                .update({'sharedUser': post.sharedUser});
          }

          // Navigate to the post details screen with the post ID
          FutureBuilder(
            future: Future.delayed(Duration.zero),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailsScreen(post: post),
                  ),
                );
              }
              return Container();
            },
          );
        }
      }
    }, onError: (error) {
      debugPrint('Error: $error');
    });

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
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomeScreen(firestore: widget.firestore),
        '/agreement': (context) => AgreementScreen(firestore: widget.firestore),
        '/nickname': (context) => NicknameScreen(firestore: widget.firestore),
        '/mapSelection': (context) => const MapSelectionScreen(),
        '/mapScreen': (context) => const MapScreen(),
        '/list': (context) => const ListScreen(),
        '/postSuccess': (context) => const PostSuccessScreen(
              imageAssetPaths: ['assets/images/logo.png'],
            ),
        '/payment': (context) => const PaymentScreen(),
      },
    );
  }
}
