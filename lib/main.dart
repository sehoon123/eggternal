import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eggciting/handler/location_handler.dart';
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
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
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

  await Permission.notification.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBranchSdk.init(
    // useTestKey: false,
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

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocationHandler _locationHandler = LocationHandler();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? subscription;

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

  Future<void> _initializeLocationHandler() async {
    // Load the initial value of useBackgroundNotifications from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool useBackgroundNotifications =
        prefs.getBool('useBackgroundNotifications') ?? false;
    _locationHandler
        .updateUseBackgroundNotifications(useBackgroundNotifications);
  }

  @override
  void initState() {
    super.initState();
    _initializeLocationHandler();
    _initialization();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SchedulerBinding.instance.addPostFrameCallback(
      (_) {
        FlutterBranchSdk.listSession().listen((linkData) async {
          debugPrint('Link Data: $linkData');
          // Extract the post data from the link data
          Map<String, dynamic>? postData = jsonDecode(linkData['post']);
          if (postData != null) {
            // Fetch the current user's ID
            String? currentUserId = FirebaseAuth.instance.currentUser!.uid;
            debugPrint('Current User ID in main.dart: $currentUserId');

            // Convert the post data to a Post object
            Post post = Post.fromSharedJson(postData);

            debugPrint('post: $post');

            // Get a reference to the user document
            DocumentReference userDoc = FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId);
            DocumentSnapshot userSnapshot = await userDoc.get();

            if (userSnapshot.exists) {
              // Check if the post is already in the user's posts
              Map<String, dynamic>? userPosts =
                  (userSnapshot.data() as Map<String, dynamic>?)?['posts'];
              if (userPosts != null &&
                  userPosts.containsKey('shared_${post.key}')) {
                // The post is already in the user's posts, so we can proceed to the PostDetailsScreen
                debugPrint("moving to post details screen, post: ${post.key}");
                MyApp.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailsScreen(
                      post: post,
                    ),
                  ),
                );
              } else {
                // The post is not in the user's posts, so we need to add it
                // Create a map representing the post data
                Map<String, dynamic> postMap = post.toJson();

                // Update the user document by adding the post data to the 'posts' map field
                await userDoc.update({
                  'posts.shared_${post.key}': postMap,
                });

                // Now that the post is added to the user's posts, we can proceed to the PostDetailsScreen
                debugPrint("moving to post details screen, post: ${post.key}");
                MyApp.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailsScreen(
                      post: post,
                    ),
                  ),
                );
              }
            }
          }
        }, onError: (error) {
          debugPrint('Error: $error');
        });
      },
    );
    // Listen for deep link events
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
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
        '/payment': (context) => const PaymentScreen(),
      },
    );
  }
}
